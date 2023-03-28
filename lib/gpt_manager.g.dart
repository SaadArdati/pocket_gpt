// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gpt_manager.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map json) => ChatMessage(
      id: json['id'] as String,
      timestamp: jsonToDate(json['timestamp'] as int?),
      text: json['text'] as String,
      role: $enumDecode(_$OpenAIChatMessageRoleEnumMap, json['role']),
      status: $enumDecodeNullable(_$MessageStatusEnumMap, json['status']) ??
          MessageStatus.waiting,
    );

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': _$OpenAIChatMessageRoleEnumMap[instance.role]!,
      'timestamp': dateToJson(instance.timestamp),
      'text': instance.text,
      'status': _$MessageStatusEnumMap[instance.status]!,
    };

const _$OpenAIChatMessageRoleEnumMap = {
  OpenAIChatMessageRole.system: 'system',
  OpenAIChatMessageRole.user: 'user',
  OpenAIChatMessageRole.assistant: 'assistant',
};

const _$MessageStatusEnumMap = {
  MessageStatus.waiting: 'waiting',
  MessageStatus.streaming: 'streaming',
  MessageStatus.done: 'done',
  MessageStatus.errored: 'errored',
};

Chat _$ChatFromJson(Map json) => Chat(
      id: json['id'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map))
          .toList(),
      type: $enumDecodeNullable(_$ChatTypeEnumMap, json['type']) ??
          ChatType.general,
    );

Map<String, dynamic> _$ChatToJson(Chat instance) => <String, dynamic>{
      'id': instance.id,
      'messages': instance.messages.map((e) => e.toJson()).toList(),
      'type': _$ChatTypeEnumMap[instance.type]!,
    };

const _$ChatTypeEnumMap = {
  ChatType.general: 'general',
  ChatType.email: 'email',
  ChatType.documentCode: 'documentCode',
  ChatType.scientific: 'scientific',
  ChatType.analyze: 'analyze',
  ChatType.readMe: 'readMe',
};
