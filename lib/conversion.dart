import "dart:io";

/// Where a format belongs in the picker. The UI turns these into filter chips
/// and users can also create their own groups on top.
enum FormatCategory { daily, lossless, voice, legacy, other }

/// A bitstream version or encoder profile that really changes the output.
/// Only listed when the encoder can actually produce it; LHDC / L2HC are
/// wireless transport codecs and have no FFmpeg encoder, so they are not here.
class FormatVariant {
  final String id;
  final String labelEn;
  final String labelZh;
  final String noteEn;
  final String noteZh;

  /// Forced sample rate, 0 keeps the source rate.
  final int sampleRate;

  /// Upper CBR bound for this variant, 0 falls back to the format range.
  final int maxKbps;

  const FormatVariant({
    required this.id,
    required this.labelEn,
    required this.labelZh,
    required this.noteEn,
    required this.noteZh,
    this.sampleRate = 0,
    this.maxKbps = 0,
  });
}

class AudioFormat {
  final String id;
  final String label;
  final String ext;
  final String mime;
  final FormatCategory category;
  final List<FormatVariant> variants;

  /// Lossless formats ignore the bitrate control entirely.
  final bool lossless;

  /// Continuous CBR range, in kbps. 0 means "not applicable".
  final int minKbps;
  final int maxKbps;

  /// If the codec only accepts discrete bitrates (AMR), list them here.
  /// An empty list means the range above is continuous.
  final List<double> fixedKbps;

  /// Highest VBR quality index supported (0 = best). null = no VBR mode.
  final int? vbrMax;

  final String summaryEn;
  final String summaryZh;
  final String detailEn;
  final String detailZh;

  const AudioFormat({
    required this.id,
    required this.label,
    required this.ext,
    required this.mime,
    this.category = FormatCategory.daily,
    this.variants = const [],
    this.lossless = false,
    this.minKbps = 0,
    this.maxKbps = 0,
    this.fixedKbps = const [],
    this.vbrMax,
    this.summaryEn = "",
    this.summaryZh = "",
    this.detailEn = "",
    this.detailZh = "",
  });

  bool get hasCbr => !lossless && (maxKbps > 0 || fixedKbps.isNotEmpty);
  bool get hasVbr => !lossless && vbrMax != null;
  bool get hasFixedSteps => fixedKbps.isNotEmpty;
  bool get isPcm => id == "wav" || id == "aiff" || id == "caf" || id == "au";

  String get extWithDot => ".$ext";
}

/// A one-tap combination shown at the bottom of the format sheet.
class FormatPreset {
  final String labelEn;
  final String labelZh;
  final String noteEn;
  final String noteZh;
  final int bitrate;
  final bool vbr;
  final int vbrQuality;
  final int flacLevel;
  final int pcmDepth;

  const FormatPreset({
    required this.labelEn,
    required this.labelZh,
    required this.noteEn,
    required this.noteZh,
    this.bitrate = 0,
    this.vbr = false,
    this.vbrQuality = 2,
    this.flacLevel = 5,
    this.pcmDepth = 16,
  });
}

