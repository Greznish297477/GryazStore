import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Скачивание и установка APK (как в Аптечке).
class DownloadService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(minutes: 5),
    headers: {
      'User-Agent': 'GryazStore/1.0',
      'Accept': 'application/octet-stream',
    },
  ));

  static Future<Directory> _updatesDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/updates');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<void> cleanup() async {
    try {
      final dir = await _updatesDir();
      if (await dir.exists()) {
        await for (final f in dir.list()) {
          if (f is File &&
              (f.path.endsWith('.apk') || f.path.endsWith('.tmp'))) {
            await f.delete();
          }
        }
      }
    } catch (_) {}
  }

  static Future<bool> canInstallPackages() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.requestInstallPackages.status;
    return status.isGranted;
  }

  static Future<void> openInstallPermissionSettings() async {
    await Permission.requestInstallPackages.request();
  }

  static Future<File?> downloadApk({
    required String url,
    required String fileName,
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await cleanup();
      final dir = await _updatesDir();
      final safeName = fileName.endsWith('.apk') ? fileName : '$fileName.apk';
      final out = File('${dir.path}/$safeName');
      final tmp = File('${dir.path}/$safeName.tmp');

      if (await tmp.exists()) await tmp.delete();

      await _dio.download(
        url,
        tmp.path,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress((received / total).clamp(0.0, 1.0));
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (!await tmp.exists() || await tmp.length() < 10000) {
        if (await tmp.exists()) await tmp.delete();
        return null;
      }

      if (await out.exists()) await out.delete();
      await tmp.rename(out.path);
      onProgress(1.0);
      return out;
    } catch (e) {
      debugPrint('Download error: $e');
      return null;
    }
  }

  static Future<bool> installApk(File apkFile) async {
    if (!await apkFile.exists() || await apkFile.length() < 10000) {
      return false;
    }

    try {
      final result = await OpenFilex.open(
        apkFile.path,
        type: 'application/vnd.android.package-archive',
      );
      return result.type == ResultType.done ||
          result.type == ResultType.noAppToOpen;
    } catch (e) {
      debugPrint('Install error: $e');
      return false;
    }
  }

  static Future<DownloadResult> downloadAndInstall({
    required String url,
    required String fileName,
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    if (Platform.isAndroid) {
      final can = await canInstallPackages();
      if (!can) {
        final status = await Permission.requestInstallPackages.request();
        if (!status.isGranted) {
          return DownloadResult.needPermission;
        }
      }
    }

    final file = await downloadApk(
      url: url,
      fileName: fileName,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );

    if (file == null) {
      return DownloadResult.failed;
    }

    final ok = await installApk(file);
    return ok ? DownloadResult.success : DownloadResult.installFailed;
  }
}

enum DownloadResult {
  success,
  failed,
  needPermission,
  installFailed,
}
