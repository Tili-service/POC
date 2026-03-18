import 'package:brick_core/core.dart';
import 'package:brick_offline_first_with_rest/brick_offline_first_with_rest.dart';
import 'package:brick_rest/brick_rest.dart';
import 'package:brick_sqlite/brick_sqlite.dart';

class CustomerRequest extends RestRequestTransformer {
  @override
  RestRequest get get => const RestRequest(url: '/users');

  @override
  RestRequest get upsert => const RestRequest(url: '/users');

  @override
  RestRequest? get delete {
    final customer = instance as Customer?;
    if (customer == null) return null;

    return RestRequest(url: '/users/${customer.id}');
  }

  CustomerRequest(Query? query, Model? instance) : super(query, instance);
}

@ConnectOfflineFirstWithRest(
  restConfig: RestSerializable(requestTransformer: CustomerRequest.new),
  sqliteConfig: SqliteSerializable(),
)
class Customer extends OfflineFirstWithRestModel {
  @Sqlite(unique: true)
  final int id;

  final String name;

  final String email;

  final int age;

  final String? bio;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    this.bio,
  });
}
