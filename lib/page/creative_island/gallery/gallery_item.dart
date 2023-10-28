import 'package:askaide/bloc/gallery_bloc.dart';
import 'package:askaide/helper/ability.dart';
import 'package:askaide/helper/constant.dart';
import 'package:askaide/helper/haptic_feedback.dart';
import 'package:askaide/helper/helper.dart';
import 'package:askaide/helper/image.dart';
import 'package:askaide/lang/lang.dart';
import 'package:askaide/page/component/attached_button_panel.dart';
import 'package:askaide/page/component/background_container.dart';
import 'package:askaide/page/component/column_block.dart';
import 'package:askaide/page/component/enhanced_button.dart';
import 'package:askaide/page/component/gallery_item_share.dart';
import 'package:askaide/page/component/image_preview.dart';
import 'package:askaide/page/component/random_avatar.dart';
import 'package:askaide/page/component/dialog.dart';
import 'package:askaide/page/component/theme/custom_size.dart';
import 'package:askaide/page/component/theme/custom_theme.dart';
import 'package:askaide/repo/api_server.dart';
import 'package:askaide/repo/settings_repo.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:go_router/go_router.dart';

class GalleryItemScreen extends StatefulWidget {
  final SettingRepository setting;
  final int galleryId;
  const GalleryItemScreen({
    super.key,
    required this.setting,
    required this.galleryId,
  });

  @override
  State<GalleryItemScreen> createState() => _GalleryItemScreenState();
}

