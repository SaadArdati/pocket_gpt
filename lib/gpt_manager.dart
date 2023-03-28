import 'dart:async';

import 'package:dart_openai/openai.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import 'constants.dart';

part 'gpt_manager.g.dart';

/// Top level function for deserializing millis from json to [DateTime].
DateTime jsonToDate(int? value) => value != null
    ? DateTime.fromMillisecondsSinceEpoch(value).toLocal()
    : DateTime.now();

/// Top level function for serializing [DateTime] to millisecondsSinceEpoch.
int dateToJson(DateTime date) => date.toUtc().millisecondsSinceEpoch;

enum MessageStatus {
  waiting,
  streaming,
  done,
  errored,
}

enum ChatType {
  general(
    'General Chat',
    Icons.waving_hand,
    'Talk to the AI with any general topic.',
  ),
  email(
    'Email Writer',
    Icons.email,
    'Messages automatically convert into formal emails',
  ),
  documentCode(
    'Code Documentation',
    Icons.code,
    'Paste your code and the AI will embed docs in it for you.',
  ),
  scientific(
    'Scientific Researcher',
    Icons.school,
    'Ask the AI about any scientific topic',
  ),
  analyze(
    'Screen Analysis',
    Icons.search,
    "Analyzes your screen and gives you a summary of what's on it.",
  ),
  readMe(
    'Read Me',
    Icons.book,
    'Paste your code and the AI will generate a README.md for you.',
  );

  final String label;
  final IconData icon;
  final String caption;

  const ChatType(this.label, this.icon, this.caption);
}

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
  })  : id = Uuid().v4(),
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
  }) : id = Uuid().v4();

  factory Chat.fromJson(Map json) => _$ChatFromJson(json);

  Map toJson() => _$ChatToJson(this);

  @override
  List<Object?> get props => [messages];
}

class GPTManager extends ChangeNotifier {
  List<ChatMessage> get messages => currentChat!.messages;

  // [
//     ChatMessage(
//       text: 'how do i do a gradient blur with flutter?',
//       role: OpenAIChatMessageRole.user,
//     ),
//     ChatMessage(
//       text:
//           '''In Flutter, to create a gradient blur effect, you can use the `BackdropFilter` widget along with a `BoxDecoration` to apply a gradient. Here's an example of how you can create a gradient blur:
//
// 1. First, add the `ImageFilter` and `ui` packages:
// ```dart
// import 'dart:ui' as ui;
// import 'dart:ui' show ImageFilter;
// ```
//
// 2. Then, in your build method or inside your custom widget, you can create a gradient blur with the following code:
//
// ```dart
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Gradient Blur Example'),
//       ),
//       body: Stack(
//         children: [
//           // Add your background image or content here
//           Image.asset(
//             'assets/your_image_here.jpg',
//             fit: BoxFit.cover,
//             height: MediaQuery.of(context).size.height,
//             width: MediaQuery.of(context).size.width,
//           ),
//
//           // Implement the Gradient Blur
//           Container(
//             height: MediaQuery.of(context).size.height,
//             width: MediaQuery.of(context).size.width,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Colors.transparent,
//                   Colors.black54,
//                 ],
//               ),
//             ),
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//               child: Container(
//                 color: Colors.black.withOpacity(0),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// ```
//
// Replace `'assets/your_image_here.jpg'` with the desired image file path. You can adjust the `sigmaX` and `sigmaY` values in the `ImageFilter.blur` function to control the intensity of the blur effect.
//
// In this example, a `LinearGradient` is used to apply a gradient from transparent to black. The `BackdropFilter` widget is used to blur the image by wrapping it inside a `Container`.''',
//       role: OpenAIChatMessageRole.assistant,
//     ),
//   ];

  final StreamController<ChatMessage> responseStreamController =
      StreamController<ChatMessage>.broadcast();
  final box = Hive.box(history);

  Stream<ChatMessage> get responseStream => responseStreamController.stream;

  StreamSubscription<OpenAIStreamChatCompletionModel>? listener;

  Map<String, Chat> chatHistory = {};

  Chat? currentChat;

  void init() {
    final Map serializedHistory = box.get(history) ?? {};
    chatHistory = {
      for (final chat in serializedHistory.entries)
        chat.key: Chat.fromJson(chat.value)
    };
  }

  void openChat({String? id, required bool notify, ChatType? type}) {
    if (id == null) {
      currentChat = Chat.simple(messages: [], type: type!);
      chatHistory[currentChat!.id] = currentChat!;
    } else {
      currentChat = chatHistory[id];
      purgeEmptyChats();
    }
    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopGenerating();
    responseStreamController.close();
    listener?.cancel();
    super.dispose();
  }

  void saveChat() {
    box.put(history, {
      for (final MapEntry<String, Chat> chat in chatHistory.entries)
        chat.key: chat.value.toJson(),
    });
  }

  void purgeEmptyChats() {
    chatHistory.removeWhere((key, value) => value.messages.isEmpty);
  }

  void deleteChat(String id) {
    chatHistory.remove(id);
    saveChat();
    notifyListeners();
  }