const List<AudioFormat> kFormats = [
  AudioFormat(
    id: "mp3",
    label: "MP3",
    ext: "mp3",
    mime: "audio/mpeg",
    variants: [
      FormatVariant(
        id: "mpeg1",
        labelEn: "MPEG-1",
        labelZh: "MPEG-1",
        noteEn: "44.1/48 kHz, the normal MP3",
        noteZh: "44.1/48 kHz，最常见的 MP3",
      ),
      FormatVariant(
        id: "mpeg2",
        labelEn: "MPEG-2",
        labelZh: "MPEG-2",
        noteEn: "24 kHz, max 160 kbps",
        noteZh: "24 kHz，最高 160 kbps",
        sampleRate: 24000,
        maxKbps: 160,
      ),
      FormatVariant(
        id: "mpeg25",
        labelEn: "MPEG-2.5",
        labelZh: "MPEG-2.5",
        noteEn: "12 kHz, max 64 kbps",
        noteZh: "12 kHz，最高 64 kbps",
        sampleRate: 12000,
        maxKbps: 64,
      ),
    ],
    minKbps: 8,
    maxKbps: 320,
    vbrMax: 9,
    summaryEn: "The most compatible lossy format. Plays basically everywhere.",
    summaryZh: "兼容性最广的有损格式，几乎什么设备都能播。",
    detailEn: "Plays almost anywhere, including old car stereos and ancient phones. Fixed bitrate gives a predictable size; variable bitrate sounds a little better at the same size. Don't use it as a master copy: every re-encode loses detail.",
    detailZh: "什么地方都能放，老车机、随身听、旧手机基本都认。想要体积可预估就用固定码率，想同体积下好听一点就用动态码率。别拿它存母带，转一次就少一点细节。",
  ),
  AudioFormat(
    id: "m4a",
    label: "M4A (AAC)",
    ext: "m4a",
    mime: "audio/mp4",
    minKbps: 8,
    maxKbps: 512,
    summaryEn:
        "Native on both iOS and Android. Usually cleaner than MP3 at the same bitrate.",
    summaryZh: "苹果和安卓都原生支持，同码率下通常比 MP3 好听。",
    detailEn: "Native on phones and Apple devices; reliable for ringtones, voice notes and video soundtracks. Usually cleaner than MP3 at the same bitrate, but it is fixed bitrate only. For variable bitrate, use Opus or OGG.",
    detailZh: "手机和苹果设备都原生支持，做铃声、语音备忘、视频配乐都稳。同码率通常比 MP3 干净，但它是固定码率，想要动态码率得换 Opus 或 OGG。",
  ),
  AudioFormat(
    id: "aac",
    label: "AAC (ADTS)",
    ext: "aac",
    mime: "audio/aac",
    minKbps: 8,
    maxKbps: 512,
    summaryEn:
        "Raw AAC stream with no container. Used by broadcast, radio tools and some TVs.",
    summaryZh: "裸 AAC 流，没有容器，广播、电台工具和部分电视在用。",
    detailEn: "AAC without a container. Broadcast gear, some TVs and car units ask for this raw stream. It plays, but seeking is worse than M4A because there is no index. Use it only when the target explicitly wants .aac.",
    detailZh: "就是没有外壳的 AAC，广播和一些电视、车载设备点名要这种裸流。它能播，但拖动定位不如 M4A，因为没有索引。只在对方明确要 .aac 时用。",
  ),
  AudioFormat(
    id: "ogg",
    label: "OGG (Vorbis)",
    ext: "ogg",
    mime: "audio/ogg",
    minKbps: 32,
    maxKbps: 500,
    vbrMax: 10,
    summaryEn: "Open-source lossy format, strong at low and mid bitrates.",
    summaryZh: "开源有损格式，中低码率下音质扎实。",
    detailEn: "Open-source lossy format that holds up well at low and mid bitrates, with mature variable bitrate. Android plays it natively, but some old car units, Windows and portable players need an extra codec.",
    detailZh: "开源有损格式，中低码率下很能打，动态码率也成熟。安卓原生能放，但部分老车机、Windows 和播放器需要另装解码器。",
  ),
  AudioFormat(
    id: "opus",
    label: "Opus",
    ext: "opus",
    mime: "audio/opus",
    minKbps: 6,
    maxKbps: 510,
    vbrMax: 1,
    summaryEn:
        "The strongest lossy codec at low bitrates. Best pick for speech and streaming.",
    summaryZh: "低码率最强的有损格式，语音和流媒体首选。",
    detailEn: "The best value at low bitrates; good for speech, podcasts and online classes. Already clear at 64–96 kbps, with low latency. Old hardware support is poor, so check the target device before sending.",
    detailZh: "低码率下最划算，语音、播客、网课都适合。64-96 kbps 已经很清楚，延迟也低。老设备支持差，给陌生设备发文件前先确认对方能放。",
  ),
  AudioFormat(
    id: "flac",
    label: "FLAC",
    ext: "flac",
    mime: "audio/flac",
    category: FormatCategory.lossless,
    lossless: true,
    summaryEn:
        "Lossless compression at roughly half the size of WAV. Zero quality loss.",
    summaryZh: "无损压缩，体积约为 WAV 的一半，音质零损失。",
    detailEn: "Lossless compression at roughly half the size of WAV, decoded back bit-for-bit. Good for archives, masters and samples. The compression level changes encoding speed, not quality.",
    detailZh: "无损压缩，体积大概 WAV 的一半，解出来和原文件一模一样。适合存档、母带、采样素材。压缩等级只影响编码速度，不影响音质。",
  ),
  AudioFormat(
    id: "wav",
    label: "WAV",
    ext: "wav",
    mime: "audio/wav",
    category: FormatCategory.lossless,
    lossless: true,
    summaryEn: "Uncompressed PCM. The standard for recording and editing.",
    summaryZh: "无压缩 PCM，录音和后期剪辑的标准格式。",
    detailEn: "Uncompressed PCM, the usual intermediate for recording and editing. Very large, so don't use it for messaging or phone storage. If you need smaller files, use FLAC.",
    detailZh: "没压缩的 PCM，录音、剪辑、后期都拿它当中间格式。体积很大，别拿来发微信或存手机。要省空间就换 FLAC。",
  ),
  AudioFormat(
    id: "aiff",
    label: "AIFF",
    ext: "aiff",
    mime: "audio/aiff",
    category: FormatCategory.lossless,
    lossless: true,
    summaryEn: "Apple's uncompressed PCM. Same family as WAV, different byte order.",
    summaryZh: "苹果系的无压缩 PCM，和 WAV 同类，只是字节序不同。",
    detailEn: "Apple's uncompressed PCM, same family as WAV with a different byte order. Common in older Mac projects and sample libraries. Android can play it, but it is as large as WAV.",
    detailZh: "苹果那边的无压缩 PCM，和 WAV 是同类，只是字节序不一样。Mac 上的老工程、采样库常见。安卓能放，但体积和 WAV 一样大。",
  ),
  AudioFormat(
    id: "alac",
    label: "ALAC",
    ext: "m4a",
    mime: "audio/mp4",
    category: FormatCategory.lossless,
    lossless: true,
    summaryEn: "Apple's lossless codec, packaged in an m4a container.",
    summaryZh: "苹果的无损压缩，封装在 m4a 里。",
    detailEn: "Apple's lossless codec inside an m4a container; Apple devices play it directly. Android depends on the player and is less universal than FLAC. Use it when the target is an iPhone or iPad.",
    detailZh: "苹果的无损压缩，装在 m4a 里，苹果设备直接能放。安卓要看播放器支持，不如 FLAC 通用。适合给 iPhone、iPad 存无损。",
  ),
  AudioFormat(
    id: "caf",
    label: "CAF",
    ext: "caf",
    mime: "audio/x-caf",
    category: FormatCategory.lossless,
    lossless: true,
    summaryEn: "Apple Core Audio Format. PCM in a container built for long recordings.",
    summaryZh: "苹果 Core Audio 容器，装 PCM，专为长录音设计。",
    detailEn: "Apple's container for long PCM recordings, without WAV's 4 GB ceiling. Useful for multi-hour takes. Android and Windows rarely open it natively, so don't use it for general sharing.",
    detailZh:
        "苹果的长录音容器，装 PCM，没有 WAV 那种 4 GB 上限。录几个小时的东西用它比较稳。安卓和 Windows 很少原生认，别拿它做通用分发。",
  ),
  AudioFormat(
    id: "au",
    label: "AU",
    ext: "au",
    mime: "audio/basic",
    category: FormatCategory.other,
    lossless: true,
    summaryEn: "Sun/NeXT audio. A tiny legacy PCM container.",
    summaryZh: "Sun/NeXT 的老式音频容器，极简 PCM。",
    detailEn: "A Unix-era PCM format with no metadata. Mostly seen in old tools and test samples now. Phones and players generally ignore it unless you specifically need it.",
    detailZh: "Unix 时代留下的老格式，极简 PCM，没有元数据。现在基本只在老工具和测试样本里见到。手机和播放器大多不认，除非你明确需要它。",
  ),
  AudioFormat(
    id: "wv",
    label: "WavPack",
    ext: "wv",
    mime: "audio/x-wavpack",
    category: FormatCategory.lossless,
    lossless: true,
    summaryEn:
        "Lossless with better compression than FLAC on some material, far less common.",
    summaryZh: "无损，某些素材比 FLAC 压得更狠，但用的人少。",
    detailEn: "Lossless compression that can beat FLAC on some material, but few people use it. Good for archiving, bad for sharing. Desktop players handle it; phones usually need extra software.",
    detailZh: "无损压缩，某些素材比 FLAC 还小一点，但用的人少。适合归档，不适合发给别人。桌面播放器支持还行，手机基本要另装。",
  ),
  AudioFormat(
    id: "amr",
    label: "AMR-NB",
    ext: "amr",
    mime: "audio/amr",
    category: FormatCategory.voice,
    minKbps: 5,
    maxKbps: 12,
    fixedKbps: [4.75, 5.15, 5.9, 6.7, 7.4, 7.95, 10.2, 12.2],
    summaryEn: "The old phone-call codec. Tiny files, 8 kHz mono, made for speech only.",
    summaryZh: "老式通话编码，体积极小，8 kHz 单声道，只适合人声。",
    detailEn: "Old phone-call audio: 8 kHz mono, tiny files. Only for voice memos and legacy voicemail; music will sound like a phone call. Bitrate is limited to a few fixed steps.",
    detailZh: "老式电话音，8 kHz 单声道，体积极小。只适合语音备忘、老语音信箱，音乐会变成电话里的声音。码率只能从固定的几档里选。",
  ),
  AudioFormat(
    id: "awb",
    label: "AMR-WB",
    ext: "awb",
    mime: "audio/amr-wb",
    category: FormatCategory.voice,
    minKbps: 7,
    maxKbps: 24,
    fixedKbps: [6.6, 8.85, 12.65, 14.25, 15.85, 18.25, 19.85, 23.05, 23.85],
    summaryEn: "Wideband speech codec. Clearer than AMR-NB, still speech-only.",
    summaryZh: "宽带语音编码，比 AMR-NB 清楚，但仍然只为人声设计。",
    detailEn: "Clearer than AMR-NB: 16 kHz mono, used by HD voice and some recorders. Still designed for speech only; don't use it for music.",
    detailZh: "比 AMR-NB 清楚的语音编码，16 kHz 单声道，高清通话和一些录音笔在用。仍然只为人声设计，别拿它转音乐。",
  ),
  AudioFormat(
    id: "wma",
    label: "WMA",
    ext: "wma",
    mime: "audio/x-ms-wma",
    category: FormatCategory.legacy,
    minKbps: 32,
    maxKbps: 320,
    summaryEn: "Microsoft's legacy lossy format, mostly found in old Windows libraries.",
    summaryZh: "微软的老式有损格式，多见于旧 Windows 资料库。",
    detailEn: "Microsoft's legacy format, still found in old Windows libraries and some car systems. Most modern phones don't play it natively; convert to it only to keep old material usable.",
    detailZh: "微软的老格式，旧 Windows 资料库和某些车载系统里还有。现代手机大多不原生支持，转它基本是为了兼容旧资料。",
  ),
  AudioFormat(
    id: "mp2",
    label: "MP2",
    ext: "mp2",
    mime: "audio/mpeg",
    category: FormatCategory.legacy,
    minKbps: 32,
    maxKbps: 384,
    summaryEn: "MP3's predecessor, still used in broadcast and DVD authoring.",
    summaryZh: "MP3 的前身，广播和 DVD 制作里还在用。",
    detailEn: "MP3's predecessor, still used in broadcast, DVD authoring and some old video pipelines. No reason for everyday music; use it for legacy gear.",
    detailZh: "MP3 的前身，广播、DVD 制作和一些老视频工程还在用。日常听歌没必要选，兼容老设备时再用。",
  ),
  AudioFormat(
    id: "ac3",
    label: "AC-3",
    ext: "ac3",
    mime: "audio/ac3",
    category: FormatCategory.legacy,
    minKbps: 64,
    maxKbps: 640,
    summaryEn: "Dolby Digital - the standard for multichannel film and home theatre.",
    summaryZh: "杜比数字，多声道影视和家庭影院的标准。",
    detailEn: "Dolby Digital, the standard for multichannel film and home theatre. Good for making movie soundtracks that a receiver understands; not for headphone music.",
    detailZh: "杜比数字，多声道影视和家庭影院的标准。适合把电影音轨转成老功放能认的东西，不适合耳机听歌。",
  ),
  AudioFormat(
    id: "eac3",
    label: "E-AC-3",
    ext: "eac3",
    mime: "audio/eac3",
    category: FormatCategory.legacy,
    minKbps: 64,
    maxKbps: 640,
    summaryEn:
        "Dolby Digital Plus. Same family as AC-3, more efficient at low bitrates.",
    summaryZh: "杜比数字 Plus，和 AC-3 同门，低码率下效率更高。",
    detailEn: "Dolby Digital Plus, same family as AC-3 and more efficient at low bitrates. Streaming services use it for film audio; older receivers may only understand AC-3.",
    detailZh: "杜比数字 Plus，和 AC-3 同门，低码率下更省。流媒体拿它装影视音轨，老功放可能只认 AC-3。",
  ),
];

