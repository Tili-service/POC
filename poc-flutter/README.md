# POC Caisse — Flutter

Application de caisse minimaliste en Flutter.

## Fonctionnalités

- Grille de produits (6 articles prédéfinis)
- Ajout au panier par tap
- Suppression unitaire depuis le panier
- Total calculé en temps réel
- Dialog de confirmation de paiement
- Vider le panier

## Structure

```
poc-flutter/
├── pubspec.yaml
└── lib/
    ├── main.dart
    ├── models/
    │   ├── product.dart
    │   └── cart_item.dart
    └── screens/
        └── pos_screen.dart
```

## Lancer

```bash
flutter pub get
flutter run
```
