import 'dart:io';

import 'package:brick_offline_first_with_rest/brick_offline_first_with_rest.dart';
import 'package:brick_rest/brick_rest.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart' show databaseFactory;

import 'brick.g.dart';
import 'db/schema.g.dart';

class ToggleableNetworkClient extends http.BaseClient {
  final http.Client _inner;
  bool isOnline;

  ToggleableNetworkClient({http.Client? inner, this.isOnline = true})
      : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (!isOnline) {
      throw const SocketException('Network disabled by user');
    }

    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

class AppRepository extends OfflineFirstWithRestRepository {
  final ToggleableNetworkClient networkClient;

  AppRepository._({
    required this.networkClient,
    required RestProvider restProvider,
    required SqliteProvider sqliteProvider,
  }) : super(
          restProvider: restProvider,
          sqliteProvider: sqliteProvider,
          migrations: migrations,
          offlineQueueManager: RestRequestSqliteCacheManager(
            'brick_offline_queue.sqlite',
            databaseFactory: databaseFactory,
          ),
        );

  static Future<AppRepository> configure({
    String baseUrl = 'http://10.0.2.2:8000',
  }) async {
    final networkClient = ToggleableNetworkClient();

    final repository = AppRepository._(
      networkClient: networkClient,
      restProvider: RestProvider(
        baseUrl,
        modelDictionary: restModelDictionary,
        client: networkClient,
      ),
      sqliteProvider: SqliteProvider(
        'brick_offline_repository.sqlite',
        databaseFactory: databaseFactory,
        modelDictionary: sqliteModelDictionary,
      ),
    );

    await repository.initialize();
    return repository;
  }

  void setNetworkEnabled(bool enabled) {
    networkClient.isOnline = enabled;
  }
}
