import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

/// Convert `[label](https://url)` markdown links into `label (https://url)`
/// so Linkify can detect them.
String _deMarkdown(String input) {
  final exp = RegExp(r'\[([^\]]+)\]\((https?:\/\/[^\)]+)\)');
  return input.replaceAllMapped(exp, (m) => '${m[1]} (${m[2]})');
}

class LinkifiedMessage extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;

  const LinkifiedMessage({
    super.key,
    required this.text,
    this.style,
    this.linkStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SelectableLinkify(
      text: _deMarkdown(text),
      style: style,
      linkStyle: linkStyle ??
          TextStyle(
            decoration: TextDecoration.underline,
            color: Theme.of(context).colorScheme.primary,
          ),
      options: const LinkifyOptions(humanize: true),
      onOpen: (link) async {
        final uri = Uri.parse(link.url);
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Couldn’t open link')));
        }
      },
    );
  }
}
