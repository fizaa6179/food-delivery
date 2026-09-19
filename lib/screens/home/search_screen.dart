import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/cart_item_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/food_tile.dart';

class SearchScreen extends StatefulWidget {
  final UserModel user;
  const SearchScreen({super.key, required this.user});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searched = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    final results = await DatabaseHelper.instance.searchFoodItemsWithRestaurant(query.trim());
    setState(() {
      _results = results;
      _searched = true;
    });
  }

  Future<void> _addToCart(Map<String, dynamic> item) async {
    await DatabaseHelper.instance.addToCart(
      CartItemModel(
        userId: widget.user.id!,
        foodItemId: item['id'] as int,
        foodName: item['name'] as String,
        price: (item['price'] as num).toDouble(),
        quantity: 1,
        restaurantId: item['restaurantId'] as int,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item['name']} added to cart'), duration: const Duration(seconds: 1)),
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
        title: const Text('Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: _search,
                      decoration: const InputDecoration(
                        hintText: 'Search Burger, Pizza, Biryani...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _controller.clear();
                        _search('');
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_searched && _results.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      Text('No matching food found', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final item = _results[index];
                  return FoodTile(
                    name: item['name'] as String,
                    price: (item['price'] as num).toDouble(),
                    subtitle: item['restaurantName'] as String,
                    restaurantName: item['restaurantName'] as String,
                    onAdd: () => _addToCart(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
