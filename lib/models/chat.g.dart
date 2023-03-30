// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
