
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/cart_item_model.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/card_input_field.dart';
import '../../widgets/custom_button.dart';
import '../home/home_screen.dart';
import 'select_address_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final UserModel user;
  final List<CartItemModel> cartItems;
  final double totalAmount;
  final int totalItems;

  const CheckoutScreen({
    super.key,
    required this.user,
    required this.cartItems,
    required this.totalAmount,
    required this.totalItems,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPayment = 'Cash on Delivery';
  bool _loading = false;

  // Delivery address state - defaults to the placeholder "Home" text
  // until the user picks a real address from the map.
  String _addressLabel = 'Home';
  String _addressSubtitle = "";
  SelectedAddress? _selectedAddress;

  // Card form state
  bool _cardComplete = false;

  final _paymentMethods = [
    {'label': 'Cash on Delivery', 'icon': Icons.payments_outlined},
    {'label': 'Credit/Debit Card', 'icon': Icons.credit_card_rounded},
    {
      'label': 'JazzCash / Easypaisa',
      'icon': Icons.account_balance_wallet_outlined
    },
  ];

  @override
  void initState() {
    super.initState();
    _addressSubtitle = "${widget.user.name}'s saved address";
  }

  Future<void> _pickAddress() async {
    final result = await Navigator.of(context).push<SelectedAddress>(
      MaterialPageRoute(builder: (_) => const SelectAddressScreen()),
    );

    if (result != null) {
      setState(() {
        _selectedAddress = result;
        _addressLabel = 'Delivery address';
        _addressSubtitle = result.address;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Simulates a successful card payment for demo purposes.
  /// No real Stripe payment is processed.
  Future<bool> _payWithCard() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      _showError('Payment failed.');
      return false;
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedPayment == 'Credit/Debit Card' && !_cardComplete) {
      _showError('Please enter your complete card details.');
      return;
    }

    setState(() => _loading = true);

    if (_selectedPayment == 'Credit/Debit Card') {
      final paid = await _payWithCard();

      if (!paid) {
        setState(() => _loading = false);
        return;
      }
    }

    await _createOrderInDatabase();
  }

  Future<void> _createOrderInDatabase() async {
    final summary =
        widget.cartItems.map((c) => '${c.foodName} x${c.quantity}').join(', ');

    final order = OrderModel(
      userId: widget.user.id!,
      itemsSummary: summary,
      itemCount: widget.totalItems,
      totalAmount: widget.totalAmount,
      status: 'Placed',
      paymentMethod: _selectedPayment == 'Credit/Debit Card'
          ? 'Credit/Debit Card (Paid)'
          : _selectedPayment,
      dateTime: DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
      // If your OrderModel has address fields, wire them in like this:
      // deliveryAddress: _addressSubtitle,
      // deliveryLat: _selectedAddress?.latLng.latitude,
      // deliveryLng: _selectedAddress?.latLng.longitude,
    );

    await DatabaseHelper.instance.createOrder(order);
    await DatabaseHelper.instance.clearCart(widget.user.id!);

    setState(() => _loading = false);

    if (!mounted) return;
    _showSuccessSheet();
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accent,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Order placed!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your order has been placed successfully. Thank you!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 26),
            CustomButton(
              text: 'Back to home',
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(user: widget.user),
                  ),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Delivery address',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickAddress,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _addressLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _addressSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment method',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ..._paymentMethods.map((method) {
              final selected = _selectedPayment == method['label'];

              return GestureDetector(
                onTap: () => setState(
                  () => _selectedPayment = method['label'] as String,
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : Colors.grey.shade200,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        method['icon'] as IconData,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          method['label'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: selected
                            ? AppColors.primary
                            : Colors.grey.shade400,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            }),
            // Card form only shows up when "Credit/Debit Card" is selected.
            if (_selectedPayment == 'Credit/Debit Card') ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: CardInputField(
                  onCompleteChanged: (complete) {
                    setState(() => _cardComplete = complete);
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total amount (${widget.totalItems} items)',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Rs. ${widget.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Place Order',
              onPressed: _placeOrder,
              loading: _loading,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

