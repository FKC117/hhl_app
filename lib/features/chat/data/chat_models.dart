class ChatSessionRecord {
  const ChatSessionRecord({
    required this.id,
    this.title = '',
  });

  final String id;
  final String title;

  factory ChatSessionRecord.fromJson(Map<String, dynamic> json) {
    final nestedSession = _firstMap([
      json['session'],
      json['data'],
      json['result'],
      json['chat_session'],
      json['conversation'],
    ]);

    return ChatSessionRecord(
      id: _asString(
        json['id'] ??
            json['session_id'] ??
            json['chat_session_id'] ??
            nestedSession?['id'],
      ),
      title: _firstNonEmpty([
        '${json['title'] ?? ''}',
        '${json['name'] ?? ''}',
        '${json['session_name'] ?? ''}',
        '${nestedSession?['title'] ?? ''}',
        '${nestedSession?['name'] ?? ''}',
      ]),
    );
  }
}

class ChatMessageRecord {
  const ChatMessageRecord({
    required this.id,
    required this.role,
    required this.text,
    required this.messageType,
    this.items = const [],
    this.quickReplies = const [],
    this.jobId,
    this.actionId,
  });

  final String id;
  final String role;
  final String text;
  final String messageType;
  final List<ChatCardItem> items;
  final List<String> quickReplies;
  final String? jobId;
  final String? actionId;

  bool get isAssistant => role.toLowerCase() != 'user';

  factory ChatMessageRecord.fromJson(Map<String, dynamic> json) {
    final itemSource =
        _asList(json['items']) ??
        _asList(json['cards']) ??
        _asList(json['data']) ??
        _asList(json['results']) ??
        _extractItemsFromBlocks(json['blocks']) ??
        const <dynamic>[];
    final blockText = _textFromBlocks(json['blocks']);
    final blockReplies = _quickRepliesFromBlocks(json['blocks']);
    final blockActionId = _actionIdFromBlocks(json['blocks']);

    return ChatMessageRecord(
      id: _firstNonEmpty([
        '${json['id'] ?? ''}',
        '${json['message_id'] ?? ''}',
        '${json['uuid'] ?? ''}',
        '${DateTime.now().microsecondsSinceEpoch}',
      ]),
      role: _normalizeRole(
        _firstNonEmpty([
          '${json['role'] ?? ''}',
          '${json['sender_role'] ?? ''}',
          '${json['sender'] ?? ''}',
          '${json['author_type'] ?? ''}',
        ]),
      ),
      text: _firstNonEmpty([
        '${json['text'] ?? ''}',
        '${json['message'] ?? ''}',
        '${json['content'] ?? ''}',
        '${json['body'] ?? ''}',
        '${json['reply'] ?? ''}',
        '${json['response'] ?? ''}',
        blockText,
      ]),
      messageType: _firstNonEmpty([
        '${json['message_type'] ?? ''}',
        '${json['content_type'] ?? ''}',
        '${json['type'] ?? ''}',
        'text',
      ]),
      items: itemSource
          .map(ChatCardItem.fromDynamic)
          .where((item) => item.title.isNotEmpty || item.description.isNotEmpty)
          .toList(),
      quickReplies: _extractQuickReplies(
        json['quick_replies'] ?? json['suggestions'] ?? json['replies'],
      ).followedBy(blockReplies).toSet().toList(),
      jobId: _asNullableString(
        json['job_id'] ??
            (json['job'] is Map<String, dynamic>
                ? (json['job'] as Map<String, dynamic>)['id']
                : null),
      ),
      actionId: _asNullableString(
        json['action_id'] ??
            (json['action'] is Map<String, dynamic>
                ? (json['action'] as Map<String, dynamic>)['id']
                : null) ??
            blockActionId,
      ),
    );
  }
}

