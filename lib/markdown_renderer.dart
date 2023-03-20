import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/atom-one-dark-reasonable.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:google_fonts/google_fonts.dart';
import 'package:highlighter/highlighter.dart' show highlight, Node;
import 'package:url_launcher/url_launcher_string.dart';

import 'gpt_manager.dart';
import 'theme_extensions.dart';

class CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    String language = '';

    if (element.attributes['class'] != null) {
      final String lg = element.attributes['class'] as String;
      language = lg.substring(9);
    }
    return CorrectedHighlightView(
      element.textContent,
      language: language,
      theme: atomOneDarkReasonableTheme,
    );
  }
}

class MarkdownText extends StatefulWidget {
  final String text;
  final Role role;

  const MarkdownText({super.key, required this.text, required this.role});

  @override
  State<MarkdownText> createState() => _MarkdownTextState();
}

class _MarkdownTextState extends State<MarkdownText> {
  MarkdownStyleSheet assistantSheet() {
    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      a: TextStyle(
        color: context.colorScheme.onPrimaryContainer,
      ),
      p: TextStyle(
        color: context.colorScheme.onPrimaryContainer,
      ),
      h1: TextStyle(
        color: context.colorScheme.onPrimaryContainer,
      ),
      h2: TextStyle(
        color: context.colorScheme.onPrimaryContainer,
      ),
      h3: TextStyle(
        color: context.colorScheme.onPrimaryContainer,
      ),
      h4: TextStyle(
        color: context.colorScheme.onPrimaryContainer,
      ),
      h5: TextStyle(
        color: context.colorScheme.onPrimaryContainer,
      ),
      h6: TextStyle(
        color: context.colorScheme.onPrimaryContainer,
      ),
      em: TextStyle(
        color: context.colorScheme.onPrimaryContainer,
      ),
      strong: TextStyle(
        color: context.colorScheme.onPrimaryContainer,
      ),
      del: TextStyle(
        color: context.colorScheme.onPrimaryContainer,
      ),
      blockquote: TextStyle(
        color: context.colorScheme.onSurfaceVariant,
      ),
      code: TextStyle(
        color: context.colorScheme.onSurface,
      ),
      codeblockDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      codeblockPadding: const EdgeInsets.all(0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: widget.text,
      selectable: false,
      styleSheet: assistantSheet(),
      builders: {
        'code': CodeElementBuilder(),
      },
      onTapLink: (String text, String? href, String title) {
        if (href == null) return;
        launchUrlString(href);
      },
    );
  }
}

class CorrectedHighlightView extends HighlightView {
  // ignore: use_key_in_widget_constructors
  CorrectedHighlightView(
    super.input, {
    super.language,
    super.theme = const {},
    super.tabSize = 8,
  });

  List<TextSpan> _convert(List<Node> nodes) {
    final List<TextSpan> spans = [];
    final List<List<TextSpan>> stack = [];
    List<TextSpan> currentSpans = spans;

    void traverse(Node node) {
      if (node.value != null) {
        currentSpans.add(node.className == null
            ? TextSpan(text: node.value)
            : TextSpan(text: node.value, style: theme[node.className!]));
      } else if (node.children != null) {
        final List<TextSpan> tmp = [];
        currentSpans
            .add(TextSpan(children: tmp, style: theme[node.className!]));
        stack.add(currentSpans);
        currentSpans = tmp;

        for (final child in node.children!) {
          traverse(child);
          if (child == node.children!.last) {
            currentSpans = stack.isEmpty ? spans : stack.removeLast();
          }
        }
      }
    }

    for (var node in nodes) {
      traverse(node);
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return BetterCodeBlock(
      source: source,
      syntax: _convert(highlight.parse(source, language: language).nodes!),
      language: language,
    );
  }
}

class BetterCodeBlock extends StatefulWidget {
  final String source;
  final List<TextSpan> syntax;
  final String? language;

  const BetterCodeBlock({
    super.key,
    required this.source,
    required this.syntax,
    required this.language,
  });

  @override
  State<BetterCodeBlock> createState() => _BetterCodeBlockState();
}

class _BetterCodeBlockState extends State<BetterCodeBlock> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    final bool hasLanguage = widget.language?.isNotEmpty ?? false;
    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: Stack(
        children: [
          Container(
            width: hasLanguage ? double.infinity : null,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: context.colorScheme.surface,
            ),
            clipBehavior: Clip.hardEdge,
            padding: hasLanguage
                ? const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 0)
                : const EdgeInsets.only(left: 3, right: 3, bottom: 1.5),
            child: Text.rich(
              TextSpan(
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  color: context.colorScheme.onSurface,
                ),
                children: widget.syntax,
              ),
            ),
          ),
          if (hasLanguage)
            Positioned(
              top: 0,
              right: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                child: isHovering
                    ? Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: context.colorScheme.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              Tooltip(
                                message: 'Copy',
                                child: InkWell(
                                  onTap: () {
                                    Clipboard.setData(
                                        ClipboardData(text: widget.source));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Copied to clipboard',
                                          style: TextStyle(
                                            color: context.colorScheme
                                                .onTertiaryContainer,
                                          ),
                                        ),
                                        backgroundColor: context
                                            .colorScheme.tertiaryContainer,
                                        duration:
                                            const Duration(milliseconds: 500),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(
                                      Icons.copy,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}
