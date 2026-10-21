package io.github.bruce_yang_422.life_chronicle

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.StatFs
import android.media.ExifInterface
import android.media.MediaMetadataRetriever
import android.webkit.MimeTypeMap
import android.content.Intent
import androidx.core.content.FileProvider
import java.io.File
import android.view.WindowManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.CancellationSignal
import android.os.Bundle
import android.Manifest
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.location.LocationListener
import android.net.Uri
import androidx.core.content.ContextCompat
import android.app.DatePickerDialog
import java.util.GregorianCalendar

class MainActivity : FlutterFragmentActivity() {
    private val photoWorker = java.util.concurrent.Executors.newSingleThreadExecutor()
    private val photoRequests = java.util.concurrent.ConcurrentHashMap<String, java.util.concurrent.atomic.AtomicBoolean>()
    private val photoHandler = Handler(Looper.getMainLooper())
    private var locationResult: MethodChannel.Result? = null
    private var locationCancellation: CancellationSignal? = null
    private var locationListener: LocationListener? = null
    private val locationHandler = Handler(Looper.getMainLooper())

    private fun finishLocation(location: Location? = null, error: String? = null, expected: MethodChannel.Result? = null) {
        val pending = locationResult ?: return
        // 已取消的原生回呼不得完成後續另一筆定位請求。
        if (expected != null && pending !== expected) return
        locationResult = null
        locationHandler.removeCallbacksAndMessages(null)
        locationCancellation?.cancel()
        locationCancellation = null
        locationListener?.let { (getSystemService(LOCATION_SERVICE) as LocationManager).removeUpdates(it) }
        locationListener = null
        if (location == null) pending.error(error ?: "location_unavailable", "無法取得目前位置，可繼續使用文字地點", null)
        else pending.success(mapOf("latitude" to location.latitude, "longitude" to location.longitude,
            "radius_m" to if (location.hasAccuracy() && location.accuracy > 0) location.accuracy.toDouble() else null))
    }

    private fun hasLocationPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
        ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

