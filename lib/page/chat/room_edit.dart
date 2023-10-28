import 'dart:io';
import 'dart:math';

import 'package:askaide/helper/ability.dart';
import 'package:askaide/helper/model.dart';
import 'package:askaide/helper/upload.dart';
import 'package:askaide/lang/lang.dart';
import 'package:askaide/page/chat/room_create.dart';
import 'package:askaide/page/component/avatar_selector.dart';
import 'package:askaide/page/component/background_container.dart';
import 'package:askaide/page/component/column_block.dart';
import 'package:askaide/page/component/enhanced_button.dart';
import 'package:askaide/page/component/enhanced_input.dart';
import 'package:askaide/page/component/enhanced_textfield.dart';
import 'package:askaide/page/component/image.dart';
import 'package:askaide/page/component/item_selector_search.dart';
import 'package:askaide/page/component/loading.dart';
import 'package:askaide/page/component/random_avatar.dart';
import 'package:askaide/page/component/theme/custom_size.dart';
import 'package:askaide/page/component/theme/custom_theme.dart';
import 'package:askaide/bloc/room_bloc.dart';
import 'package:askaide/page/component/dialog.dart';
import 'package:askaide/repo/api_server.dart';
import 'package:askaide/repo/model/model.dart' as mm;
import 'package:askaide/repo/settings_repo.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:go_router/go_router.dart';

class RoomEditPage extends StatefulWidget {
  final int roomId;
  final SettingRepository setting;
  const RoomEditPage({super.key, required this.roomId, required this.setting});

  @override
  State<RoomEditPage> createState() => _RoomEditPageState();
}

class _RoomEditPageState extends State<RoomEditPage> {
  final _nameController = TextEditingController();
  final _promptController = TextEditingController(text: '');
  final _initMessageController = TextEditingController(text: '');

  final randomSeed = Random().nextInt(10000);

  String? _originalAvatarUrl;
  int? _originalAvatarId;

  String? _avatarUrl;
  int? _avatarId;

  List<String> avatarPresets = [];

  int maxContext = 5;

  List<ChatMemory> validMemories = [
    ChatMemory('无记忆', 1, description: '每次对话都是独立的，常用于一次性问答'),
    ChatMemory('基础', 3, description: '记住最近的 3 次对话'),
    ChatMemory('中等', 6, description: '记住最近的 6 次对话'),
    ChatMemory('深度', 10, description: '记住最近的 10 次对话'),
  ];

  bool showAdvancedOptions = false;

  mm.Model? _selectedModel;
  String? reservedModel;

