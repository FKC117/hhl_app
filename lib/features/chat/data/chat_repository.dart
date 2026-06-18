import '../../../core/api/api_client.dart';
import '../../../core/config/api_config.dart';
import 'chat_models.dart';

class ChatRepository {
  ChatRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ChatSessionRecord> createSession({
    required String accessToken,
  }) async {
    final json = await _postWithFallback(
      accessToken: accessToken,
      candidates: [
        _EndpointCandidate(
          baseUrl: ApiConfig.apiBaseUrl,
          path: '/chat/sessions/',
        ),
        _EndpointCandidate(
          baseUrl: ApiConfig.apiRootUrl,
          path: '/api/v1/chat/sessions/',
        ),
      ],
      body: const {},
    );

    return ChatSessionRecord.fromJson(json);
  }

  Future<List<ChatMessageRecord>> fetchMessages({
    required String sessionId,
    required String accessToken,
  }) async {
    final json = await _getWithFallback(
      accessToken: accessToken,
      candidates: [
        _EndpointCandidate(
          baseUrl: ApiConfig.apiBaseUrl,
          path: '/chat/sessions/$sessionId/messages/',
        ),
        _EndpointCandidate(
          baseUrl: ApiConfig.apiRootUrl,
          path: '/api/v1/chat/sessions/$sessionId/messages/',
        ),
      ],
    );

    return _extractMessages(json);
  }

  Future<ChatSendResult> sendMessage({
    required String sessionId,
    required String text,
    required String accessToken,
  }) async {
    final json = await _postWithFallback(
      accessToken: accessToken,
      candidates: [
        _EndpointCandidate(
          baseUrl: ApiConfig.apiBaseUrl,
          path: '/chat/sessions/$sessionId/messages/',
        ),
        _EndpointCandidate(
          baseUrl: ApiConfig.apiRootUrl,
          path: '/api/v1/chat/sessions/$sessionId/messages/',
        ),
      ],
      body: {
        'content': text,
        'client_message_id': 'flutter-${DateTime.now().millisecondsSinceEpoch}',
        'metadata': {'channel': 'mobile'},
      },
    );

    final messages = _extractMessages(json);
    final jobId = _firstNonEmpty([
      '${json['job_id'] ?? ''}',
      '${(json['job'] is Map<String, dynamic> ? (json['job'] as Map<String, dynamic>)['id'] : '')}',
    ]);

    return ChatSendResult(
      messages: messages,
      jobId: jobId.isEmpty ? null : jobId,
      jobStatus: _firstNonEmpty([
        '${(json['job'] is Map<String, dynamic> ? (json['job'] as Map<String, dynamic>)['status'] : '')}',
        '${json['status'] ?? ''}',
      ]),
    );
  }

  Future<ChatSendResult> confirmJob({
    required String jobId,
    required String accessToken,
  }) async {
    final json = await _postWithFallback(
      accessToken: accessToken,
      candidates: [
        _EndpointCandidate(
          baseUrl: ApiConfig.apiBaseUrl,
          path: '/chat/actions/$jobId/confirm/',
        ),
        _EndpointCandidate(
          baseUrl: ApiConfig.apiRootUrl,
          path: '/api/v1/chat/actions/$jobId/confirm/',
        ),
      ],
      body: const {},
    );

    final messages = _extractMessages(json);
    final returnedJobId = _firstNonEmpty([
      '${json['job_id'] ?? ''}',
      '${(json['job'] is Map<String, dynamic> ? (json['job'] as Map<String, dynamic>)['id'] : '')}',
    ]);

    return ChatSendResult(
      messages: messages,
      jobId: returnedJobId.isEmpty ? null : returnedJobId,
      jobStatus: _firstNonEmpty([
        '${(json['job'] is Map<String, dynamic> ? (json['job'] as Map<String, dynamic>)['status'] : '')}',
        '${json['status'] ?? ''}',
      ]),
    );
  }

  Future<ChatSendResult> cancelJob({
    required String jobId,
    required String accessToken,
  }) async {
    final json = await _postWithFallback(
      accessToken: accessToken,
      candidates: [
        _EndpointCandidate(
          baseUrl: ApiConfig.apiBaseUrl,
          path: '/chat/actions/$jobId/reject/',
        ),
        _EndpointCandidate(
          baseUrl: ApiConfig.apiRootUrl,
          path: '/api/v1/chat/actions/$jobId/reject/',
        ),
      ],
      body: const {},
    );

    final messages = _extractMessages(json);
    final returnedJobId = _firstNonEmpty([
      '${json['job_id'] ?? ''}',
      '${(json['job'] is Map<String, dynamic> ? (json['job'] as Map<String, dynamic>)['id'] : '')}',
    ]);

    return ChatSendResult(
      messages: messages,
      jobId: returnedJobId.isEmpty ? null : returnedJobId,
      jobStatus: _firstNonEmpty([
        '${(json['job'] is Map<String, dynamic> ? (json['job'] as Map<String, dynamic>)['status'] : '')}',
        '${json['status'] ?? ''}',
      ]),
    );
  }

