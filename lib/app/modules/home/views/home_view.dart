import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/payment_service.dart';
import '../../../../theme/app_colors.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = [
      _ProductsTab(controller: controller),
      _CartTab(controller: controller),
      _CheckoutTab(controller: controller),
      _TrackingTab(controller: controller),
      _NotificationsTab(controller: controller),
    ];

    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: const Text('ShopEase'),
          actions: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  tooltip: 'Cart',
                  onPressed: () => controller.selectedTab.value = 1,
                  icon: const Icon(Icons.shopping_cart_outlined),
                ),
                if (controller.cartItemCount > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${controller.cartItemCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: SafeArea(child: pages[controller.selectedTab.value]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: controller.selectedTab.value,
          onDestinationSelected: (index) =>
              controller.selectedTab.value = index,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Shop',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined),
              selectedIcon: Icon(Icons.shopping_bag),
              label: 'Cart',
            ),
            NavigationDestination(
              icon: Icon(Icons.credit_card_outlined),
              selectedIcon: Icon(Icons.credit_card),
              label: 'Pay',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon: Icon(Icons.local_shipping),
              label: 'Track',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Alerts',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsTab extends StatelessWidget {
  const _ProductsTab({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text(
            'Find your next favorite thing',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Curated picks with fast checkout and live order updates.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = controller.categories[index];
                final selected = controller.selectedCategory.value == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  onSelected: (_) => controller.selectCategory(category),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            itemCount: controller.filteredProducts.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final product = controller.filteredProducts[index];
              return _ProductCard(
                product: product,
                onAdd: () => controller.addToCart(product),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onAdd});

  final Product product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(product.color).withAlpha(28),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  IconData(product.icon, fontFamily: 'MaterialIcons'),
                  color: Color(product.color),
                  size: 54,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                Text(' ${product.rating}'),
                const Spacer(),
                Text(
                  product.category,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton.filled(
                  tooltip: 'Add to cart',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_shopping_cart),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartTab extends StatelessWidget {
  const _CartTab({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(
            title: 'Cart',
            subtitle: '${controller.cartItemCount} items ready for checkout',
          ),
          const SizedBox(height: 12),
          if (controller.cart.isEmpty)
            const _EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Your cart is empty',
              message: 'Add products from the shop to build an order.',
            )
          else
            ...controller.cart.map(
              (line) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(line.product.color).withAlpha(32),
                    child: Icon(
                      IconData(line.product.icon, fontFamily: 'MaterialIcons'),
                      color: Color(line.product.color),
                    ),
                  ),
                  title: Text(line.product.name),
                  subtitle: Text('\$${line.product.price.toStringAsFixed(2)}'),
                  trailing: SizedBox(
                    width: 118,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Decrease',
                          onPressed: () => controller.decrement(line.product),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('${line.quantity}'),
                        IconButton(
                          tooltip: 'Increase',
                          onPressed: () => controller.increment(line.product),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          _OrderSummary(controller: controller),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: controller.cart.isEmpty
                ? null
                : () => controller.selectedTab.value = 2,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Continue to checkout'),
          ),
        ],
      ),
    );
  }
}

class _CheckoutTab extends StatelessWidget {
  const _CheckoutTab({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader(
            title: 'Checkout',
            subtitle: 'Pay with local gateways and idempotent webhooks',
          ),
          const SizedBox(height: 12),
          _OptionCard(
            icon: Icons.location_on_outlined,
            title: 'Delivery address',
            subtitle: '221 Market Street, San Francisco, CA',
          ),
          SwitchListTile(
            value: controller.expressShipping.value,
            onChanged: (value) => controller.expressShipping.value = value,
            title: const Text('Express shipping'),
            subtitle: const Text('Priority handling with live updates'),
          ),
          const SizedBox(height: 12),
          ...controller.paymentGateways.map(
            (gateway) => _PaymentGatewayTile(
              gateway: gateway,
              selected: controller.selectedGateway.value == gateway.type,
              onTap: () => controller.selectedGateway.value = gateway.type,
            ),
          ),
          const SizedBox(height: 12),
          _OrderSummary(controller: controller),
          const SizedBox(height: 12),
          _PaymentStatusCard(controller: controller),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed:
                controller.cart.isEmpty || controller.paymentProcessing.value
                ? null
                : controller.placeOrder,
            icon: controller.paymentProcessing.value
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.payment),
            label: Text(
              controller.cart.isEmpty
                  ? 'Add items to pay'
                  : 'Pay with ${controller.selectedGatewayName}',
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingTab extends StatelessWidget {
  const _TrackingTab({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader(
            title: 'Order tracking',
            subtitle: 'Follow the order from confirmation to delivery',
          ),
          const SizedBox(height: 12),
          if (!controller.orderPlaced.value)
            const _EmptyState(
              icon: Icons.route_outlined,
              title: 'No active order yet',
              message: 'Place an order to see the tracking timeline.',
            )
          else
            Column(
              children: [
                _OptionCard(
                  icon: Icons.verified_outlined,
                  title: controller.paymentReference.value,
                  subtitle:
                      '${controller.selectedGatewayName} payment captured',
                ),
                const _TrackingStep(
                  done: true,
                  title: 'Order confirmed',
                  subtitle: 'Payment approved and receipt sent',
                ),
                const _TrackingStep(
                  done: true,
                  title: 'Packed',
                  subtitle: 'Items are prepared for pickup',
                ),
                const _TrackingStep(
                  done: false,
                  title: 'On the way',
                  subtitle: 'Estimated arrival today, 6:30 PM',
                ),
                const _TrackingStep(
                  done: false,
                  title: 'Delivered',
                  subtitle: 'Proof of delivery will appear here',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: controller.replayLatestWebhook,
                  icon: const Icon(Icons.replay),
                  label: const Text('Replay webhook'),
                ),
                const SizedBox(height: 12),
                _WebhookLog(controller: controller),
              ],
            ),
        ],
      ),
    );
  }
}

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader(
            title: 'Push notifications',
            subtitle: 'Manage alerts for deals, payments, and delivery',
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: controller.pushNotificationsEnabled.value,
            onChanged: (value) =>
                controller.pushNotificationsEnabled.value = value,
            title: const Text('Enable push notifications'),
            subtitle: const Text('Receive order and promotion alerts'),
          ),
          const SizedBox(height: 8),
          const _OptionCard(
            icon: Icons.local_offer_outlined,
            title: 'Price drops',
            subtitle: 'Instant alerts when saved products go on sale',
          ),
          const _OptionCard(
            icon: Icons.receipt_long_outlined,
            title: 'Payment updates',
            subtitle: 'Confirmation, failed payments, and refunds',
          ),
          const _OptionCard(
            icon: Icons.delivery_dining_outlined,
            title: 'Delivery status',
            subtitle: 'Courier pickup, delays, and delivery proof',
          ),
        ],
      ),
    );
  }
}

