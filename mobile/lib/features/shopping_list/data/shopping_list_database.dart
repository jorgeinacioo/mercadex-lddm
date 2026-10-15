import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class ShoppingListDatabase {
  ShoppingListDatabase({this._factory, this._filePath});

  final DatabaseFactory? _factory;
  final String? _filePath;

  static const fileName = 'mercadex.db';
  static const version = 1;
  static const createTableSql = '''
CREATE TABLE shopping_list_items (
    product_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    packaging TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
)
''';

  Database? _database;
  Future<Database>? _opening;

  static Future<void> onCreate(Database database, int version) {
    return database.execute(createTableSql);
  }

  Future<Database> open() {
    final current = _database;
    if (current != null && current.isOpen) return Future.value(current);
    return _opening ??= _open();
  }

  Future<Database> _open() async {
    try {
      final database = _factory == null
          ? await openDatabase(
              _filePath ?? path.join(await getDatabasesPath(), fileName),
              version: version,
              onCreate: onCreate,
            )
          : await _factory.openDatabase(
              _filePath ?? path.join(await getDatabasesPath(), fileName),
              options: OpenDatabaseOptions(
                version: version,
                onCreate: onCreate,
              ),
            );
      _database = database;
      return database;
    } finally {
      _opening = null;
    }
  }

  Future<void> close() async {
    final opening = _opening;
    if (opening != null) await opening;
    final current = _database;
    _database = null;
    if (current != null && current.isOpen) await current.close();
  }
}
