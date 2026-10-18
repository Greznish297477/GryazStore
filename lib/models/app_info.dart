class AppInfo {
  final String name;
  final String repoName;
  final String description;
  final String version;
  final String tagName;
  final String? releaseNotes;
  final DateTime publishedAt;
  final String? apkUrl;
  final String? apkName;
  final int? apkSize;
  final String htmlUrl;
  final String? ownerAvatar;
  final String? iconUrl;

  AppInfo({
    required this.name,
    required this.repoName,
    required this.description,
    required this.version,
    required this.tagName,
    this.releaseNotes,
    required this.publishedAt,
    this.apkUrl,
    this.apkName,
    this.apkSize,
    required this.htmlUrl,
    this.ownerAvatar,
    this.iconUrl,
  });

  String get displayName {
    switch (repoName.toLowerCase()) {
      case 'aptechka':
        return 'Аптечка';
      case 'multimail':
        return 'MultiMail';
      case 'gryazstore':
      case 'gryaz_store':
        return 'Gryaz Store';
      default:
        return name.isNotEmpty ? name : repoName;
    }
  }

  String get shortDescription {
    if (description.isNotEmpty) return description;
    return 'Приложение из репозитория $repoName';
  }

  String get formattedSize {
    if (apkSize == null) return '';
    final mb = apkSize! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} МБ';
  }

  String get formattedDate {
    return '${publishedAt.day.toString().padLeft(2, '0')}.'
        '${publishedAt.month.toString().padLeft(2, '0')}.'
        '${publishedAt.year}';
  }

  /// Цвет для буквенной иконки, если нет картинки
  int get colorSeed {
    var hash = 0;
    for (final c in repoName.codeUnits) {
      hash = (hash * 31 + c) & 0x7FFFFFFF;
    }
    return hash;
  }
}
