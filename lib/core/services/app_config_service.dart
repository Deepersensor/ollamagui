import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AppConfigService {
  static Directory? _appDataDir;

  static Future<Directory> getAppDir() async {
    if (_appDataDir != null) {
      return Future.value(_appDataDir);
    }

    Directory appDocDir = await getApplicationDocumentsDirectory();
    _appDataDir = Directory(p.join(appDocDir.path, 'ollamagui'));

    if (!await _appDataDir!.exists()) {
      await _appDataDir!.create(recursive: true);
    }

    return _appDataDir!;
  }
}
