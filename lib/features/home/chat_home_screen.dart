import 'package:flutter/material.dart';

import '../../app/theme.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key, this.onOpenSection});

  final ValueChanged<String>? onOpenSection;

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<_ChatMessage> _messages = const [
    _ChatMessage(
      role: _MessageRole.assistant,
      text:
          'Hello. I am your HHL care assistant. I can help you find a doctor, arrange tests, check invoices, and guide your next step.',
    ),
  ].toList();

  static const _quickPrompts = <_QuickPrompt>[
    _QuickPrompt(
      title: 'Find a doctor',
      prompt: 'I need a cardiologist this week.',
      icon: Icons.medical_services_outlined,
      sectionKey: 'doctors',
    ),
    _QuickPrompt(
      title: 'Book tests',
      prompt: 'I want to book diagnostic tests.',
      icon: Icons.biotech_outlined,
      sectionKey: 'diagnostics',
    ),
    _QuickPrompt(
      title: 'Open reports',
      prompt: 'Show me my reports.',
      icon: Icons.description_outlined,
      sectionKey: 'reports',
    ),
    _QuickPrompt(
      title: 'View invoices',
      prompt: 'Open my invoices.',
      icon: Icons.receipt_long_outlined,
      sectionKey: 'invoices',
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage([String? seededPrompt]) {
    final text = (seededPrompt ?? _messageController.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(role: _MessageRole.user, text: text));
      _messages.add(
        const _ChatMessage(
          role: _MessageRole.assistant,
          text:
              'This is the chat-first UI shell. Next we will connect these prompts to the real agent and backend workflows.',
        ),
      );
      _messageController.clear();
    });
  }

  void _handlePrompt(_QuickPrompt prompt) {
    _sendMessage(prompt.prompt);
    if (prompt.sectionKey != null && widget.onOpenSection != null) {
      widget.onOpenSection!(prompt.sectionKey!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 840;

    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickPrompts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final prompt = _quickPrompts[index];
                        return ActionChip(
                          avatar: Icon(
                            prompt.icon,
                            size: 18,
                            color: AppColors.primaryDark,
                          ),
                          label: Text(prompt.title),
                          onPressed: () => _handlePrompt(prompt),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(0xFFD9EFEB),
                            foregroundColor: AppColors.primaryDark,
                            child: Icon(Icons.auto_awesome_outlined, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Care Chat',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE4ECEA)),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        itemCount: _messages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _MessageBubble(message: _messages[index]);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: _Composer(
                        controller: _messageController,
                        onSend: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(flex: 3, child: _HeroCopy()),
                const SizedBox(width: 18),
                Expanded(
                  flex: 2,
                  child: _StatusPanel(onOpenSection: widget.onOpenSection),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final prompt in _quickPrompts)
                  ActionChip(
                    avatar: Icon(
                      prompt.icon,
                      size: 18,
                      color: AppColors.primaryDark,
                    ),
                    label: Text(prompt.title),
                    onPressed: () => _handlePrompt(prompt),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFFD9EFEB),
                          foregroundColor: AppColors.primaryDark,
                          child: Icon(Icons.auto_awesome_outlined, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Care Chat',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Prototype conversation workspace',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE4ECEA)),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      itemCount: _messages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _MessageBubble(message: _messages[index]);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _Composer(
                      controller: _messageController,
                      onSend: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE4F4F1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Chat-based home',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Describe symptoms, ask for help, and move into care flows from the conversation.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 28,
            height: 1.18,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'This home screen is now centered on chat. Doctors, diagnostics, reports, and invoices stay available as connected sections around it.',
        ),
      ],
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.onOpenSection});

  final ValueChanged<String>? onOpenSection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE8E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connected now',
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'Doctor booking',
            value: 'Live',
            onTap: () => onOpenSection?.call('doctors'),
          ),
          const SizedBox(height: 10),
          _StatusRow(
            label: 'Diagnostics',
            value: 'Live',
            onTap: () => onOpenSection?.call('diagnostics'),
          ),
          const SizedBox(height: 10),
          _StatusRow(
            label: 'Invoices',
            value: 'Live',
            onTap: () => onOpenSection?.call('invoices'),
          ),
          const SizedBox(height: 10),
          const _StatusRow(label: 'AI agent', value: 'UI only'),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFDDF2EE),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: content,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isAssistant = message.role == _MessageRole.assistant;

    return Align(
      alignment: isAssistant ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisAlignment: isAssistant
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAssistant) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFD9EFEB),
              foregroundColor: AppColors.primaryDark,
              child: Icon(Icons.auto_awesome_outlined, size: 16),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 640),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isAssistant ? const Color(0xFFF7FAF9) : AppColors.primary,
                borderRadius: BorderRadius.circular(22),
                border: isAssistant
                    ? Border.all(color: const Color(0xFFE0EBE9))
                    : null,
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isAssistant ? AppColors.ink : Colors.white,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE8E6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSend(),
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ask about symptoms, appointments, tests, or documents...',
                prefixIcon: Icon(Icons.mode_comment_outlined),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: onSend,
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
    );
  }
}

class _QuickPrompt {
  const _QuickPrompt({
    required this.title,
    required this.prompt,
    required this.icon,
    this.sectionKey,
  });

  final String title;
  final String prompt;
  final IconData icon;
  final String? sectionKey;
}

class _ChatMessage {
  const _ChatMessage({required this.role, required this.text});

  final _MessageRole role;
  final String text;
}

enum _MessageRole { assistant, user }