/// Short reference copy used by the "all formats" sheet. This is deliberately
/// not the same text as the detail sheet: the list answers "should I pick
/// this?", the detail sheet explains what it costs.
const Map<String, String> kFormatReferenceEn = {
  "mp3": "Old stereos, car units and files you have to send to someone: pick this first. The size is easy to predict, but do not use it as an editing master.",
  "m4a": "Phone-to-phone sharing, ringtones and video soundtracks. Both Apple and Android open it; if you need variable bitrate, go to Opus or OGG.",
  "aac": "Only when the other side explicitly asks for a raw .aac stream. For normal playback and sharing, M4A is less hassle.",
  "ogg": "Solid on Android, Linux and open-source players. Old car units and Windows may need an extra codec.",
  "opus": "Speech, podcasts and online classes. 64–96 kbps is already clear; check that the target device can open it before sending.",
  "flac": "Archives, masters and sample libraries. Decodes back bit-for-bit; the compression level only changes encoding speed.",
  "wav": "Recording, editing and post-production. Do not use it for messaging or phone storage; the files get large fast.",
  "aiff": "Older Mac projects and sample libraries. Android can play it, but it is as large as WAV.",
  "alac": "Lossless for iPhone and iPad. Android players vary; for general lossless sharing, FLAC is safer.",
  "caf": "Multi-hour recordings, where WAV's 4 GB ceiling gets in the way. Not for general sharing.",
  "au": "Only for old tools or test samples that explicitly want .au. Nothing everyday uses it.",
  "wv": "Archiving where you want a little less than FLAC. Anyone you send it to will probably need extra software.",
  "amr": "Voice memos and legacy voicemail. 8 kHz mono; do not put music through it.",
  "awb": "HD voice and recorder speech. 16 kHz mono; still speech only.",
  "wma": "Old Windows libraries and some car systems. Modern phones do not open it natively.",
  "mp2": "Broadcast, DVD authoring and old video pipelines. For everyday listening, use MP3.",
  "ac3": "Multichannel soundtracks for older receivers and home theatre. Not for headphone music.",
  "eac3": "Streaming-style film audio and newer receivers. Older gear may only understand AC-3.",
};