class ChatCardItem {
  const ChatCardItem({
    required this.title,
    this.subtitle = '',
    this.description = '',
    this.badge = '',
    this.trailing = '',
    this.actionLabel = '',
    this.actionPrompt = '',
    this.scheduleId = '',
    this.suggestedDate = '',
    this.blockType = '',
    this.submitPrefix = '',
    this.minDate = '',
    this.paymentSourceType = '',
    this.paymentSourceId = '',
    this.paymentGateway = '',
    this.paymentInitiateUrl = '',
    this.paymentCompleteUrlTemplate = '',
    this.paymentConfirmUrl = '',
    this.paymentSuccessMessage = '',
    this.documentId = 0,
    this.downloadPath = '',
    this.fileName = '',
  });

  final String title;
  final String subtitle;
  final String description;
  final String badge;
  final String trailing;
  final String actionLabel;
  final String actionPrompt;
  final String scheduleId;
  final String suggestedDate;
  final String blockType;
  final String submitPrefix;
  final String minDate;
  final String paymentSourceType;
  final String paymentSourceId;
  final String paymentGateway;
  final String paymentInitiateUrl;
  final String paymentCompleteUrlTemplate;
  final String paymentConfirmUrl;
  final String paymentSuccessMessage;
  final int documentId;
  final String downloadPath;
  final String fileName;

  factory ChatCardItem.fromDynamic(dynamic raw) {
    if (raw is String) {
      return ChatCardItem(title: raw.trim());
    }

    if (raw is! Map<String, dynamic>) {
      return const ChatCardItem(title: '');
    }

    return ChatCardItem(
      title: _firstNonEmpty([
        '${raw['title'] ?? ''}',
        '${raw['name'] ?? ''}',
        '${raw['doctor_name'] ?? ''}',
        '${raw['lab_name'] ?? ''}',
        '${raw['test_name'] ?? ''}',
        '${raw['invoice_number'] ?? ''}',
        '${raw['label'] ?? ''}',
      ]),
      subtitle: _firstNonEmpty([
        '${raw['subtitle'] ?? ''}',
        '${raw['specialty'] ?? ''}',
        '${raw['department'] ?? ''}',
        '${raw['designation'] ?? ''}',
        '${raw['type'] ?? ''}',
        '${raw['status'] ?? ''}',
      ]),
      description: _firstNonEmpty([
        '${raw['description'] ?? ''}',
        '${raw['summary'] ?? ''}',
        '${raw['details'] ?? ''}',
        _joinNonEmpty([
          '${raw['designation'] ?? ''}',
          '${raw['qualification'] ?? ''}',
          _experienceLabel(raw['experience_years']),
        ]),
        _joinNonEmpty([
          '${raw['date'] ?? ''}',
          _formatDisplayTime(raw['time']),
          '${raw['mode'] ?? ''}',
        ]),
      ]),
      badge: _firstNonEmpty([
        '${raw['badge'] ?? ''}',
        '${raw['price'] ?? ''}',
        '${raw['fee'] ?? ''}',
        '${raw['amount'] ?? ''}',
        _doctorFeeBadge(raw),
      ]),
      trailing: _firstNonEmpty([
        '${raw['trailing'] ?? ''}',
        '${raw['cta'] ?? ''}',
        '${raw['action_label'] ?? ''}',
        _scheduleSummary(raw['schedule_summaries']),
      ]),
      actionLabel: _firstNonEmpty([
        '${raw['action_label'] ?? ''}',
        _doctorActionLabel(raw['schedule_summaries']),
      ]),
      actionPrompt: _firstNonEmpty([
        '${raw['action_prompt'] ?? ''}',
        _doctorActionPrompt(raw['schedule_summaries']),
      ]),
      scheduleId: _firstNonEmpty([
        '${raw['schedule_id'] ?? ''}',
        _doctorScheduleId(raw['schedule_summaries']),
      ]),
      suggestedDate: _firstNonEmpty([
        '${raw['next_available_date'] ?? ''}',
        _doctorSuggestedDate(raw['schedule_summaries']),
      ]),
      blockType: '${raw['block_type'] ?? ''}'.trim(),
      submitPrefix: '${raw['submit_prefix'] ?? ''}'.trim(),
      minDate: '${raw['min_date'] ?? ''}'.trim(),
      paymentSourceType: '${raw['payment_source_type'] ?? ''}'.trim(),
      paymentSourceId: '${raw['payment_source_id'] ?? ''}'.trim(),
      paymentGateway: '${raw['payment_gateway'] ?? ''}'.trim(),
      paymentInitiateUrl: '${raw['payment_initiate_url'] ?? ''}'.trim(),
      paymentCompleteUrlTemplate:
          '${raw['payment_complete_url_template'] ?? ''}'.trim(),
      paymentConfirmUrl: '${raw['payment_confirm_url'] ?? ''}'.trim(),
      paymentSuccessMessage: '${raw['payment_success_message'] ?? ''}'.trim(),
      documentId: raw['document_id'] is int
          ? raw['document_id'] as int
          : int.tryParse('${raw['document_id'] ?? raw['id'] ?? '0'}') ?? 0,
      downloadPath: _normalizeDownloadPath(
        _firstNonEmpty([
          '${raw['download_path'] ?? ''}',
          '${raw['download_url'] ?? ''}',
        ]),
      ),
      fileName: '${raw['file_name'] ?? ''}'.trim(),
    );
  }
}

