import 'package:dart_openai/openai.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../constants.dart';
import '../theme_extensions.dart';

class OpenAIKeyInstructions extends StatelessWidget {
  const OpenAIKeyInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You need to provide your own key, otherwise this app would'
          ' cost money to run!',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'The key is stored locally on your device, and is never sent to'
          ' any servers.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text('Steps:', style: Theme.of(context).textTheme.bodyMedium),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('1.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(text: 'Go to ', children: [
                    TextSpan(
                      text: 'https://platform.openai.com/account/api-keys',
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launchUrlString(
                            'https://platform.openai.com/account/api-keys',
                          );
                        },
                    ),
                  ]),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('2.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Register an account or sign in.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('3.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tap on the "Create new secret key" button.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('4.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Copy the key and paste it below.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ]),
          ]),
        ),
      ],
    );
  }
}

class OpenAIKeyScreen extends StatefulWidget {
  const OpenAIKeyScreen({super.key});

  @override
  State<OpenAIKeyScreen> createState() => _OpenAIKeyScreenState();
}

class _OpenAIKeyScreenState extends State<OpenAIKeyScreen> {
  final box = Hive.box(settings);
  late final TextEditingController controller = TextEditingController(
    text: box.get(openAIKey, defaultValue: ''),
  );

  bool validating = false;
  String? errorMessage;

  void textListener() {
    setState(() {});
  }

  Future<bool> validateKey() async {
    setState(() {
      validating = true;
    });

    try {
      OpenAI.apiKey = controller.text;
      final List<OpenAIModelModel> models = await OpenAI.instance.model.list();

      return models.isNotEmpty;
    } catch (e) {
      return false;
    } finally {
      setState(() {
        validating = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(textListener);
  }

  @override
  void dispose() {
    controller.removeListener(textListener);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(12);
    return SingleChildScrollView(
      child: Form(
        child: Builder(builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerRight,
                      margin: const EdgeInsets.only(right: 16),
                      child:
                          const ImageIcon(AssetImage('assets/openai_256.png')),
                    ),
                  ),
                  Text(
                    'Enter your OpenAI API Key',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 16),
              const OpenAIKeyInstructions(),
              SizedBox(
                height: 48,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (errorMessage != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          errorMessage!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.colorScheme.error,
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your OpenAI API key';
                        }
                        return null;
                      },
                      onChanged: (_) {
                        setState(() {
                          errorMessage = null;
                        });
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: context.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: 'sk-xxxxxxxxxxxxxxx',
                        isDense: true,
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        filled: true,
                        fillColor: context.colorScheme.secondaryContainer
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
                  const SizedBox(width: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: borderRadius),
                      backgroundColor: controller.text.isNotEmpty
                          ? context.colorScheme.primaryContainer
                          : context.colorScheme.secondaryContainer
                              .withOpacity(0.5),
                    ),
                    onPressed: validating ? null : () => onSubmitKey(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: validating
                          ? const CircularProgressIndicator.adaptive()
                          : Icon(
                              Icons.navigate_next,
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> onSubmitKey(BuildContext context) async {
    final router = GoRouter.of(context);
    setState(() => errorMessage = null);
    if (!Form.of(context).validate()) return;

    final success = await validateKey();
    if (success) {
      box.put(openAIKey, controller.text);
      box.put(isFirstTime, false);
      router.go('/onboarding/three');
    } else {
      errorMessage = "Invalid API key. Make sure it's correct and try again.";
      if (mounted) setState(() {});
    }
  }
}

class OpenAIKeyTile extends StatefulWidget {
  const OpenAIKeyTile({super.key});

  @override
  State<OpenAIKeyTile> createState() => _OpenAIKeyTileState();
}

class _OpenAIKeyTileState extends State<OpenAIKeyTile> {
  final box = Hive.box(settings);
  late final TextEditingController controller = TextEditingController(
    text: box.get(openAIKey, defaultValue: ''),
  );

  bool isEditing = false;
  bool validating = false;
  String? message;
  bool isError = false;

  void textListener() {
    setState(() {});
  }

  Future<bool> validateKey() async {
    setState(() {
      validating = true;
    });

    try {
      OpenAI.apiKey = controller.text;
      final List<OpenAIModelModel> models = await OpenAI.instance.model.list();

      return models.isNotEmpty;
    } catch (e) {
      return false;
    } finally {
      setState(() {
        validating = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(textListener);
  }

  @override
  void dispose() {
    controller.removeListener(textListener);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(12);
    return Form(
      child: Builder(builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ImageIcon(AssetImage('assets/openai_256.png')),
                  const SizedBox(width: 8),
                  Text(
                    'OpenAI API Key',
                    style: context.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuart,
              height: isEditing ? 325 : 16,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  switchInCurve: Curves.easeOutQuart,
                  switchOutCurve: Curves.easeInQuart,
                  child: isEditing
                      ? ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context)
                              .copyWith(scrollbars: false),
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            primary: false,
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                const OpenAIKeyInstructions(),
                                statusSection(context),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox(height: 16)),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your OpenAI API key';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      setState(() {
                        message = null;
                        isError = false;
                      });
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: context.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      counterText: '',
                      labelText: 'sk-xxxxxxxxxxxxxxx',
                      isDense: true,
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      filled: true,
                      fillColor: context.colorScheme.secondaryContainer
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
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: borderRadius),
                    backgroundColor: controller.text.isNotEmpty && isEditing
                        ? context.colorScheme.primaryContainer
                        : context.colorScheme.secondaryContainer
                            .withOpacity(0.5),
                  ),
                  onPressed: validating
                      ? null
                      : () {
                          if (!isEditing) {
                            setState(() {
                              message = null;
                              isError = false;
                              isEditing = true;
                            });
                            return;
                          } else if (controller.text == box.get(openAIKey)) {
                            setState(() {
                              message = null;
                              isError = false;
                              isEditing = false;
                            });
                            return;
                          }

                          if (message != null) {
                            setState(() {
                              message = null;
                              isError = false;
                            });
                          }

                          if (!Form.of(context).validate()) return;

                          validateKey().then(
                            (bool success) {
                              if (success) {
                                box.put(openAIKey, controller.text);
                                if (!mounted) return;
                                setState(() {
                                  message = 'Key updated successfully!';
                                  isError = false;
                                });
                              } else {
                                if (!mounted) return;
                                setState(() {
                                  message =
                                      "Invalid API key. Make sure it's correct and try again.";
                                  isError = true;
                                });
                              }
                            },
                          );
                        },
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: validating
                        ? const CircularProgressIndicator.adaptive()
                        : Icon(
                            !isEditing
                                ? Icons.edit
                                : controller.text == box.get(openAIKey)
                                    ? Icons.edit_off
                                    : Icons.navigate_next,
                            color: context.colorScheme.onSurfaceVariant,
                            size: 22,
                          ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  SizedBox statusSection(BuildContext context) {
    return SizedBox(
      height: 48,
      child: message == null
          ? null
          : Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isError
                          ? context.colorScheme.error
                          : context.colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
    );
  }
}