  ChatMessage? buildTypePrompt() {
    switch (currentChat!.type) {
      case ChatType.general:
        return null;
      case ChatType.email:
        return ChatMessage.simple(
          text: 'Anything the user sends should be converted to a formal email.'
              ' Feel free to ask them for any information you need to complete'
              ' the email. Try to be short, concise, and to the point rather'
              ' than verbose.',
          role: OpenAIChatMessageRole.system,
        );
      case ChatType.scientific:
        return ChatMessage.simple(
          text: 'Be as precise, objective, and scientific as possible. Do not'
              ' use any colloquialisms or slang. Do not hesitate to admit lack of'
              ' knowledge on anything.',
          role: OpenAIChatMessageRole.system,
        );
      case ChatType.analyze:
        return ChatMessage.simple(
          text:
              'Be as objective as possible. Try to summarize whatever the user'
              ' sends in a few sentences. Ask the user about what to look for'
              ' specifically if there is nothing obvious.',
          role: OpenAIChatMessageRole.system,
        );
      case ChatType.documentCode:
        return ChatMessage.simple(
          text: 'Try to embed code high quality, clean, and concise code docs '
              'into any code the user sends. If the programming language is not'
              'obvious, ask the user for it.',
          role: OpenAIChatMessageRole.system,
        );
      case ChatType.readMe:
        return ChatMessage.simple(
          text: 'Analyze all of the user\'s code and try to write a README.md.'
              'Ask the user for a template. If there is no template, try to do it'
              ' yourself.',
          role: OpenAIChatMessageRole.system,
        );
    }
  }

  bool needsExtendedContext() {
    return currentChat!.type == ChatType.documentCode ||
        currentChat!.type == ChatType.scientific ||
        currentChat!.type == ChatType.readMe;
  }

  /// Not clean. But it's the most optimized way to do it.
  void sendMessage(String message, {required bool generateResponse}) {
    final ChatMessage userMsg = ChatMessage.simple(
      text: message.trim(),
      role: OpenAIChatMessageRole.user,
      status: MessageStatus.done,
    );
    messages.add(userMsg);
    saveChat();
    notifyListeners();

    if (generateResponse) {
      _generate();
    }
  }

  void _generate() {
    final ChatMessage? typePrompt = buildTypePrompt();

    final Stream<OpenAIStreamChatCompletionModel> stream =
        OpenAI.instance.chat.createStream(
      model: needsExtendedContext() ? 'gpt-4-0314' : 'gpt-4',
      messages: [
        ChatMessage.simple(
          text: "You are PocketGPT, living in the user's system tray for easy"
              ' access. The app in which you live in was created by Saad Ardati.'
              '\n - Twitter: @SaadArdati.'
              '\n - Website: https://saad-ardati.web.app/.'
              '\n - Github: https://github.com/SaadArdati.'
              '\n - Description: Self-taught software developer with 8+ years'
              ' of experience in game modding and 4+ years of experience'
              ' in Flutter development. Currently pursuing a degree in'
              ' Computer Science.',
          role: OpenAIChatMessageRole.system,
        ).toOpenAI(),
        if (typePrompt != null) typePrompt.toOpenAI(),
        ...messages.map((msg) => msg.toOpenAI())
      ],
    );

    final ChatMessage responseMsg = ChatMessage.simple(
      text: '',
      role: OpenAIChatMessageRole.assistant,
      status: MessageStatus.waiting,
    );
    messages.add(responseMsg);
    saveChat();
    notifyListeners();
    responseStreamController.add(responseMsg);

    listener = stream.listen(
      (streamChatCompletion) {
        final content = streamChatCompletion.choices.first.delta.content;
        if (content != null) {
          responseMsg.text += content;
          if (responseMsg.status != MessageStatus.streaming) {
            responseMsg.status = MessageStatus.streaming;
            notifyListeners();
          }
        }
        saveChat();
        responseStreamController.add(responseMsg);
      },
      onError: (error) {
        responseMsg.text = error.toString();
        responseMsg.status = MessageStatus.errored;
        saveChat();
        responseStreamController.add(responseMsg);
      },
      cancelOnError: false,
      onDone: () {
        if (responseMsg.status == MessageStatus.streaming) {
          responseMsg.status = MessageStatus.done;
        }
        saveChat();
        responseStreamController.add(responseMsg);
        notifyListeners();
      },
    );
  }

  void stopGenerating() {
    if (messages.isEmpty) return;
    listener?.cancel();
    final ChatMessage responseMsg = messages.last;
    if (responseMsg.status == MessageStatus.streaming) {
      responseMsg.status = MessageStatus.done;
      saveChat();
      responseStreamController.add(responseMsg);
      notifyListeners();
    }
  }

  void regenerateLastResponse() {
    if (messages.isEmpty) return;
    final ChatMessage last = messages.last;
    if (last.role != OpenAIChatMessageRole.assistant) return;

    messages.removeLast();
    saveChat();
    notifyListeners();

    _generate();
  }
}
