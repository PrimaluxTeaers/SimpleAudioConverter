# 开发日志（残卷）

这不是完整变更记录，是从 1.2 到 1.3.2 的工作笔记里挑出来的部分。有些内容不放出：签名材料、构建机凭据、个别机型的未公开兼容数据，以及和第三方 ROM 内部实现相关的排查记录。删掉的部分不影响下面的结论。

## 2026-11-15：1.3.2 的处理器名单和音量

这一天先把 2025–2026 的机器过了一遍。2025 下半年到 2026 的旗舰基本落在天玑 9500/9600 和骁龙 8 Elite Gen 5/Gen 6 这几档，天玑 9500M、9600 Pro 这类衍生也在出货；中高端新增的是骁龙 7 Gen 4 和天玑 8500。8500 和 8400 是同一颗芯片的不同开关，GPU 解锁、频率抬一点，识别时不能当成两个完全不同的平台。

骁龙 7s 最后的处理是排除。7s 各型号的 MediaCodec 实现不一致，也没有和 7 标准款、7+ 共享同一套验证结果。名单里只留 7 Gen 3/4、7+ Gen 2/3；7s 走通用软件解码，界面直接写“不在名单”，不给“可能支持”这种模糊话。

性能卡的商品名是上一版留下的问题。`displayName` 优先读 `ro.product.marketname`，所以商品名会顶在芯片名位置上。这一版把 getter 删了，标题固定用 `chipName`，副行只留厂商、核心数、架构和 Android 版本。没读到芯片就写“未识别”，不再拿机型名兜底。

识别又补了几个入口：`ro.hardware.chipname`、`ro.build.display.id`、realme UI 的版本属性。Exynos 2400/2500 也进了映射，虽然不在主适配线，至少不会显示成一串原始字符串。`getprop` 一次性读全表并缓存，HyperOS 把 `SystemProperties` 反射掐掉时还有东西可读。

声音这块在现有 FFmpeg 包里查过，`volume`、`alimiter`、`loudnorm` 三个 filter 都在 `libavfilter.so` 里，不是纸面功能。实现是一条 filter 链：降噪在前，增益或响度统一在后。正增益自动挂 `alimiter=limit=0.95`，避免 +12 dB 直接把波形削平。响度统一用单遍 EBU R128，目标 -16 LUFS；批量里轻录音和成品混在一起时，比手动拖滑块稳。

## 2026-11-15：1.3.1 的设备识别

有台天玑 9400+ 的机器在 1.3.0 里显示“未识别 / Android 0”。一开始怀疑是 HyperOS 藏了 `ro.soc.model`，后来发现更基础：`MainActivity` 把 `Build.SUPPORTED_ABIS` 这个 `String[]` 直接塞进 MethodChannel 的 map。StandardMessageCodec 不支持 Java 字符串数组，编码整张 map 时抛异常，Dart 侧 catch 到后返回 `unknown`，于是核心数、架构、SDK 全丢了，连 `sdkInt` 都变成 0。

改法不复杂：数组用 `TextUtils.join` 转成逗号分隔字符串，SDK 和 release 直接用 `Build.VERSION`，不再绕 `SystemProperties`。另外留了三条后路：`getprop` 一次读出全部属性并缓存；`/proc/cpuinfo` 的 `Hardware` 行；`/proc/device-tree/model` 和 `/sys/devices/soc0/*`。HyperOS 把反射禁掉时，至少还有一条能读到东西。

## 2026-11 上旬：1.2 收尾

1.2 的起点是“转换后没声音”。FFmpeg 默认会挑一条它觉得合适的流，源文件里带封面或字幕时容易挑错。命令改成 `-map 0:a:0 -vn -map_metadata 0`，只取第一条音频、不碰视频、保留元数据。后来又把 `-map_chapters -1` 加上，省得章节轨跟着跑进输出。

格式从 11 种扩到 18 种。AMR-NB 只认 4.75 到 12.2 kbps 那八档，AMR-WB 只认 6.6 到 23.85 那九档，采样率还锁 8k/16k、单声道。滑块如果继续用连续值，FFmpeg 会直接拒绝。所以 AMR 单独走固定档位。

## 没做完和没验证的

- 没有 Android 模拟器，也没有 adb 设备。所有点击、滚动、长按都是 widget 测试里模拟的，真机转码没跑过。
- 1.3.2 的音量和响度 filter 名称在 `libavfilter.so` 里查到了，命令字符串也有单测，但没有逐条真机出文件。
- AMR-WB 的 muxer 是否真的接受 `-f amr`，只有编码器字符串证据。
- WavPack、CAF、AU、E-AC-3 的编码路径同样只有构建内的 encoder 列表证据。
- Android 17 的 SDK 平台仍然没有装，targetSdk 保持 36；17 的识别逻辑有单测，但没有 adb。
- 包名保留 `com.technicjelle.simple_audio_converter.zh`，没有改成独立包名。改了会断覆盖升级。

## 给后来改的人

这份代码按 MPL-2.0 走，可以改、可以再发布，但改过的文件要保留同样的许可证，别把上游署名抹掉。要独立分发，建议换自己的包名和签名。构建参数和依赖版本在 README 里，签名材料不在仓库里。
