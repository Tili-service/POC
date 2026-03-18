import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:brick_offline_first/brick_offline_first.dart';

import 'models/customer.model.dart';
import 'repository.dart';

/// Service pour détecter et synchroniser les divergences entre SQLite et l'API
class SyncService {
  final AppRepository repository;
  final String baseUrl;

  SyncService({
    required this.repository,
    required this.baseUrl,
  });

  /// Compare les données locales (SQLite) avec les données de l'API
  /// et pousse les changements vers l'API si elles diffèrent
  /// PRIORITÉ: DELETE > CREATE/UPDATE
  Future<SyncResult> syncDataWithApi() async {
    final result = SyncResult();

    try {
      // Récupérer les données locales (SQLite)
      final localCustomers = await repository.get<Customer>(
        policy: OfflineFirstGetPolicy.localOnly,
      );

      // Récupérer les données de l'API
      final remoteCustomers = await _fetchRemoteCustomers();

      // Analyser les différences
      final (toUpdate, toCreate, toDelete) = _analyzer(
        localCustomers: localCustomers,
        remoteCustomers: remoteCustomers,
      );

      // **PRIORITÉ 1: Traiter les suppressions EN PREMIER**
      for (final id in toDelete) {
        await _deleteRemoteCustomer(id);
        result.deleted.add(id);
      }

      // **PRIORITÉ 2: Traiter les créations**
      for (final customer in toCreate) {
        await _createRemoteCustomer(customer);
        result.created.add(customer);
      }

      // **PRIORITÉ 3: Traiter les mises à jour**
      for (final customer in toUpdate) {
        await _updateRemoteCustomer(customer);
        result.updated.add(customer);
      }

      result.success = true;
    } catch (e) {
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// Analyser les différences entre données locales et distantes
  (
    List<Customer> toUpdate,
    List<Customer> toCreate,
    List<int> toDelete
  ) _analyzer({
    required List<Customer> localCustomers,
    required List<Customer> remoteCustomers,
  }) {
    final toUpdate = <Customer>[];
    final toCreate = <Customer>[];
    final toDelete = <int>[];

    // Créer un map des clients distants par ID pour comparaison rapide
    final remoteMap = {for (var c in remoteCustomers) c.id: c};
    final localMap = {for (var c in localCustomers) c.id: c};

    // Vérifier chaque client local
    for (final local in localCustomers) {
      final remote = remoteMap[local.id];

      if (remote == null) {
        // Le client n'existe pas sur l'API -> créer
        toCreate.add(local);
      } else if (!_customersEqual(local, remote)) {
        // Les données différent -> mettre à jour
        toUpdate.add(local);
      }
    }

    // **IMPORTANT: Vérifier les clients qui existent en remote mais pas en local**
    // = Clients supprimés localement -> DELETE sur l'API
    for (final remoteCustomer in remoteCustomers) {
      if (!localMap.containsKey(remoteCustomer.id)) {
        // Le client existe en remote mais pas en local -> il a été supprimé localement
        toDelete.add(remoteCustomer.id);
      }
    }

    return (toUpdate, toCreate, toDelete);
  }

  /// Comparer si deux clients sont égaux
  bool _customersEqual(Customer a, Customer b) {
    return a.id == b.id &&
        a.name == b.name &&
        a.email == b.email &&
        a.age == b.age &&
        a.bio == b.bio;
  }

  /// Récupérer les clients de l'API
  Future<List<Customer>> _fetchRemoteCustomers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData
            .map((json) => Customer(
                  id: json['id'] as int,
                  name: json['name'] as String,
                  email: json['email'] as String,
                  age: json['age'] as int,
                  bio: json['bio'] as String?,
                ))
            .toList();
      } else {
        throw Exception(
            'Erreur lors de la récupération des données: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion à l\'API: $e');
    }
  }

  /// Mettre à jour un client sur l'API
  Future<void> _updateRemoteCustomer(Customer customer) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/${customer.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': customer.id,
        'name': customer.name,
        'email': customer.email,
        'age': customer.age,
        'bio': customer.bio,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Erreur MAJ client ${customer.id}: ${response.statusCode}');
    }
  }

  /// Créer un client sur l'API
  Future<void> _createRemoteCustomer(Customer customer) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': customer.id,
        'name': customer.name,
        'email': customer.email,
        'age': customer.age,
        'bio': customer.bio,
      }),
    );

    // 200 ou 201 (Created) acceptés
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Erreur création client ${customer.id}: ${response.statusCode} - ${response.body}');
    }
  }

  /// Supprimer un client sur l'API
  Future<void> _deleteRemoteCustomer(int customerId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$customerId'),
        headers: {'Content-Type': 'application/json'},
      );

      // 200 OK ou 404 Not Found acceptés
      // 404 = normal si le client n'a jamais été créé en API (créé que localement)
      if (response.statusCode != 200 && response.statusCode != 404) {
        throw Exception(
            'Erreur suppression client $customerId: ${response.statusCode}');
      }
    } catch (e) {
      // Ignorer les 404 (client créé localement uniquement)
      if (!e.toString().contains('404')) {
        rethrow;
      }
    }
  }
}

/// Résultat de la synchronisation
class SyncResult {
  bool success = false;
  String? error;
  final List<Customer> created = [];
  final List<Customer> updated = [];
  final List<int> deleted = [];

  int get totalChanges => created.length + updated.length + deleted.length;

  String get summary {
    if (!success) {
      return 'Erreur: $error';
    }
    if (totalChanges == 0) {
      return 'Aucune modification détectée';
    }
    final parts = <String>[];
    if (created.isNotEmpty) parts.add('✅ ${created.length} créés');
    if (updated.isNotEmpty) parts.add('🔄 ${updated.length} mis à jour');
    if (deleted.isNotEmpty) parts.add('❌ ${deleted.length} supprimés');
    return parts.join(' • ');
  }
}
