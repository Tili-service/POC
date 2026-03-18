# Flutter SQLite ↔ API Synchronization POC

Proof of concept d'une application Flutter avec synchronisation bidirectionnelle automatique entre SQLite (local) et une API REST.

## 🎯 Fonctionnalités

- ✅ **Offline-First**: Brick framework pour gestion offline/online
- ✅ **Sync Bidirectionnelle**: SQLite ↔ API REST
- ✅ **Détection Automatique**: Détecte et synchronise les différences
- ✅ **Mode Offline**: Fonctionnement complet sans réseau
- ✅ **Priorités Smart**: DELETE > CREATE > UPDATE
- ✅ **Auto-Sync**: Quand le réseau se rétablit
- ✅ **Gestion des Erreurs**: Graceful error handling

## 🏗️ Architecture

```
Flutter App (Brick ORM)
    ↓
SQLite (Stockage Local)
    ↓
SyncService (Détection des diff)
    ↓
FastAPI Backend
```

## 📱 Utilisation

### Démarrer l'app

```bash
flutter run
```

### Démarrer le backend

```bash
cd backend
source .venv/bin/activate
uvicorn main:app --reload --port 8000
```

## 🔄 Workflows de Synchronisation

### 1. Mode Online (Switch = ON)
- **GET API**: Récupère tous les clients depuis l'API
- **PUSH Local**: Envoie les changements locaux (DELETE, CREATE, UPDATE)
- Ordre: DELETE → CREATE → UPDATE

### 2. Mode Offline (Switch = OFF)
- Affiche uniquement les données locales (SQLite)
- Permet la création/modification/suppression locale
- Auto-sync au rétablissement du réseau

### 3. Auto-Sync
- Détecte automatiquement le rétablissement du réseau
- Pousse les changements locaux vers l'API
- Récupère les données mises à jour

## 🎨 Interface Utilisateur

| Élément | Fonction |
|---------|----------|
| 🟢/🔴 Switch | Connecte/Déconnecte le réseau |
| 📥 GET API | Récupère les données de l'API |
| 📤 PUSH Local | Envoie les changements locaux |
| ➕ Ajouter | Crée un nouveau client |
| 🗑️ Delete | Supprime un client |

## 📊 IDs des Clients

- **IDs < 10000**: Clients de l'API (ID statiques)
- **IDs >= 10000**: Clients créés localement (offline)

## 🔍 Détection des Changements

### Clients à Créer (CREATE)
Existent en local mais pas en API

### Clients à Mettre à Jour (UPDATE)
Existent dans les deux mais avec données différentes

### Clients à Supprimer (DELETE)
Existent en API mais pas en local (suppression locale)

## 🛠️ Stack Technologique

**Frontend**:
- Flutter 3.11+
- Brick (Offline-First ORM)
- SQLite (Storage)
- connectivity_plus (Network monitoring)

**Backend**:
- FastAPI
- Python 3.8+

## 📝 Points Importants

1. **Les suppressions locales sont poussées en priorité** pour éviter les conflits
2. **Les clients créés offline (ID >= 10000)** ne sont jamais supprimés de l'API
3. **Messages d'erreur détaillés** pour chaque opération
4. **État UI en temps réel** avec spinners et feedback messages
