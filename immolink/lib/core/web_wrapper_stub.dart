// Stub implementations for non-web platforms so code that references
// web DOM types can compile on Windows/Mac/Linux. These are no-op
// implementations and only exist to satisfy the analyzer and compiler.

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

class Element {
  String? id;
  void appendChild(Object? child) {}
  void remove() {}
}

class Document {
  Element? querySelector(String selector) => null;
  Element? get body => null;
  Element? getElementById(String id) => null;
}

final Document document = Document();
