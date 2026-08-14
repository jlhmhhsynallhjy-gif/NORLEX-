enum FileSourceType { local, remote, uploaded, generated, project }

enum FileStatus { pending, uploading, uploaded, processing, ready, failed, deleted }

class NorlexFile {
  final String id;
  final String name;
  final String? originalName;
  final String mimeType;
  final int sizeBytes;
  final FileSourceType sourceType;
  final FileStatus status;
  final String? localPath;
  final String? remoteUrl;
  final String? projectId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NorlexFile({
    required this.id,
    required this.name,
    this.originalName,
    required this.mimeType,
    required this.sizeBytes,
    required this.sourceType,
    required this.status,
    this.localPath,
    this.remoteUrl,
    this.projectId,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';
  bool get isAudio => mimeType.startsWith('audio/');
  bool get isReady => status == FileStatus.ready;

}

abstract class FileService {
  Future<NorlexFile> upload({required String localPath, String? projectId});
  Future<NorlexFile> getFile(String fileId);
  Future<void> deleteFile(String fileId);
  Future<String> getDownloadUrl(String fileId);
  Stream<double> uploadProgress(String fileId);
}
