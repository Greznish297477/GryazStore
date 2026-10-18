import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_info.dart';
import '../services/download_service.dart';

class AppDetailScreen extends StatefulWidget {
  final AppInfo app;

  const AppDetailScreen({super.key, required this.app});

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> {
  bool _downloading = false;
  double _progress = 0;
  CancelToken? _cancelToken;

  AppInfo get app => widget.app;

  Future<void> _startDownload() async {
    if (app.apkUrl == null) {
      _snack('APK не найден');
      return;
    }
    if (_downloading) return;

    setState(() {
      _downloading = true;
      _progress = 0;
    });
    _cancelToken = CancelToken();

    HapticFeedback.mediumImpact();

    final result = await DownloadService.downloadAndInstall(
      url: app.apkUrl!,
      fileName: app.apkName ?? '${app.repoName}.apk',
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
      cancelToken: _cancelToken,
    );

    if (!mounted) return;
    setState(() => _downloading = false);

    switch (result) {
      case DownloadResult.success:
        _snack('Открыт установщик. Подтверди установку.');
        break;
      case DownloadResult.needPermission:
        _showPermissionDialog();
        break;
      case DownloadResult.failed:
        _snack('Не удалось скачать APK');
        break;
      case DownloadResult.installFailed:
        _snack('Скачано, но не удалось открыть установщик');
        break;
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Нужно разрешение'),
        content: const Text(
          'Чтобы устанавливать приложения, разреши установку из этого источника в настройках.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DownloadService.openInstallPermissionSettings();
            },
            child: const Text('Открыть настройки'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openGitHub() async {
    final uri = Uri.parse(app.htmlUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final letter = app.displayName.isNotEmpty
        ? app.displayName[0].toUpperCase()
        : '?';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // --- Header ---
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1A1A2E), const Color(0xFF0F3460)]
                        : [
                            theme.colorScheme.primaryContainer,
                            theme.colorScheme.secondaryContainer,
                          ],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        _AppIcon(
                          iconUrl: app.iconUrl ?? app.ownerAvatar,
                          letter: letter,
                          size: 88,
                          radius: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- Body ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.displayName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    app.repoName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _InfoChip(icon: Icons.tag_rounded, label: 'Версия ${app.version}'),
                      if (app.formattedSize.isNotEmpty)
                        _InfoChip(icon: Icons.sd_storage_rounded, label: app.formattedSize),
                      _InfoChip(icon: Icons.calendar_today_rounded, label: app.formattedDate),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // --- Download button / progress ---
                  if (_downloading) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _progress > 0 ? _progress : null,
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _progress > 0
                              ? 'Скачивание… ${(_progress * 100).toStringAsFixed(0)}%'
                              : 'Подключение…',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            _cancelToken?.cancel();
                            setState(() {
                              _downloading = false;
                              _progress = 0;
                            });
                          },
                          child: const Text('Отмена'),
                        ),
                      ],
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: _startDownload,
                        icon: const Icon(Icons.download_rounded, size: 24),
                        label: const Text(
                          'Скачать и установить',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _openGitHub,
                      icon: const Icon(Icons.open_in_new_rounded, size: 20),
                      label: const Text('Открыть на GitHub'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Описание',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    app.shortDescription,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  if (app.releaseNotes != null && app.releaseNotes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(
                      'Что нового',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        app.releaseNotes!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final String? iconUrl;
  final String letter;
  final double size;
  final double radius;

  const _AppIcon({
    required this.iconUrl,
    required this.letter,
    this.size = 64,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (iconUrl != null && iconUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: iconUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _LetterIcon(letter: letter, size: size, radius: radius),
          errorWidget: (_, __, ___) => _LetterIcon(letter: letter, size: size, radius: radius),
        ),
      );
    }
    return _LetterIcon(letter: letter, size: size, radius: radius);
  }
}

class _LetterIcon extends StatelessWidget {
  final String letter;
  final double size;
  final double radius;

  const _LetterIcon({required this.letter, required this.size, required this.radius});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
