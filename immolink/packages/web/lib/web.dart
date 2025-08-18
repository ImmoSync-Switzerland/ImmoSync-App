// Minimal stub that mimics the small part of `package:web` the app uses.

class HTMLDivElement {
  String? id;
  final Style style = Style();
  void appendChild(Object? child) {}
  void remove() {}
}

class Style {
  String? width;
  String? height;
  String? minHeight;
}

class Document {
  dynamic querySelector(String s) => null;
  dynamic get body => null;
  dynamic getElementById(String id) => null;
}

final Document document = Document();

// Keep the same import name used by the app

typedef JSAny = Object; // fallback

extension ToJS on String {
  dynamic get toJS => this;
}

dynamic jsify(Object? o) => o;
