import 'package:hive/hive.dart';
import 'package:dash_chat_2/dash_chat_2.dart';

part 'chat_message_adapter.g.dart';

@HiveType(typeId: 0)
class HiveChatMessage {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final DateTime createdAt;

  @HiveField(2)
  final String text;

  @HiveField(3)
  final String? imagePath;

  HiveChatMessage({
    required this.userId,
    required this.createdAt,
    required this.text,
    this.imagePath,
  });

  // Convert HiveChatMessage to ChatMessage
  ChatMessage toChatMessage() {
    return ChatMessage(
      user: ChatUser(id: userId),
      createdAt: createdAt,
      text: text,
      customProperties: imagePath != null ? {'imagePath': imagePath} : null,
    );
  }

  // Convert ChatMessage to HiveChatMessage
  static HiveChatMessage fromChatMessage(ChatMessage message) {
    return HiveChatMessage(
      userId: message.user.id,
      createdAt: message.createdAt,
      text: message.text,
      imagePath: message.customProperties?['imagePath'] as String?,
    );
  }
}
