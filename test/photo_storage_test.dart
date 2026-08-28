import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:photo_report/data/photo_storage.dart';

void main() {
  test('repairs a stored photo path after the iOS container changes', () async {
    final root = await Directory.systemTemp.createTemp(
      'photo-report-path-test-',
    );
    addTearDown(() => root.delete(recursive: true));
    final currentDocuments = Directory(p.join(root.path, 'Documents'));
    final currentPhoto = File(
      p.join(currentDocuments.path, 'PhotoReport', 'photos', 'site-photo.png'),
    );
    await currentPhoto.create(recursive: true);
    await currentPhoto.writeAsBytes(const [0, 1, 2]);

    final resolved = await const PhotoStorage().resolvePhotoPath(
      '/old/container/Documents/PhotoReport/photos/site-photo.png',
      documentsPath: currentDocuments.path,
    );

    expect(resolved, currentPhoto.path);
  });

  test('keeps the stored path when no relocated photo exists', () async {
    final root = await Directory.systemTemp.createTemp(
      'photo-report-path-test-',
    );
    addTearDown(() => root.delete(recursive: true));
    const storedPath =
        '/old/container/Documents/PhotoReport/photos/missing.png';

    final resolved = await const PhotoStorage().resolvePhotoPath(
      storedPath,
      documentsPath: root.path,
    );

    expect(resolved, storedPath);
  });
}
