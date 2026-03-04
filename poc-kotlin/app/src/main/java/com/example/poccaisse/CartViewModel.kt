package com.example.poccaisse

import androidx.lifecycle.ViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

class CartViewModel : ViewModel() {

    private val _cart = MutableStateFlow<Map<String, CartItem>>(emptyMap())
    val cart: StateFlow<Map<String, CartItem>> = _cart.asStateFlow()

    val total: Double get() = _cart.value.values.sumOf { it.subtotal }

    fun addProduct(product: Product) {
        _cart.update { current ->
            val updated = current.toMutableMap()
            val existing = updated[product.id]
            if (existing != null) {
                updated[product.id] = existing.copy(quantity = existing.quantity + 1)
            } else {
                updated[product.id] = CartItem(product)
            }
            updated
        }
    }

    fun removeProduct(productId: String) {
        _cart.update { current ->
            val updated = current.toMutableMap()
            val existing = updated[productId] ?: return@update current
            if (existing.quantity > 1) {
                updated[productId] = existing.copy(quantity = existing.quantity - 1)
            } else {
                updated.remove(productId)
            }
            updated
        }
    }

    fun clearCart() {
        _cart.value = emptyMap()
    }
}
