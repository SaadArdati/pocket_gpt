import 'package:dart_openai/openai.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import 'message_status.dart';
import 'model_utils.dart';

part 'chat_message.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class ChatMessage with EquatableMixin {
  final String id;
  final OpenAIChatMessageRole role;
  @JsonKey(fromJson: jsonToDate, toJson: dateToJson)
  final DateTime timestamp;

  String text;
  MessageStatus status;

  ChatMessage({
    required this.id,
    required this.timestamp,
    required this.text,
    required this.role,
    this.status = MessageStatus.waiting,
  });

  ChatMessage.simple({
    required this.text,
    required this.role,
    this.status = MessageStatus.waiting,
  })  : id = const Uuid().v4(),
        timestamp = DateTime.now();

  OpenAIChatCompletionChoiceMessageModel toOpenAI() {
    return OpenAIChatCompletionChoiceMessageModel(
      content: text,
      role: role,
    );
  }

  factory ChatMessage.fromJson(Map json) => _$ChatMessageFromJson(json);

  Map toJson() => _$ChatMessageToJson(this);

  @override
  List<Object?> get props => [text, status];
}