    private fun requestCurrentLocation() {
        val pending = locationResult ?: return
        try {
            val manager = getSystemService(LOCATION_SERVICE) as LocationManager
            if (!manager.isProviderEnabled(LocationManager.GPS_PROVIDER)) { finishLocation(error = "location_disabled"); return }
            locationHandler.postDelayed({ finishLocation(error = "location_timeout", expected = pending) }, 30000)
            if (Build.VERSION.SDK_INT >= 30) {
                val cancellation = CancellationSignal()
                locationCancellation = cancellation
                manager.getCurrentLocation(LocationManager.GPS_PROVIDER, cancellation, mainExecutor) { location -> finishLocation(location, expected = pending) }
            } else {
                val listener = object : LocationListener {
                    override fun onLocationChanged(location: Location) { finishLocation(location, expected = pending) }
                    override fun onProviderEnabled(provider: String) {}
                    override fun onProviderDisabled(provider: String) { finishLocation(error = "location_disabled", expected = pending) }
                    @Deprecated("舊版系統相容")
                    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                }
                locationListener = listener
                @Suppress("DEPRECATION")
                manager.requestSingleUpdate(LocationManager.GPS_PROVIDER, listener, Looper.getMainLooper())
            }
        } catch (_: SecurityException) { finishLocation(error = "location_denied") }
        catch (_: Exception) { finishLocation(error = "location_unavailable") }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 7303 && locationResult != null) {
            if (hasLocationPermission()) requestCurrentLocation() else finishLocation(error = "location_denied")
        }
    }

    override fun onDestroy() {
        finishLocation(error = "location_cancelled")
        photoRequests.values.forEach { it.set(true) }
        photoWorker.shutdown()
        super.onDestroy()
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "life_chronicle/date_picker")
            .setMethodCallHandler { call, result ->
                if (call.method != "choose") { result.notImplemented(); return@setMethodCallHandler }
                var completed = false
                val dialog = DatePickerDialog(this, { _, year, month, day ->
                    if (!completed) {
                        completed = true
                        result.success(mapOf("year" to year, "month" to month + 1, "day" to day))
                    }
                }, call.argument<Int>("year")!!, call.argument<Int>("month")!! - 1, call.argument<Int>("day")!!)
                dialog.datePicker.minDate = GregorianCalendar(1, 0, 1).timeInMillis
                dialog.datePicker.maxDate = GregorianCalendar(9999, 11, 31).timeInMillis
                dialog.setOnCancelListener { if (!completed) { completed = true; result.success(null) } }
                dialog.show()
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "life_chronicle/location")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "current" -> {
                        if (locationResult != null) result.error("location_busy", "定位正在進行", null)
                        else {
                            locationResult = result
                            if (hasLocationPermission()) requestCurrentLocation()
                            else requestPermissions(arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION), 7303)
                        }
                    }
                    "cancel" -> { finishLocation(error = "location_cancelled"); result.success(null) }
                    "openMap" -> {
                        val lat = call.argument<Double>("latitude")
                        val lng = call.argument<Double>("longitude")
                        if (lat == null || lng == null || !lat.isFinite() || !lng.isFinite() || lat !in -90.0..90.0 || lng !in -180.0..180.0)
                            result.error("location_invalid", "無效的座標", null)
                        else try { startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("geo:$lat,$lng?q=$lat,$lng"))); result.success(null) }
                        catch (_: Exception) { result.error("location_unavailable", "沒有可開啟的地圖 APP", null) }
                    }
                    "openCopyright" -> {
                        try { startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://www.openstreetmap.org/copyright"))); result.success(null) }
                        catch (_: Exception) { result.error("location_unavailable", "無法開啟著作權頁面", null) }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "life_chronicle/security")
            .setMethodCallHandler { call, result ->
                if (call.method == "hidePreview") {
                    val hidden = call.argument<Boolean>("enabled") == true
                    if (hidden) window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    else window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    if (Build.VERSION.SDK_INT >= 33) setRecentsScreenshotEnabled(!hidden)
                    result.success(null)
                } else result.notImplemented()
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "life_chronicle/photos")
            .setMethodCallHandler { call, result ->
                val requestId = call.argument<String>("requestId")
                if (call.method == "cancel") {
                    if (requestId != null) photoRequests[requestId]?.set(true)
                    result.success(null)
                } else if (call.method == "inspect" || call.method == "compress" || call.method == "preview") {
                    val path = call.argument<String>("path")
                    val output = call.argument<String>("output")
                    val edge = call.argument<Int>("longEdge")
                    if (path == null || (call.method != "inspect" && (requestId == null || output == null || edge == null))) {
                        result.error("photo_invalid", "Invalid photo request", null)
                    } else {
                        val cancellation = java.util.concurrent.atomic.AtomicBoolean(false)
                        if (requestId != null && photoRequests.putIfAbsent(requestId, cancellation) != null) {
                            result.error("photo_busy", "Duplicate photo request", null)
                            return@setMethodCallHandler
                        }
                        photoWorker.execute {
                            try {
                                val value = if (call.method == "inspect") PhotoProcessor.inspect(path)
                                    else if (call.method == "preview") PhotoProcessor.preview(path, output!!, edge!!, cancellation)
                                    else PhotoProcessor.compress(path, output!!, edge!!, call.argument<Boolean>("keepGps") != false, cancellation)
                                photoHandler.post { result.success(value) }
                            } catch (error: Exception) {
                                photoHandler.post { result.error(if (cancellation.get()) "photo_cancelled" else "photo_error", "Photo processing failed", error.javaClass.simpleName) }
                            } catch (_: OutOfMemoryError) {
                                photoHandler.post { result.error("photo_memory", "Photo exceeds available memory", null) }
                            } finally {
                                if (requestId != null) photoRequests.remove(requestId, cancellation)
                            }
                        }
                    }
                } else result.notImplemented()
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "life_chronicle/attachments")
            .setMethodCallHandler { call, result ->
                if (call.method == "storageUsage") {
                    photoWorker.execute {
                        try {
                            val appBytes = if (Build.VERSION.SDK_INT >= 26) {
                                val manager = getSystemService(android.app.usage.StorageStatsManager::class.java)
                                val storage = getSystemService(android.os.storage.StorageManager::class.java)
                                val stats = manager.queryStatsForUid(storage.getUuidForPath(filesDir), applicationInfo.uid)
                                // dataBytes 已含 cacheBytes，不能再加一次。
                                stats.appBytes + stats.dataBytes
                            } else {
                                // 舊版只走訪本 APP 已知目錄，略過符號連結並避免重複計數。
                                val roots = listOfNotNull(File(applicationInfo.dataDir),
                                    getExternalFilesDir(null), externalCacheDir,
                                    File(applicationInfo.sourceDir), File(applicationInfo.nativeLibraryDir)) +
                                    (applicationInfo.splitSourceDirs?.map { File(it) } ?: emptyList())
                                val visited = hashSetOf<String>()
                                var total = 0L
                                for (root in roots) {
                                    val canonical = root.canonicalFile
                                    for (file in canonical.walkTopDown().onEnter { it.canonicalPath == it.absolutePath }) {
                                        if (file.isFile && file.canonicalPath == file.absolutePath && visited.add(file.canonicalPath)) total += file.length()
                                    }
                                }
                                total
                            }
                            val free = StatFs(filesDir.path).availableBytes
                            photoHandler.post { result.success(mapOf("appBytes" to appBytes, "freeBytes" to free)) }
                        } catch (error: Exception) {
                            photoHandler.post { result.error("storage_unavailable", "無法取得空間資訊", null) }
                        }
                    }
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("invalid_path", "缺少檔案路徑", null)
                    return@setMethodCallHandler
                }
                try {
                    when (call.method) {
                        "availableBytes" -> result.success(StatFs(path).availableBytes)
                        "metadata" -> {
                            val extension = File(path).extension.lowercase()
                            val type = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
                                ?: "application/octet-stream"
                            var captured: String? = null
                            var latitude: Double? = null
                            var longitude: Double? = null
                            if (type.startsWith("image/")) {
                                try {
                                    val exif = ExifInterface(path)
                                    val coordinates = FloatArray(2)
                                    if (exif.getLatLong(coordinates)) {
                                        latitude = coordinates[0].toDouble()
                                        longitude = coordinates[1].toDouble()
                                    }
                                    val date = exif.getAttribute(ExifInterface.TAG_DATETIME_ORIGINAL)
                                    // EXIF 日期保留原時間，不以匯入時間代替拍攝時間。
                                    if (date != null && date.length >= 19) {
                                        captured = date.substring(0, 10).replace(':', '-') + "T" + date.substring(11, 19)
                                        exif.getAttribute("OffsetTimeOriginal")?.let { offset ->
                                            if (Regex("[+-]\\d{2}:\\d{2}").matches(offset)) captured += offset
                                        }
                                    }
                                } catch (_: Exception) { /* 不支援的影像仍可保存。 */ }
                            }
                            if (type.startsWith("video/") || type.startsWith("audio/")) {
                                val retriever = MediaMetadataRetriever()
                                try {
                                    retriever.setDataSource(path)
                                    val date = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DATE)
                                    val match = date?.let { Regex("^(\\d{4})(\\d{2})(\\d{2})T(\\d{2})(\\d{2})(\\d{2})(?:\\.\\d+)?(Z|[+-]\\d{4})?$").find(it) }
                                    if (match != null) {
                                        val value = match.groupValues
                                        captured = "${value[1]}-${value[2]}-${value[3]}T${value[4]}:${value[5]}:${value[6]}${value[7]}"
                                    }
                                } catch (_: Exception) { /* 沒有拍攝時間時留空，不補成匯入時間。 */ }
                                finally { try { retriever.release() } catch (_: Exception) {} }
                            }
                            result.success(mapOf("mediaType" to type, "capturedAt" to captured, "latitude" to latitude, "longitude" to longitude))
                        }
                        "open" -> {
                            val file = File(path).canonicalFile
                            val media = File(filesDir, "media").canonicalFile
                            if (!file.path.startsWith(media.path + File.separator)) {
                                result.error("invalid_path", "只允許開啟 APP 管理的附件", null)
                            } else {
                                val uri = FileProvider.getUriForFile(this, "$packageName.attachments", file)
                                val intent = Intent(Intent.ACTION_VIEW).setDataAndType(uri,
                                    call.argument<String>("mediaType") ?: "application/octet-stream")
                                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                startActivity(intent)
                                result.success(null)
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("attachment_error", "附件操作失敗", error.javaClass.simpleName)
                }
            }
    }
}
