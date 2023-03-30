import 'package:flutter/material.dart';

/// TODO: Properly abstract or turn into strings for customizable chat types.
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
