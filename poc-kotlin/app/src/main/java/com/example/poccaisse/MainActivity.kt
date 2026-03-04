package com.example.poccaisse

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

class MainActivity : ComponentActivity() {
    private val viewModel: CartViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                PosScreen(viewModel)
            }
        }
    }
}

@Composable
fun PosScreen(viewModel: CartViewModel) {
    val cart by viewModel.cart.collectAsState()
    var showDialog by remember { mutableStateOf(false) }
    val total = cart.values.sumOf { it.subtotal }

    if (showDialog) {
        AlertDialog(
            onDismissRequest = { showDialog = false },
            title = { Text("Paiement") },
            text = { Text("Total à payer : ${"%.2f".format(total)} €") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.clearCart()
                    showDialog = false
                }) { Text("Confirmer") }
            },
            dismissButton = {
                TextButton(onClick = { showDialog = false }) { Text("Annuler") }
            }
        )
    }

    Column(modifier = Modifier.fillMaxSize()) {

        // ── App bar ──────────────────────────────────────────────────
        Surface(color = Color(0xFF3F51B5)) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    "Caisse — POC",
                    color = Color.White,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        Row(modifier = Modifier.weight(1f)) {

            // ── Grille produits ──────────────────────────────────────
            LazyVerticalGrid(
                columns = GridCells.Fixed(2),
                modifier = Modifier
                    .weight(3f)
                    .padding(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(sampleProducts) { product ->
                    ProductCard(product) { viewModel.addProduct(product) }
                }
            }

            // ── Panier ───────────────────────────────────────────────
            Surface(
                modifier = Modifier.width(260.dp),
                color = Color(0xFFF5F5F5)
            ) {
                Column(modifier = Modifier.fillMaxHeight()) {
                    Surface(color = Color(0xFF3F51B5)) {
                        Text(
                            "Commande",
                            color = Color.White,
                            fontWeight = FontWeight.Bold,
                            fontSize = 16.sp,
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(12.dp)
                        )
                    }

                    if (cart.isEmpty()) {
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxWidth(),
                            contentAlignment = Alignment.Center
                        ) {
                            Text("Panier vide", color = Color.Gray)
                        }
                    } else {
                        LazyColumn(modifier = Modifier.weight(1f)) {
                            items(cart.values.toList()) { item ->
                                CartItemRow(item) { viewModel.removeProduct(item.product.id) }
                                HorizontalDivider()
                            }
                        }
                    }

                    HorizontalDivider()

                    // ── Total ────────────────────────────────────────
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("TOTAL", fontWeight = FontWeight.Bold, fontSize = 18.sp)
                        Text(
                            "${"%.2f".format(total)} €",
                            fontWeight = FontWeight.Bold,
                            fontSize = 18.sp,
                            color = Color(0xFF3F51B5)
                        )
                    }

                    // ── Actions ──────────────────────────────────────
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 12.dp, vertical = 8.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Button(
                            onClick = { if (cart.isNotEmpty()) showDialog = true },
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
                        ) {
                            Text("Payer", fontSize = 16.sp)
                        }
                        OutlinedButton(
                            onClick = { viewModel.clearCart() },
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.Red)
                        ) {
                            Text("Vider")
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ProductCard(product: Product, onClick: () -> Unit) {
    ElevatedButton(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .height(80.dp),
        colors = ButtonDefaults.elevatedButtonColors(
            containerColor = Color(0xFFE8EAF6)
        )
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(product.name, fontWeight = FontWeight.Bold, fontSize = 14.sp)
            Text("${"%.2f".format(product.price)} €", fontSize = 13.sp, color = Color(0xFF5C6BC0))
        }
    }
}

@Composable
fun CartItemRow(item: CartItem, onRemove: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(item.product.name, fontWeight = FontWeight.Medium)
            Text(
                "${"%.2f".format(item.product.price)} €  x${item.quantity}",
                fontSize = 12.sp,
                color = Color.Gray
            )
        }
        Text("${"%.2f".format(item.subtotal)} €", fontWeight = FontWeight.Bold)
        IconButton(onClick = onRemove) {
            Text("−", color = Color.Red, fontSize = 18.sp, fontWeight = FontWeight.Bold)
        }
    }
}
