import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/openai_service.dart';
import '../services/analytics_service.dart';
import '../services/connectivity_service.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatTab extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onSaveConversation;
  final List<Map<String, dynamic>> messages;
  final Function(List<Map<String, dynamic>>) onMessagesChanged;
  final VoidCallback? onOpenSources;

  const ChatTab({
    super.key,
    required this.onSaveConversation,
    required this.messages,
    required this.onMessagesChanged,
    this.onOpenSources,
  });

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  bool _isThinking = false;

  final List<String> _examplePrompts = const [
    'Explain offside when a player is in front of the kicker.',
    'What happens if the ball hits the referee?',
    'Walk me through Law 19 lineout basics.',
    'Quick throw: when is it still legal?',
    'How do you manage repeated scrum collapses?',
  ];

  String _toVIEW(String input) {
    final re = RegExp(r'\[Link\]\((https?:\/\/[^)]+)\)', caseSensitive: false);
    return input.replaceAllMapped(re, (m) => '[VIEW](${m.group(1)})');
  }

  String _linkifyLawRefs(String input) {
    final lawRe = RegExp(
      r'\bLaw\s+(\d{1,2}(?:\.\d{1,2})?)\b',
      caseSensitive: false,
    );
    final withLaw = input.replaceAllMapped(lawRe, (m) {
      final ref = m.group(1);
      if (ref == null) return m.group(0) ?? '';
      return '[Law $ref](lawref:$ref)';
    });

    final bareRe = RegExp(r'\b([1-9]\d?(?:\.\d{1,2})?)\b');
    return withLaw.replaceAllMapped(bareRe, (m) {
      final ref = m.group(1);
      if (ref == null) return m.group(0) ?? '';
      final start = m.start;
      final before = withLaw.substring(start >= 8 ? start - 8 : 0, start);
      if (before.contains('lawref:') || before.contains('http')) {
        return m.group(0) ?? '';
      }
      return '[Law $ref](lawref:$ref)';
    });
  }

  String _formatAssistantText(String input) {
    return _linkifyLawRefs(_toVIEW(input));
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $url')));
    }
  }

  Future<String> _loadLawContent(String lawRef) async {
    // Extract the main law number (e.g., "11" from "11.5.a")
    final mainLawMatch = RegExp(r'^(\d{1,2})').firstMatch(lawRef);
    if (mainLawMatch == null) {
      return 'Law not found.';
    }

    final lawNumber = mainLawMatch.group(1)!;
    final lawPath = 'assets/laws/rugbylaw${lawNumber.padLeft(2, '0')}.md';

    try {
      final content = await rootBundle.loadString(lawPath);
      return content;
    } catch (e) {
      return 'Law $lawNumber content not available.';
    }
  }

  void _openLawRefPopover(String lawRef) {
    final canonicalRef = _canonicalizeLawRef(lawRef);
    bool showFull = false;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Header with drag handle
                      Container(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              'Law $lawRef',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (_hasExcerpt(canonicalRef)) ...[
                              const SizedBox(width: 8),
                              FilledButton.tonal(
                                onPressed: () => setState(() => showFull = !showFull),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  textStyle: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: Text(showFull ? 'Section only' : 'Full law'),
                              ),
                            ],
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: 'Close',
                              onPressed: () => Navigator.of(sheetContext).pop(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Scrollable content
                      Expanded(
                        child: FutureBuilder<String>(
                          future: _loadLawContent(canonicalRef),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              );
                            }

                            final content = snapshot.data ?? 'Failed to load law content.';
                            final excerpt = _extractLawSection(content, canonicalRef);
                            final showExcerptOnly = excerpt != null && !showFull;
                            final displayContent = showExcerptOnly ? excerpt : content;

                            return SingleChildScrollView(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MarkdownBody(
                                    data: displayContent,
                                    onTapLink: (label, href, title) {
                                      if (href != null) _openLink(href);
                                    },
                                    styleSheet:
                                        MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                      h1: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      h2: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      h3: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      p: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        height: 1.5,
                                      ),
                                      listBullet: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      strong: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _prefillAndFocus(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    _inputFocus.requestFocus();
  }

  void _sendMessage() async {
    final text = (_controller.text).trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a message!')));
      return;
    }

    final incidentContext = _findLastIncidentContext();
    final isFollowUp = _isFollowUpToIncident(text, incidentContext);
    final pendingIndex = _findPendingClarificationIndex();
    if (pendingIndex != null) {
      final updatedMessages = _applyFreeTextClarification(pendingIndex, text);
      updatedMessages.add({
        'sender': 'user',
        'text': text,
        'timestamp': DateTime.now(),
        'type': 'clarification_answer',
      });
      widget.onMessagesChanged(updatedMessages);
      _scrollToBottom();
      _controller.clear();
      await _submitClarifications(
        updatedMessages[pendingIndex],
        pendingIndex,
        updatedMessages,
      );
      return;
    }

    final updatedMessages = List<Map<String, dynamic>>.from(widget.messages)
      ..add({'sender': 'user', 'text': text, 'timestamp': DateTime.now()});

    widget.onMessagesChanged(updatedMessages);
    _scrollToBottom();

    setState(() {
      _isThinking = true;
    });
    _controller.clear();

    try {
      final isLikelyIncident = _isLikelyIncident(text);
      if (kDebugMode) print('[incidentFlow] isLikelyIncident=$isLikelyIncident isFollowUp=$isFollowUp');
      if (isFollowUp) {
        await _handleIncidentFollowUp(
          incidentContext,
          updatedMessages,
          text,
        );
      } else if (isLikelyIncident) {
        final analysis = await OpenAIService.analyzeIncident(text);
        if (analysis['error'] != null) throw Exception(analysis['error']);

        if (analysis['needsClarification'] == true) {
          final clarifications = (analysis['clarifications'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          final clarificationsText = clarifications
              .map((c) {
                final question = (c['question'] ?? '').toString();
                final options = (c['options'] as List? ?? [])
                    .map((e) => e.toString())
                    .toList();
                if (options.isEmpty) return question;
                return '$question (${options.join(' / ')})';
              })
              .where((line) => line.trim().isNotEmpty)
              .join('\n\n');
          final messageText = [
            (analysis['message'] ?? 'I have a few questions:').toString(),
            if (clarificationsText.isNotEmpty) clarificationsText,
          ].join('\n\n');

          final withClarifications =
              List<Map<String, dynamic>>.from(updatedMessages)..add({
                'sender': 'sofia',
                'text': messageText,
                'timestamp': DateTime.now(),
                'type': 'clarification_request',
                'incidentText': text,
                'clarifications': clarifications,
                'answers': <String, String>{},
              });

          widget.onMessagesChanged(withClarifications);
          _scrollToBottom();

          // Log analytics event for incident analysis
          await AnalyticsService.logIncidentAnalyzed(hadClarifications: true);
        } else {
          final result = await OpenAIService.getIncidentRuling(
            text,
            const {},
            context: _buildConversationContext(),
          );
          if (result['error'] != null) throw Exception(result['error']);

          final withAssessment = List<Map<String, dynamic>>.from(updatedMessages);
          _appendIncidentAssessment(
            withAssessment,
            result,
            incidentText: text,
            answers: const {},
          );
          widget.onMessagesChanged(withAssessment);
          _scrollToBottom();

          // Log analytics event for incident ruling
          final lawRefs = result['assessment']?['law_refs'] as List? ?? [];
          await AnalyticsService.logIncidentRuling(lawRefsCount: lawRefs.length);
        }
      } else {
        await _handleNormalChat(updatedMessages);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      await _handleNormalChat(updatedMessages);
    }

    if (mounted) setState(() => _isThinking = false);
  }

  Future<void> _handleNormalChat(List<Map<String, dynamic>> messages) async {
    final responseText = await OpenAIService.sendMessage(messages);
    final updatedMessagesAfterResponse =
        List<Map<String, dynamic>>.from(messages)..add({
          'sender': 'sofia',
          'text': responseText,
          'timestamp': DateTime.now(),
        });

    widget.onMessagesChanged(updatedMessagesAfterResponse);
    _scrollToBottom();

    // Log analytics event
    await AnalyticsService.logChatSent(
      queryType: 'normal_chat',
      messageCount: messages.length,
    );
  }

  bool _isLikelyIncident(String text) {
    final words = text.trim().split(RegExp(r'\s+')).length;
    if (words < 6) return false;
    final re = RegExp(
      r'\b(tackle|high tackle|ruck|maul|scrum|lineout|offside|card|penalty|'
      r'knock[-\s]?on|dangerous play|foul play|not releasing|'
      r'sin bin|yellow card|red card|advantage|breakdown|off\s+feet|'
      r'seal(?:ing)?|side\s+entry|clear[-\s]?out|jackal|no\s+arms|'
      r'tip tackle|shoulder\s+charge)\b',
      caseSensitive: false,
    );
    return re.hasMatch(text);
  }

  bool _isFollowUpToIncident(
    String text,
    Map<String, dynamic>? incidentContext,
  ) {
    if (incidentContext == null) return false;
    final t = text.trim().toLowerCase();
    if (t.isEmpty) return false;
    if (t.contains('?')) return true;
    if (t.startsWith('what if') ||
        t.startsWith('what about') ||
        t.startsWith('so ') ||
        t.startsWith('and if') ||
        t.startsWith('in that case') ||
        t.startsWith('in this case') ||
        t.startsWith('same situation') ||
        t.startsWith('does that') ||
        t.startsWith('is it') ||
        t.startsWith('is that') ||
        t.startsWith('should it') ||
        t.startsWith('would it')) {
      return true;
    }
    final followUpWords = RegExp(
      r'\b(penalty|sanction|card|yellow|red|legal|illegal|allowed|'
      r'advantage|play on|restart|free kick)\b',
    );
    final wordCount = t.split(RegExp(r'\s+')).length;
    return wordCount <= 14 && followUpWords.hasMatch(t);
  }

  Map<String, dynamic>? _findLastIncidentContext() {
    for (int i = widget.messages.length - 1; i >= 0; i -= 1) {
      final message = widget.messages[i];
      final incidentText = (message['incidentText'] ?? '').toString();
      if (incidentText.isNotEmpty) {
        final answers = Map<String, String>.from(message['answers'] ?? {});
        return {'incidentText': incidentText, 'answers': answers};
      }
    }
    return null;
  }

  List<Map<String, String>> _buildConversationContext({int maxItems = 8}) {
    final ctx = <Map<String, String>>[];
    for (final message in widget.messages) {
      final sender = (message['sender'] ?? '').toString();
      final text = (message['text'] ?? '').toString();
      if (text.isNotEmpty) {
        ctx.add({'role': sender, 'content': text});
        continue;
      }
      if (message['type'] == 'assessment') {
        final assessment = message['assessment'] as Map? ?? {};
        final decision = (assessment['decision'] ?? '').toString();
        if (decision.isNotEmpty) {
          ctx.add({'role': 'sofia', 'content': 'Assessment: $decision'});
        }
      }
    }
    if (ctx.length <= maxItems) return ctx;
    return ctx.sublist(ctx.length - maxItems);
  }

  int? _findPendingClarificationIndex() {
    for (int i = widget.messages.length - 1; i >= 0; i -= 1) {
      final message = widget.messages[i];
      if (message['type'] == 'clarification_request' && message['resolved'] != true) {
        return i;
      }
    }
    return null;
  }

  Widget _buildMessage(Map<String, dynamic> message, int index) {
    final bool isUser = message['sender'] == 'user';
    final String text = (message['text'] ?? '').toString();
    final DateTime ts = (message['timestamp'] is DateTime)
        ? message['timestamp'] as DateTime
        : DateTime.now();

    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final colorScheme = Theme.of(context).colorScheme;
    final bubbleColor = isUser ? colorScheme.primary : colorScheme.surfaceContainerHighest;
    final textColor = isUser ? colorScheme.onPrimary : colorScheme.onSurface;

    if (!isUser && message['type'] == 'clarification_request') {
      final clarifications = (message['clarifications'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final answers = Map<String, String>.from(message['answers'] ?? {});
      final resolved = message['resolved'] == true;

      return Align(
        alignment: alignment,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: GoogleFonts.inter(fontSize: 16, color: textColor),
              ),
              if (clarifications.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...clarifications.map((q) {
                  final id = (q['id'] ?? '').toString();
                  final questionText = (q['question'] ?? '').toString();
                  final options = (q['options'] as List? ?? [])
                      .map((e) => e.toString())
                      .toList();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          questionText,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (options.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: options.map((option) {
                              final selected = answers[id] == option;
                              return ChoiceChip(
                                label: Text(
                                  option,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                selected: selected,
                                selectedColor: colorScheme.primary,
                                onSelected: resolved
                                    ? null
                                    : (_) => _setClarificationAnswer(
                                          index,
                                          id,
                                          option,
                                        ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  );
                }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: resolved || _isThinking
                        ? null
                        : () => _submitClarifications(
                              Map<String, dynamic>.from(message),
                              index,
                              List<Map<String, dynamic>>.from(widget.messages),
                            ),
                    child: Text(
                      'Submit answers',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                DateFormat('h:mm a').format(ts),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!isUser && (message['type'] == 'ruling' || message['type'] == 'assessment')) {
      return Align(
        alignment: alignment,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAssessmentCard(message['assessment'] ?? message['ruling'] as Map? ?? {}),
              const SizedBox(height: 6),
              Text(
                DateFormat('h:mm a').format(ts),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Widget bubbleChild = isUser
        ? Text(text, style: GoogleFonts.inter(fontSize: 16, color: textColor))
        : MarkdownBody(
            data: _formatAssistantText(text),
            onTapLink: (label, href, title) {
              if (href == null) return;
              if (href.startsWith('lawref:')) {
                _openLawRefPopover(href.substring('lawref:'.length));
                return;
              }
              _openLink(href);
            },
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .copyWith(
                  p: GoogleFonts.inter(fontSize: 16, color: colorScheme.onSurface),
                  a: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.tertiary,
                    decoration: TextDecoration.underline,
                  ),
                ),
          );

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            bubbleChild,
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(ts),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isUser
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _applyFreeTextClarification(
    int messageIndex,
    String text,
  ) {
    final updatedMessages = List<Map<String, dynamic>>.from(widget.messages);
    final msg = Map<String, dynamic>.from(updatedMessages[messageIndex]);
    final answers = Map<String, String>.from(msg['answers'] ?? {});
    answers['free_text'] = text;
    msg['answers'] = answers;
    updatedMessages[messageIndex] = msg;
    return updatedMessages;
  }

  Widget _buildAssessmentCard(Map assessment) {
    final decision = (assessment['decision'] ?? assessment['ruling'] ?? '').toString();
    final lawRefs = (assessment['law_refs'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final explanation = (assessment['explanation'] ?? '').toString();
    final counterfactuals = (assessment['counterfactuals'] as List? ?? [])
        .map((e) => e.toString())
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          decision,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(explanation, style: GoogleFonts.inter(fontSize: 14)),
        if (lawRefs.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Relevant laws',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lawRefs.take(3).map((ref) => _buildLawRefChip(ref)).toList(),
          ),
        ],
        if (counterfactuals.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'What would change the call?',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ...counterfactuals
              .take(2)
              .map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $c', style: GoogleFonts.inter(fontSize: 13)),
                ),
              ),
        ],
      ],
    );
  }

  Widget _buildLawRefChip(String ref) {
    final normalizedRef = _canonicalizeLawRef(ref);
    return ActionChip(
      label: Text(
        ref,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      avatar: const Icon(Icons.library_books, size: 16),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      onPressed: () {
        _openLawRefPopover(normalizedRef);
      },
    );
  }

  String _canonicalizeLawRef(String ref) {
    final match = RegExp(r'(\d{1,2})(?:\.(\d{1,2}))?(?:\.?([a-z]))?')
        .firstMatch(ref.toLowerCase());
    if (match == null) return ref;
    final main = match.group(1);
    if (main == null) return ref;
    final sub = match.group(2);
    final letter = match.group(3);
    if (sub == null) return main;
    if (letter == null) return '$main.$sub';
    return '$main.$sub.$letter';
  }

  bool _hasExcerpt(String lawRef) {
    return lawRef.contains('.');
  }

  String? _extractLawSection(String content, String lawRef) {
    if (!lawRef.contains('.')) return null;
    final lines = content.split('\n');
    final refParts = lawRef.split('.');
    final startPattern = refParts.length == 2
        ? RegExp(
            r'^\s*-?\s*' + RegExp.escape(lawRef) + r'(?!\.)\b',
            caseSensitive: false,
          )
        : RegExp(
            r'^\s*-?\s*' +
                RegExp.escape(refParts[0] + '.' + refParts[1]) +
                r'\.?'+
                RegExp.escape(refParts[2]) +
                r'\b',
            caseSensitive: false,
          );

    int start = -1;
    for (var i = 0; i < lines.length; i++) {
      if (startPattern.hasMatch(lines[i])) {
        start = i;
        break;
      }
    }
    if (start == -1) return null;

    int end = lines.length;
    final topLevelPattern = RegExp(r'^\s*\d{1,2}\.\d+\b');
    final nextLetterPattern = refParts.length == 3
        ? RegExp(
            r'^\s*-?\s*' +
                RegExp.escape(refParts[0] + '.' + refParts[1]) +
                r'\.(?!' +
                RegExp.escape(refParts[2]) +
                r'\b)' +
                r'[a-z]\b',
            caseSensitive: false,
          )
        : null;

    for (var i = start + 1; i < lines.length; i++) {
      final line = lines[i];
      if (nextLetterPattern != null && nextLetterPattern.hasMatch(line)) {
        end = i;
        break;
      }
      if (topLevelPattern.hasMatch(line)) {
        end = i;
        break;
      }
    }

    return lines.sublist(start, end).join('\n').trim();
  }

  void _setClarificationAnswer(int messageIndex, String id, String value) {
    final updatedMessages = List<Map<String, dynamic>>.from(widget.messages);
    final msg = Map<String, dynamic>.from(updatedMessages[messageIndex]);
    final answers = Map<String, String>.from(msg['answers'] ?? {});
    answers[id] = value;
    msg['answers'] = answers;
    updatedMessages[messageIndex] = msg;
    widget.onMessagesChanged(updatedMessages);
  }

  Future<void> _submitClarifications(
    Map<String, dynamic> message,
    int index,
    List<Map<String, dynamic>> currentMessages,
  ) async {
    final incidentText = (message['incidentText'] ?? '').toString();
    if (incidentText.isEmpty) return;
    final answers = Map<String, String>.from(message['answers'] ?? {});

    setState(() {
      _isThinking = true;
    });

    try {
      final result = await OpenAIService.getIncidentRuling(
        incidentText,
        answers,
        context: _buildConversationContext(),
      );
      if (result['error'] != null) throw Exception(result['error']);

      final updated = List<Map<String, dynamic>>.from(currentMessages);
      final msg = Map<String, dynamic>.from(updated[index]);
      msg['resolved'] = true;
      updated[index] = msg;
      _appendIncidentAssessment(
        updated,
        result,
        incidentText: incidentText,
        answers: answers,
      );

      widget.onMessagesChanged(updated);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      await _handleNormalChat(List<Map<String, dynamic>>.from(widget.messages));
    } finally {
      if (mounted) setState(() => _isThinking = false);
    }
  }

  Future<void> _handleIncidentFollowUp(
    Map<String, dynamic>? incidentContext,
    List<Map<String, dynamic>> updatedMessages,
    String followUpText,
  ) async {
    final incidentText = (incidentContext?['incidentText'] ?? '').toString();
    if (incidentText.isEmpty) {
      await _handleNormalChat(updatedMessages);
      return;
    }
    final answers =
        Map<String, String>.from(incidentContext?['answers'] ?? {});

    final result = await OpenAIService.getIncidentRuling(
      incidentText,
      answers,
      followUp: followUpText,
      context: _buildConversationContext(),
    );
    if (result['error'] != null) throw Exception(result['error']);

    final updated = List<Map<String, dynamic>>.from(updatedMessages);
    _appendIncidentAssessment(
      updated,
      result,
      incidentText: incidentText,
      answers: answers,
    );
    widget.onMessagesChanged(updated);
    _scrollToBottom();
  }

  void _appendIncidentAssessment(
    List<Map<String, dynamic>> messages,
    Map<String, dynamic> result, {
    String incidentText = '',
    Map<String, String>? answers,
  }) {
    final messageText = (result['message'] ?? '').toString().trim();
    if (messageText.isNotEmpty) {
      messages.add({
        'sender': 'sofia',
        'text': messageText,
        'timestamp': DateTime.now(),
      });
    }
    messages.add({
      'sender': 'sofia',
      'text': '',
      'timestamp': DateTime.now(),
      'type': 'assessment',
      'incidentText': incidentText,
      'answers': answers ?? {},
      'assessment': result['assessment'] ?? result,
    });
  }

  Widget _buildPromptChips(BuildContext context) {
    final maxChipWidth = MediaQuery.of(context).size.width * 0.60;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: _examplePrompts.map((text) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxChipWidth, minHeight: 48),
              child: InkWell(
                onTap: () => _prefillAndFocus(text),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    text,
                    softWrap: true,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _clearChat() {
    widget.onMessagesChanged([]);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat cleared!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _saveConversation() {
    if (widget.messages.isEmpty) return;
    widget.onSaveConversation(widget.messages);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isOnline,
      builder: (context, isOnline, _) {
        return SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              if (!isOnline)
                MaterialBanner(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  content: const Text('Sofia requires an internet connection'),
                  leading: Icon(Icons.wifi_off, color: colorScheme.onSurfaceVariant),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  actions: [
                    TextButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              if (widget.messages.isEmpty && !_isThinking) ...[
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icons/app_icon.png',
                        width: 80,
                        height: 80,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ask Sofia anything!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap a prompt below or type your own.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildPromptChips(context),
          ] else ...[
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: widget.messages.length + (_isThinking ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isThinking && index == widget.messages.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(strokeWidth: 2),
                            const SizedBox(width: 12),
                            Text(
                              'Sofia is thinking...',
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final message = widget.messages[index];
                  return _buildMessage(message, index);
                },
              ),
            ),
          ],

          if (widget.messages.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _saveConversation,
                    icon: const Icon(Icons.star_border),
                    label: Text(
                      'Save Conversation',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: _clearChat,
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    label: Text(
                      'Clear Thread',
                      style: GoogleFonts.inter(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom +
                  8,
              left: 12,
              right: 12,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: _inputFocus,
                    minLines: 1,
                    maxLines: 4,
                    controller: _controller,
                    enabled: isOnline,
                    textInputAction: TextInputAction.send,
                    onSubmitted: isOnline ? (_) => _sendMessage() : null,
                    decoration: InputDecoration(
                      hintText: isOnline ? 'Ask Sofia...' : 'No internet connection',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isOnline && !_isThinking ? _sendMessage : null,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
