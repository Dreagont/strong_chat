import 'package:flutter/material.dart';

TextSpan replaceEmoticons(String text) {
  final textSpans = <InlineSpan>[];
  final emoticonPattern = RegExp(r":\)");

  text.splitMapJoin(
    emoticonPattern,
    onMatch: (match) {
      textSpans.add(WidgetSpan(
        child: Icon(
          Icons.sentiment_satisfied,
          color: Colors.yellow,
          size: 20,
        ),
      ));
      return '';
    },
    onNonMatch: (nonMatch) {
      textSpans.add(TextSpan(text: nonMatch));
      return nonMatch;
    },
  );

  return TextSpan(children: textSpans);
}
