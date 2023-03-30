import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import 'chat_message.dart';
import 'chat_type.dart';

part 'chat.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class Chat with EquatableMixin {
  final String id;
  final List<ChatMessage> messages;
  final ChatType type;

  Chat({
    required this.id,
    required this.messages,
    this.type = ChatType.general,
  });

  Chat.simple({
    required this.messages,
    this.type = ChatType.general,
  }) : id = const Uuid().v4();

  factory Chat.fromJson(Map json) => _$ChatFromJson(json);

  Map toJson() => _$ChatToJson(this);

  @override
  List<Object?> get props => [messages];
}
