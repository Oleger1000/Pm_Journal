// services/update_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String _githubOwner = 'Oleger1000';
  static const String _githubRepo = 'Pm_Journal';

  final Dio _dio = Dio();

  Future<void> checkForUpdates(BuildContext context) async {
    if (!context.mounted) return;

    // Для автоматической установки нужен Android
    if (!Platform.isAndroid) {
      // Для других платформ (iOS, Desktop) используем старую логику
      _showSimpleUpdateDialog(context);
      return;
    }

    try {
      final Map<String, String>? updateInfo = await _getUpdateInfo();
      if (updateInfo == null || !context.mounted) return;

      await _showAndroidUpdateDialog(
        context,
        newVersion: updateInfo['version']!,
        apkUrl: updateInfo['url']!,
        fileName: updateInfo['fileName']!,
      );
    } catch (e) {
      print("❌ Error checking for updates: $e");
    }
  }

  /// Получает информацию о последнем релизе с GitHub.
  /// Возвращает Map с версией, URL и именем файла APK, или null.
  Future<Map<String, String>?> _getUpdateInfo() async {
    print("🚀 Checking for updates...");
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = Version.parse(packageInfo.version);

    final url = Uri.parse(
      'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest',
    );
    final response = await _dio.get(url.toString());

    if (response.statusCode != 200) return null;

    final data = response.data;
    final latestVersionStr = (data['tag_name'] as String).replaceAll('v', '');
    final latestVersion = Version.parse(latestVersionStr);

    print("   - Current version: $currentVersion");
    print("   - Latest version from GitHub: $latestVersion");

    if (latestVersion > currentVersion) {
      print("   - 🎉 New version available!");
      // Ищем в релизе APK файл
      final assets = data['assets'] as List;
      final apkAsset = assets.firstWhere(
        (asset) => (asset['name'] as String).endsWith('.apk'),
        orElse: () => null,
      );

      if (apkAsset != null) {
        return {
          'version': latestVersion.toString(),
          'url': apkAsset['browser_download_url'],
          'fileName': apkAsset['name'],
        };
      }
    }
    print("   - ✅ App is up to date.");
    return null;
  }

  /// Показывает диалог с кнопкой "Обновить", который запускает скачивание и установку.
  Future<void> _showAndroidUpdateDialog(
    BuildContext context, {
    required String newVersion,
    required String apkUrl,
    required String fileName,
  }) async {
    // Используем StatefulBuilder, чтобы обновлять состояние внутри диалога (для прогресса)
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        double? downloadProgress;
        String statusText = 'Найдена новая версия: $newVersion.';

        return StatefulBuilder(
          builder: (builderContext, setState) {
            return AlertDialog(
              title: const Text('Доступно обновление'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusText),
                  if (downloadProgress != null) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: downloadProgress),
                    const SizedBox(height: 4),
                    Text('${(downloadProgress! * 100).toStringAsFixed(0)}%'),
                  ],
                ],
              ),
              actions: <Widget>[
                // Не показываем кнопки, когда идет загрузка
                if (downloadProgress == null)
                  TextButton(
                    child: const Text('Позже'),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                if (downloadProgress == null)
                  FilledButton(
                    child: const Text('Обновить'),
                    onPressed: () async {
                      // Запрашиваем разрешение
                      final permission = await Permission.requestInstallPackages
                          .request();
                      if (permission.isGranted) {
                        _startDownload(
                          apkUrl: apkUrl,
                          fileName: fileName,
                          onProgress: (progress) {
                            setState(() {
                              downloadProgress = progress;
                              statusText = 'Идет скачивание...';
                            });
                          },
                          onDone: (filePath) {
                            Navigator.of(dialogContext).pop();
                            OpenFile.open(filePath); // Запускаем установщик
                          },
                          onError: (e) {
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Ошибка скачивания: $e')),
                            );
                          },
                        );
                      } else {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Для обновления нужно разрешение на установку.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// Логика скачивания файла
  Future<void> _startDownload({
    required String apkUrl,
    required String fileName,
    required Function(double) onProgress,
    required Function(String) onDone,
    required Function(String) onError,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';

      await _dio.download(
        apkUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );
      onDone(filePath);
    } catch (e) {
      onError(e.toString());
    }
  }

  // --- Резервная логика для iOS и других платформ ---

  /// Простая проверка и показ диалога со ссылкой на GitHub
  Future<void> _showSimpleUpdateDialog(BuildContext context) async {
    final Map<String, String>? updateInfo = await _getUpdateInfo();
    if (updateInfo == null || !context.mounted) return;

    // Получаем URL страницы релиза, а не APK
    final url = Uri.parse(
      'https://github.com/$_githubOwner/$_githubRepo/releases/latest',
    );

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Доступно обновление'),
        content: Text('Найдена новая версия: ${updateInfo['version']}.'),
        actions: [
          TextButton(
            child: const Text('Позже'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          FilledButton(
            child: const Text('Перейти'),
            onPressed: () async {
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
  }
}
