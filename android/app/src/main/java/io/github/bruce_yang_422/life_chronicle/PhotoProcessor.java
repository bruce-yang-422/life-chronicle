package io.github.bruce_yang_422.life_chronicle;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.ColorSpace;
import android.graphics.Matrix;
import android.media.ExifInterface;
import android.os.Build;
import java.io.*;
import java.util.*;
import java.util.concurrent.atomic.AtomicBoolean;

/** Native worker; never modifies its input. Only its newly created output is disposable. */
public final class PhotoProcessor {
    private static final int TARGET_BYTES = 3000000;
    private static final long MAX_DECODE_PIXELS = 32000000L;
    private static final String[] TAGS = {
        "DateTime", "DateTimeOriginal", "DateTimeDigitized", "SubSecTime", "SubSecTimeOriginal",
        "SubSecTimeDigitized", "OffsetTime", "OffsetTimeOriginal", "OffsetTimeDigitized",
        "Make", "Model", "Software", "Artist", "Copyright", "ImageDescription", "UserComment",
        "ExposureTime", "FNumber", "PhotographicSensitivity", "ISOSpeedRatings", "ExposureProgram",
        "ExposureBiasValue", "MeteringMode", "LightSource", "Flash", "FocalLength", "FocalLengthIn35mmFilm",
        "WhiteBalance", "ExposureMode", "SceneCaptureType", "LensMake", "LensModel", "LensSpecification",
        "BodySerialNumber", "LensSerialNumber", "DigitalZoomRatio", "BrightnessValue", "ApertureValue",
        "ShutterSpeedValue", "MaxApertureValue", "ExposureIndex", "SubjectDistance",
        "GPSVersionID", "GPSLatitudeRef", "GPSLatitude", "GPSLongitudeRef", "GPSLongitude",
        "GPSAltitudeRef", "GPSAltitude", "GPSTimeStamp", "GPSDateStamp", "GPSProcessingMethod",
        "GPSAreaInformation", "GPSDOP", "GPSSpeedRef", "GPSSpeed", "GPSTrackRef", "GPSTrack",
        "GPSImgDirectionRef", "GPSImgDirection", "GPSMapDatum", "GPSDifferential", "GPSHPositioningError"
    };

    private static void check(AtomicBoolean cancelled) throws InterruptedIOException {
        if (cancelled.get()) throw new InterruptedIOException("cancelled");
    }

