
import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (var file in files) {
    var content = file.readAsStringSync();
    var newContent = content
        .replaceAll('Coins', 'Diamonds')
        .replaceAll('coins', 'diamonds')
        .replaceAll('Coin', 'Diamond')
        .replaceAll('coin', 'diamond');
    if (content != newContent) {
      file.writeAsStringSync(newContent);
      print('Updated ${file.path}');
    }
  }
}