class _PaymentGatewayTile extends StatelessWidget {
  const _PaymentGatewayTile({
    required this.gateway,
    required this.selected,
    required this.onTap,
  });

  final PaymentGateway gateway;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          gateway.type == PaymentGatewayType.bakongKhqr
              ? Icons.qr_code_2
              : Icons.account_balance_wallet_outlined,
          color: selected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(gateway.name),
        subtitle: Text(gateway.description),
        trailing: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _PaymentStatusCard extends StatelessWidget {
  const _PaymentStatusCard({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    controller.paymentStatus.value == PaymentStatus.paid
                        ? Icons.check_circle
                        : Icons.pending_actions,
                    color: controller.paymentStatus.value == PaymentStatus.paid
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Payment status',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(controller.paymentMessage.value),
              if (controller.paymentReference.value.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Reference: ${controller.paymentReference.value}'),
              ],
              if (controller.khqrPayload.value.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: const Icon(Icons.qr_code_2, size: 118),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Bakong KHQR payload',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        controller.khqrPayload.value,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      if (controller.paymentProcessing.value) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: controller.pollingAttempt.value == 0
                              ? null
                              : controller.pollingAttempt.value / 3,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Polling confirmation attempt ${controller.pollingAttempt.value}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WebhookLog extends StatelessWidget {
  const _WebhookLog({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Webhook handling',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (controller.webhookLog.isEmpty)
                const Text('No webhook events received yet.')
              else
                ...controller.webhookLog.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(entry),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _SummaryRow('Subtotal', controller.subtotal),
              _SummaryRow('Shipping', controller.shipping),
              _SummaryRow('Tax', controller.tax),
              const Divider(),
              _SummaryRow('Total', controller.total, isTotal: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.isTotal = false});

  final String label;
  final double value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingStep extends StatelessWidget {
  const _TrackingStep({
    required this.done,
    required this.title,
    required this.subtitle,
  });

  final bool done;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: done ? AppColors.success : AppColors.divider,
          child: Icon(
            done ? Icons.check : Icons.more_horiz,
            color: done ? Colors.white : AppColors.textSecondary,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 46, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
