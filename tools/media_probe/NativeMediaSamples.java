import android.media.MediaCodec;
import android.media.MediaCodecInfo;
import android.media.MediaExtractor;
import android.media.MediaFormat;
import android.media.MediaMuxer;
import android.graphics.Bitmap;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;

/** 僅在指定測試目錄產生純色／靜音樣本，不使用攝影機、麥克風或 APP 資料。 */
public final class NativeMediaSamples {
  private static void encode(File target, String mime, boolean video, int container) throws Exception {
    MediaFormat format = video ? MediaFormat.createVideoFormat(mime, 64, 64)
        : MediaFormat.createAudioFormat(mime, 16000, 1);
    format.setInteger(MediaFormat.KEY_BIT_RATE, 64000);
    if (video) {
      format.setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible);
      format.setInteger(MediaFormat.KEY_FRAME_RATE, 10);
      format.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1);
    } else {
      format.setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC);
    }
    MediaCodec codec = MediaCodec.createEncoderByType(mime);
    MediaMuxer muxer = new MediaMuxer(target.getPath(), container);
    boolean started = false, muxStarted = false;
    try {
      codec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE);
      codec.start();
      started = true;
      int fed = 0, track = -1;
      boolean inputDone = false, outputDone = false;
      long deadline = System.nanoTime() + 20000000000L;
      MediaCodec.BufferInfo info = new MediaCodec.BufferInfo();
      while (!outputDone) {
        if (System.nanoTime() > deadline) throw new IllegalStateException("Encoder timed out");
        if (!inputDone) {
          int index = codec.dequeueInputBuffer(10000);
          if (index >= 0) {
            ByteBuffer input = codec.getInputBuffer(index);
            input.clear();
            int size = video ? 64 * 64 * 3 / 2 : 2048;
            for (int i = 0; i < size; i++) input.put((byte) (video ? 128 : 0));
            long time = video ? fed * 100000L : fed * 1024L * 1000000L / 16000L;
            fed++;
            inputDone = fed == (video ? 8 : 16);
            codec.queueInputBuffer(index, 0, size, time, inputDone ? MediaCodec.BUFFER_FLAG_END_OF_STREAM : 0);
          }
        }
        int index = codec.dequeueOutputBuffer(info, 10000);
        if (index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
          track = muxer.addTrack(codec.getOutputFormat());
          muxer.start();
          muxStarted = true;
        } else if (index >= 0) {
          if (info.size > 0 && (info.flags & MediaCodec.BUFFER_FLAG_CODEC_CONFIG) == 0) {
            if (!muxStarted) throw new IllegalStateException("Missing output format");
            ByteBuffer data = codec.getOutputBuffer(index);
            data.position(info.offset);
            data.limit(info.offset + info.size);
            muxer.writeSampleData(track, data, info);
          }
          outputDone = (info.flags & MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0;
          codec.releaseOutputBuffer(index, false);
        }
      }
    } finally {
      try { if (started) codec.stop(); } finally { codec.release(); }
      try { if (muxStarted) muxer.stop(); } finally { muxer.release(); }
    }
  }

  private static JSONObject inspect(File file) throws Exception {
    MediaExtractor extractor = new MediaExtractor();
    try {
      extractor.setDataSource(file.getPath());
      JSONArray tracks = new JSONArray();
      for (int i = 0; i < extractor.getTrackCount(); i++) {
        tracks.put(extractor.getTrackFormat(i).getString(MediaFormat.KEY_MIME));
      }
      if (tracks.length() == 0) throw new IllegalStateException("No extracted tracks");
      return new JSONObject().put("name", file.getName()).put("tracks", tracks).put("bytes", file.length());
    } finally { extractor.release(); }
  }

  private static void annexB(ByteBuffer input, OutputStream output) throws Exception {
    ByteBuffer data = input.duplicate();
    byte[] bytes = new byte[data.remaining()]; data.get(bytes);
    if (bytes.length >= 4 && bytes[0] == 0 && bytes[1] == 0 &&
        (bytes[2] == 1 || bytes[2] == 0 && bytes[3] == 1)) {
      output.write(bytes); return;
    }
    for (int at = 0; at < bytes.length;) {
      if (at + 4 > bytes.length) throw new IllegalStateException("Truncated AVC length");
      int size = ((bytes[at] & 255) << 24) | ((bytes[at+1] & 255) << 16)
          | ((bytes[at+2] & 255) << 8) | (bytes[at+3] & 255);
      at += 4;
      if (size <= 0 || size > bytes.length - at) throw new IllegalStateException("Invalid AVC length");
      output.write(new byte[] {0, 0, 0, 1}); output.write(bytes, at, size); at += size;
    }
  }

  private static void elementary(File source, File target, boolean video) throws Exception {
    MediaExtractor extractor = new MediaExtractor();
    try (FileOutputStream output = new FileOutputStream(target)) {
      extractor.setDataSource(source.getPath()); extractor.selectTrack(0);
      MediaFormat format = extractor.getTrackFormat(0);
      if (video) {
        for (String key : new String[] {"csd-0", "csd-1"}) {
          if (format.containsKey(key)) annexB(format.getByteBuffer(key), output);
        }
      }
      ByteBuffer buffer = ByteBuffer.allocate(1024 * 1024);
      while (true) {
        buffer.clear(); int size = extractor.readSampleData(buffer, 0);
        if (size < 0) break;
        buffer.position(0); buffer.limit(size);
        if (video) { annexB(buffer, output); }
        else {
          // 樣本由本工具固定產生 AAC-LC、16 kHz、單聲道；封裝為 ADTS。
          int length = size + 7;
          output.write(new byte[] {(byte)255, (byte)241, 0x60,
            (byte)(0x40 | (length >> 11)), (byte)(length >> 3),
            (byte)(((length & 7) << 5) | 31), (byte)252});
          byte[] data = new byte[size]; buffer.get(data); output.write(data);
        }
        extractor.advance();
      }
    } finally { extractor.release(); }
  }

  public static void main(String[] args) throws Exception {
    File directory = new File(args[0]);
    if (!directory.isDirectory()) throw new IllegalArgumentException("Create a fresh sample directory first");
    if (args.length > 1 && args[1].equals("extract")) {
      elementary(new File(directory, "voice.m4a"), new File(directory, "audio.aac"), false);
      elementary(new File(directory, "video.mp4"), new File(directory, "video.h264"), true);
      return;
    }
    if (args.length > 1 && args[1].equals("verify")) {
      JSONArray verified = new JSONArray(), unsupported = new JSONArray();
      for (String name : new String[] {"audio.aac", "audio.ts", "video.ts", "audio.ps", "video.ps"}) {
        try { verified.put(inspect(new File(directory, name))); }
        catch (Exception error) { unsupported.put(new JSONObject().put("name", name).put("reason", error.toString())); }
      }
      Files.write(new File(directory, "mpeg_native.json").toPath(),
        new JSONObject().put("samples", verified).put("unsupported", unsupported).toString(2).getBytes(StandardCharsets.UTF_8));
      return;
    }
    JSONArray samples = new JSONArray();
    File video = new File(directory, "video.mp4");
    File audio = new File(directory, "voice.m4a");
    encode(video, "video/avc", true, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4);
    encode(audio, "audio/mp4a-latm", false, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4);
    samples.put(inspect(video)); samples.put(inspect(audio));
    for (String extension : new String[] {"jpg", "pdf", "m4a"}) {
      File renamed = new File(directory, "renamed_video." + extension);
      Files.copy(video.toPath(), renamed.toPath());
      samples.put(inspect(renamed));
    }
    File disguisedAudio = new File(directory, "renamed_audio.jpg");
    Files.copy(audio.toPath(), disguisedAudio.toPath());
    samples.put(inspect(disguisedAudio));
    JSONObject report = new JSONObject().put("samples", samples);
    try {
      File webm = new File(directory, "video.webm");
      encode(webm, "video/x-vnd.on2.vp8", true, MediaMuxer.OutputFormat.MUXER_OUTPUT_WEBM);
      samples.put(inspect(webm));
    } catch (Exception error) { report.put("webm_unavailable", error.toString()); }
    Bitmap bitmap = Bitmap.createBitmap(32, 32, Bitmap.Config.ARGB_8888);
    bitmap.eraseColor(0xff237daa);
    try (FileOutputStream output = new FileOutputStream(new File(directory, "still.jpg"))) {
      bitmap.compress(Bitmap.CompressFormat.JPEG, 90, output);
    }
    bitmap.recycle();
    Files.write(new File(directory, "samples.json").toPath(), report.toString(2).getBytes(StandardCharsets.UTF_8));
    System.out.println(report.toString());
  }
}
