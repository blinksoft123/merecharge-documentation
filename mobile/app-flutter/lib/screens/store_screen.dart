import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/product.dart';
import '../routes/app_routes.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  String _selectedCategory = 'Tous';
  final List<String> _categories = ['Tous', 'Téléphones', 'Ordinateurs', 'Accessoires', 'Audio'];

  // Sample electronic devices
  final List<Product> _products = const [
    Product(
      id: '1',
      name: 'Samsung Galaxy A54',
      description: 'Smartphone Android dernière génération',
      price: 245000,
      imageUrl: 'assets/images/phone1.jpg',
      category: 'Téléphones',
      specifications: {'Storage': '128GB', 'RAM': '6GB', 'Camera': '50MP'},
    ),
    Product(
      id: '2', 
      name: 'iPhone 14',
      description: 'iPhone Apple avec puce A15 Bionic',
      price: 650000,
      imageUrl: 'assets/images/phone2.jpg',
      category: 'Téléphones',
      specifications: {'Storage': '128GB', 'RAM': '6GB', 'Camera': '48MP'},
    ),
    Product(
      id: '3',
      name: 'MacBook Air M2',
      description: 'Ordinateur portable Apple Silicon',
      price: 850000,
      imageUrl: 'assets/images/laptop1.jpg',
      category: 'Ordinateurs',
      specifications: {'Processor': 'M2', 'RAM': '8GB', 'Storage': '256GB SSD'},
    ),
    Product(
      id: '4',
      name: 'HP Pavilion',
      description: 'Ordinateur portable Windows',
      price: 420000,
      imageUrl: 'assets/images/laptop2.jpg',
      category: 'Ordinateurs',
      specifications: {'Processor': 'Intel i5', 'RAM': '8GB', 'Storage': '512GB SSD'},
    ),
    Product(
      id: '5',
      name: 'AirPods Pro',
      description: 'Écouteurs sans fil à réduction de bruit',
      price: 135000,
      imageUrl: 'assets/images/airpods.jpg',
      category: 'Audio',
      specifications: {'Battery': '6h', 'Connectivity': 'Bluetooth 5.3'},
    ),
    Product(
      id: '6',
      name: 'Chargeur Sans Fil',
      description: 'Chargeur Qi compatible tous appareils',
      price: 25000,
      imageUrl: 'assets/images/charger.jpg',
      category: 'Accessoires',
      specifications: {'Power': '15W', 'Compatibility': 'Qi Standard'},
    ),
  ];

  List<Product> get _filteredProducts {
    if (_selectedCategory == 'Tous') {
      return _products;
    }
    return _products.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = category);
                      }
                    },
                    backgroundColor: isSelected ? AppColors.primary : AppColors.lightGrey,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          
          // Products Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return _ProductCard(
                  product: product,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.productDetail,
                    arguments: product,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Placeholder
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: AppColors.lightGrey,
                child: Icon(
                  _getIconForCategory(product.category),
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            ),
            
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'XAF ${product.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Téléphones':
        return Icons.smartphone;
      case 'Ordinateurs':
        return Icons.laptop;
      case 'Accessoires':
        return Icons.cable;
      case 'Audio':
        return Icons.headphones;
      default:
        return Icons.device_unknown;
    }
  }
}