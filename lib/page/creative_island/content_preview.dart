import 'package:askaide/helper/constant.dart';
import 'package:askaide/helper/image.dart';
import 'package:askaide/page/component/image_preview.dart';
import 'package:askaide/page/component/theme/custom_theme.dart';
import 'package:askaide/repo/api/creative.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreativeIslandContentPreview extends StatefulWidget {
  final CustomColors customColors;
  final CreativeItemInServer? item;
  final String? prompt;
  final IslandResult result;

  const CreativeIslandContentPreview({
    super.key,
    required this.customColors,
    this.item,
    this.prompt,
    required this.result,
  });

  @override
  State<CreativeIslandContentPreview> createState() =>
      _CreativeIslandContentPreviewState();
}

class _CreativeIslandContentPreviewState
    extends State<CreativeIslandContentPreview> {
  var currentTime = DateTime.now().add(const Duration(days: 7));

  @override
  Widget build(BuildContext context) {
    var customColors = Theme.of(context).extension<CustomColors>()!;
    final expireTime = widget.item != null
        ? DateFormat('y-MM-dd').format(
            widget.item!.createdAt!.add(const Duration(days: 7)).toLocal())
        : DateFormat('y-MM-dd').format(currentTime);
    return widget.result.text == ''
        ? const Center(
            child: Text('生成结果将在这里展示'),
          )
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(
                    top: 5,
                    bottom: 5,
                    left: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: customColors.weakTextColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '点击图片可分享、保存；有效期至 $expireTime',
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 12,
                          color: customColors.weakTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                ...(widget.result.result
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 10,
                        ),
                        child: _buildImagePreviewer(
                          widget.result.params ?? {},
                          e,
                        ),
                      ),
                    )
                    .toList()),
              ],
            ),
          );
  }

  Widget _buildImagePreviewer(
    Map<String, dynamic> params,
    String e,
  ) {
    return NetworkImagePreviewer(
      url: e,
      preview: imageURL(e, qiniuImageTypeThumb),
      original: params['image'] == null || params['image'] == ''
          ? null
          : params['image'] as String,
      description: widget.prompt ?? widget.item?.prompt ?? '',
    );
  }
}

class IslandResult {
  final List<String> result;
  final Map<String, dynamic>? params;

  bool hasImageParam() {
    return params != null && params!['image'] != null && params!['image'] != '';
  }

  String get text {
    return result.map((e) => '![image]($e)').join("\n\n");
  }

  IslandResult({
    required this.result,
    this.params,
  });
}
