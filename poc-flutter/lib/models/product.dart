class Product {
  final String id;
  final String name;
  final double price;

  const Product({
    required this.id,
    required this.name,
    required this.price,
  });
}

const List<Product> kProducts = [
  Product(id: '1', name: 'Café', price: 1.50),
  Product(id: '2', name: 'Croissant', price: 1.20),
  Product(id: '3', name: 'Sandwich', price: 4.50),
  Product(id: '4', name: 'Jus d\'orange', price: 2.00),
  Product(id: '5', name: 'Eau minérale', price: 0.80),
  Product(id: '6', name: 'Coca-Cola', price: 2.50),
];
