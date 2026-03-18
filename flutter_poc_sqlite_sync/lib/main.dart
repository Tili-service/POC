import 'package:flutter/material.dart';
import 'package:brick_offline_first/brick_offline_first.dart';
import 'dart:async';

import 'brick/models/customer.model.dart';
import 'brick/repository.dart';
import 'brick/sync_service.dart';
import 'brick/network_service.dart';

void main() {
  runApp(const POCApp());
}

class POCApp extends StatelessWidget {
  const POCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CustomerSyncPage(),
    );
  }
}

class CustomerSyncPage extends StatefulWidget {
  const CustomerSyncPage({super.key});

  @override
  State<CustomerSyncPage> createState() => _CustomerSyncPageState();
}

class _CustomerSyncPageState extends State<CustomerSyncPage> {
  AppRepository? _repository;
  SyncService? _syncService;
  NetworkService? _networkService;
  
  bool _networkEnabled = true;
  bool _busy = true;
  bool _syncing = false;
  
  String? _error;
  String? _syncMessage;
  DateTime? _lastSyncTime;
  
  int _nextLocalId = 10_000;
  List<Customer> _customers = const [];
  
  // Polling automatique
  Timer? _pollTimer;
  static const int _pollIntervalSeconds = 2;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final repository = await AppRepository.configure();
      final syncService = SyncService(
        repository: repository,
        baseUrl: 'http://10.0.2.2:8000',
      );
      final networkService = NetworkService();
      await networkService.initialize();

      setState(() {
        _repository = repository;
        _syncService = syncService;
        _networkService = networkService;
      });

      // Écouter les changements de connectivité
      networkService.addListener(_onNetworkConnectivityChanged);

      // Sync initiale
      await _syncFromApi();
      
