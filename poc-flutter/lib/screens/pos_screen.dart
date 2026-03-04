import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/cart_item.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final Map<String, CartItem> _cart = {};

  double get _total =>
      _cart.values.fold(0, (sum, item) => sum + item.subtotal);

  void _addToCart(Product product) {
    setState(() {
      if (_cart.containsKey(product.id)) {
        _cart[product.id]!.quantity++;
      } else {
        _cart[product.id] = CartItem(product: product);
      }
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      if (_cart[productId]!.quantity > 1) {
        _cart[productId]!.quantity--;
      } else {
        _cart.remove(productId);
      }
    });
  }

  void _clearCart() {
    setState(() => _cart.clear());
  }

  void _checkout() {
    if (_cart.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Paiement'),
        content: Text('Total à payer : ${_total.toStringAsFixed(2)} €'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCart();
            },
            child: const Text('Confirmer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caisse — POC'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // ── Grille produits ──────────────────────────────────────
          Expanded(
            flex: 3,
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.2,
              ),
              itemCount: kProducts.length,
              itemBuilder: (_, index) {
                final product = kProducts[index];
                return ElevatedButton(
                  onPressed: () => _addToCart(product),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade50,
                    foregroundColor: Colors.indigo.shade900,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.price.toStringAsFixed(2)} €',
                        style: TextStyle(
                            color: Colors.indigo.shade400, fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Panier ───────────────────────────────────────────────
          Container(
            width: 280,
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.indigo,
                  padding: const EdgeInsets.all(12),
                  child: const Text(
                    'Commande',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: _cart.isEmpty
                      ? const Center(
                          child: Text(
                            'Panier vide',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView(
                          children: _cart.values
                              .map(
                                (item) => ListTile(
                                  dense: true,
                                  title: Text(item.product.name),
                                  subtitle: Text(
                                      '${item.product.price.toStringAsFixed(2)} €  x${item.quantity}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${item.subtotal.toStringAsFixed(2)} €',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle,
                                            color: Colors.red, size: 20),
                                        onPressed: () =>
                                            _removeFromCart(item.product.id),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),

                // ── Total + actions ──────────────────────────────
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(
                        '${_total.toStringAsFixed(2)} €',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.indigo),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _checkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Payer',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _clearCart,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Vider'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