const Map<String, String> kFormatReferenceZh = {
  "mp3": "老车机、随身听、要发给别人的文件，选它最稳。体积好估，但别拿它当剪辑母带，每转一次都会掉细节。",
  "m4a": "手机互传、铃声、视频配乐用它。苹果和安卓都认；想要动态码率再换 Opus 或 OGG。",
  "aac": "只有对方明确要 .aac 裸流时才选。普通播放和分享用 M4A 更省事。",
  "ogg": "安卓、Linux 和开源播放器上很稳。老车机和 Windows 可能要另装解码器。",
  "opus": "语音、播客、网课首选，64-96 kbps 已经很清楚。发给陌生设备前先确认对方能放。",
  "flac": "存档、母带、采样素材用它，解出来和原文件一样。压缩等级只管编码速度。",
  "wav": "录音、剪辑、后期当中间格式。发人和存手机别用，体积涨得很快。",
  "aiff": "苹果老工程和采样库要它。安卓能放，但体积和 WAV 一样大。",
  "alac": "给 iPhone、iPad 存无损用。安卓播放器不一定认；通用无损还是 FLAC 稳。",
  "caf": "几小时的长录音用它，不会被 WAV 的 4 GB 上限卡住。别拿它做通用分发。",
  "au": "只在老工具或测试样本明确要 .au 时选，日常基本没人用它。",
  "wv": "归档想比 FLAC 再小一点可以试。发给别人，对方多半要另装软件。",
  "amr": "语音备忘、老语音信箱用。8 kHz 单声道，音乐别碰。",
  "awb": "高清通话和录音笔里的语音用。16 kHz 单声道，仍然只适合人声。",
  "wma": "旧 Windows 资料库和某些车载系统要它时再转。现代手机不原生支持。",
  "mp2": "广播、DVD 制作、老视频工程要它时用。日常听歌选 MP3。",
  "ac3": "给老功放、家庭影院做多声道音轨。耳机听歌别选。",
  "eac3": "流媒体风格的影视音轨和较新的功放用。更老的设备可能只认 AC-3。",
};

