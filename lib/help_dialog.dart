import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Widget bulletTextUrl(BuildContext context, String text, Uri? uri) {
  if (uri == null) {
    return SelectableText.rich(TextSpan(text: "\u2022 $text"));
  }

  return RichText(
      text: TextSpan(
    text: "\u2022 $text",
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
    ),
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
  var l10n = AppLocalizations.of(context)!;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(l10n.help),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.a_game_to_help_you_learn_times_tables),
            const SizedBox(height: 16),
            bulletTextUrl(context, "${l10n.source_code}: ",
                Uri.parse("https://github.com/walles/ttt")),
            bulletTextUrl(context, "${l10n.issues}: ",
                Uri.parse("https://github.com/walles/ttt/issues")),
            bulletTextUrl(
                context, "${l10n.contact}: johan.walles@gmail.com", null),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(l10n.close),
          ),
        ],
      );
    },
  );
}
