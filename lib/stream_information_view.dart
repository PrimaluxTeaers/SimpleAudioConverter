import "package:ffmpeg_kit_flutter_new_audio/stream_information.dart";
import "package:flutter/material.dart";

import "l10n.dart";
import "utils.dart";

class StreamInformationView extends StatelessWidget {
  final StreamInformation info;

  const new({required this.info, super.key});

  @override
  Widget build(BuildContext context) {
    final int? bitrateNum = int.tryParse(info.getBitrate() ?? "");
    final String? bitrate = bitrateNum == null
        ? null
        : "${(bitrateNum / 1000.0).toStringAsFixed(0)} Kbps";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.t("Stream ${info.getIndex()} Information:", "轨道 ${info.getIndex()} 信息："),
          style: TextTheme.of(
            context,
          ).titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        Table(
          children: [
            TableRow(children: tr(S.t("Type:", "类型："), info.getType(), context)),
            TableRow(children: tr(S.t("Codec:", "编码："), info.getCodec(), context)),
            TableRow(children: tr(S.t("Format:", "格式："), info.getFormat(), context)),
            TableRow(children: tr(S.t("Channel Layout:", "声道布局："), info.getChannelLayout(), context)),
            TableRow(children: tr(S.t("Bitrate:", "码率："), bitrate, context)),
            TableRow(children: tr(S.t("Sample Rate:", "采样率："), info.getSampleRate(), context)),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
