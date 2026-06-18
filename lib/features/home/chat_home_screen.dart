import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/session/app_session_scope.dart';
import '../chat/data/chat_models.dart';
import '../chat/logic/chat_controller.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key, this.onOpenSection});

  final ValueChanged<String>? onOpenSection;

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatController _controller = ChatController();

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
      title: 'Appointments',
      prompt: 'Show my upcoming appointments.',
      icon: Icons.calendar_month_outlined,
      sectionKey: 'appointments',
    ),
    _QuickPrompt(
      title: 'Invoices',
      prompt: 'Show me my invoices.',
      icon: Icons.receipt_long_outlined,
      sectionKey: 'invoices',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage([
    String? seededPrompt,
    String? displayText,
  ]) async {
    final text = (seededPrompt ?? _messageController.text).trim();
    if (text.isEmpty) return;
    _messageController.clear();

    final session = AppSessionScope.of(context);
    await _controller.sendMessage(
      text: text,
      displayText: displayText,
      session: session,
    );
  }

  Future<void> _handleCardAction(ChatCardItem item) async {
    if (item.blockType == 'date_picker') {
      final request = await _pickBackendRequestedDate(item);
      if (request != null && request.command.trim().isNotEmpty) {
        await _sendMessage(request.command.trim(), request.displayText.trim());
      }
      return;
    }

    if (item.scheduleId.isNotEmpty) {
      final request = await showModalBottomSheet<_ChatUserRequest>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return _SlotPreferenceSheet(
            doctorName: item.title,
            suggestedDate: item.suggestedDate,
            scheduleId: item.scheduleId,
          );
        },
      );

      if (request != null && request.command.trim().isNotEmpty) {
        await _sendMessage(request.command.trim(), request.displayText.trim());
      }
      return;
    }

    if (item.actionPrompt.isNotEmpty) {
      await _sendMessage(item.actionPrompt);
    }
  }

  Future<_ChatUserRequest?> _pickBackendRequestedDate(ChatCardItem item) async {
    final now = DateTime.now();
    final minDate = _parseDate(item.minDate) ?? DateTime(now.year, now.month, now.day);
    final initialDate = _parseDate(item.suggestedDate) ?? minDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(minDate) ? minDate : initialDate,
      firstDate: minDate,
      lastDate: minDate.add(const Duration(days: 60)),
      helpText: item.title.isNotEmpty ? item.title : 'Choose date',
    );
    if (picked == null) return null;

    final normalizedDate =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    final command = item.submitPrefix.isEmpty
        ? normalizedDate
        : '${item.submitPrefix} on $normalizedDate';
    return _ChatUserRequest(
      command: command,
      displayText: normalizedDate,
    );
  }

  Future<void> _confirmJob(String jobId) async {
    final session = AppSessionScope.of(context);
    await _controller.confirmJob(actionId: jobId, session: session);
  }

  Future<void> _cancelJob(String jobId) async {
    final session = AppSessionScope.of(context);
    await _controller.cancelJob(actionId: jobId, session: session);
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
    final messages = _controller.messages;

    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          children: [
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickPrompts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
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
            const SizedBox(height: 10),
            Expanded(
              child: _ChatSurface(
                scrollController: _scrollController,
                messages: messages,
                isSending: _controller.isSending,
                errorMessage: _controller.errorMessage,
                onOpenSection: widget.onOpenSection,
                onQuickReply: _sendMessage,
                onCardAction: _handleCardAction,
                onConfirmJob: _confirmJob,
                onCancelJob: _cancelJob,
              ),
            ),
            const SizedBox(height: 10),
            _Composer(
              controller: _messageController,
              onSend: _sendMessage,
              isBusy: _controller.isSending,
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
            padding: const EdgeInsets.all(18),
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
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
          Expanded(
            child: _ChatSurface(
              scrollController: _scrollController,
              messages: messages,
              isSending: _controller.isSending,
              errorMessage: _controller.errorMessage,
              onOpenSection: widget.onOpenSection,
              onQuickReply: _sendMessage,
              onCardAction: _handleCardAction,
              onConfirmJob: _confirmJob,
              onCancelJob: _cancelJob,
            ),
          ),
          const SizedBox(height: 12),
          _Composer(
            controller: _messageController,
            onSend: _sendMessage,
            isBusy: _controller.isSending,
          ),
        ],
      ),
    );
  }
}

