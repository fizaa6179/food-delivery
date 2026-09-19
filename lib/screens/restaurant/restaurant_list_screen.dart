import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/restaurant_model.dart';
import '../../models/user_model.dart';
import '../../widgets/restaurant_card.dart';
import 'food_menu_screen.dart';

class RestaurantListScreen extends StatefulWidget {
  final UserModel user;
  final String? category;

  const RestaurantListScreen({super.key, required this.user, this.category});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  List<RestaurantModel> _restaurants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final restaurants = widget.category == null
        ? await DatabaseHelper.instance.getRestaurants()
        : await DatabaseHelper.instance.getRestaurantsByCategory(widget.category!);
    setState(() {
      _restaurants = restaurants;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.category ?? 'All restaurants'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _restaurants.isEmpty
              ? Center(
                  child: Text('No restaurants found', style: TextStyle(color: Colors.grey.shade500)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  itemCount: _restaurants.length,
                  itemBuilder: (context, index) {
                    final r = _restaurants[index];
                    return RestaurantCard(
                      restaurant: r,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => FoodMenuScreen(user: widget.user, restaurant: r)),
                      ),
                    );
                  },
                ),
    );
  }
}