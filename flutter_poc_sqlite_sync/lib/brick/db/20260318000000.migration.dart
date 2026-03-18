// GENERATED CODE EDIT WITH CAUTION
// THIS FILE **WILL NOT** BE REGENERATED
// This file should be version controlled and can be manually edited.
part of 'schema.g.dart';

// While migrations are intelligently created, the difference between some commands, such as
// DropTable vs. RenameTable, cannot be determined. For this reason, please review migrations after
// they are created to ensure the correct inference was made.

// The migration version must **always** mirror the file name

const List<MigrationCommand> _migration_20260318000000_up = [
  DropColumn('username', onTable: 'Customer'),
  InsertColumn('age', Column.integer, onTable: 'Customer'),
  InsertColumn('bio', Column.varchar, onTable: 'Customer')
];

const List<MigrationCommand> _migration_20260318000000_down = [
  InsertColumn('username', Column.varchar, onTable: 'Customer'),
  DropColumn('age', onTable: 'Customer'),
  DropColumn('bio', onTable: 'Customer')
];

//
// DO NOT EDIT BELOW THIS LINE
//

@Migratable(
  version: '20260318000000',
  up: _migration_20260318000000_up,
  down: _migration_20260318000000_down,
)
class Migration20260318000000 extends Migration {
  const Migration20260318000000()
    : super(
        version: 20260318000000,
        up: _migration_20260318000000_up,
        down: _migration_20260318000000_down,
      );
}