AudioFormat formatById(String id) =>
    kFormats.firstWhere((f) => f.id == id, orElse: () => kFormats.first);

/// Presets offered at the bottom of the detail sheet. Nothing is applied
/// until the user taps, so opening a format never silently rewrites settings.
List<FormatPreset> presetsFor(AudioFormat f) {
  if (f.lossless) {
    if (f.id == "flac" || f.id == "wv") {
      return [
        FormatPreset(
          labelEn: "Archive",
          labelZh: "归档",
          noteEn: "Maximum compression, slowest",
          noteZh: "压到最小，编码最慢",
          flacLevel: f.id == "flac" ? 12 : 8,
        ),
        FormatPreset(
          labelEn: "Balanced",
          labelZh: "均衡",
          noteEn: "Default speed and size",
          noteZh: "默认速度与体积",
          flacLevel: 5,
        ),
        FormatPreset(
          labelEn: "Fast",
          labelZh: "快速",
          noteEn: "Bigger file, quickest encode",
          noteZh: "体积大一点，编码最快",
          flacLevel: 0,
        ),
      ];
    }
    return [
      FormatPreset(
        labelEn: "24-bit",
        labelZh: "24 位",
        noteEn: "More headroom, bigger file",
        noteZh: "动态余量更大，文件更大",
        pcmDepth: 24,
      ),
      FormatPreset(
        labelEn: "16-bit",
        labelZh: "16 位",
        noteEn: "CD depth, half the size",
        noteZh: "CD 位深，体积减半",
        pcmDepth: 16,
      ),
    ];
  }

  if (f.hasFixedSteps) {
    final List<double> steps = f.fixedKbps;
    return [
      FormatPreset(
        labelEn: "Clearest",
        labelZh: "最清晰",
        noteEn: "${steps.last} kbps, still tiny",
        noteZh: "${steps.last} kbps，依然很小",
        bitrate: steps.last.round(),
      ),
      FormatPreset(
        labelEn: "Middle",
        labelZh: "中等",
        noteEn: "${steps[steps.length ~/ 2]} kbps",
        noteZh: "${steps[steps.length ~/ 2]} kbps",
        bitrate: steps[steps.length ~/ 2].round(),
      ),
      FormatPreset(
        labelEn: "Smallest",
        labelZh: "最小",
        noteEn: "${steps.first} kbps",
        noteZh: "${steps.first} kbps",
        bitrate: steps.first.round(),
      ),
    ];
  }

  final int high = f.maxKbps;
  final int mid = ((f.minKbps + f.maxKbps) / 2).round();
  final int low = (f.minKbps + (f.maxKbps - f.minKbps) * 0.3).round();
  return [
    FormatPreset(
      labelEn: "High quality",
      labelZh: "高音质",
      noteEn: "$high kbps CBR",
      noteZh: "$high kbps 固定码率",
      bitrate: high,
    ),
    FormatPreset(
      labelEn: "Balanced",
      labelZh: "均衡",
      noteEn: "$mid kbps CBR",
      noteZh: "$mid kbps 固定码率",
      bitrate: mid,
    ),
    FormatPreset(
      labelEn: "Small file",
      labelZh: "小体积",
      noteEn: "$low kbps CBR",
      noteZh: "$low kbps 固定码率",
      bitrate: low,
    ),
  ];
}

