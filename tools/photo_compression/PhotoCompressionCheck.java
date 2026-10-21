import android.graphics.*;
import android.media.ExifInterface;
import java.io.*;
import java.nio.file.Files;
import java.security.MessageDigest;
import java.util.*;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.zip.CRC32;
import org.json.*;
import io.github.bruce_yang_422.life_chronicle.PhotoProcessor;

public final class PhotoCompressionCheck {
    static final JSONArray checks = new JSONArray();
    static void check(boolean value, String label) {
        if (!value) throw new AssertionError(label);
        checks.put(label);
    }
    static File image(File dir, String name, int width, int height, boolean transparent) throws Exception {
        Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        Random random = new Random(412);
        int[] row = new int[width];
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) row[x] = (transparent ? 0x60000000 : 0xff000000) | random.nextInt(0x1000000);
            bitmap.setPixels(row, 0, width, 0, y, width, 1);
        }
        File file = new File(dir, name);
        try (FileOutputStream out = new FileOutputStream(file)) {
            bitmap.compress(transparent ? Bitmap.CompressFormat.PNG : Bitmap.CompressFormat.JPEG, 100, out);
        }
        bitmap.recycle();
        return file;
    }
    static byte[] digest(File file) throws Exception {
        MessageDigest hash = MessageDigest.getInstance("SHA-256");
        try (InputStream in = new FileInputStream(file)) {
            byte[] bytes = new byte[65536]; int count;
            while ((count = in.read(bytes)) >= 0) hash.update(bytes, 0, count);
        }
        return hash.digest();
    }
    static File corners(File dir, String name, int orientation) throws Exception {
        Bitmap bitmap = Bitmap.createBitmap(120, 80, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap); Paint p = new Paint();
        int[] colors = {Color.RED, Color.GREEN, Color.BLUE, Color.WHITE};
        for (int i = 0; i < 4; i++) { p.setColor(colors[i]); canvas.drawRect((i % 2) * 60, (i / 2) * 40, (i % 2 + 1) * 60, (i / 2 + 1) * 40, p); }
        File file = new File(dir, name);
        try (FileOutputStream out = new FileOutputStream(file)) { bitmap.compress(Bitmap.CompressFormat.JPEG, 100, out); }
        bitmap.recycle();
        ExifInterface exif = new ExifInterface(file.getPath());
        exif.setAttribute(ExifInterface.TAG_ORIENTATION, Integer.toString(orientation));
        exif.setAttribute(ExifInterface.TAG_MODEL, "SyntheticCamera");
        exif.setAttribute(ExifInterface.TAG_DATETIME_ORIGINAL, "2003:09:15 10:20:30");
        exif.setAttribute(ExifInterface.TAG_GPS_LATITUDE, "25/1,1/1,48/1");
        exif.setAttribute(ExifInterface.TAG_GPS_LATITUDE_REF, "N");
        exif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE, "121/1,33/1,36/1");
        exif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE_REF, "E");
        exif.saveAttributes();
        // Force a smaller recompressed result, without altering image pixels.
        try (FileOutputStream out = new FileOutputStream(file, true)) { out.write(new byte[200000]); }
        return file;
    }
    public static void main(String[] args) throws Exception {
        android.os.Looper.prepareMainLooper();
        Object thread = Class.forName("android.app.ActivityThread").getMethod("systemMain").invoke(null);
        thread.getClass().getMethod("getSystemContext").invoke(thread);
        File dir = new File(args[0]); dir.mkdirs();
        final int[] expected = {Color.RED, Color.GREEN, Color.WHITE, Color.BLUE, Color.RED, Color.BLUE, Color.WHITE, Color.GREEN};
        for (int orientation = 1; orientation <= 8; orientation++) {
            File source = corners(dir, "orientation-" + orientation + ".jpg", orientation);
            byte[] before = digest(source);
            File target = new File(dir, "upright-" + orientation + ".jpg");
            Map<String, Object> result = PhotoProcessor.compress(source.getPath(), target.getPath(), 2048, new AtomicBoolean());
            check(!(Boolean) result.get("keptOriginal"), "orientation-" + orientation + " compressed");
            Bitmap bitmap = BitmapFactory.decodeFile(target.getPath());
            int pixel = bitmap.getPixel(5, 5), desired = expected[orientation - 1];
            check(Math.abs(Color.red(pixel) - Color.red(desired)) < 20 && Math.abs(Color.green(pixel) - Color.green(desired)) < 20 && Math.abs(Color.blue(pixel) - Color.blue(desired)) < 20, "orientation-" + orientation + " corner");
            check(bitmap.getWidth() == (orientation >= 5 ? 80 : 120) && bitmap.getHeight() == (orientation >= 5 ? 120 : 80), "orientation-" + orientation + " dimensions/no-upscale");
            bitmap.recycle();
            ExifInterface exif = new ExifInterface(target.getPath());
            check(exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, 0) == 1, "orientation normalized " + orientation);
            check("SyntheticCamera".equals(exif.getAttribute(ExifInterface.TAG_MODEL)), "camera retained " + orientation);
            check("2003:09:15 10:20:30".equals(exif.getAttribute(ExifInterface.TAG_DATETIME_ORIGINAL)), "capture time retained " + orientation);
            check(exif.getLatLong(new float[2]), "GPS retained " + orientation);
            check(Arrays.equals(before, digest(source)), "original unchanged " + orientation);
        }
        File large = image(dir, "noise.jpg", 4200, 2800, false);
        byte[] before = digest(large);
        Map<String, Object> result = PhotoProcessor.compress(large.getPath(), new File(dir, "noise-standard.jpg").getPath(), 3072, new AtomicBoolean());
        check(result.get("width").equals(3072) && result.get("height").equals(2048), "standard proportional 3072x2048");
        int quality = (Integer) result.get("quality");
        check(quality >= 75 && quality <= 90 && quality % 5 == 0, "JPEG quality 90..75 step 5");
        check(((Number) result.get("bytes")).longValue() <= 3000000 || quality == 75, "3 MB is a target; quality never below 75");
        check(Arrays.equals(before, digest(large)), "large original unchanged");
        File alpha = image(dir, "alpha.png", 3000, 1000, true);
        result = PhotoProcessor.compress(alpha.getPath(), new File(dir, "alpha-compact.png").getPath(), 2048, new AtomicBoolean());
        check(result.get("mediaType").equals("image/png"), "transparent PNG stays PNG");
        check(result.get("width").equals(2048) && result.get("height").equals(683), "short edge rounded to integer");
        Bitmap bitmap = BitmapFactory.decodeFile((String) result.get("path"));
        check(Color.alpha(bitmap.getPixel(10, 10)) == 96, "alpha preserved without dark fringe");
        bitmap.recycle();
        File dense = image(dir, "dense.jpg", 4096, 4096, false);
        Map<String, Object> floor = PhotoProcessor.compress(dense.getPath(), new File(dir, "dense-high.jpg").getPath(), 4096, new AtomicBoolean());
        check(floor.get("quality").equals(75) && ((Number) floor.get("bytes")).longValue() > 3000000,
            "quality floor 75 keeps resolution even when larger than 3 MB");
        check(floor.get("width").equals(4096) && floor.get("height").equals(4096), "no extra resolution reduction to meet size target");
        for (boolean alphaWebp : new boolean[] {false, true}) {
            File webp = new File(dir, alphaWebp ? "static-alpha.webp" : "static.webp");
            Bitmap webBitmap = Bitmap.createBitmap(120, 80, Bitmap.Config.ARGB_8888);
            webBitmap.eraseColor(alphaWebp ? 0x60ff0000 : Color.RED);
            try (FileOutputStream stream = new FileOutputStream(webp)) { webBitmap.compress(Bitmap.CompressFormat.WEBP_LOSSLESS, 100, stream); }
            webBitmap.recycle();
            try (FileOutputStream stream = new FileOutputStream(webp, true)) { stream.write(new byte[200000]); }
            Map<String, Object> web = PhotoProcessor.compress(webp.getPath(), new File(dir, alphaWebp ? "web-alpha.png" : "web.jpg").getPath(), 2048, new AtomicBoolean());
            check(web.get("mediaType").equals(alphaWebp ? "image/png" : "image/jpeg"), alphaWebp ? "transparent WebP converts to PNG" : "opaque static WebP converts to JPEG");
        }
        File p3 = new File(dir, "wide-gamut.png");
        ColorSpace p3Space = ColorSpace.get(ColorSpace.Named.DISPLAY_P3);
        Bitmap wide = Bitmap.createBitmap(80, 60, Bitmap.Config.RGBA_F16, false, p3Space);
        wide.eraseColor(Color.valueOf(.5f, .8f, .2f, 1f, p3Space).pack());
        try (FileOutputStream stream = new FileOutputStream(p3)) { wide.compress(Bitmap.CompressFormat.PNG, 100, stream); }
        wide.recycle();
        try (FileOutputStream stream = new FileOutputStream(p3, true)) { stream.write(new byte[200000]); }
        BitmapFactory.Options srgb = new BitmapFactory.Options(); srgb.inPreferredColorSpace = ColorSpace.get(ColorSpace.Named.SRGB);
        Bitmap reference = BitmapFactory.decodeFile(p3.getPath(), srgb);
        int referenceColor = reference.getPixel(20, 20); reference.recycle();
        Map<String, Object> convertedColor = PhotoProcessor.compress(p3.getPath(), new File(dir, "srgb.jpg").getPath(), 2048, new AtomicBoolean());
        Bitmap srgbBitmap = BitmapFactory.decodeFile((String) convertedColor.get("path"));
        int actualColor = srgbBitmap.getPixel(20, 20);
        check(srgbBitmap.getColorSpace().isSrgb(), "Display P3 converted to sRGB");
        check(Math.abs(Color.red(actualColor) - Color.red(referenceColor)) < 8 && Math.abs(Color.green(actualColor) - Color.green(referenceColor)) < 8 && Math.abs(Color.blue(actualColor) - Color.blue(referenceColor)) < 8, "wide gamut color matches sRGB reference");
        srgbBitmap.recycle();
        File tiny = new File(dir, "tiny.png");
        bitmap = Bitmap.createBitmap(8, 8, Bitmap.Config.ARGB_8888); bitmap.eraseColor(Color.BLACK);
        try (FileOutputStream out = new FileOutputStream(tiny)) { bitmap.compress(Bitmap.CompressFormat.PNG, 100, out); }
        bitmap.recycle();
        File larger = new File(dir, "tiny-output.jpg");
        result = PhotoProcessor.compress(tiny.getPath(), larger.getPath(), 4096, new AtomicBoolean());
        check((Boolean) result.get("keptOriginal") && !larger.exists(), "larger compression discarded; original retained");
        ExifInterface located = new ExifInterface(tiny.getPath());
        located.setAttribute(ExifInterface.TAG_GPS_LATITUDE, "25/1,1/1,48/1");
        located.setAttribute(ExifInterface.TAG_GPS_LATITUDE_REF, "N");
        located.setAttribute(ExifInterface.TAG_GPS_LONGITUDE, "121/1,33/1,36/1");
        located.setAttribute(ExifInterface.TAG_GPS_LONGITUDE_REF, "E");
        located.setAttribute(ExifInterface.TAG_GPS_ALTITUDE, "100/1");
        located.setAttribute(ExifInterface.TAG_MODEL, "SyntheticCamera");
        located.setAttribute(ExifInterface.TAG_DATETIME_ORIGINAL, "2003:09:15 10:20:30");
        located.saveAttributes();
        byte[] locatedBefore = digest(tiny);
        Map<String, Object> stripped = PhotoProcessor.compress(tiny.getPath(), new File(dir, "no-gps.jpg").getPath(), 2048, false, new AtomicBoolean());
        check(!(Boolean) stripped.get("keptOriginal"), "GPS removal never falls back to original");
        check(((Number) stripped.get("bytes")).longValue() > tiny.length(), "GPS removal keeps larger processed result");
        ExifInterface withoutGps = new ExifInterface((String) stripped.get("path"));
        check(!withoutGps.getLatLong(new float[2]), "processed file has no GPS coordinates");
        for (java.lang.reflect.Field tag : ExifInterface.class.getFields()) {
            if (tag.getName().startsWith("TAG_GPS_") && tag.getType() == String.class) {
                check(withoutGps.getAttribute((String) tag.get(null)) == null, "removed " + tag.getName());
            }
        }
        check("SyntheticCamera".equals(withoutGps.getAttribute(ExifInterface.TAG_MODEL)), "GPS removal retains camera metadata");
        check("2003:09:15 10:20:30".equals(withoutGps.getAttribute(ExifInterface.TAG_DATETIME_ORIGINAL)), "GPS removal retains capture time");
        check(Arrays.equals(locatedBefore, digest(tiny)) && new ExifInterface(tiny.getPath()).getLatLong(new float[2]), "GPS removal leaves original location intact");
        for (int edge : new int[] {80, 512, 1600}) {
            File preview = new File(dir, "preview-" + edge + ".jpg");
            Map<String, Object> view = PhotoProcessor.preview(large.getPath(), preview.getPath(), edge, new AtomicBoolean());
            check(view.get("width").equals(edge) && view.get("height").equals((int) Math.round(edge * 2800.0 / 4200)), "preview bound and aspect " + edge);
            check(!(Boolean) view.get("keptOriginal") && view.get("path").equals(preview.getPath()), "preview never returns original " + edge);
            check(Boolean.FALSE.equals(PhotoProcessor.inspect(preview.getPath()).get("hasGps")), "preview contains no GPS " + edge);
        }
        File strippedPreview = new File(dir, "located-preview.jpg");
        PhotoProcessor.preview(tiny.getPath(), strippedPreview.getPath(), 1600, new AtomicBoolean());
        ExifInterface previewExif = new ExifInterface(strippedPreview.getPath());
        for (java.lang.reflect.Field tag : ExifInterface.class.getFields()) {
            if (tag.getName().startsWith("TAG_GPS_") && tag.getType() == String.class) {
                check(previewExif.getAttribute((String) tag.get(null)) == null, "preview removed " + tag.getName());
            }
        }
        check(previewExif.getAttribute(ExifInterface.TAG_MODEL) == null, "preview does not copy original EXIF");
        check(Arrays.equals(locatedBefore, digest(tiny)), "preview keeps original GPS and bytes intact");
        for (int orientation = 1; orientation <= 8; orientation++) {
            File source = new File(dir, "orientation-" + orientation + ".jpg");
            File view = new File(dir, "preview-orientation-" + orientation + ".jpg");
            PhotoProcessor.preview(source.getPath(), view.getPath(), 80, new AtomicBoolean());
            Bitmap upright = BitmapFactory.decodeFile(view.getPath());
            int pixel = upright.getPixel(3, 3), desired = expected[orientation - 1];
            check(Math.abs(Color.red(pixel) - Color.red(desired)) < 20 && Math.abs(Color.green(pixel) - Color.green(desired)) < 20 && Math.abs(Color.blue(pixel) - Color.blue(desired)) < 20, "preview orientation " + orientation);
            check(Math.max(upright.getWidth(), upright.getHeight()) == 80, "thumbnail stays bounded " + orientation);
            upright.recycle();
        }
        File stoppedPreview = new File(dir, "cancelled-preview.jpg");
        try { PhotoProcessor.preview(large.getPath(), stoppedPreview.getPath(), 512, new AtomicBoolean(true)); throw new AssertionError("preview cancel must throw"); }
        catch (InterruptedIOException expectedError) { check(!stoppedPreview.exists(), "cancel removes preview partial"); }
        File cancelled = new File(dir, "cancelled.jpg");
        try { PhotoProcessor.compress(large.getPath(), cancelled.getPath(), 2048, new AtomicBoolean(true)); throw new AssertionError("cancel must throw"); }
        catch (InterruptedIOException expectedError) { check(!cancelled.exists(), "cancel removes owned output"); }
        byte[] existing = Files.readAllBytes(tiny.toPath());
        try { PhotoProcessor.compress(large.getPath(), tiny.getPath(), 2048, new AtomicBoolean()); throw new AssertionError("collision must throw"); }
        catch (IOException expectedError) { check(Arrays.equals(existing, Files.readAllBytes(tiny.toPath())), "existing output never overwritten"); }
        File gif = new File(dir, "animation.gif");
        Files.write(gif.toPath(), Base64.getDecoder().decode("R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"));
        check(PhotoProcessor.inspect(gif.getPath()) == null, "GIF never compressed");
        // Insert a valid APNG animation control chunk before IDAT.
        byte[] png = Files.readAllBytes(tiny.toPath());
        ByteArrayOutputStream apng = new ByteArrayOutputStream(); apng.write(png, 0, 33);
        DataOutputStream chunk = new DataOutputStream(apng); chunk.writeInt(8);
        byte[] payload = {97, 99, 84, 76, 0, 0, 0, 1, 0, 0, 0, 0};
        chunk.write(payload); CRC32 crc = new CRC32(); crc.update(payload); chunk.writeInt((int) crc.getValue()); apng.write(png, 33, png.length - 33);
        File animated = new File(dir, "animation.png"); Files.write(animated.toPath(), apng.toByteArray());
        check(PhotoProcessor.inspect(animated.getPath()) == null, "APNG never flattened");
        JSONObject report = new JSONObject(); report.put("passed", checks.length()); report.put("checks", checks);
        try (FileWriter out = new FileWriter(new File(dir, "report.json"))) { out.write(report.toString(2)); }
        System.out.println(report.toString(2));
    }
}
