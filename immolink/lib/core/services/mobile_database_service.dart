import 'package:mongo_dart/mongo_dart.dart';
import 'database_interface.dart';
import 'database_exception.dart';
import '../config/db_config.dart';

class MobileDatabaseService implements IDatabaseService {
  static Db? _db;

  @override
  Future<void> connect() async {
    try {
      _db = await Db.create(DbConfig.connectionUri);
      await _db!.open();
      print('Mobile database connected successfully');
    } catch (e) {
      print('Mobile database connection failed: $e');
      throw DatabaseException('Failed to connect: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    await _db?.close();
    _db = null;
  }

  @override
  Future<dynamic> query(String collection, Map<String, dynamic> filter) async {
    if (_db == null) {
      throw DatabaseException('Database not connected');
    }

    try {
      final coll = _db!.collection(collection);
      return await coll.find(filter).toList();
    } catch (e) {
      throw DatabaseException('Query failed: $e');
    }
  }

  @override
  Future<dynamic> insert(
      String collection, Map<String, dynamic> document) async {
    if (_db == null) {
      throw DatabaseException('Database not connected');
    }

    try {
      final coll = _db!.collection(collection);
      return await coll.insertOne(document);
    } catch (e) {
      throw DatabaseException('Insert failed: $e');
    }
  }

  @override
  Future<dynamic> update(String collection, Map<String, dynamic> filter,
      Map<String, dynamic> update) async {
    if (_db == null) {
      throw DatabaseException('Database not connected');
    }

    try {
      final coll = _db!.collection(collection);
      return await coll.updateOne(filter, {'\$set': update});
    } catch (e) {
      throw DatabaseException('Update failed: $e');
    }
  }

  @override
  Future<dynamic> delete(String collection, Map<String, dynamic> filter) async {
    if (_db == null) {
      throw DatabaseException('Database not connected');
    }

    try {
      final coll = _db!.collection(collection);
      return await coll.deleteOne(filter);
    } catch (e) {
      throw DatabaseException('Delete failed: $e');
    }
  }
}