/// Everything the UI collects. Bitrate is continuous unless the codec only
/// accepts discrete steps; those are validated in [clampToFormat].
class ConversionSettings {
  String formatId = "mp3";
  String variantId = "mpeg1";
  bool vbr = false;
  int bitrate = 192;
  int vbrQuality = 2;
  int flacLevel = 5;
  int pcmDepth = 16;
  int sampleRate = 0;
  int channels = 0;
  int threads = 0;
  bool hardwareDecode = false;
  bool voiceOptimization = false;

  /// Overall gain applied to the whole file. 0 dB leaves it untouched.
  double gainDb = 0;

  /// Single-pass EBU R128 normalisation. When on, [gainDb] is ignored.
  bool normalizeLoudness = false;

  AudioFormat get format => formatById(formatId);

  int get effectiveMaxKbps {
    final FormatVariant? v = variant;
    if (v != null && v.maxKbps > 0 && v.maxKbps < format.maxKbps) {
      return v.maxKbps;
    }
    return format.maxKbps;
  }

  FormatVariant? get variant {
    for (final FormatVariant v in format.variants) {
      if (v.id == variantId) return v;
    }
    return null;
  }

  void selectFormat(String id) {
    formatId = id;
    variantId = formatById(id).variants.isEmpty ? "" : formatById(id).variants.first.id;
    clampToFormat();
  }