    /** Excludes APNG and animated WebP instead of flattening them into one frame. */
    public static Map<String, Object> inspect(String path) throws IOException {
        if (Build.VERSION.SDK_INT < 30) return null;
        BitmapFactory.Options bounds = new BitmapFactory.Options();
        bounds.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(path, bounds);
        String mime = bounds.outMimeType;
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0 || mime == null) return null;
        if (!Arrays.asList("image/jpeg", "image/png", "image/webp", "image/heif", "image/heic").contains(mime)) return null;
        if (animated(path, mime)) return null;
        ExifInterface exif = new ExifInterface(path);
        int orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, 1);
        boolean swap = orientation >= 5 && orientation <= 8;
        Map<String, Object> info = new HashMap<>();
        info.put("width", swap ? bounds.outHeight : bounds.outWidth);
        info.put("height", swap ? bounds.outWidth : bounds.outHeight);
        info.put("mediaType", mime);
        boolean hasGps = false;
        for (java.lang.reflect.Field field : ExifInterface.class.getFields()) {
            if (field.getName().startsWith("TAG_GPS_") && field.getType() == String.class) {
                try { if (exif.getAttribute((String) field.get(null)) != null) hasGps = true; }
                catch (IllegalAccessException error) { throw new IOException(error); }
            }
        }
        info.put("hasGps", hasGps);
        return info;
    }

    private static boolean animated(String path, String mime) throws IOException {
        try (RandomAccessFile input = new RandomAccessFile(path, "r")) {
            if (mime.equals("image/webp")) {
                if (input.length() < 12) throw new IOException("Truncated WebP");
                long end = Integer.toUnsignedLong(Integer.reverseBytes(readIntAt(input, 4))) + 8;
                if (end > input.length()) throw new IOException("Truncated WebP");
                long pos = 12;
                while (pos + 8 <= end) {
                    input.seek(pos);
                    int type = input.readInt();
                    long size = Integer.toUnsignedLong(Integer.reverseBytes(input.readInt()));
                    if (pos + 8 + size > end) throw new IOException("Truncated chunk");
                    if (type == 0x414e494d || type == 0x414e4d46) return true; // ANIM / ANMF
                    if (type == 0x56503858 && size > 0 && (input.readUnsignedByte() & 2) != 0) return true;
                    pos += 8 + size + (size & 1);
                }
            } else if (mime.equals("image/png")) {
                long pos = 8;
                while (pos + 12 <= input.length()) {
                    input.seek(pos);
                    long size = Integer.toUnsignedLong(input.readInt());
                    int type = input.readInt();
                    if (pos + 12 + size > input.length()) throw new IOException("Truncated PNG");
                    if (type == 0x6163544c) return true; // acTL
                    if (type == 0x49454e44) break;
                    pos += 12 + size;
                }
            } else if (mime.equals("image/heif") || mime.equals("image/heic")) {
                input.seek(0);
                long size = Integer.toUnsignedLong(input.readInt());
                if (size < 16 || size > 65536 || size > input.length() || input.readInt() != 0x66747970) return true;
                for (long pos = 8; pos + 4 <= size; pos += 4) {
                    input.seek(pos);
                    int brand = input.readInt();
                    if (brand == 0x6d736631 || brand == 0x68657663 || brand == 0x68657678) return true;
                }
            }
        }
        return false;
    }

    private static int readIntAt(RandomAccessFile input, long pos) throws IOException {
        input.seek(pos); return input.readInt();
    }

    public static Map<String, Object> compress(String path, String output, int longEdge,
            AtomicBoolean cancelled) throws IOException {
        return compress(path, output, longEdge, true, cancelled);
    }

    public static Map<String, Object> compress(String path, String output, int longEdge,
            boolean keepGps, AtomicBoolean cancelled) throws IOException {
        return render(path, output, longEdge, keepGps, false, cancelled);
    }

    public static Map<String, Object> preview(String path, String output, int longEdge,
            AtomicBoolean cancelled) throws IOException {
        if (longEdge != 80 && longEdge != 512 && longEdge != 1600) throw new IOException("Invalid preview size");
        return render(path, output, longEdge, false, true, cancelled);
    }

    private static Map<String, Object> render(String path, String output, int longEdge,
            boolean keepGps, boolean preview, AtomicBoolean cancelled) throws IOException {
        if (!preview && longEdge != 4096 && longEdge != 3072 && longEdge != 2048) throw new IOException("Invalid preset");
        Map<String, Object> info = inspect(path);
        if (info == null) throw new IOException("Not a supported static photo");
        File target = new File(output);
        if (target.getCanonicalPath().equals(new File(path).getCanonicalPath()) || !target.createNewFile()) {
            throw new IOException("Output must be a new file");
        }
        Bitmap decoded = null, oriented = null, resized = null;
        boolean complete = false;
        try {
            check(cancelled);
            int width = (Integer) info.get("width"), height = (Integer) info.get("height");
            int edge = Math.max(width, height);
            int outWidth = edge <= longEdge ? width : Math.max(1, (int) Math.round((double) width * longEdge / edge));
            int outHeight = edge <= longEdge ? height : Math.max(1, (int) Math.round((double) height * longEdge / edge));
            BitmapFactory.Options options = new BitmapFactory.Options();
            options.inSampleSize = 1;
            while (edge / (options.inSampleSize * 2) >= Math.max(outWidth, outHeight)) options.inSampleSize *= 2;
            if (((long) width / options.inSampleSize + 1) * ((long) height / options.inSampleSize + 1) > MAX_DECODE_PIXELS) {
                throw new IOException("Photo exceeds bounded decode budget");
            }
            options.inPreferredConfig = Bitmap.Config.ARGB_8888;
            options.inPreferredColorSpace = ColorSpace.get(ColorSpace.Named.SRGB);
            options.inScaled = false;
            decoded = BitmapFactory.decodeFile(path, options);
            if (decoded == null) throw new IOException("Decode failed");
            check(cancelled);
            ExifInterface sourceExif = new ExifInterface(path);
            int orientation = sourceExif.getAttributeInt(ExifInterface.TAG_ORIENTATION, 1);
            Matrix matrix = new Matrix();
            switch (orientation) {
                case 2: matrix.setScale(-1, 1); break;
                case 3: matrix.setRotate(180); break;
                case 4: matrix.setScale(1, -1); break;
                case 5: matrix.setRotate(90); matrix.postScale(-1, 1); break;
                case 6: matrix.setRotate(90); break;
                case 7: matrix.setRotate(-90); matrix.postScale(-1, 1); break;
                case 8: matrix.setRotate(-90); break;
                default: break;
            }
            oriented = Bitmap.createBitmap(decoded, 0, 0, decoded.getWidth(), decoded.getHeight(), matrix, false);
            if (oriented != decoded) { decoded.recycle(); decoded = null; }
            resized = resize(oriented, outWidth, outHeight, cancelled);
            if (resized != oriented) { oriented.recycle(); oriented = null; }
            boolean transparent = false;
            int[] row = new int[outWidth];
            for (int y = 0; y < outHeight && !transparent; y++) {
                check(cancelled);
                resized.getPixels(row, 0, outWidth, 0, y, outWidth, 1);
                for (int color : row) if ((color >>> 24) != 255) { transparent = true; break; }
            }
            String mime = transparent ? "image/png" : "image/jpeg";
            Integer quality = transparent ? null : 90;
            while (true) {
                check(cancelled);
                try (FileOutputStream stream = new FileOutputStream(target)) {
                    if (!resized.compress(transparent ? Bitmap.CompressFormat.PNG : Bitmap.CompressFormat.JPEG,
                            quality == null ? 100 : quality, stream)) throw new IOException("Encode failed");
                }
                if (!preview) {
                ExifInterface exif = new ExifInterface(output);
                for (String tag : TAGS) {
                    if (!keepGps && tag.startsWith("GPS")) continue;
                    String value = sourceExif.getAttribute(tag);
                    if (value != null) exif.setAttribute(tag, value);
                }
                exif.setAttribute(ExifInterface.TAG_ORIENTATION, "1");
                exif.setAttribute(ExifInterface.TAG_IMAGE_WIDTH, Integer.toString(outWidth));
                exif.setAttribute(ExifInterface.TAG_IMAGE_LENGTH, Integer.toString(outHeight));
                exif.setAttribute(ExifInterface.TAG_PIXEL_X_DIMENSION, Integer.toString(outWidth));
                exif.setAttribute(ExifInterface.TAG_PIXEL_Y_DIMENSION, Integer.toString(outHeight));
                exif.setAttribute(ExifInterface.TAG_COLOR_SPACE, "1"); // decoded into sRGB
                exif.saveAttributes();
                }
                check(cancelled);
                if (transparent || target.length() <= TARGET_BYTES || quality <= 75) break;
                quality -= 5;
            }
            long originalBytes = new File(path).length();
            boolean original = !preview && keepGps && target.length() >= originalBytes;
            if (original && !target.delete()) throw new IOException("Cannot discard larger output");
            info.put("path", original ? path : output);
            info.put("bytes", original ? originalBytes : target.length());
            info.put("width", original ? width : outWidth);
            info.put("height", original ? height : outHeight);
            info.put("quality", original ? null : quality);
            info.put("mediaType", original ? info.get("mediaType") : mime);
            info.put("keptOriginal", original);
            complete = true;
            return info;
        } finally {
            if (resized != null && !resized.isRecycled()) resized.recycle();
            if (oriented != null && !oriented.isRecycled()) oriented.recycle();
            if (decoded != null && !decoded.isRecycled()) decoded.recycle();
            if (!complete) target.delete();
        }
    }

    // Catmull-Rom bicubic interpolation, with alpha-premultiplied color accumulation.
    // Only four scanlines plus one output row are retained outside the two bounded bitmaps.
    private static Bitmap resize(Bitmap source, int width, int height, AtomicBoolean cancelled) throws IOException {
        if (source.getWidth() == width && source.getHeight() == height) return source;
        Bitmap result = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        try {
            int sw = source.getWidth(), sh = source.getHeight();
            int[][] rows = new int[4][sw];
            int[] output = new int[width];
            for (int y = 0; y < height; y++) {
                check(cancelled);
                double sy = (y + .5) * sh / height - .5;
                int iy = (int) Math.floor(sy);
                double[] wy = new double[4];
                for (int j = 0; j < 4; j++) {
                    wy[j] = cubic(sy - (iy + j - 1));
                    source.getPixels(rows[j], 0, sw, 0, Math.max(0, Math.min(sh - 1, iy + j - 1)), sw, 1);
                }
                for (int x = 0; x < width; x++) {
                    double sx = (x + .5) * sw / width - .5;
                    int ix = (int) Math.floor(sx);
                    double a = 0, r = 0, g = 0, b = 0;
                    for (int i = 0; i < 4; i++) {
                        int col = Math.max(0, Math.min(sw - 1, ix + i - 1));
                        double wx = cubic(sx - (ix + i - 1));
                        for (int j = 0; j < 4; j++) {
                            int pixel = rows[j][col];
                            double weight = wx * wy[j], alpha = pixel >>> 24;
                            a += alpha * weight;
                            r += ((pixel >> 16) & 255) * alpha * weight;
                            g += ((pixel >> 8) & 255) * alpha * weight;
                            b += (pixel & 255) * alpha * weight;
                        }
                    }
                    output[x] = a <= 0 ? 0 : (clamp(a) << 24) | (clamp(r / a) << 16) | (clamp(g / a) << 8) | clamp(b / a);
                }
                result.setPixels(output, 0, width, 0, y, width, 1);
            }
            return result;
        } catch (IOException | RuntimeException | OutOfMemoryError error) { result.recycle(); throw error; }
    }

    private static int clamp(double value) { return (int) Math.max(0, Math.min(255, Math.round(value))); }
    private static double cubic(double x) {
        x = Math.abs(x);
        if (x <= 1) return (1.5 * x - 2.5) * x * x + 1;
        return x < 2 ? ((-.5 * x + 2.5) * x - 4) * x + 2 : 0;
    }
}
