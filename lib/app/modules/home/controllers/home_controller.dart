import 'package:get/get.dart';

import '../../../core/services/payment_service.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.color,
    required this.icon,
  });

  final int id;
  final String name;
  final String category;
  final double price;
  final double rating;
  final int color;
  final int icon;
}

class CartLine {
  CartLine({required this.product, this.quantity = 1});

  final Product product;
  int quantity;

  double get total => product.price * quantity;
}

class HomeController extends GetxController {
  final selectedTab = 0.obs;
  final selectedCategory = 'All'.obs;
  final cart = <CartLine>[].obs;
  final pushNotificationsEnabled = true.obs;
  final expressShipping = false.obs;
  final selectedGateway = PaymentGatewayType.payWayAba.obs;
  final orderPlaced = false.obs;
  final paymentProcessing = false.obs;
  final paymentStatus = PaymentStatus.pending.obs;
  final paymentReference = ''.obs;
  final paymentMessage = 'Choose a local gateway to start payment.'.obs;
  final khqrPayload = ''.obs;
  final pollingAttempt = 0.obs;
  final webhookLog = <String>[].obs;

  final PaymentService _paymentService = PaymentService();
  final categories = const ['All', 'Tech', 'Style', 'Home', 'Sport'];
  final paymentGateways = PaymentService.gateways;

  final products = const [
    Product(
      id: 1,
      name: 'AeroPods Max',
      category: 'Tech',
      price: 149.99,
      rating: 4.8,
      color: 0xFF4F46E5,
      icon: 0xe30b,
    ),
    Product(
      id: 2,
      name: 'Travel Hoodie',
      category: 'Style',
      price: 64.50,
      rating: 4.6,
      color: 0xFF0F766E,
      icon: 0xe59c,
    ),
    Product(
      id: 3,
      name: 'Glow Desk Lamp',
      category: 'Home',
      price: 42.00,
      rating: 4.7,
      color: 0xFFE11D48,
      icon: 0xe3a5,
    ),
    Product(
      id: 4,
      name: 'Flex Run Shoes',
      category: 'Sport',
      price: 88.75,
      rating: 4.9,
      color: 0xFFEA580C,
      icon: 0xe536,
    ),
    Product(
      id: 5,
      name: 'Smart Bottle',
      category: 'Sport',
      price: 31.25,
      rating: 4.5,
      color: 0xFF0891B2,
      icon: 0xe541,
    ),
    Product(
      id: 6,
      name: 'Cotton Tote',
      category: 'Style',
      price: 24.90,
      rating: 4.4,
      color: 0xFF7C3AED,
      icon: 0xe59d,
    ),
  ];

  List<Product> get filteredProducts {
    if (selectedCategory.value == 'All') return products;
    return products
        .where((product) => product.category == selectedCategory.value)
        .toList();
  }

  int get cartItemCount => cart.fold(0, (sum, line) => sum + line.quantity);

  double get subtotal => cart.fold(0, (sum, line) => sum + line.total);

  double get shipping => cart.isEmpty
      ? 0
      : expressShipping.value
      ? 12.95
      : 4.95;

  double get tax => subtotal * 0.075;

  double get total => subtotal + shipping + tax;

  void selectCategory(String category) => selectedCategory.value = category;

  void addToCart(Product product) {
    final index = cart.indexWhere((line) => line.product.id == product.id);
    if (index == -1) {
      cart.add(CartLine(product: product));
    } else {
      cart[index].quantity++;
      cart.refresh();
    }
  }

  void increment(Product product) {
    final index = cart.indexWhere((line) => line.product.id == product.id);
    if (index == -1) return;
    cart[index].quantity++;
    cart.refresh();
  }

  void decrement(Product product) {
    final index = cart.indexWhere((line) => line.product.id == product.id);
    if (index == -1) return;
    if (cart[index].quantity == 1) {
      cart.removeAt(index);
    } else {
      cart[index].quantity--;
      cart.refresh();
    }
  }

  Future<void> placeOrder() async {
    if (cart.isEmpty || paymentProcessing.value) return;

    paymentProcessing.value = true;
    paymentStatus.value = PaymentStatus.pending;
    paymentMessage.value = 'Creating secure payment intent...';
    pollingAttempt.value = 0;

    final idempotencyKey = _buildPaymentIdempotencyKey();
    final intent = await _paymentService.createIntent(
      gateway: selectedGateway.value,
      amount: total,
      idempotencyKey: idempotencyKey,
    );

    paymentReference.value = intent.reference;
    khqrPayload.value = intent.qrPayload ?? '';
    paymentMessage.value = intent.gateway == PaymentGatewayType.bakongKhqr
        ? 'KHQR generated. Waiting for scan confirmation...'
        : 'Payment request sent to $selectedGatewayName.';

    if (intent.gateway == PaymentGatewayType.bakongKhqr) {
      await _pollKhqrConfirmation(intent);
    } else {
      await _confirmIntentWithWebhook(intent);
    }

    paymentProcessing.value = false;
  }

  Future<void> _pollKhqrConfirmation(PaymentIntentResult intent) async {
    for (var attempt = 1; attempt <= 5; attempt++) {
      pollingAttempt.value = attempt;
      paymentMessage.value =
          'Polling Bakong KHQR confirmation... attempt $attempt';

      final status = await _paymentService.pollPaymentStatus(intent.reference);
      if (status == PaymentStatus.paid) {
        await _confirmIntentWithWebhook(intent);
        return;
      }
    }

    paymentStatus.value = PaymentStatus.failed;
    paymentMessage.value =
        'KHQR confirmation timed out. You can retry payment safely.';
  }

  Future<void> _confirmIntentWithWebhook(PaymentIntentResult intent) async {
    final webhookEvent = PaymentWebhookEvent(
      id: 'payment.paid.${intent.reference}',
      reference: intent.reference,
      status: PaymentStatus.paid,
      idempotencyKey: intent.idempotencyKey,
      message: '$selectedGatewayName confirmed payment.',
    );
    final webhookResult = await _paymentService.handleWebhook(webhookEvent);

    if (webhookResult.wasProcessed) {
      paymentStatus.value = webhookResult.event.status;
      paymentMessage.value = webhookResult.event.message;
      orderPlaced.value = true;
      selectedTab.value = 3;
    }

    webhookLog.insert(
      0,
      '${webhookResult.event.id} | ${webhookResult.wasProcessed ? 'processed' : 'duplicate ignored'} | key ${webhookResult.event.idempotencyKey}',
    );
  }

  Future<void> replayLatestWebhook() async {
    if (paymentReference.value.isEmpty) return;

    final event = PaymentWebhookEvent(
      id: 'payment.paid.${paymentReference.value}',
      reference: paymentReference.value,
      status: PaymentStatus.paid,
      idempotencyKey: _buildPaymentIdempotencyKey(),
      message: 'Duplicate webhook replay ignored.',
    );
    final result = await _paymentService.handleWebhook(event);
    webhookLog.insert(
      0,
      '${result.event.id} | ${result.wasProcessed ? 'processed' : 'duplicate ignored'} | key ${result.event.idempotencyKey}',
    );
  }

  String get selectedGatewayName => paymentGateways
      .firstWhere((gateway) => gateway.type == selectedGateway.value)
      .name;

  String _buildPaymentIdempotencyKey() {
    final cartFingerprint = cart
        .map((line) => '${line.product.id}x${line.quantity}')
        .join('-');
    return 'checkout-$cartFingerprint-${total.toStringAsFixed(2)}';
  }
}
