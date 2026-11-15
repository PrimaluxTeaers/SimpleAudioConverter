# 开发日志（残卷）

这不是完整变更记录，是从 1.2 到 1.3.1 的工作笔记里挑出来的部分。有些内容不放出：签名材料、构建机凭据、个别机型的未公开兼容数据，以及和第三方 ROM 内部实现相关的排查记录。删掉的部分不影响下面的结论。

## 2026-11 上旬：先把 1.2 收尾

1.2 的起点是“转换后没声音”。FFmpeg 默认会挑一条它觉得合适的流，源文件里带封面或字幕时容易挑错。命令改成 `-map 0:a:0 -vn -map_metadata 0`，只取第一条音频、不碰视频、保留元数据。后来又把 `-map_chapters -1` 加上，省得章节轨跟着跑进输出。

格式从 11 种扩到 18 种。冷门格式不是加一行枚举就完事：AMR-NB 只认 4.75 到 12.2 kbps 那八档，AMR-WB 只认 6.6 到 23.85 那九档，采样率还必须锁 8k/16k、单声道。滑块如果继续用连续值，FFmpeg 会直接拒绝。所以 AMR 单独走固定档位，UI 上也只显示这几档。

WavPack、CAF、AU 一开始按有损配参数，转出来对不上。后来统一走无损路径，问题消失。E-AC-3 的码率上限和 AC-3 不一样，也单独收了口。

## 2026-11 中旬：1.2 的 UI

推荐预设原来放在详情页顶部，点开格式就被塞一套参数，很烦。挪到滚动到底部，点了才生效。这个改动本身很小，测试里那条“滚到预设”就是为了防止以后又被挪回去。

滑块的长按微调是 0.35 倍速，松手吸附整数。第一版只改了拖动灵敏度，没做吸附，松手会停在 137.4 kbps 这种数。补了 `onLongPressEnd` 才闭环。

切换按钮的过渡动画踩了一个断言：`AnimatedContainer` 从“无阴影”插值到“有阴影”时，`BoxShadow.scale` 会算出负的 blur，Flutter 直接抛 `Text shadow blur radius should be non-negative`。改成两种状态都给阴影列表，未选中用透明色，插值就不再经过“没有阴影”这个中间态。

## 2026-11 中旬：窄屏溢出

`flutter test` 里首页那条一直报 `RenderFlex overflowed by 98 / 195 pixels on the right`，而且只在测试字体和窄屏下出现。先怀疑模式切换，后来怀疑码率行，最后是分组横向滚动外层没限宽。改法不复杂：该用 `Flexible` 的地方不要直接放 `Row`，横向列表外面套一层 `SizedBox` 高度约束。修完 7 条 widget 测试全过。

## 2026-11 下旬：1.3 的取舍

MP3 的版本选择不是把所有版本都摆出来。MPEG-2 和 MPEG-2.5 的采样率、码率上限和 MPEG-1 差很多，选错版本再拖 320 kbps，FFmpeg 会静默降级或者直接报错。所以版本下拉放在码率面板上方，选完立刻 clamp 到该版本的真实范围。

硬件解码失败的弹窗是补出来的。之前只在结果卡片上标红，用户得自己回设置里关硬解。现在弹窗直接给“切软件并重试”，软件也失败再提示换格式或版本。

## 2026-11-15：1.3.1 的设备识别

有台 REDMI K80 Ultra（天玑 9400+、HyperOS 4、Android 17）在 1.3.0 里显示“未识别 / Android 0”。一开始怀疑是 HyperOS 藏了 `ro.soc.model`，后来发现更基础：`MainActivity` 把 `Build.SUPPORTED_ABIS` 这个 `String[]` 直接塞进 MethodChannel 的 map。StandardMessageCodec 不支持 Java 字符串数组，编码整张 map 时抛异常，Dart 侧 catch 到后返回 `unknown`，于是核心数、架构、SDK 全丢了，连 `sdkInt` 都变成 0。

改法不复杂：数组用 `TextUtils.join` 转成逗号分隔字符串，SDK 和 release 直接用 `Build.VERSION`，不再绕 `SystemProperties`。另外留了三条后路：`getprop` 一次读出全部属性并缓存；`/proc/cpuinfo` 的 `Hardware` 行；`/proc/device-tree/model` 和 `/sys/devices/soc0/*`。HyperOS 把反射禁掉时，至少还有一条能读到东西。

型号映射补了单测：MT6991 对天玑 9400+ / 9400，MT6989 对 9300 / 9300+，MT6993 对 9500 系列，MT6995 对 9600 系列；骁龙那边 SM8650 到 SM8975 逐个过。`SOC_MODEL` 写成 `0` 的机器也有测试，确认会落到 `ro.mediatek.platform`。

## 没做完和没验证的

- 没有 Android 模拟器，也没有 adb 设备。所有点击、滚动、长按都是 widget 测试里模拟的，真机转码没跑过。
- AMR-WB 的 muxer 是否真的接受 `-f amr`，只有编码器字符串证据，没在设备上出过文件。
- WavPack、CAF、AU、E-AC-3 的编码路径同样只有构建内的 encoder 列表证据，没有逐条试转。
- Android 17 的 SDK 平台仍然没有装，targetSdk 保持 36；17 的识别逻辑有单测，但没有 adb，装包和真机转码要在用户机器上验。
- 包名保留 `com.technicjelle.simple_audio_converter.zh`，没有改成独立包名。改了会断覆盖升级，旧设置和输出目录也会丢。

## 给后来改的人

这份代码按 MPL-2.0 走，可以改、可以再发布，但改过的文件要保留同样的许可证，别把上游署名抹掉。要独立分发，建议换自己的包名和签名，别用这个包名发修改版，否则用户没法区分。构建参数和依赖版本在 README 里，签名材料不在仓库里，自己生成一份。
