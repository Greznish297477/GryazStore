import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_info.dart';

class GitHubService {
  static const String _username = 'Greznish297477';
  static const String _baseUrl = 'https://api.github.com';

  Future<List<AppInfo>> fetchApps() async {
    final repos = await _fetchRepos();
    final List<AppInfo> apps = [];

    for (final repo in repos) {
      final app = await _fetchLatestRelease(repo);
      if (app != null) {
        apps.add(app);
      }
    }

    apps.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return apps;
  }

  Future<List<Map<String, dynamic>>> _fetchRepos() async {
    final url = Uri.parse('$_baseUrl/users/$_username/repos?per_page=100&sort=updated');
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'GryazStore/1.0',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Не удалось загрузить репозитории: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  /// Иконка: пробуем известные пути, иначе Open Graph / аватар
  String? _resolveIconUrl(String repoName, String? ownerAvatar) {
    final lower = repoName.toLowerCase();
    // Известные иконки из репозиториев (raw)
    const known = <String, String>{
      // можно добавить прямые ссылки на иконки позже
    };
    if (known.containsKey(lower)) return known[lower];

    // GitHub Open Graph preview репозитория — часто выглядит как карточка
    // Более стабильный вариант: аватар владельца
    if (ownerAvatar != null && ownerAvatar.isNotEmpty) {
      return ownerAvatar;
    }
    return null;
  }

  Future<AppInfo?> _fetchLatestRelease(Map<String, dynamic> repo) async {
    final repoName = repo['name'] as String;
    final ownerAvatar = repo['owner']?['avatar_url'] as String?;
    final url = Uri.parse('$_baseUrl/repos/$_username/$repoName/releases/latest');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'GryazStore/1.0',
        },
      );

      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final assets = data['assets'] as List<dynamic>? ?? [];

      Map<String, dynamic>? apkAsset;
      for (final asset in assets) {
        final name = (asset['name'] as String).toLowerCase();
        if (name.endsWith('.apk')) {
          if (name.contains('release') && !name.contains('debug')) {
            apkAsset = asset;
            break;
          }
          apkAsset ??= asset;
        }
      }

      if (apkAsset == null) return null;

      final publishedAt = DateTime.parse(data['published_at'] as String);
      final iconUrl = _resolveIconUrl(repoName, ownerAvatar);

      return AppInfo(
        name: (data['name'] as String?)?.isNotEmpty == true
            ? data['name'] as String
            : repoName,
        repoName: repoName,
        description: (repo['description'] as String?) ?? '',
        version: data['tag_name'] as String? ?? '',
        tagName: data['tag_name'] as String? ?? '',
        releaseNotes: data['body'] as String?,
        publishedAt: publishedAt,
        apkUrl: apkAsset['browser_download_url'] as String?,
        apkName: apkAsset['name'] as String?,
        apkSize: apkAsset['size'] as int?,
        htmlUrl: data['html_url'] as String? ?? repo['html_url'] as String,
        ownerAvatar: ownerAvatar,
        iconUrl: iconUrl,
      );
    } catch (e) {
      return null;
    }
  }
}