  void selectVariant(String id) {
    variantId = id;
    final FormatVariant? v = variant;
    if (v != null && v.maxKbps > 0 && bitrate > v.maxKbps) {
      bitrate = v.maxKbps;
    }
    clampToFormat();
  }

  /// For AMR the slider shows an index into fixedKbps; the UI maps it.
  int get fixedIndex {
    final List<double> steps = format.fixedKbps;
    if (steps.isEmpty) return 0;
    int best = 0;
    for (int i = 0; i < steps.length; i++) {
      if ((steps[i] - bitrate.toDouble()).abs() <
          (steps[best] - bitrate.toDouble()).abs()) {
        best = i;
      }
    }
    return best;
  }

  void clampToFormat() {
    final AudioFormat f = format;
    if (f.fixedKbps.isNotEmpty) {
      int best = 0;
      for (int i = 0; i < f.fixedKbps.length; i++) {
        if ((f.fixedKbps[i] - bitrate.toDouble()).abs() <
            (f.fixedKbps[best] - bitrate.toDouble()).abs()) {
          best = i;
        }
      }
      bitrate = f.fixedKbps[best].round();
    } else if (f.hasCbr) {
      if (bitrate < f.minKbps) bitrate = f.minKbps;
      if (bitrate > f.maxKbps) bitrate = f.maxKbps;
    }
    final FormatVariant? v = variant;
    if (v != null && v.maxKbps > 0 && bitrate > v.maxKbps) {
      bitrate = v.maxKbps;
    }
    if (f.vbrMax != null && vbrQuality > f.vbrMax!) vbrQuality = f.vbrMax!;
    if (!f.hasVbr) vbr = false;
  }

