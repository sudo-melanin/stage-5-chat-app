import 'package:flutter/material.dart';

class HighlightedMessageText extends StatelessWidget {
  const HighlightedMessageText({
    super.key,
    required this.text,
    required this.query,
  });

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return Text(text);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = trimmedQuery.toLowerCase();
    final matchIndex = lowerText.indexOf(lowerQuery);

    if (matchIndex == -1) {
      return Text(text);
    }

    final before = text.substring(0, matchIndex);
    final match = text.substring(matchIndex, matchIndex + trimmedQuery.length);
    final after = text.substring(matchIndex + trimmedQuery.length);

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: TextStyle(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}
