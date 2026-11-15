import "dart:io";

/// Output format description plus the ffmpeg arguments it needs.
class AudioFormat {
  final String id;
  final String label;
  final String ext;
  final String mime;

  /// Lossless formats ignore the bitrate control entirely.
  final bool lossless;

  /// Continuous CBR range, in kbps. 0 means "not applicable".
  final int minKbps;
  final int maxKbps;

  /// Highest VBR quality index supported (0 = best). null = no VBR mode.
  final int? vbrMax;

  /// VBR quality meaning, e.g. mp3 uses -q:a.
  final String vbrHint;

  const AudioFormat({
    required this.id,
    required this.label,
    required this.ext,
    required this.mime,
    this.lossless = false,
    this.minKbps = 0,
    this.maxKbps = 0,
    this.vbrMax,
    this.vbrHint = "",
  });

  bool get hasCbr => !lossless && maxKbps > 0;
  bool get hasVbr => !lossless && vbrMax != null;
}

const List<AudioFormat> kFormats = [
  AudioFormat(
    id: "mp3",
    label: "MP3",
    ext: "mp3",
    mime: "audio/mpeg",
    minKbps: 8,
    maxKbps: 320,
    vbrMax: 9,
    vbrHint: "0 最好 / 9 最小",
  ),
  AudioFormat(
    id: "m4a",
    label: "M4A（AAC）",
    ext: "m4a",
    mime: "audio/mp4",
    minKbps: 8,
    maxKbps: 512,
  ),
  AudioFormat(
    id: "ogg",
    label: "OGG（Vorbis）",
    ext: "ogg",
    mime: "audio/ogg",
    minKbps: 32,
    maxKbps: 500,
    vbrMax: 10,
    vbrHint: "0 最好 / 10 最小",
  ),
  AudioFormat(
    id: "opus",
    label: "Opus",
    ext: "opus",
    mime: "audio/opus",
    minKbps: 6,
    maxKbps: 510,
    vbrMax: 1,
    vbrHint: "可变码率开关",
  ),
  AudioFormat(
    id: "flac",
    label: "FLAC（无损）",
    ext: "flac",
    mime: "audio/flac",
    lossless: true,
  ),
  AudioFormat(
    id: "wav",
    label: "WAV（无损）",
    ext: "wav",
    mime: "audio/wav",
    lossless: true,
  ),
  AudioFormat(
    id: "aiff",
    label: "AIFF（无损）",
    ext: "aiff",
    mime: "audio/aiff",
    lossless: true,
  ),
  AudioFormat(
    id: "alac",
    label: "ALAC（无损）",
    ext: "m4a",
    mime: "audio/mp4",
    lossless: true,
  ),
  AudioFormat(
    id: "wma",
    label: "WMA",
    ext: "wma",
    mime: "audio/x-ms-wma",
    minKbps: 32,
    maxKbps: 320,
  ),
  AudioFormat(
    id: "mp2",
    label: "MP2",
    ext: "mp2",
    mime: "audio/mpeg",
    minKbps: 32,
    maxKbps: 384,
  ),
  AudioFormat(
    id: "ac3",
    label: "AC-3",
    ext: "ac3",
    mime: "audio/ac3",
    minKbps: 64,
    maxKbps: 640,
  ),
];

AudioFormat formatById(String id) =>
    kFormats.firstWhere((f) => f.id == id, orElse: () => kFormats.first);

/// Everything the UI collects. Bitrate is continuous: any kbps value inside
/// the format range is accepted, the codec rounds internally if it needs to.
class ConversionSettings {
  String formatId = "mp3";
  bool vbr = false;
  int bitrate = 192;
  int vbrQuality = 2;
  int flacLevel = 5;

  /// 16 / 24 / 32(float) for WAV, 16 / 24 for AIFF.
  int pcmDepth = 16;

  /// 0 = keep source.
  int sampleRate = 0;

  /// 0 = keep, 1 = mono, 2 = stereo.
  int channels = 0;

  /// Encoder threads. 0 = let ffmpeg decide.
  int threads = 0;

  /// Ask MediaCodec to decode the video stream. Only meaningful when the
  /// source actually carries video; pure audio never touches it.
  bool hardwareDecode = false;

  bool voiceOptimization = false;

  AudioFormat get format => formatById(formatId);

  void clampToFormat() {
    final AudioFormat f = format;
    if (f.hasCbr) {
      if (bitrate < f.minKbps) bitrate = f.minKbps;
      if (bitrate > f.maxKbps) bitrate = f.maxKbps;
    }
    if (f.vbrMax != null && vbrQuality > f.vbrMax!) vbrQuality = f.vbrMax!;
    if (!f.hasVbr) vbr = false;
  }
}

String _codecArgs(AudioFormat f, ConversionSettings s) {
  switch (f.id) {
    case "mp3":
      return s.vbr
          ? "-c:a libmp3lame -q:a ${s.vbrQuality} -id3v2_version 3 -write_id3v1 1"
          : "-c:a libmp3lame -b:a ${s.bitrate}k -id3v2_version 3 -write_id3v1 1";
    case "m4a":
      return "-c:a aac -b:a ${s.bitrate}k";
    case "ogg":
      return s.vbr
          ? "-c:a libvorbis -q:a ${s.vbrQuality}"
          : "-c:a libvorbis -b:a ${s.bitrate}k";
    case "opus":
      return "-c:a libopus -b:a ${s.bitrate}k -vbr ${s.vbr ? "on" : "off"}"
          "${s.voiceOptimization ? " -application voip" : " -application audio"}";
    case "flac":
      return "-c:a flac -compression_level ${s.flacLevel}";
    case "wav":
      final String codec = switch (s.pcmDepth) {
        24 => "pcm_s24le",
        32 => "pcm_f32le",
        _ => "pcm_s16le",
      };
      return "-c:a $codec";
    case "aiff":
      return s.pcmDepth == 24 ? "-c:a pcm_s24be" : "-c:a pcm_s16be";
    case "alac":
      return "-c:a alac";
    case "wma":
      return "-c:a wmav2 -b:a ${s.bitrate}k";
    case "mp2":
      return "-c:a mp2 -b:a ${s.bitrate}k";
    case "ac3":
      return "-c:a ac3 -b:a ${s.bitrate}k";
    default:
      return "";
    }
  }

/// Builds the ffmpeg command for one file.
///
/// Only the first audio stream is mapped and video/cover-art streams are
/// dropped (`-vn`). That is what keeps players from latching onto a cover
/// image as a "video" track and playing silence.
String buildConvertCommand({
  required String inputUrl,
  required String outputPath,
  required ConversionSettings settings,
  File? rnnModel,
  bool hasVideo = false,
}) {
  final AudioFormat f = settings.format;
  final StringBuffer b = StringBuffer();
  b.write("-hide_banner -y ");
  if (settings.hardwareDecode && hasVideo) {
    b.write("-hwaccel mediacodec ");
  }
  b.write('-i "$inputUrl" ');
  if (rnnModel != null) {
    b.write('-filter:a "arnndn=model=${rnnModel.path}:mix=1.0" ');
  }
  b.write("-map 0:a:0 -vn -map_metadata 0 ");
  if (settings.sampleRate > 0) b.write("-ar ${settings.sampleRate} ");
  if (settings.channels > 0) b.write("-ac ${settings.channels} ");
  if (settings.threads > 0) b.write("-threads ${settings.threads} ");
  b.write("${_codecArgs(f, settings)} ");
  if (f.id == "m4a" || f.id == "alac") b.write("-movflags +faststart ");
  b.write('"$outputPath"');
  return b.toString();
}