class ChatSendResult {
  const ChatSendResult({
    required this.messages,
    this.jobId,
    this.jobStatus,
  });

  final List<ChatMessageRecord> messages;
  final String? jobId;
  final String? jobStatus;
}

String _asString(dynamic value) => '${value ?? ''}'.trim();

String? _asNullableString(dynamic value) {
  final parsed = '${value ?? ''}'.trim();
  return parsed.isEmpty || parsed.toLowerCase() == 'null' ? null : parsed;
}

String _firstNonEmpty(List<String> values) {
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty && trimmed.toLowerCase() != 'null') {
      return trimmed;
    }
  }
  return '';
}

String _joinNonEmpty(List<String> values) {
  final parts = values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty && value.toLowerCase() != 'null')
      .toList();
  return parts.join(' | ');
}

String _experienceLabel(dynamic raw) {
  final value = '${raw ?? ''}'.trim();
  if (value.isEmpty || value.toLowerCase() == 'null') {
    return '';
  }
  return '$value yrs exp';
}

String _doctorFeeBadge(Map<String, dynamic> raw) {
  final online = '${raw['consultation_fee_online'] ?? ''}'.trim();
  final offline = '${raw['consultation_fee_offline'] ?? ''}'.trim();
  if (online.isNotEmpty && online.toLowerCase() != 'null') {
    return 'Online BDT $online';
  }
  if (offline.isNotEmpty && offline.toLowerCase() != 'null') {
    return 'Offline BDT $offline';
  }
  return '';
}

String _scheduleSummary(dynamic raw) {
  if (raw is! List || raw.isEmpty) return '';

  final first = raw.first;
  if (first is! Map<String, dynamic>) return '';

  final nextDate = '${first['next_available_date'] ?? ''}'.trim();
  final weekday = '${first['weekday'] ?? ''}'.trim();
  final mode = '${first['mode'] ?? ''}'.trim();
  final slots = _asList(first['next_available_slots']) ?? const <dynamic>[];
  final firstSlot = slots.isEmpty ? '' : _formatDisplayTime(slots.first);

  return _joinNonEmpty([
    if (weekday.isNotEmpty) weekday,
    if (mode.isNotEmpty) mode,
    if (nextDate.isNotEmpty) 'Next $nextDate',
    if (firstSlot.isNotEmpty) 'From $firstSlot',
  ]);
}

String _doctorActionLabel(dynamic raw) {
  if (raw is! List || raw.isEmpty) return '';
  return 'Show slots';
}