  Future<ChatSendResult> fetchJob({
    required String jobId,
    required String accessToken,
  }) async {
    final json = await _getWithFallback(
      accessToken: accessToken,
      candidates: [
        _EndpointCandidate(
          baseUrl: ApiConfig.apiBaseUrl,
          path: '/chat/jobs/$jobId/',
        ),
        _EndpointCandidate(
          baseUrl: ApiConfig.apiRootUrl,
          path: '/api/v1/chat/jobs/$jobId/',
        ),
      ],
    );

    final outputPayload = json['output_payload'];
    final output = outputPayload is Map<String, dynamic>
        ? outputPayload
        : <String, dynamic>{};

    final actionId = _firstNonEmpty([
      '${json['action_id'] ?? ''}',
      '${output['action_id'] ?? ''}',
      '${(output['action'] is Map<String, dynamic> ? (output['action'] as Map<String, dynamic>)['id'] : '')}',
      '${(output['pending_action'] is Map<String, dynamic> ? (output['pending_action'] as Map<String, dynamic>)['id'] : '')}',
    ]);

    final messages = [
      ..._extractMessages(json),
      ..._extractMessages(output),
    ];

    final decorated = actionId.isEmpty
        ? messages
        : messages
              .map(
                (message) => ChatMessageRecord(
                  id: message.id,
                  role: message.role,
                  text: message.text,
                  messageType: message.messageType,
                  items: message.items,
                  quickReplies: message.quickReplies,
                  jobId: message.jobId,
                  actionId: message.actionId ?? actionId,
                ),
              )
              .toList();

    return ChatSendResult(messages: decorated, jobId: null);
  }

  Future<int> initiateManualPayment({
    required String sourceType,
    required String sourceId,
    required String gateway,
    required String accessToken,
    String initiateUrl = '/api/v1/payments/initiate/',
  }) async {
    final json = await _apiClient.postJson(
      ApiConfig.apiRootUrl,
      initiateUrl,
      headers: {'Authorization': 'Bearer $accessToken'},
      body: {
        'source_type': sourceType,
        'source_id': int.tryParse(sourceId) ?? sourceId,
        'gateway': gateway.isEmpty ? 'manual' : gateway,
      },
    );

    final paymentId =
        json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0;
    if (paymentId <= 0) {
      throw const ApiException('Payment initiation succeeded without a valid payment id.');
    }
    return paymentId;
  }

  Future<void> completeManualPayment({
    required int paymentId,
    required String accessToken,
    String completeUrlTemplate = '/api/v1/payments/{payment_id}/complete/',
  }) async {
    final completeUrl = completeUrlTemplate.replaceAll('{payment_id}', '$paymentId');
    await _apiClient.postJson(
      ApiConfig.apiRootUrl,
      completeUrl,
      headers: {'Authorization': 'Bearer $accessToken'},
      body: const {},
    );
  }

  Future<Map<String, dynamic>> confirmPaymentSource({
    required String confirmUrl,
    required int paymentId,
    required String accessToken,
  }) {
    return _apiClient.postJson(
      ApiConfig.apiRootUrl,
      confirmUrl,
      headers: {'Authorization': 'Bearer $accessToken'},
      body: {'payment_id': paymentId},
    );
  }

  Future<Map<String, dynamic>> _getWithFallback({
    required String accessToken,
    required List<_EndpointCandidate> candidates,
  }) async {
    ApiException? lastError;

    for (final candidate in candidates) {
      try {
        return await _apiClient.getJson(
          candidate.baseUrl,
          candidate.path,
          headers: {'Authorization': 'Bearer $accessToken'},
        );
      } on ApiException catch (error) {
        lastError = error;
      }
    }

    throw lastError ??
        const ApiException('Could not reach the chat endpoint.');
  }

  Future<Map<String, dynamic>> _postWithFallback({
    required String accessToken,
    required List<_EndpointCandidate> candidates,
    required Map<String, dynamic> body,
  }) async {
    ApiException? lastError;

    for (final candidate in candidates) {
      try {
        return await _apiClient.postJson(
          candidate.baseUrl,
          candidate.path,
          headers: {'Authorization': 'Bearer $accessToken'},
          body: body,
        );
      } on ApiException catch (error) {
        lastError = error;
      }
    }

    throw lastError ??
        const ApiException('Could not reach the chat endpoint.');
  }

  List<ChatMessageRecord> _extractMessages(Map<String, dynamic> json) {
    final rawList =
        _asList(json['messages']) ??
        _asList(json['results']) ??
        _asList(json['data']) ??
        _asList(json['items']) ??
        _asList(json['conversation']);

    if (rawList != null) {
      return rawList
          .whereType<Map<String, dynamic>>()
          .map(ChatMessageRecord.fromJson)
          .where(
            (message) =>
                message.text.isNotEmpty ||
                message.items.isNotEmpty ||
                message.quickReplies.isNotEmpty,
          )
          .toList();
    }

    if (json.containsKey('message') ||
        json.containsKey('text') ||
        json.containsKey('reply') ||
        json.containsKey('content') ||
        json.containsKey('response')) {
      final single = ChatMessageRecord.fromJson(json);
      if (single.text.isNotEmpty ||
          single.items.isNotEmpty ||
          single.quickReplies.isNotEmpty) {
        return [single];
      }
    }

    final assistant = json['assistant_message'];
    if (assistant is Map<String, dynamic>) {
      final single = ChatMessageRecord.fromJson(assistant);
      if (single.text.isNotEmpty || single.items.isNotEmpty) {
        return [single];
      }
    }

    return const [];
  }
}

class _EndpointCandidate {
  const _EndpointCandidate({
    required this.baseUrl,
    required this.path,
  });

  final String baseUrl;
  final String path;
}

List<dynamic>? _asList(dynamic value) {
  if (value is List<dynamic>) return value;
  return null;
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
