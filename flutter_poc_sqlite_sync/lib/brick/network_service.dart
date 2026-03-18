import 'package:connectivity_plus/connectivity_plus.dart';

/// Service pour gérer l'état du réseau en temps réel
class NetworkService {
  final Connectivity _connectivity = Connectivity();
  final List<Function(bool)> _listeners = [];
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  /// Initialiser le monitoring du réseau
  Future<void> initialize() async {
    // Vérifier l'état initial
    await _updateOnlineStatus();

    // Écouter les changements de connectivité
    _connectivity.onConnectivityChanged.listen((result) async {
      await _updateOnlineStatus();
    });
  }

  /// Mettre à jour l'état du réseau
  Future<void> _updateOnlineStatus() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    final wasOnline = _isOnline;
    
    _isOnline = connectivityResult != ConnectivityResult.none;

    // Notifier les écouteurs si le statut a changé
    if (wasOnline != _isOnline) {
      for (final listener in _listeners) {
        listener(_isOnline);
      }
    }
  }

  /// Ajouter un écouteur pour les changements de connectivité
  void addListener(Function(bool isOnline) listener) {
    _listeners.add(listener);
  }

  /// Retirer un écouteur
  void removeListener(Function(bool isOnline) listener) {
    _listeners.remove(listener);
  }
}
