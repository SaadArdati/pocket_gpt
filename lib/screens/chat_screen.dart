import 'dart:ui';

import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../gpt_manager.dart';
import '../markdown_renderer.dart';
import '../system_manager.dart';
import '../theme_extensions.dart';

class ChatScreenWrapper extends StatelessWidget {
  final ChatType type;

  const ChatScreenWrapper({
    super.key,
    this.type = ChatType.general,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GPTManager>(
      create: (context) => GPTManager(),
      child: ChatScreen(type: type),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final ChatType type;

  const ChatScreen({
    super.key,
    this.type = ChatType.general,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController scrollController = ScrollController();

  late final AnimationController animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  late final Animation<double> blurAnimation = CurvedAnimation(
    parent: animationController,
    curve: Curves.easeInOut,
  );

  @override
  void initState() {
    super.initState();

    final GPTManager gpt = context.read<GPTManager>();
    gpt.init();
    gpt.openChat(notify: false, type: widget.type);
  }

  @override
  void dispose() {
    scrollController.dispose();
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;
    final bool isDesktop = platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS;

    final GPTManager gpt = context.watch<GPTManager>();
    return LayoutBuilder(builder: (context, constraints) {
      final bool isWide = constraints.maxWidth > 800;
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_upward),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () {
              context.go('/home', extra: {'from': '/chat'});
            },
          ),
          title: Text(widget.type.label),
          centerTitle: false,
          actions: [
            if (!isWide)
              Builder(
                builder: (context) {
                  return IconButton(
                    tooltip: 'Chat History',
                    onPressed: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                    icon: const Icon(Icons.history),
                  );
                },
              ),
            if (isDesktop)
              const IconButton(
                tooltip: 'Minimize',
                icon: Icon(Icons.minimize),
                onPressed: SystemManager.closeWindow,
              ),
          ],
        ),
        endDrawerEnableOpenDragGesture: false,
        endDrawer: isWide
            ? null
            : ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Builder(builder: (context) {
                  return Drawer(
                    child: ListView(children: [
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'Chat History',
                          style: context.textTheme.bodyLarge,
                        ),
                      ),
                      // Tooltip(
                      //   message: 'Start a new chat',
                      //   child: ListTile(
                      //     leading: const Icon(Icons.add),
                      //     title: const Text('New Chat'),
                      //     onTap: () {
                      //       gpt.openChat(notify: true);
                      //       Scaffold.of(context).closeEndDrawer();
                      //     },
                      //   ),
                      // ),
                      for (final Chat chat
                          in gpt.chatHistory.values.toList().reversed)
                        HistoryTile(chat: chat),
                    ]),
                  );
                }),
              ),
        body: SizedBox.expand(
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: SelectionArea(
                            child: NotificationListener<ScrollNotification>(
                              // onNotification: _handleScrollNotification,
                              child: ListView.separated(
                                controller: scrollController,
                                reverse: true,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: gpt.messages.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final int reversedIndex =
                                      gpt.messages.length - 1 - index;
                                  final ChatMessage message =
                                      gpt.messages[reversedIndex];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      top: index == gpt.messages.length - 1
                                          ? (Scaffold.of(context)
                                                      .appBarMaxHeight ??
                                                  48) +
                                              16
                                          : 0,
                                      bottom: index == 0 ? 16 : 0,
                                    ),
                                    child: ChatMessageBubble(
                                      message: message,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const UserInteractionRegion(),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Builder(builder: (context) {
                        return ClipRect(
                          child: AnimatedBuilder(
                            animation: blurAnimation,
                            builder: (context, child) {
                              return BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: blurAnimation.value * 5,
                                  sigmaY: blurAnimation.value * 5,
                                ),
                                child: child!,
                              );
                            },
                            child: Container(
                              color: Colors.transparent,
                              height: Scaffold.of(context).appBarMaxHeight ??
                                  48 + 16,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              if (isWide)
                SizedBox(
                  width: 300,
                  child: Drawer(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(18),
                          child: Text(
                            'Chat History',
                            style: context.textTheme.bodyLarge,
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: Text(
                            'New Chat',
                            style: context.textTheme.bodyMedium,
                          ),
                          onTap: () {
                            gpt.openChat(notify: true);
                          },
                        ),
                        for (final Chat chat
                            in gpt.chatHistory.values.toList().reversed)
                          HistoryTile(chat: chat),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class HistoryTile extends StatefulWidget {
  const HistoryTile({
    super.key,
    required this.chat,
  });

  final Chat chat;

  @override
  State<HistoryTile> createState() => _HistoryTileState();
}

class _HistoryTileState extends State<HistoryTile> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    final GPTManager gpt = context.watch<GPTManager>();
    final bool isActiveChat = widget.chat.id == gpt.currentChat?.id;
    return MouseRegion(
      onEnter: (event) {
        setState(() {
          isHovering = true;
        });
      },
      onExit: (event) {
        setState(() {
          isHovering = false;
        });
      },
      child: ListTile(
        leading: Icon(
          widget.chat.type.icon,
        ),
        title: Text(
          widget.chat.messages.isEmpty
              ? 'No messages'
              : widget.chat.messages.first.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium,
        ),
        onTap: () {
          gpt.openChat(id: widget.chat.id, notify: true);
          Scaffold.of(context).closeEndDrawer();
        },
        selected: isActiveChat,
        selectedTileColor: context.colorScheme.primaryContainer,
        selectedColor: context.colorScheme.onPrimaryContainer,
        trailing: !isHovering
            ? isActiveChat
                ? IconButton(
                    tooltip: 'Currently active chat',
                    icon: Icon(
                      Icons.chat,
                      color: context.colorScheme.onPrimaryContainer,
                    ),
                    iconSize: 20,
                    onPressed: null,
                  )
                : null
            : IconButton(
                tooltip: 'Delete chat',
                iconSize: 20,
                icon: Icon(Icons.delete, color: context.colorScheme.error),
                onPressed: () {
                  gpt.deleteChat(widget.chat.id);
                },
              ),
      ),
    );
  }
}

class UserInteractionRegion extends StatefulWidget {
  const UserInteractionRegion({super.key});

  @override
  State<UserInteractionRegion> createState() => _UserInteractionRegionState();
}

class _UserInteractionRegionState extends State<UserInteractionRegion> {
  late final focusNode = FocusNode(
    onKey: (FocusNode node, RawKeyEvent evt) {
      if (!evt.isShiftPressed && evt.logicalKey == LogicalKeyboardKey.enter) {
        if (evt is RawKeyDownEvent) {
          triggerSend(node.context!, generateResponse: true);
        }
        return KeyEventResult.handled;
      } else {
        return KeyEventResult.ignored;
      }
    },
  );

  final TextEditingController textController = TextEditingController();

  void triggerSend(BuildContext context, {required bool generateResponse}) {
    if (!Form.of(context).validate()) return;

    final GPTManager gpt = context.read<GPTManager>();
    gpt.sendMessage(textController.text, generateResponse: generateResponse);
    textController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final GPTManager gpt = context.watch<GPTManager>();
    final BorderRadius borderRadius = BorderRadius.circular(12);

    final bool isGenerating = gpt.messages.isNotEmpty &&
        gpt.messages.last.status == MessageStatus.streaming;
    return Form(
      child: Builder(builder: (context) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800, minHeight: 56),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchOutCurve: Curves.easeOutQuart,
                switchInCurve: Curves.easeOutQuart,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: isGenerating
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Tooltip(
                              message: 'Stop generating response',
                              child: FilledButton.tonalIcon(
                                onPressed: gpt.stopGenerating,
                                icon: const Icon(Icons.stop_circle),
                                label: const Text('Stop generating'),
                              ),
                            )
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          IconButton(
                            tooltip: 'Add attachment',
                            onPressed: () {},
                            icon: const Icon(Icons.add),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height / 3,
                              ),
                              child: TextFormField(
                                controller: textController,
                                focusNode: focusNode,
                                maxLength: 10000,
                                maxLengthEnforcement:
                                    MaxLengthEnforcement.enforced,
                                textInputAction: TextInputAction.newline,
                                keyboardType: TextInputType.multiline,
                                maxLines: null,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter some text';
                                  }
                                  return null;
                                },
                                autovalidateMode: AutovalidateMode.disabled,
                                onChanged: (_) {
                                  setState(() {});
                                },
                                onFieldSubmitted: (_) => triggerSend(
                                  context,
                                  generateResponse: true,
                                ),
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color:
                                      context.colorScheme.onSecondaryContainer,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  labelText: 'Type a message...',
                                  isDense: true,
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.never,
                                  filled: true,
                                  fillColor: context
                                      .colorScheme.secondaryContainer
                                      .withOpacity(0.5),
                                  hoverColor: Colors.transparent,
                                  border: OutlineInputBorder(
                                    borderRadius: borderRadius,
                                    borderSide: const BorderSide(width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: borderRadius,
                                    borderSide: BorderSide(
                                      color: context.colorScheme.primary,
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: borderRadius,
                                    borderSide: const BorderSide(
                                      color: Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                cursorRadius: const Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Material(
                              color: Colors.transparent,
                              child: Tooltip(
                                message: textController.text.isEmpty
                                    ? 'Start recording'
                                    : 'Send message',
                                child: InkWell(
                                  onTap: () => triggerSend(
                                    context,
                                    generateResponse: true,
                                  ),
                                  onLongPress: () {
                                    triggerSend(
                                      context,
                                      generateResponse: false,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Icon(
                                      textController.text.isEmpty
                                          ? Icons.mic
                                          : Icons.send,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    switch (message.role) {
      case Role.user:
        child = UserMessageBubble(message: message);
        break;
      case Role.system:
        child = SystemMessageBubble(message: message);
        break;
      case Role.assistant:
        child = AssistantMessageBubble(message: message);
        break;
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: child,
      ),
    );
  }
}

class SystemMessageBubble extends StatelessWidget {
  const SystemMessageBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Bubble(
      color: context.colorScheme.surfaceVariant,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.security, size: 16),
          const SizedBox(width: 4),
          Text(
            message.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.0),
          ),
        ],
      ),
    );
  }
}

class UserMessageBubble extends StatelessWidget {
  const UserMessageBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      margin: const EdgeInsets.only(left: 32),
      child: Bubble(
        showNip: true,
        nip: BubbleNip.rightTop,
        color: context.colorScheme.secondaryContainer,
        child: MarkdownText(
          text: message.text,
          role: message.role,
        ),
      ),
    );
  }
}

class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final GPTManager gpt = context.read<GPTManager>();
    final Widget child;
    if (message.status == MessageStatus.streaming) {
      child = StreamBuilder<ChatMessage?>(
        stream: gpt.responseStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return buildErrorBubble(context, snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final ChatMessage streamingMessage = snapshot.data!;
          switch (streamingMessage.status) {
            case MessageStatus.waiting:
              return const SizedBox.shrink();
            case MessageStatus.errored:
              return buildErrorBubble(context, streamingMessage.text);
            case MessageStatus.streaming:
            case MessageStatus.done:
              return buildConversationBubble(context, streamingMessage);
          }
        },
      );
    } else {
      child = buildConversationBubble(context, message);
    }

    final bool showRegenButton = gpt.messages.last.id == message.id &&
        message.status != MessageStatus.streaming;
    return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(right: showRegenButton ? 0 : 32),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(child: child),
          if (showRegenButton) ...[
            IconButton(
              tooltip: 'Regenerate',
              icon: const Icon(Icons.refresh),
              onPressed: () {
                gpt.regenerateLastResponse();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget buildConversationBubble(BuildContext context, ChatMessage message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Bubble(
        showNip: true,
        nip: BubbleNip.leftTop,
        color: context.colorScheme.primaryContainer,
        child: MarkdownText(
          text: message.text,
          role: message.role,
        ),
      ),
    );
  }

  Widget buildErrorBubble(BuildContext context, String text) {
    return Bubble(
      color: context.colorScheme.errorContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.error_outline, size: 14),
              SizedBox(width: 4),
              Text(
                'An error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.0),
              ),
            ],
          ),
          Text(
            text,
            style: TextStyle(
              color: context.colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
