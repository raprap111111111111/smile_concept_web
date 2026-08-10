import 'dart:typed_data';

/// Non-web platforms: no-op stub.
/// Add mobile save + open logic here later using path_provider + open_filex.
void openPdfBytes(Uint8List bytes, {required String filename}) {
  // Example:
  //   final dir = await getApplicationDocumentsDirectory();
  //   final file = File('${dir.path}/$filename');
  //   await file.writeAsBytes(bytes);
  //   await OpenFilex.open(file.path);
}