  @override
  void initState() {
    super.initState();

    BlocProvider.of<RoomBloc>(context)
        .add(RoomLoadEvent(widget.roomId, cascading: false));

    // 获取预设头像
    if (Ability().enableAPIServer()) {
      APIServer().avatars().then((value) {
        avatarPresets = value;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocale.roomSetting.getString(context),
          style: const TextStyle(fontSize: CustomSize.appBarTitleSize),
        ),
        centerTitle: true,
        elevation: 0,
        toolbarHeight: CustomSize.toolbarHeight,
      ),
      backgroundColor: customColors.backgroundContainerColor,
      body: BackgroundContainer(
        setting: widget.setting,
        enabled: false,
        child: BlocConsumer<RoomBloc, RoomState>(
          listener: (context, state) {
            if (state is RoomLoaded) {
              _nameController.text = state.room.name;
              _promptController.text = state.room.systemPrompt ?? '';
              maxContext = state.room.maxContext;
              _initMessageController.text = state.room.initMessage ?? '';

              ModelAggregate.model(state.room.model).then((value) {
                setState(() {
                  _selectedModel = value;
                  reservedModel = value.id;
                });
              });

              if (state.room.avatarUrl != null && state.room.avatarUrl != '') {
                setState(() {
                  _avatarUrl = state.room.avatarUrl;
                  _avatarId = null;

                  _originalAvatarUrl = state.room.avatarUrl;
                  _originalAvatarId = null;
                });
              } else if (state.room.avatarId != null &&
                  state.room.avatarId != 0) {
                setState(() {
                  _avatarId = state.room.avatarId;
                  _avatarUrl = null;

                  _originalAvatarId = state.room.avatarId;
                  _originalAvatarUrl = null;
                });
              } else {
                setState(() {
                  _avatarId = null;
                  _avatarUrl = null;

                  _originalAvatarId = state.room.id;
                  _originalAvatarUrl = null;
                });
              }
            }
          },
          builder: (context, state) {
            if (state is RoomLoaded) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // 名称
                      if (state.room.category != 'system')
                        ColumnBlock(
                          children: [
                            EnhancedTextField(
                              customColors: customColors,
                              controller: _nameController,
                              maxLength: 50,
                              maxLines: 1,
                              showCounter: false,
                              labelText: AppLocale.roomName.getString(context),
                              labelPosition: LabelPosition.left,
                              hintText: AppLocale.required.getString(context),
                              textDirection: TextDirection.rtl,
                            ),
                            if (Ability().enableAPIServer())
                              EnhancedInput(
                                padding:
                                    const EdgeInsets.only(top: 10, bottom: 5),
                                title: Text(
                                  '头像',
                                  style: TextStyle(
                                    color: customColors.textfieldLabelColor,
                                    fontSize: 16,
                                  ),
                                ),
                                value: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 45,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: _avatarUrl == null
                                            ? null
                                            : DecorationImage(
                                                image: (_avatarUrl!
                                                            .startsWith('http')
                                                        ? CachedNetworkImageProviderEnhanced(
                                                            _avatarUrl!)
                                                        : FileImage(
                                                            File(_avatarUrl!)))
                                                    as ImageProvider,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                      child: _avatarUrl == null &&
                                              _avatarId == null
                                          ? const Center(
                                              child: Icon(
                                                Icons.interests,
                                                color: Colors.grey,
                                              ),
                                            )
                                          : (_avatarId == null
                                              ? const SizedBox()
                                              : RandomAvatar(
                                                  id: _avatarId!,
                                                  usage: AvatarUsage.room,
                                                )),
                                    ),
                                  ],
                                ),
                                onPressed: () {
                                  openModalBottomSheet(
                                    context,
                                    (context) {
                                      return AvatarSelector(
                                        onSelected: (selected) {
                                          setState(() {
                                            _avatarUrl = selected.url;
                                            _avatarId = selected.id;
                                          });
                                          context.pop();
                                        },
                                        usage: AvatarUsage.room,
                                        randomSeed: randomSeed,
                                        defaultAvatarId: _avatarId,
                                        defaultAvatarUrl: _avatarUrl,
                                        externalAvatarIds:
                                            _originalAvatarId == null
                                                ? []
                                                : [_originalAvatarId!],
                                        externalAvatarUrls:
                                            _originalAvatarUrl == null
                                                ? [...avatarPresets]
                                                : [
                                                    _originalAvatarUrl!,
                                                    ...avatarPresets
                                                  ],
                                      );
                                    },
                                    heightFactor: 0.8,
                                  );
                                },
                              ),
                          ],
                        ),

                      ColumnBlock(
                        innerPanding: 10,
                        children: [
                          // 模型
                          EnhancedInputSimple(
                            title: AppLocale.model.getString(context),
                            padding: const EdgeInsets.only(top: 10, bottom: 0),
                            onPressed: () {
                              openSelectModelDialog(
                                context,
                                (selected) {
                                  setState(() {
                                    _selectedModel = selected;
                                  });
                                },
                                initValue: _selectedModel?.uid(),
                                reservedModels: reservedModel != null
                                    ? [reservedModel!]
                                    : [],
                              );
                            },
                            value: _selectedModel != null
                                ? _selectedModel!.name
                                : AppLocale.select.getString(context),
                          ),
                          // 提示语
                          if ((_selectedModel != null &&
                                  _selectedModel!.isChatModel) ||
                              _promptController.text != '')
                            EnhancedTextField(
                              customColors: customColors,
                              controller: _promptController,
                              labelText: AppLocale.prompt.getString(context),
                              labelPosition: LabelPosition.top,
                              hintText: AppLocale.promptHint.getString(context),
                              bottomButton: Row(
                                children: [
                                  Icon(
                                    Icons.tips_and_updates_outlined,
                                    size: 13,
                                    color:
                                        customColors.linkColor?.withAlpha(150),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '示例',
                                    style: TextStyle(
                                      color: customColors.linkColor
                                          ?.withAlpha(150),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              bottomButtonOnPressed: () async {
                                openSystemPromptSelectDialog(
                                  context,
                                  customColors,
                                  _promptController,
                                );
                              },
                              minLines: 4,
                              maxLines: 8,
                              showCounter: false,
                            ),
                        ],
                      ),
                      if (showAdvancedOptions)
                        ColumnBlock(
                          innerPanding: 10,
                          padding: const EdgeInsets.only(
                              top: 15, left: 15, right: 15, bottom: 5),
                          children: [
                            EnhancedTextField(
                              customColors: customColors,
                              controller: _initMessageController,
                              labelText: '引导语',
                              labelPosition: LabelPosition.top,
                              hintText: '每次开始新对话时，系统将会以 AI 的身份自动发送引导语。',
                              maxLines: 3,
                              showCounter: false,
                              maxLength: 1000,
                            ),
                            EnhancedInput(
                              title: Text(
                                '记忆深度',
                                style: TextStyle(
                                  color: customColors.textfieldLabelColor,
                                  fontSize: 16,
                                ),
                              ),
                              value: Text(
                                validMemories
                                        .where((element) =>
                                            element.number == maxContext)
                                        .firstOrNull
                                        ?.name ??
                                    '',
                              ),
                              onPressed: () {
                                openListSelectDialog(
                                  context,
                                  validMemories
                                      .map(
                                        (e) => SelectorItem(
                                          Column(
                                            children: [
                                              Text(
                                                e.name,
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                e.description ?? '',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: customColors
                                                      .weakTextColor,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          e.number,
                                        ),
                                      )
                                      .toList(),
                                  (value) {
                                    setState(() {
                                      maxContext = value.value;
                                    });
                                    return true;
                                  },
                                  heightFactor: 0.5,
                                  value: validMemories
                                      .where((element) =>
                                          element.number == maxContext)
                                      .firstOrNull,
                                );
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          EnhancedButton(
                            title: showAdvancedOptions ? '收起选项' : '高级选项',
                            width: 100,
                            backgroundColor: Colors.transparent,
                            color: customColors.weakLinkColor,
                            fontSize: 15,
                            icon: Icon(
                              showAdvancedOptions
                                  ? Icons.unfold_less
                                  : Icons.unfold_more,
                              color: customColors.weakLinkColor,
                              size: 15,
                            ),
                            onPressed: () {
                              setState(() {
                                showAdvancedOptions = !showAdvancedOptions;
                              });
                            },
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: EnhancedButton(
                              title: AppLocale.save.getString(context),
                              onPressed: () async {
                                if (_nameController.text == '') {
                                  showErrorMessage(AppLocale.nameRequiredMessage
                                      .getString(context));
                                  return;
                                }

                                if (_selectedModel == null) {
                                  showErrorMessage(AppLocale
                                      .modelRequiredMessage
                                      .getString(context));
                                  return;
                                }

                                if (_promptController.text.length > 1000) {
                                  showErrorMessage(AppLocale.promptFormatError
                                      .getString(context));
                                  return;
                                }

                                if (_avatarUrl != null) {
                                  if (!(_avatarUrl!.startsWith('http://') ||
                                      _avatarUrl!.startsWith('https://'))) {
                                    // 上传文件，获取 URL
                                    final cancel = BotToast.showCustomLoading(
                                      toastBuilder: (cancel) {
                                        return const LoadingIndicator(
                                          message: "正在上传图片，请稍后...",
                                        );
                                      },
                                      allowClick: false,
                                    );

                                    final uploadRes =
                                        await ImageUploader(widget.setting)
                                            .upload(_avatarUrl!,
                                                usage: 'avatar')
                                            .whenComplete(() => cancel());
                                    _avatarUrl = uploadRes.url;
                                  }
                                }

                                if (context.mounted) {
                                  context.read<RoomBloc>().add(
                                        RoomUpdateEvent(
                                          widget.roomId,
                                          name: _nameController.text,
                                          model: _selectedModel!.uid(),
                                          prompt: _promptController.text,
                                          avatarUrl: _avatarUrl,
                                          avatarId: _avatarId,
                                          maxContext: maxContext,
                                          initMessage:
                                              _initMessageController.text,
                                        ),
                                      );

                                  showSuccessMessage(AppLocale.operateSuccess
                                      .getString(context));
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }

            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }
}