String _doctorActionPrompt(dynamic raw) {
  if (raw is! List || raw.isEmpty) return '';

  Map<String, dynamic>? preferred;
  for (final item in raw) {
    if (item is! Map<String, dynamic>) continue;
    final nextDate = '${item['next_available_date'] ?? ''}'.trim();
    if (nextDate.isNotEmpty) {
      preferred = item;
      break;
    }
    preferred ??= item;
  }

  if (preferred == null) return '';

  final scheduleId = '${preferred['schedule_id'] ?? ''}'.trim();
  final nextDate = '${preferred['next_available_date'] ?? ''}'.trim();
  if (scheduleId.isEmpty || nextDate.isEmpty) return '';

  return 'show slots schedule $scheduleId $nextDate';
}

String _doctorScheduleId(dynamic raw) {
  if (raw is! List || raw.isEmpty) return '';
  for (final item in raw) {
    if (item is! Map<String, dynamic>) continue;
    final scheduleId = '${item['schedule_id'] ?? ''}'.trim();
    if (scheduleId.isNotEmpty) {
      return scheduleId;
    }
  }
  return '';
}

String _doctorSuggestedDate(dynamic raw) {
  if (raw is! List || raw.isEmpty) return '';
  for (final item in raw) {
    if (item is! Map<String, dynamic>) continue;
    final nextDate = '${item['next_available_date'] ?? ''}'.trim();
    if (nextDate.isNotEmpty) {
      return nextDate;
    }
  }
  return '';
}

String _normalizeRole(String raw) {
  final value = raw.trim().toLowerCase();
  if (value == 'patient' || value == 'user') return 'user';
  if (value == 'assistant' || value == 'system' || value == 'agent') {
    return 'assistant';
  }
  return value.isEmpty ? 'assistant' : value;
}

String _normalizeDownloadPath(String raw) {
  final value = raw.trim();
  if (value.isEmpty || value.toLowerCase() == 'null') {
    return '';
  }
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) {
    return uri.path;
  }
  return value;
}

String _formatDisplayTime(dynamic raw) {
  final value = '${raw ?? ''}'.trim();
  if (value.isEmpty || value.toLowerCase() == 'null') {
    return '';
  }

  final match = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$').firstMatch(value);
  if (match == null) {
    return value;
  }

  final hour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '');
  if (hour == null || minute == null || hour > 23 || minute > 59) {
    return value;
  }

  final suffix = hour >= 12 ? 'PM' : 'AM';
  final normalizedHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$normalizedHour:${minute.toString().padLeft(2, '0')} $suffix';
}

List<dynamic>? _asList(dynamic value) {
  if (value is List<dynamic>) return value;
  return null;
}

Map<String, dynamic>? _firstMap(List<dynamic> values) {
  for (final value in values) {
    if (value is Map<String, dynamic>) {
      return value;
    }
  }
  return null;
}

List<String> _extractQuickReplies(dynamic raw) {
  if (raw is! List) return const [];

  return raw.map((item) {
    if (item is String) return item.trim();
    if (item is Map<String, dynamic>) {
      return _firstNonEmpty([
        '${item['label'] ?? ''}',
        '${item['title'] ?? ''}',
        '${item['text'] ?? ''}',
        '${item['prompt'] ?? ''}',
      ]);
    }
    return '';
  }).where((value) => value.isNotEmpty).toList();
}

