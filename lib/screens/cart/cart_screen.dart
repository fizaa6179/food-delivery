import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/cart_item_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_assets.dart';
import '../../widgets/custom_button.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final UserModel user;
  const CartScreen({super.key, required this.user});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItemModel> _cartItems = [];
  Map<int, String> _restaurantNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await DatabaseHelper.instance.getCartItems(widget.user.id!);
    final restaurants = await DatabaseHelper.instance.getRestaurants();
    setState(() {
      _cartItems = items;
      _restaurantNames = {for (final r in restaurants) r.id!: r.name};
      _loading = false;
    });
  }

  double get _totalAmount => _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  int get _totalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  Future<void> _updateQuantity(CartItemModel item, int newQuantity) async {
    await DatabaseHelper.instance.updateCartQuantity(item.id!, newQuantity);
    _load();
  }

  Future<void> _removeItem(CartItemModel item) async {
    await DatabaseHelper.instance.removeFromCart(item.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('My Cart'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? _emptyState()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) => _cartTile(_cartItems[index]),
                      ),
                    ),
                    _summaryBar(),
                  ],
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Your cart is empty', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          const SizedBox(height: 6),
          Text('Add something tasty from the menu', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _cartTile(CartItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          AppImage(
            path: AppAssets.foodImage(_restaurantNames[item.restaurantId] ?? '', item.foodName),
            fallbackIcon: Icons.fastfood_rounded,
            width: 54,
            height: 54,
            borderRadius: BorderRadius.circular(14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.foodName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Text('Rs. ${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ],
            ),
          ),
          Row(
            children: [
              _qtyButton(Icons.remove_rounded, () => _updateQuantity(item, item.quantity - 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              _qtyButton(Icons.add_rounded, () => _updateQuantity(item, item.quantity + 1)),
            ],
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade400, size: 20),
            onPressed: () => _removeItem(item),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: AppColors.primary),
      ),
    );
  }

  Widget _summaryBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total items ($_totalItems)', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              Text('Rs. ${_totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 14),
          CustomButton(
            text: 'Proceed to Checkout',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CheckoutScreen(
                    user: widget.user,
                    cartItems: _cartItems,
                    totalAmount: _totalAmount,
                    totalItems: _totalItems,
                  ),
                ),
              );
              _load();
            },
          ),
        ],
      ),
    );
  }
}