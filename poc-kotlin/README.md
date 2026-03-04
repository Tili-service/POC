# POC Caisse — Kotlin (Android Compose)

Application de caisse minimaliste en Kotlin avec Jetpack Compose.

## Fonctionnalités

- Grille de produits (6 articles prédéfinis)
- Ajout au panier par tap
- Suppression unitaire depuis le panier
- Total calculé en temps réel via `StateFlow`
- Dialog de confirmation de paiement
- Vider le panier

## Structure

```
poc-kotlin/
├── build.gradle
├── settings.gradle
└── app/
    ├── build.gradle
    └── src/main/
        ├── AndroidManifest.xml
        └── java/com/example/poccaisse/
            ├── Models.kt          # Product, CartItem, données exemple
            ├── CartViewModel.kt   # Logique panier (StateFlow)
            └── MainActivity.kt    # UI Compose (PosScreen, ProductCard, CartItemRow)
```

## Ouvrir dans Android Studio

1. `File > Open` → sélectionner le dossier `poc-kotlin`
2. Laisser Gradle synchroniser
3. Lancer sur un émulateur ou appareil physique (API 24+)
