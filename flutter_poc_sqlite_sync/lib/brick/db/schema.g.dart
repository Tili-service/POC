// GENERATED CODE DO NOT EDIT
// This file should be version controlled
import 'package:brick_sqlite/db.dart';
part '20260317160322.migration.dart';
part '20260318000000.migration.dart';

/// All intelligently-generated migrations from all `@Migratable` classes on disk
final migrations = <Migration>{const Migration20260317160322(), const Migration20260318000000()};

/// A consumable database structure including the latest generated migration.
final schema = Schema(
  20260318000000,
  generatorVersion: 1,
  tables: <SchemaTable>{
    SchemaTable(
      'Customer',
      columns: <SchemaColumn>{
        SchemaColumn(
          '_brick_id',
          Column.integer,
          autoincrement: true,
          nullable: false,
          isPrimaryKey: true,
        ),
        SchemaColumn('id', Column.integer, unique: true),
        SchemaColumn('name', Column.varchar),
        SchemaColumn('email', Column.varchar),
        SchemaColumn('age', Column.integer),
        SchemaColumn('bio', Column.varchar),
      },
      indices: <SchemaIndex>{},
    ),
  },
);
