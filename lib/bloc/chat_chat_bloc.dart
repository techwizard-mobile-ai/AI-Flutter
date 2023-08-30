import 'package:askaide/helper/constant.dart';
import 'package:askaide/repo/api_server.dart';
import 'package:askaide/repo/chat_message_repo.dart';
import 'package:askaide/repo/model/chat_history.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'chat_chat_event.dart';
part 'chat_chat_state.dart';

class ChatChatBloc extends Bloc<ChatChatEvent, ChatChatState> {
  final ChatMessageRepository _chatMessageRepository;
  ChatChatBloc(this._chatMessageRepository) : super(ChatChatInitial()) {
    // 加载最近的历史记录
    on<ChatChatLoadRecentHistories>((event, emit) async {
      final histories = await _chatMessageRepository.recentChatHistories(
        chatAnywhereRoomId,
        30,
        userId: APIServer().localUserID(),
      );

      emit(ChatChatRecentHistoriesLoaded(
        histories: histories,
        examples: await APIServer().example('openai:$defaultChatModel'),
      ));
    });

    // 删除历史记录
    on<ChatChatDeleteHistory>((event, emit) async {
      await _chatMessageRepository.deleteChatHistory(event.chatId);
      add(ChatChatLoadRecentHistories());
    });
  }
}