  void applyPreset(FormatPreset preset) {
    vbr = preset.vbr;
    if (preset.bitrate > 0) bitrate = preset.bitrate;
    vbrQuality = preset.vbrQuality;
    flacLevel = preset.flacLevel;
    pcmDepth = preset.pcmDepth;
    clampToFormat();
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
    case "aac":
      return "-c:a aac -b:a ${s.bitrate}k -f adts";
    case "ogg":
      return s.vbr
          ? "-c:a libvorbis -q:a ${s.vbrQuality}"
          : "-c:a libvorbis -b:a ${s.bitrate}k";
    case "opus":
      return "-c:a libopus -b:a ${s.bitrate}k -vbr ${s.vbr ? "on" : "off"}"
          "${s.voiceOptimization ? " -application voip" : " -application audio"}";
    case "flac":
      return "-c:a flac -compression_level ${s.flacLevel}";
    case "wv":
      return "-c:a wavpack -compression_level ${s.flacLevel.clamp(0, 8)}";
    case "wav":
      final String codec = switch (s.pcmDepth) {
        24 => "pcm_s24le",
        32 => "pcm_f32le",
        _ => "pcm_s16le",
      };
      return "-c:a $codec";
    case "caf":
      return "-c:a ${s.pcmDepth == 24 ? "pcm_s24be" : "pcm_s16be"} -f caf";
    case "au":
      return "-c:a pcm_s16be -f au";
    case "aiff":
      return s.pcmDepth == 24 ? "-c:a pcm_s24be" : "-c:a pcm_s16be";
    case "alac":
      return "-c:a alac";
    case "amr":
      return "-c:a amr_nb -b:a ${s.bitrate}k -ar 8000 -ac 1 -f amr";
    case "awb":
      return "-c:a amr_wb -b:a ${s.bitrate}k -ar 16000 -ac 1 -f amr";
    case "wma":
      return "-c:a wmav2 -b:a ${s.bitrate}k";
    case "mp2":
      return "-c:a mp2 -b:a ${s.bitrate}k";
    case "ac3":
      return "-c:a ac3 -b:a ${s.bitrate}k";
    case "eac3":
      return "-c:a eac3 -b:a ${s.bitrate}k";
    default:
      return "";
  }
}

/// Builds the ffmpeg command for one file.
///
/// Only the first audio stream is mapped and video/cover-art streams are
/// dropped (`-vn`), which is what keeps players from latching onto a cover
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
  final List<String> filters = <String>[];
  if (rnnModel != null) {
    filters.add("arnndn=model=${rnnModel.path}:mix=1.0");
  }
  if (settings.normalizeLoudness) {
    filters.add("loudnorm=I=-16:TP=-1.5:LRA=11");
  } else if (settings.gainDb.abs() >= 0.05) {
    filters.add("volume=${settings.gainDb.toStringAsFixed(1)}dB");
    if (settings.gainDb > 0) {
      filters.add("alimiter=limit=0.95");
    }
  }
  if (filters.isNotEmpty) {
    b.write('-filter:a "${filters.join(",")}" ');
  }
  b.write("-map 0:a:0 -vn -map_metadata 0 -map_chapters -1 ");
  final int sampleRate = settings.variant?.sampleRate ?? settings.sampleRate;
  if (sampleRate > 0 && !f.id.startsWith("amr")) {
    b.write("-ar $sampleRate ");
  }
  if (settings.channels > 0 && !f.id.startsWith("amr")) {
    b.write("-ac ${settings.channels} ");
  }
  if (settings.threads > 0) b.write("-threads ${settings.threads} ");
  b.write("${_codecArgs(f, settings)} ");
  if (f.id == "m4a" || f.id == "alac") b.write("-movflags +faststart ");
  b.write('"$outputPath"');
  return b.toString();
}