class _GalleryItemScreenState extends State<GalleryItemScreen> {
  @override
  void initState() {
    super.initState();

    context.read<GalleryBloc>().add(GalleryItemLoadEvent(id: widget.galleryId));
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: customColors.backgroundContainerColor?.withAlpha(200),
        toolbarHeight: CustomSize.toolbarHeight,
        actions: [
          BlocBuilder<GalleryBloc, GalleryState>(
            buildWhen: (previous, current) => current is GalleryItemLoaded,
            builder: (context, state) {
              if (state is GalleryItemLoaded &&
                  state.isInternalUser &&
                  state.item.status == 1) {
                return TextButton(
                  onPressed: () {
                    openConfirmDialog(
                      context,
                      '确认取消？',
                      () => APIServer()
                          .cancelShareCreativeHistoryToGallery(
                              historyId: state.item.creativeHistoryId!)
                          .then((value) {
                        showSuccessMessage(
                            AppLocale.operateSuccess.getString(context));

                        context.read<GalleryBloc>().add(GalleryItemLoadEvent(
                            id: widget.galleryId, forceRefresh: true));
                      }),
                    );
                  },
                  child: Text(
                    '取消共享',
                    style: TextStyle(
                      color: customColors.weakLinkColor,
                      fontSize: 12,
                    ),
                  ),
                );
              }

              return const SizedBox();
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      backgroundColor: customColors.backgroundContainerColor,
      body: BackgroundContainer(
        setting: widget.setting,
        enabled: false,
        child: BlocBuilder<GalleryBloc, GalleryState>(
          buildWhen: (previous, current) => current is GalleryItemLoaded,
          builder: (context, state) {
            if (state is GalleryItemLoaded) {
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: CustomSize.smallWindowSize,
                  ),
                  child: SingleChildScrollView(
                    child: SafeArea(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            for (var img in state.item.images)
                              Container(
                                decoration: BoxDecoration(
                                  color: customColors.backgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                // padding: const EdgeInsets.symmetric(
                                //   horizontal: 10,
                                //   vertical: 10,
                                // ),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 5),
                                child: NetworkImagePreviewer(
                                  url: img,
                                  preview: imageURL(img, qiniuImageTypeThumb),
                                  hidePreviewButton: true,
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      RandomAvatar(
                                        id: state.item.userId ?? 0,
                                        usage: AvatarUsage.user,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        state.item.username ?? '匿名',
                                        style: TextStyle(
                                          color: customColors.weakTextColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${state.item.hotValue}',
                                        style: TextStyle(
                                          color: customColors.weakTextColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            ColumnBlock(
                              innerPanding: 10,
                              padding: const EdgeInsets.all(15),
                              children: [
                                if (state.item.prompt != null &&
                                    state.item.prompt!.isNotEmpty)
                                  TextItem(
                                    title: 'Prompt',
                                    value: state.item.prompt!,
                                  ),
                                if (state.item.negativePrompt != null &&
                                    state.item.negativePrompt!.isNotEmpty)
                                  TextItem(
                                    title: 'Negative Prompt',
                                    value: state.item.negativePrompt!,
                                  ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  EnhancedButton(
                                    title: '分享',
                                    icon: const Icon(Icons.share, size: 14),
                                    width: 100,
                                    color: customColors.backgroundInvertedColor,
                                    backgroundColor:
                                        customColors.backgroundColor,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          fullscreenDialog: true,
                                          builder: (context) =>
                                              GalleryItemShareScreen(
                                            images: state.item.images,
                                            prompt: state.item.prompt,
                                            negativePrompt:
                                                state.item.negativePrompt,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: EnhancedButton(
                                      title: '制作同款',
                                      onPressed: () {
                                        if (Ability().enableAPIServer()) {
                                          context.push(
                                              '/creative-draw/create?mode=text-to-image&id=${state.item.creativeId}&gallery_copy_id=${state.item.id}');
                                        } else {
                                          context.push('/login');
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return const Center(
              child: Text('Loading ...'),
            );
          },
        ),
      ),
    );
  }
}

class TextItem extends StatefulWidget {
  final String title;
  final String value;

  const TextItem({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  State<TextItem> createState() => _TextItemState();
}

class _TextItemState extends State<TextItem> {
  String valueTranslated = '';

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: customColors.weakTextColor,
            ),
          ),
          const SizedBox(height: 5),
          GestureDetector(
            onLongPressStart: (details) {
              HapticFeedbackHelper.mediumImpact();

              BotToast.showAttachedWidget(
                target: details.globalPosition,
                duration: const Duration(seconds: 8),
                animationDuration: const Duration(milliseconds: 200),
                animationReverseDuration: const Duration(milliseconds: 200),
                preferDirection: PreferDirection.topCenter,
                ignoreContentClick: false,
                onlyOne: true,
                allowClick: true,
                enableSafeArea: true,
                attachedBuilder: (cancel) => AttachedButtonPanel(
                  buttons: [
                    TextButton.icon(
                      onPressed: () {
                        FlutterClipboard.copy(widget.value).then((value) {
                          showSuccessMessage('已复制到剪贴板');
                        });
                        cancel();
                      },
                      label: const Text(''),
                      icon: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.copy,
                            color: Color.fromARGB(255, 255, 255, 255),
                            size: 14,
                          ),
                          Text(
                            "复制",
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        cancel();

                        APIServer().translate(widget.value).then((value) {
                          setState(() {
                            valueTranslated = value.result!;
                          });
                        }).onError((error, stackTrace) {
                          showErrorMessage(resolveError(context, error!));
                        });
                      },
                      label: const Text(''),
                      icon: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.translate,
                            color: Color.fromARGB(255, 255, 255, 255),
                            size: 14,
                          ),
                          Text(
                            '翻译',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Text(
              widget.value,
              style: TextStyle(
                fontSize: 12,
                color: customColors.weakTextColor,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (valueTranslated != '')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(children: [
                  Icon(
                    Icons.check_circle,
                    size: 12,
                    color: customColors.linkColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '中文翻译 ↓',
                    style: TextStyle(
                      fontSize: 12,
                      color: customColors.weakTextColor,
                    ),
                  ),
                ]),
                const SizedBox(height: 5),
                GestureDetector(
                  onLongPressStart: (details) {
                    HapticFeedbackHelper.mediumImpact();

                    BotToast.showAttachedWidget(
                      target: details.globalPosition,
                      duration: const Duration(seconds: 8),
                      animationDuration: const Duration(milliseconds: 200),
                      animationReverseDuration:
                          const Duration(milliseconds: 200),
                      preferDirection: PreferDirection.topCenter,
                      ignoreContentClick: false,
                      onlyOne: true,
                      allowClick: true,
                      enableSafeArea: true,
                      attachedBuilder: (cancel) => AttachedButtonPanel(
                        buttons: [
                          TextButton.icon(
                            onPressed: () {
                              FlutterClipboard.copy(valueTranslated)
                                  .then((value) {
                                showSuccessMessage('已复制到剪贴板');
                              });
                              cancel();
                            },
                            label: const Text(''),
                            icon: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.copy,
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  size: 14,
                                ),
                                Text(
                                  "复制",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text(
                    valueTranslated,
                    style: TextStyle(
                      fontSize: 12,
                      color: customColors.weakTextColor,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }
}
