import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';

class BackupFileService {
  static const int schemaVersion = 1;

  const BackupFileService();

  Future<({String fileName, Uint8List bytes, String preview})> buildBackupFile({
    required Map<String, dynamic> snapshot,
  }) async {
    final now = DateTime.now();
    final payload = <String, dynamic>{
      'schemaVersion': schemaVersion,
      'exportedAt': now.toIso8601String(),
      'payload': snapshot,
    };
    final jsonText = const JsonEncoder.withIndent('  ').convert(payload);
    return (
      fileName: '${snapshot['backupId'] ?? 'backup_${now.millisecondsSinceEpoch}'}.petbackup.json',
      bytes: Uint8List.fromList(utf8.encode(jsonText)),
      preview: jsonText.length > 2500 ? jsonText.substring(0, 2500) : jsonText,
    );
  }

  Future<String> persistTempBackupBytes({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String?> pickBackupFile() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'Backup',
          extensions: ['json'],
        ),
      ],
    );
    return file?.path;
  }

  Future<Map<String, dynamic>> readBackupPayload(String path) async {
    final content = await File(path).readAsString();
    final decoded = jsonDecode(content);
    if (decoded is! Map) {
      throw const FormatException('Backup file is not a JSON object');
    }
    final map = Map<String, dynamic>.from(decoded);
    final version = map['schemaVersion'];
    if (version is! int || version != schemaVersion) {
      throw FormatException('Unsupported backup schemaVersion: $version');
    }
    final payload = map['payload'];
    if (payload is! Map) {
      throw const FormatException('Backup file payload is missing');
    }
    return Map<String, dynamic>.from(payload);
  }
}