String _textFromBlocks(dynamic raw) {
  if (raw is! List) return '';

  final parts = <String>[];
  for (final item in raw) {
    if (item is String) {
      final value = item.trim();
      if (value.isNotEmpty) {
        parts.add(value);
      }
      continue;
    }

    if (item is! Map<String, dynamic>) continue;

    final value = _firstNonEmpty([
      '${item['text'] ?? ''}',
      '${item['content'] ?? ''}',
      '${item['message'] ?? ''}',
      '${item['body'] ?? ''}',
      '${item['markdown'] ?? ''}',
      '${item['title'] ?? ''}',
      '${item['description'] ?? ''}',
      '${item['subtitle'] ?? ''}',
    ]);
    if (value.isNotEmpty) {
      parts.add(value);
    }

    final nestedItems =
        _asList(item['items']) ??
        _asList(item['cards']) ??
        _asList(item['options']) ??
        _asList(item['actions']);
    if (nestedItems != null) {
      for (final nested in nestedItems) {
        if (nested is Map<String, dynamic>) {
          final nestedValue = _firstNonEmpty([
            '${nested['text'] ?? ''}',
            '${nested['label'] ?? ''}',
            '${nested['title'] ?? ''}',
            '${nested['description'] ?? ''}',
          ]);
          if (nestedValue.isNotEmpty) {
            parts.add(nestedValue);
          }
        }
      }
    }
  }

  return parts.join('\n\n').trim();
}

List<String> _quickRepliesFromBlocks(dynamic raw) {
  if (raw is! List) return const [];

  final replies = <String>[];
  for (final item in raw) {
    if (item is! Map<String, dynamic>) continue;

    final nestedItems =
        _asList(item['suggestions']) ??
        _asList(item['quick_replies']) ??
        _asList(item['replies']) ??
        _asList(item['options']) ??
        _asList(item['actions']);
    if (nestedItems == null) continue;

    replies.addAll(_extractQuickReplies(nestedItems));
  }

  return replies.where((value) => value.isNotEmpty).toList();
}

