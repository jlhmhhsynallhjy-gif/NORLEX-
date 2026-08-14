import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'file_entity.dart';

class LocalFileService implements FileService {
  @override
  Future<NorlexFile> upload({required String localPath, String? projectId}) async {
    // Foundation only - no real upload yet
    throw UnimplementedError('File upload not implemented - foundation only');
  }

  @override
  Future<void> deleteFile(String fileId) async {
    throw UnimplementedError();
  }

  @override
  Future<NorlexFile> getFile(String fileId) async {
    throw UnimplementedError();
  }

  @override
  Future<String> getDownloadUrl(String fileId) async {
    throw UnimplementedError();
  }

  @override
  Stream<double> uploadProgress(String fileId) => const Stream.empty();

  Future<Directory> getAppDocumentsDir() => getApplicationDocumentsDirectory();
}