class _ChatSurface extends StatelessWidget {
  const _ChatSurface({
    required this.scrollController,
    required this.messages,
    required this.isSending,
    required this.errorMessage,
    required this.onQuickReply,
    required this.onCardAction,
    required this.onConfirmJob,
    required this.onCancelJob,
    this.onOpenSection,
  });

  final ScrollController scrollController;
  final List<ChatMessageRecord> messages;
  final bool isSending;
  final String? errorMessage;
  final ValueChanged<String> onQuickReply;
  final Future<void> Function(ChatCardItem item) onCardAction;
  final Future<void> Function(String jobId) onConfirmJob;
  final Future<void> Function(String jobId) onCancelJob;
  final ValueChanged<String>? onOpenSection;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
              itemCount: messages.length + (isSending ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index >= messages.length) {
                  return const _TypingBubble();
                }

                final message = messages[index];
                final previousUserPrompt = _previousUserPrompt(messages, index);
                return _MessageBubble(
                  message: message,
                  previousUserPrompt: previousUserPrompt,
                  onQuickReply: onQuickReply,
                  onCardAction: onCardAction,
                  onConfirmJob: onConfirmJob,
                  onCancelJob: onCancelJob,
                  onOpenSection: onOpenSection,
                );
              },
            ),
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
            'Care assistant',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Ask naturally and move into real booking, diagnostics, and billing flows from chat.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 26,
            height: 1.18,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'This chat is now wired for real backend sessions and message flow, with structured cards ready for doctor, test, and invoice actions.',
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
            label: 'Appointments',
            value: 'Live',
            onTap: () => onOpenSection?.call('appointments'),
          ),
          const SizedBox(height: 10),
          const _StatusRow(label: 'AI agent', value: 'Connected'),
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
  const _MessageBubble({
    required this.message,
    required this.previousUserPrompt,
    required this.onQuickReply,
    required this.onCardAction,
    required this.onConfirmJob,
    required this.onCancelJob,
    this.onOpenSection,
  });

  final ChatMessageRecord message;
  final String previousUserPrompt;
  final ValueChanged<String> onQuickReply;
  final Future<void> Function(ChatCardItem item) onCardAction;
  final Future<void> Function(String jobId) onConfirmJob;
  final Future<void> Function(String jobId) onCancelJob;
  final ValueChanged<String>? onOpenSection;

  @override
  Widget build(BuildContext context) {
    final isAssistant = message.isAssistant;
    final visibleItems = _visibleChatItems(
      message.items,
      previousUserPrompt: previousUserPrompt,
    );
    final hasSlotCards = _containsBookableSlotItems(visibleItems);

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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isAssistant
                            ? const Color(0xFFF7FAF9)
                            : AppColors.primary,
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
                  if (visibleItems.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    if (hasSlotCards)
                      _SlotCardScroller(
                        items: visibleItems,
                        onCardAction: onCardAction,
                      )
                    else
                      Column(
                        children: [
                          for (final item in visibleItems) ...[
                            _AgentCard(
                              item: item,
                              onAction: item.actionPrompt.isEmpty
                                  ? null
                                  : () => onCardAction(item),
                              onOpenSection: () {
                                final section = _sectionForType(message.messageType);
                                if (section != null) {
                                  onOpenSection?.call(section);
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                  ],
                  if (message.quickReplies.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final reply in message.quickReplies)
                          ActionChip(
                            label: Text(reply),
                            onPressed: () => onQuickReply(reply),
                          ),
                      ],
                    ),
                  ],
                  if (_shouldShowActionControls(message)) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => onCancelJob(message.actionId!),
                            child: Text(_secondaryActionLabel(message)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => onConfirmJob(message.actionId!),
                            child: Text(_primaryActionLabel(message)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotCardScroller extends StatefulWidget {
  const _SlotCardScroller({
    required this.items,
    required this.onCardAction,
  });

  final List<ChatCardItem> items;
  final Future<void> Function(ChatCardItem item) onCardAction;

  @override
  State<_SlotCardScroller> createState() => _SlotCardScrollerState();
}

class _SlotCardScrollerState extends State<_SlotCardScroller> {
  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = widget.items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 214,
          child: PageView.builder(
            controller: _pageController,
            itemCount: pageCount,
            onPageChanged: (index) {
              setState(() => _pageIndex = index);
            },
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return Padding(
                padding: EdgeInsets.only(right: index == pageCount - 1 ? 0 : 10),
                child: _AgentCard(
                  item: item,
                  onAction: item.actionPrompt.isEmpty
                      ? null
                      : () => widget.onCardAction(item),
                ),
              );
            },
          ),
        ),
        if (pageCount > 1) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Slot ${_pageIndex + 1} of $pageCount',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _pageIndex == 0
                    ? null
                    : () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                        );
                      },
                icon: const Icon(Icons.chevron_left_rounded),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: _pageIndex >= pageCount - 1
                    ? null
                    : () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                        );
                      },
                icon: const Icon(Icons.chevron_right_rounded),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const Text(
            'Use the arrows or swipe sideways to move through matching slots.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _AgentCard extends StatelessWidget {
  const _AgentCard({
    required this.item,
    this.onAction,
    this.onOpenSection,
  });

  final ChatCardItem item;
  final VoidCallback? onAction;
  final VoidCallback? onOpenSection;

  @override
  Widget build(BuildContext context) {
    final primaryTap = onAction ?? onOpenSection;

    return InkWell(
      onTap: primaryTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCE8E6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (item.badge.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F5F1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.badge,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            if (item.subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.description,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
            if (item.trailing.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                item.trailing,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
            if (item.actionLabel.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: onAction,
                  child: Text(item.actionLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SlotPreferenceSheet extends StatefulWidget {
  const _SlotPreferenceSheet({
    required this.doctorName,
    required this.suggestedDate,
    required this.scheduleId,
  });

  final String doctorName;
  final String suggestedDate;
  final String scheduleId;

  @override
  State<_SlotPreferenceSheet> createState() => _SlotPreferenceSheetState();
}

class _SlotPreferenceSheetState extends State<_SlotPreferenceSheet> {
  static const _periodOptions = <String>[
    'morning',
    'afternoon',
    'evening',
    '',
  ];

  DateTime? _selectedDate;
  String _selectedPeriod = 'morning';

  @override
  void initState() {
    super.initState();
    _selectedDate = _parseDate(widget.suggestedDate) ?? DateTime.now();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  void _submit() {
    final date = _selectedDate;
    if (date == null) return;

    final normalizedDate =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final suffix = _selectedPeriod.isEmpty ? '' : ' $_selectedPeriod';
    final labelPeriod = _selectedPeriod.isEmpty ? 'any time' : _selectedPeriod;
    Navigator.of(context).pop(
      _ChatUserRequest(
        command: 'show slots schedule ${widget.scheduleId} $normalizedDate$suffix',
        displayText: 'Show $labelPeriod slots for $normalizedDate',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = _selectedDate;
    final formattedDate = date == null
        ? 'Pick a date'
        : '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9E7E4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Choose slot preference',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                widget.doctorName,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Preferred date',
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(formattedDate),
              ),
              const SizedBox(height: 18),
              const Text(
                'Preferred time of day',
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in _periodOptions)
                    ChoiceChip(
                      label: Text(
                        option.isEmpty
                            ? 'Any time'
                            : '${option[0].toUpperCase()}${option.substring(1)}',
                      ),
                      selected: _selectedPeriod == option,
                      onSelected: (_) {
                        setState(() => _selectedPeriod = option);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'We will ask the backend for slots on this date and filter by your preferred time of day first.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Show matching slots'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: Color(0xFFD9EFEB),
          foregroundColor: AppColors.primaryDark,
          child: Icon(Icons.auto_awesome_outlined, size: 16),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAF9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE0EBE9)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _TypingDot(),
              SizedBox(width: 4),
              _TypingDot(),
              SizedBox(width: 4),
              _TypingDot(),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypingDot extends StatelessWidget {
  const _TypingDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.isBusy,
  });

  final TextEditingController controller;
  final Future<void> Function([String? seededPrompt]) onSend;
  final bool isBusy;

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
              textInputAction: TextInputAction.send,
              decoration: const InputDecoration(
                hintText:
                    'Ask about symptoms, appointments, diagnostics, or invoices...',
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
            onPressed: isBusy ? null : () => onSend(),
            icon: Icon(
              isBusy ? Icons.hourglass_top_rounded : Icons.arrow_upward_rounded,
            ),
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

class _ChatUserRequest {
  const _ChatUserRequest({
    required this.command,
    required this.displayText,
  });

  final String command;
  final String displayText;
}

String? _sectionForType(String messageType) {
  final type = messageType.toLowerCase();
  if (type.contains('doctor') || type.contains('slot') || type.contains('appointment')) {
    return 'doctors';
  }
  if (type.contains('lab') ||
      type.contains('test') ||
      type.contains('diagnostic')) {
    return 'diagnostics';
  }
  if (type.contains('invoice')) return 'invoices';
  if (type.contains('report')) return 'reports';
  if (type.contains('prescription')) return 'prescriptions';
  return null;
}

DateTime? _parseDate(String raw) {
  if (raw.trim().isEmpty) return null;
  return DateTime.tryParse(raw.trim());
}

String _previousUserPrompt(List<ChatMessageRecord> messages, int index) {
  for (var cursor = index - 1; cursor >= 0; cursor--) {
    final candidate = messages[cursor];
    if (candidate.role == 'user' && candidate.text.trim().isNotEmpty) {
      return candidate.text.trim();
    }
  }
  return '';
}

List<ChatCardItem> _visibleChatItems(
  List<ChatCardItem> items, {
  required String previousUserPrompt,
}) {
  if (!_containsBookableSlotItems(items)) {
    return items;
  }

  final preferredPeriod = _preferredPeriodFromPrompt(previousUserPrompt);
  final filtered = preferredPeriod.isEmpty
      ? items
      : items
            .where((item) => _matchesPreferredPeriod(item, preferredPeriod))
            .toList();

  if (filtered.isNotEmpty) {
    return filtered;
  }

  return [
    ChatCardItem(
      title: 'No matching slots',
      subtitle: preferredPeriod[0].toUpperCase() + preferredPeriod.substring(1),
      description:
          'No slots matched your selected time of day. Try another period or pick any time.',
    ),
  ];
}

bool _containsBookableSlotItems(List<ChatCardItem> items) {
  return items.any((item) => _isBookableSlotItem(item));
}

bool _isBookableSlotItem(ChatCardItem item) {
  final prompt = item.actionPrompt.toLowerCase();
  return item.actionLabel.toLowerCase() == 'book this slot' ||
      prompt.startsWith('book schedule');
}

String _preferredPeriodFromPrompt(String prompt) {
  final normalized = prompt.toLowerCase();
  if (normalized.contains(' morning')) return 'morning';
  if (normalized.contains(' afternoon')) return 'afternoon';
  if (normalized.contains(' evening')) return 'evening';
  return '';
}

bool _matchesPreferredPeriod(ChatCardItem item, String period) {
  final hour = _extractHourFromDisplayText(item.description);
  if (hour == null) return true;

  switch (period) {
    case 'morning':
      return hour >= 5 && hour < 12;
    case 'afternoon':
      return hour >= 12 && hour < 17;
    case 'evening':
      return hour >= 17 && hour < 23;
    default:
      return true;
  }
}

int? _extractHourFromDisplayText(String text) {
  final match = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false)
      .firstMatch(text);
  if (match == null) return null;

  final rawHour = int.tryParse(match.group(1) ?? '');
  final meridiem = (match.group(3) ?? '').toUpperCase();
  if (rawHour == null || rawHour < 1 || rawHour > 12) {
    return null;
  }

  if (meridiem == 'AM') {
    return rawHour == 12 ? 0 : rawHour;
  }

  return rawHour == 12 ? 12 : rawHour + 12;
}

bool _shouldShowActionControls(ChatMessageRecord message) {
  if (message.actionId == null) return false;

  final haystack = [
    message.messageType,
    message.text,
    for (final item in message.items) item.title,
    for (final item in message.items) item.subtitle,
  ].join(' ').toLowerCase();

  return haystack.contains('confirm') ||
      haystack.contains('draft') ||
      haystack.contains('payment') ||
      haystack.contains('booking');
}

String _primaryActionLabel(ChatMessageRecord message) {
  final haystack = [
    message.messageType,
    message.text,
    for (final item in message.items) item.title,
    for (final item in message.items) item.trailing,
    for (final item in message.items) item.description,
  ].join(' ').toLowerCase();

  if (haystack.contains('payment') || haystack.contains('pay for')) {
    return 'Payment completed';
  }
  if (haystack.contains('draft') || haystack.contains('confirm')) {
    return 'Confirm booking';
  }
  return 'Continue';
}

String _secondaryActionLabel(ChatMessageRecord message) {
  final haystack = [
    message.messageType,
    message.text,
    for (final item in message.items) item.title,
    for (final item in message.items) item.trailing,
  ].join(' ').toLowerCase();

  if (haystack.contains('payment') || haystack.contains('pay for')) {
    return 'Back';
  }
  return 'Cancel';
}