      // Démarrer le polling automatique
      _startPolling();
    } catch (e) {
      setState(() {
        _error = 'Initialisation impossible: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  /// Démarrer le polling automatique (sync toutes les 2 secondes)
  void _startPolling() {
    // Arrêter le polling précédent s'il existe
    _pollTimer?.cancel();
    _pollTimer = null;

    if (!_networkEnabled) {
      return;
    }

    // Démarrer un nouveau polling
    _pollTimer = Timer.periodic(
      Duration(seconds: _pollIntervalSeconds),
      (_) {
        if (mounted && _networkEnabled && !_busy) {
          _autoSync();
        }
      },
    );
  }

  /// Arrêter le polling automatique
  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Synchronisation automatique (sans gêner l'utilisateur)
  Future<void> _autoSync() async {
    final repository = _repository;
    if (repository == null) return;

    try {
      // Récupérer les données depuis l'API
      await repository.get<Customer>(
        policy: OfflineFirstGetPolicy.awaitRemote,
      );
      
      // Charger les données locales
      final local = await repository.get<Customer>(
        policy: OfflineFirstGetPolicy.localOnly,
      );

      if (mounted) {
        setState(() {
          _customers = local;
          _lastSyncTime = DateTime.now();
          _error = null;
        });
      }
    } catch (e) {
      // Log silencieusement les erreurs de polling
      if (mounted) {
        setState(() {
          _lastSyncTime = DateTime.now();
        });
      }
    }
  }

  /// Callback quand la connectivité change
  void _onNetworkConnectivityChanged(bool isOnline) {
    if (mounted && isOnline && _networkEnabled) {
      // Le réseau est revenu et activé -> sync auto
      // D'abord PUSH, puis GET
      _syncLocalToApi().then((_) {
        _syncFromApi();
      });
      // Redémarrer le polling
      _startPolling();
    } else if (!isOnline) {
      // Réseau perdu -> arrêter le polling
      _stopPolling();
    }
  }

  @override
  void dispose() {
    final networkService = _networkService;
    if (networkService != null) {
      networkService.removeListener(_onNetworkConnectivityChanged);
    }
    _stopPolling(); // Arrêter le polling à la destruction
    super.dispose();
  }

  Future<void> _loadLocalOnly() async {
    final repository = _repository;
    if (repository == null) return;

    final local = await repository.get<Customer>(
      policy: OfflineFirstGetPolicy.localOnly,
    );

    if (!mounted) return;
    setState(() {
      _customers = local;
      _error = null;
    });
  }

  Future<void> _syncFromApi() async {
    final repository = _repository;
    if (repository == null) return;

    setState(() {
      _busy = true;
    });

    try {
      await repository.get<Customer>(
        policy: OfflineFirstGetPolicy.awaitRemote,
      );
      await _loadLocalOnly();
    } catch (e) {
      setState(() {
        _error = 'Sync distante en erreur: $e';
      });
      await _loadLocalOnly();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _addLocalCustomer() async {
    final repository = _repository;
    if (repository == null) return;
    final id = _nextLocalId++;

    final customer = Customer(
      id: id,
      name: 'Client local $id',
      email: 'offline$id@example.com',
      age: 25,
      bio: 'Offline user',
    );

    await repository.upsert<Customer>(
      customer,
      policy: OfflineFirstUpsertPolicy.optimisticLocal,
    );

    await _loadLocalOnly();
  }

  Future<void> _toggleNetwork(bool enabled) async {
    final repository = _repository;
    if (repository == null) return;

    repository.setNetworkEnabled(enabled);
    setState(() {
      _networkEnabled = enabled;
      _error = null;
      _syncMessage = null;
    });

    if (enabled) {
      // Réseau réactivé :
      // 1. D'ABORD PUSH les changements locaux (DELETE, CREATE, UPDATE)
      await _syncLocalToApi();
      // 2. ENSUITE GET les données mises à jour de l'API
      await _syncFromApi();
      // 3. Démarrer le polling automatique
      _startPolling();
    } else {
      // Réseau désactivé : 
      // - Arrêter le polling
      _stopPolling();
      // - Charger les données locales uniquement
      await _loadLocalOnly();
    }
  }

  /// Synchronise les données locales vers l'API en détectant les différences
  Future<void> _syncLocalToApi() async {
    final syncService = _syncService;
    if (syncService == null) return;

    setState(() {
      _syncing = true;
      _syncMessage = null;
      _error = null;
    });

    try {
      final result = await syncService.syncDataWithApi();
      
      if (!mounted) return;
      
      if (result.success) {
        setState(() {
          _syncMessage = result.summary;
        });
        // Efface le message après 3 secondes
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              if (_syncMessage == result.summary) {
                _syncMessage = null;
              }
            });
          }
        });
        // Recharger les données locales après la sync
        await _loadLocalOnly();
      } else {
        setState(() {
          _error = 'Sync échouée: ${result.error}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur sync: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _syncing = false;
        });
      }
    }
  }

  /// Supprime un client localement et sur l'API
  Future<void> _deleteCustomer(Customer customer) async {
    final repository = _repository;
    if (repository == null) return;

    try {
      // Supprimer localement en premier
      await repository.delete<Customer>(
        customer,
        policy: OfflineFirstDeletePolicy.optimisticLocal,
      );

      // Recharger la liste immédiatement
      await _loadLocalOnly();

      // Syncer avec l'API si connecté
      if (_networkEnabled) {
        try {
          final result = await _syncService?.syncDataWithApi();
          if (result?.success == true) {
            setState(() {
              _syncMessage = 'Client supprimé (local + API)';
            });
          }
        } catch (e) {
          // Le client a été supprimé localement malgré tout
          setState(() {
            _syncMessage = 'Client supprimé localement (erreur API: $e)';
          });
        }
      } else {
        setState(() {
          _syncMessage = 'Client supprimé localement (offline)';
        });
      }

      // Efface le message après 2 secondes
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _syncMessage = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur suppression: $e';
      });
    }
  }

  /// Formater l'heure de la dernière sync
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inSeconds < 1) {
      return 'maintenant';
    } else if (diff.inSeconds < 60) {
      return 'il y a ${diff.inSeconds}s';
    } else if (diff.inMinutes < 60) {
      return 'il y a ${diff.inMinutes}m';
    } else {
      return 'il y a ${diff.inHours}h';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brick Offline-First POC'),
        elevation: 2,
      ),
      body: Column(
        children: [
          // Connectivité
          SwitchListTile(
            title: Text(
              _networkEnabled ? '🟢 Connecté' : '🔴 Déconnecté',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _networkEnabled ? Colors.green : Colors.red,
              ),
            ),
            subtitle: _lastSyncTime != null
                ? Text(
                    'Active/Désactive la synchronisation • Dernière sync: ${_formatTime(_lastSyncTime!)}',
                  )
                : const Text('Active/Désactive la synchronisation réseau'),
            value: _networkEnabled,
            onChanged: _repository == null ? null : _toggleNetwork,
          ),
          const Divider(),

          // Messages d'erreur
          if (_error != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Messages de succès
          if (_syncMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.green.shade50,
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _syncMessage!,
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Boutons d'action
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: _busy ? null : _syncFromApi,
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('GET API'),
                ),
                ElevatedButton.icon(
                  onPressed: (_busy || _syncing) ? null : _syncLocalToApi,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('PUSH Local'),
                ),
                ElevatedButton.icon(
                  onPressed: _busy ? null : _addLocalCustomer,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Ajouter'),
                ),
                // Indicateur de polling actif
                if (_networkEnabled && _pollTimer != null)
                  Chip(
                    avatar: const Icon(Icons.sync, size: 16),
                    label: const Text('Polling auto'),
                    backgroundColor: Colors.green.shade100,
                  ),
                if (_busy || _syncing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Liste des clients
          Expanded(
            child: _customers.isEmpty
                ? Center(
                    child: Text(
                      _networkEnabled ? 'Aucun client' : 'Mode offline - Aucun client local',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _customers.length,
                    itemBuilder: (context, index) {
                      final customer = _customers[index];
                      final isLocalId = customer.id >= 10000;
                      return ListTile(
                        title: Text(customer.name),
                        subtitle: Text(
                          '${customer.email} • ${customer.age} ans',
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isLocalId ? Colors.blue : Colors.grey,
                          child: Text(
                            customer.id.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCustomer(customer),
                          tooltip: 'Supprimer',
                        ),
                        tileColor: isLocalId ? Colors.blue.shade50 : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
