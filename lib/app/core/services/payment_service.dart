enum PaymentGatewayType { payWayAba, bakongKhqr, wingMock }

enum PaymentStatus { pending, paid, failed }

class PaymentGateway {
  const PaymentGateway({
    required this.type,
    required this.name,
    required this.description,
  });

  final PaymentGatewayType type;
  final String name;
  final String description;
}

class PaymentIntentResult {
  const PaymentIntentResult({
    required this.gateway,
    required this.reference,
    required this.idempotencyKey,
    required this.status,
    required this.amount,
    this.qrPayload,
  });

  final PaymentGatewayType gateway;
  final String reference;
  final String idempotencyKey;
  final PaymentStatus status;
  final double amount;
  final String? qrPayload;
}

class PaymentWebhookEvent {
  const PaymentWebhookEvent({
    required this.id,
    required this.reference,
    required this.status,
    required this.idempotencyKey,
    required this.message,
  });

  final String id;
  final String reference;
  final PaymentStatus status;
  final String idempotencyKey;
  final String message;
}

class PaymentWebhookResult {
  const PaymentWebhookResult({required this.event, required this.wasProcessed});

  final PaymentWebhookEvent event;
  final bool wasProcessed;
}

class PaymentService {
  final Map<String, PaymentIntentResult> _intentByIdempotencyKey = {};
  final Map<String, int> _pollAttemptsByReference = {};
  final Set<String> _processedWebhookIds = {};

  static const gateways = [
    PaymentGateway(
      type: PaymentGatewayType.payWayAba,
      name: 'PayWay ABA',
      description: 'Sandbox card and ABA PAY flow',
    ),
    PaymentGateway(
      type: PaymentGatewayType.bakongKhqr,
      name: 'Bakong KHQR',
      description: 'Mock KHQR payload for scan-to-pay',
    ),
    PaymentGateway(
      type: PaymentGatewayType.wingMock,
      name: 'Wing Mock',
      description: 'Mock wallet payment fallback',
    ),
  ];

  Future<PaymentIntentResult> createIntent({
    required PaymentGatewayType gateway,
    required double amount,
    required String idempotencyKey,
  }) async {
    final existing = _intentByIdempotencyKey[idempotencyKey];
    if (existing != null) return existing;

    await Future<void>.delayed(const Duration(milliseconds: 450));

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final referencePrefix = switch (gateway) {
      PaymentGatewayType.payWayAba => 'ABA',
      PaymentGatewayType.bakongKhqr => 'KHQR',
      PaymentGatewayType.wingMock => 'WING',
    };
    final reference = '$referencePrefix-$timestamp';
    final intent = PaymentIntentResult(
      gateway: gateway,
      reference: reference,
      idempotencyKey: idempotencyKey,
      status: PaymentStatus.pending,
      amount: amount,
      qrPayload: gateway == PaymentGatewayType.bakongKhqr
          ? '00020101021229370010kh.gov.nbc0117SHOP-EASE-$timestamp'
          : null,
    );
    _intentByIdempotencyKey[idempotencyKey] = intent;
    return intent;
  }

  Future<PaymentWebhookResult> handleWebhook(PaymentWebhookEvent event) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final wasProcessed = _processedWebhookIds.add(event.id);
    return PaymentWebhookResult(event: event, wasProcessed: wasProcessed);
  }

  Future<PaymentStatus> pollPaymentStatus(String reference) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final attempts = (_pollAttemptsByReference[reference] ?? 0) + 1;
    _pollAttemptsByReference[reference] = attempts;

    return attempts >= 3 ? PaymentStatus.paid : PaymentStatus.pending;
  }
}
