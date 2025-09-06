abstract class IDatabaseService {
  Future<void> connect();
  Future<void> disconnect();
  Future<dynamic> query(String collection, Map<String, dynamic> filter);
  Future<dynamic> insert(String collection, Map<String, dynamic> document);
  Future<dynamic> update(String collection, Map<String, dynamic> filter,
      Map<String, dynamic> update);
  Future<dynamic> delete(String collection, Map<String, dynamic> filter);
}
