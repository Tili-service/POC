package com.example.poccaisse

data class Product(
    val id: String,
    val name: String,
    val price: Double
)

data class CartItem(
    val product: Product,
    var quantity: Int = 1
) {
    val subtotal: Double get() = product.price * quantity
}

val sampleProducts = listOf(
    Product("1", "Café",         1.50),
    Product("2", "Croissant",    1.20),
    Product("3", "Sandwich",     4.50),
    Product("4", "Jus d'orange", 2.00),
    Product("5", "Eau minérale", 0.80),
    Product("6", "Coca-Cola",    2.50),
)