List<dynamic>? _extractItemsFromBlocks(dynamic raw) {
  if (raw is! List) return null;

  final items = <dynamic>[];
  for (final block in raw) {
    if (block is! Map<String, dynamic>) continue;

    final data = block['data'];
    final type = '${block['type'] ?? ''}'.trim().toLowerCase();

    if (data is Map<String, dynamic>) {
      final nestedItems = _asList(data['items']);
      if (nestedItems != null) {
        items.addAll(nestedItems);
      }

      if (type == 'slot_cards') {
        final slots = _asList(data['slots']) ?? const <dynamic>[];
        final scheduleId = '${data['schedule_id'] ?? ''}'.trim();
        final appointmentDate = '${data['date'] ?? ''}'.trim();
        for (final slot in slots) {
          if (slot is Map<String, dynamic>) {
            final rawTime = '${slot['time'] ?? ''}'.trim();
            final bookMessage = _firstNonEmpty([
              _slotBookingPrompt(
                scheduleId: scheduleId,
                appointmentDate: appointmentDate,
                appointmentTime: rawTime,
              ),
              '${slot['book_message'] ?? ''}',
            ]);
            items.add({
              'title': '${data['doctor_name'] ?? 'Available slot'}'.trim(),
              'subtitle': _joinNonEmpty([
                '${data['date'] ?? ''}',
                '${data['mode'] ?? ''}',
              ]),
              'description': rawTime,
              'trailing': _firstNonEmpty([
                '${data['department'] ?? ''}',
                '${data['designation'] ?? ''}',
              ]),
              'action_label': bookMessage.isNotEmpty
                  ? 'Book this slot'
                  : '',
              'action_prompt': bookMessage,
            });
          }
        }
      }

      if (type == 'confirmation_card' || type == 'payment_handoff') {
        final summary = data['summary'];
        final summaryMap = summary is Map<String, dynamic> ? summary : <String, dynamic>{};
        items.add({
          'title': _firstNonEmpty([
            type == 'payment_handoff' ? 'Complete payment' : '',
            '${data['title'] ?? ''}',
            '${data['action'] ?? ''}',
            type == 'payment_handoff' ? 'Payment' : 'Confirmation',
          ]),
          'subtitle': _firstNonEmpty([
            '${summaryMap['doctor_name'] ?? ''}',
            '${summaryMap['lab_name'] ?? ''}',
            '${summaryMap['department'] ?? ''}',
          ]),
          'description': _joinNonEmpty([
            '${summaryMap['appointment_date'] ?? ''}',
            '${summaryMap['appointment_time'] ?? ''}',
            '${summaryMap['mode'] ?? ''}',
            '${summaryMap['patient_note'] ?? ''}',
          ]),
          'badge': _firstNonEmpty([
            '${summaryMap['fee'] ?? ''}',
            '${summaryMap['amount'] ?? ''}',
          ]),
          'trailing': _firstNonEmpty([
            type == 'payment_handoff'
                ? 'No gateway yet. Tapping continue will mark this as paid.'
                : '',
          ]),
          'action_label': type == 'payment_handoff' ? 'Continue' : '',
          'block_type': type,
          'payment_source_type': '${summaryMap['source_type'] ?? ''}'.trim(),
          'payment_source_id': '${summaryMap['source_id'] ?? ''}'.trim(),
          'payment_gateway': '${summaryMap['gateway'] ?? 'manual'}'.trim(),
          'payment_initiate_url': '${data['initiate_url'] ?? ''}'.trim(),
          'payment_complete_url_template':
              '${data['complete_url_template'] ?? ''}'.trim(),
          'payment_confirm_url': '${data['confirm_url'] ?? ''}'.trim(),
          'payment_success_message': '${data['success_message'] ?? ''}'.trim(),
        });
      }

      if (type == 'date_picker') {
        items.add({
          'title': 'Choose date',
          'subtitle': '${data['min_date'] ?? ''}'.trim(),
          'description': '${data['prompt'] ?? ''}'.trim(),
          'action_label': 'Pick a date',
          'block_type': type,
          'submit_prefix': '${data['submit_prefix'] ?? ''}'.trim(),
          'min_date': '${data['min_date'] ?? ''}'.trim(),
        });
      }

      if (type == 'date_suggestions') {
        final dates = _asList(data['dates']) ?? const <dynamic>[];
        final submitPrefix = '${data['submit_prefix'] ?? ''}'.trim();
        final prompt = '${data['prompt'] ?? ''}'.trim();
        for (final date in dates) {
          if (date is! Map<String, dynamic>) continue;
          final isoDate = '${date['date'] ?? ''}'.trim();
          if (isoDate.isEmpty) continue;
          items.add({
            'title': '${date['label'] ?? isoDate}'.trim(),
            'subtitle': 'Suggested date',
            'description': prompt,
            'action_label': 'Use this date',
            'action_prompt': submitPrefix.isEmpty ? isoDate : '$submitPrefix on $isoDate',
            'suggested_date': isoDate,
            'block_type': type,
            'submit_prefix': submitPrefix,
          });
        }
      }
    }
  }

  return items.isEmpty ? null : items;
}

String _slotBookingPrompt({
  required String scheduleId,
  required String appointmentDate,
  required String appointmentTime,
}) {
  final normalizedScheduleId = scheduleId.trim();
  final normalizedDate = appointmentDate.trim();
  final normalizedTime = appointmentTime.trim();
  if (normalizedScheduleId.isEmpty ||
      normalizedDate.isEmpty ||
      normalizedTime.isEmpty) {
    return '';
  }

  return 'book schedule $normalizedScheduleId $normalizedDate $normalizedTime';
}

String? _actionIdFromBlocks(dynamic raw) {
  if (raw is! List) return null;

  for (final block in raw) {
    if (block is! Map<String, dynamic>) continue;

    final actions = _asList(block['actions']) ?? const <dynamic>[];
    for (final action in actions) {
      if (action is! Map<String, dynamic>) continue;
      final actionId = _asNullableString(action['action_id']);
      if (actionId != null) {
        return actionId;
      }
    }

    final data = block['data'];
    if (data is Map<String, dynamic>) {
      final actionId = _asNullableString(
        data['action_id'] ?? data['pending_action_id'],
      );
      if (actionId != null) {
        return actionId;
      }
    }
  }

  return null;
}
