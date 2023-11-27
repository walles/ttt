import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Widget bulletTextUrl(BuildContext context, String text, Uri? uri) {
  if (uri == null) {
    return SelectableText.rich(TextSpan(text: "\u2022 $text"));
  }

  return RichText(
      text: TextSpan(
    text: "\u2022 $text",
    children: [
      TextSpan(
        text: uri.toString(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            launchUrl(uri);
          },
      ),
    ],
  ));
}

void showHelpDialog(BuildContext context) {
  // With clickable links to the source code, GitHub Issues and for e-mailing
  // Johan
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Help"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("A game to help you learn times tables. "),
            const SizedBox(height: 16),
            bulletTextUrl(context, "Source code: ",
                Uri.parse("https://github.com/walles/ttt")),
            bulletTextUrl(context, "Issues: ",
                Uri.parse("https://github.com/walles/ttt/issues")),
            bulletTextUrl(context, "Contact: johan.walles@gmail.com", null),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Close"),
          ),
        ],
      );
    },
  );
}
