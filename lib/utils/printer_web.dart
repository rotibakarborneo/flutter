// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void printReceipt() {
  try {
    js.context.callMethod('print');
  } catch (_) {}
}
