import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class PhotoStorage {
  const PhotoStorage();

  Future<String> resolvePhotoPath(
    String storedPath, {
    String? documentsPath,
  }) async {
    if (await File(storedPath).exists()) return storedPath;
    final documents = documentsPath == null
        ? await getApplicationDocumentsDirectory()
        : Directory(documentsPath);
    final relocated = p.join(
      documents.path,
      'PhotoReport',
      'photos',
      p.basename(storedPath),
    );
    return await File(relocated).exists() ? relocated : storedPath;
  }

  Future<String> importPhoto(String sourcePath) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      p.join(documents.path, 'PhotoReport', 'photos'),
    );
    await directory.create(recursive: true);
    final extension = p.extension(sourcePath).toLowerCase();
    final safeExtension = extension.isEmpty ? '.jpg' : extension;
    final destination = p.join(
      directory.path,
      '${const Uuid().v4()}$safeExtension',
    );
    await File(sourcePath).copy(destination);
    return destination;
  }

  Future<void> deletePaths(Iterable<String> paths) async {
    for (final path in paths) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<String> writePhotoBytes(List<int> bytes, String extension) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      p.join(documents.path, 'PhotoReport', 'photos'),
    );
    await directory.create(recursive: true);
    final normalized = extension.startsWith('.') ? extension : '.$extension';
    final safeExtension = RegExp(r'^\.[A-Za-z0-9]{1,8}$').hasMatch(normalized)
        ? normalized.toLowerCase()
        : '.jpg';
    final destination = p.join(
      directory.path,
      '${const Uuid().v4()}$safeExtension',
    );
    await File(destination).writeAsBytes(bytes, flush: true);
    return destination;
  }
}
