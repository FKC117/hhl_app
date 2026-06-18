import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/app_session.dart';
import '../data/chat_models.dart';
import '../data/chat_repository.dart';
import '../../invoices/data/invoice_item.dart';
import '../../invoices/data/invoices_repository.dart';

class ChatController extends ChangeNotifier {
  ChatController({ChatRepository? repository})
    : _repository = repository ?? ChatRepository(),
      _invoicesRepository = InvoicesRepository() {
    _messages.add(
      const ChatMessageRecord(
        id: 'seed-assistant',
        role: 'assistant',
        text:
            'Hello. I am your HHL care assistant. I can help you find a doctor, arrange tests, check invoices, and guide your next step.',
        messageType: 'text',
      ),
    );
  }

  final ChatRepository _repository;
  final InvoicesRepository _invoicesRepository;
  final List<ChatMessageRecord> _messages = [];

  String? _sessionId;
  int _localMessageSeed = 0;

  bool isSending = false;
  String? errorMessage;

  List<ChatMessageRecord> get messages => List.unmodifiable(_messages);

  Future<void> sendMessage({
    required String text,
    String? displayText,
    required AppSession session,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isSending) return;
    final visibleText = (displayText ?? trimmed).trim();

    _messages.add(
      ChatMessageRecord(
        id: 'local-user-${_localMessageSeed++}',
        role: 'user',
        text: visibleText,
        messageType: 'text',
      ),
    );
    errorMessage = null;
    isSending = true;
    notifyListeners();

    try {
      await _ensureSession(session);

      final result = await session.withFreshToken(
        (accessToken) => _repository.sendMessage(
          sessionId: _sessionId!,
          text: trimmed,
          accessToken: accessToken,
        ),
      );

      if (result.jobId != null && result.jobId!.isNotEmpty) {
        final polled = await _pollJob(result.jobId!, session);
        if (polled.isNotEmpty) {
          _mergeMessages(polled);
        }

        final refreshed = await session.withFreshToken(
          (accessToken) => _repository.fetchMessages(
            sessionId: _sessionId!,
            accessToken: accessToken,
          ),
        );
        _mergeMessages(refreshed);
      } else if (result.messages.isEmpty) {
        final refreshed = await session.withFreshToken(
          (accessToken) => _repository.fetchMessages(
            sessionId: _sessionId!,
            accessToken: accessToken,
          ),
        );
        _mergeMessages(refreshed);
      } else {
        _mergeMessages(result.messages);
      }
    } on ApiException catch (error) {
      errorMessage = _humanizeAgentError(error);
      _messages.add(
        ChatMessageRecord(
          id: 'local-error-${_localMessageSeed++}',
          role: 'assistant',
          text: errorMessage!,
          messageType: 'text',
        ),
      );
    } catch (_) {
      errorMessage =
          'Could not send the message to the care assistant right now.';
      _messages.add(
        ChatMessageRecord(
          id: 'local-error-${_localMessageSeed++}',
          role: 'assistant',
          text: errorMessage!,
          messageType: 'text',
        ),
      );
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> confirmJob({
    required String actionId,
    required AppSession session,
  }) async {
    if (isSending) return;

    isSending = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await session.withFreshToken(
        (accessToken) => _repository.confirmJob(
          jobId: actionId,
          accessToken: accessToken,
        ),
      );
      if (result.jobId != null && result.jobId!.isNotEmpty) {
        final polled = await _pollJob(result.jobId!, session);
        if (polled.isNotEmpty) {
          _mergeMessages(polled);
        }

        if (_sessionId != null) {
          final refreshed = await session.withFreshToken(
            (accessToken) => _repository.fetchMessages(
              sessionId: _sessionId!,
              accessToken: accessToken,
            ),
          );
          _mergeMessages(refreshed);
        }
      } else if (result.messages.isNotEmpty) {
        _mergeMessages(result.messages);
      }
    } on ApiException catch (error) {
      errorMessage = _humanizeAgentError(error);
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> cancelJob({
    required String actionId,
    required AppSession session,
  }) async {
    if (isSending) return;

    isSending = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await session.withFreshToken(
        (accessToken) => _repository.cancelJob(
          jobId: actionId,
          accessToken: accessToken,
        ),
      );
      if (result.jobId != null && result.jobId!.isNotEmpty) {
        final polled = await _pollJob(result.jobId!, session);
        if (polled.isNotEmpty) {
          _mergeMessages(polled);
        }

        if (_sessionId != null) {
          final refreshed = await session.withFreshToken(
            (accessToken) => _repository.fetchMessages(
              sessionId: _sessionId!,
              accessToken: accessToken,
            ),
          );
          _mergeMessages(refreshed);
        }
      } else if (result.messages.isNotEmpty) {
        _mergeMessages(result.messages);
      }
    } on ApiException catch (error) {
      errorMessage = _humanizeAgentError(error);
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> completePayment({
    required ChatCardItem item,
    required AppSession session,
  }) async {
    if (isSending) return;

    isSending = true;
    errorMessage = null;
    notifyListeners();

    try {
      final paymentId = await session.withFreshToken(
        (accessToken) => _repository.initiateManualPayment(
          sourceType: item.paymentSourceType,
          sourceId: item.paymentSourceId,
          gateway: item.paymentGateway,
          accessToken: accessToken,
          initiateUrl: item.paymentInitiateUrl.isEmpty
              ? '/api/v1/payments/initiate/'
              : item.paymentInitiateUrl,
        ),
      );

      await session.withFreshToken(
        (accessToken) => _repository.completeManualPayment(
          paymentId: paymentId,
          accessToken: accessToken,
          completeUrlTemplate: item.paymentCompleteUrlTemplate.isEmpty
              ? '/api/v1/payments/{payment_id}/complete/'
              : item.paymentCompleteUrlTemplate,
        ),
      );

      if (item.paymentConfirmUrl.isNotEmpty) {
        await session.withFreshToken(
          (accessToken) => _repository.confirmPaymentSource(
            confirmUrl: item.paymentConfirmUrl,
            paymentId: paymentId,
            accessToken: accessToken,
          ),
        );
      }

      _messages.add(
        ChatMessageRecord(
          id: 'local-payment-${_localMessageSeed++}',
          role: 'assistant',
          text: item.paymentSuccessMessage.isNotEmpty
              ? item.paymentSuccessMessage
              : 'Payment completed and the draft is now confirmed.',
          messageType: 'payment',
        ),
      );

      if (_sessionId != null) {
        final refreshed = await session.withFreshToken(
          (accessToken) => _repository.fetchMessages(
            sessionId: _sessionId!,
            accessToken: accessToken,
          ),
        );
        _mergeMessages(refreshed);
      }

      final sourceId = int.tryParse(item.paymentSourceId) ?? 0;
      if (sourceId > 0) {
        final invoices = await session.withFreshToken(
          (accessToken) => _invoicesRepository.fetchInvoices(accessToken: accessToken),
        );
        final matchingInvoice = _findMatchingInvoice(
          invoices,
          sourceType: item.paymentSourceType,
          sourceId: sourceId,
        );
        if (matchingInvoice != null) {
          _messages.add(
            ChatMessageRecord(
              id: 'local-invoice-${matchingInvoice.id}-${_localMessageSeed++}',
              role: 'assistant',
              text: 'Your invoice is ready.',
              messageType: 'invoice_card',
              items: [_invoiceToChatCard(matchingInvoice)],
            ),
          );
        }
      }
    } on ApiException catch (error) {
      errorMessage = _humanizeAgentError(error);
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> _ensureSession(AppSession session) async {
    if (_sessionId != null) return;

    final record = await session.withFreshToken(
      (accessToken) => _repository.createSession(accessToken: accessToken),
    );
    if (record.id.isEmpty) {
      throw const ApiException(
        'Chat session was created but no valid session id was returned.',
      );
    }
    _sessionId = record.id;
  }

  Future<List<ChatMessageRecord>> _pollJob(
    String jobId,
    AppSession session,
  ) async {
    for (var attempt = 0; attempt < 40; attempt++) {
      final result = await session.withFreshToken(
        (accessToken) => _repository.fetchJob(
          jobId: jobId,
          accessToken: accessToken,
        ),
      );
      if (result.messages.isNotEmpty) {
        return result.messages;
      }
      final status = (result.jobStatus ?? '').toUpperCase();
      if (status == 'FAILED' || status == 'CANCELLED') {
        return const [];
      }
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }
    return const [];
  }

  void _mergeMessages(List<ChatMessageRecord> incoming) {
    for (final message in incoming) {
      final exists = _messages.any((item) => item.id == message.id);
      if (exists) {
        continue;
      }

      final duplicateOptimisticUser = message.role == 'user' &&
          _messages.any(
            (item) =>
                item.id.startsWith('local-user-') &&
                item.role == 'user' &&
                item.text.trim() == message.text.trim(),
          );

      if (duplicateOptimisticUser) {
        continue;
      }

      _messages.add(message);
    }
  }

  String _humanizeAgentError(ApiException error) {
    if (error.statusCode == 401) {
      return 'Your session expired. Please sign in again and retry the message.';
    }

    if (error.statusCode == 404) {
      return 'The chat agent endpoint is not available on this backend yet.';
    }

    if (error.message.contains('no valid session id')) {
      return 'The backend created a chat response without returning a usable session id.';
    }

    return 'The care assistant could not complete that request right now.';
  }

  InvoiceItem? _findMatchingInvoice(
    List<InvoiceItem> invoices, {
    required String sourceType,
    required int sourceId,
  }) {
    final normalized = sourceType.trim().toUpperCase();
    for (final invoice in invoices) {
      if (normalized == 'APPOINTMENT' && invoice.appointmentId == sourceId) {
        return invoice;
      }
      if (normalized == 'DIAGNOSTIC' && invoice.diagnosticOrderId == sourceId) {
        return invoice;
      }
    }
    return null;
  }

  ChatCardItem _invoiceToChatCard(InvoiceItem invoice) {
    return ChatCardItem(
      title: invoice.title,
      subtitle: invoice.invoiceType,
      description: invoice.subtitle,
      badge: invoice.amount,
      documentId: invoice.id,
      downloadPath: invoice.downloadPath,
      fileName: invoice.fileName,
    );
  }
}
