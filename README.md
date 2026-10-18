# Gryaz Store

Магазин приложений, который автоматически показывает Android-приложения из твоих GitHub Releases.

## Возможности

- Автоматически загружает все публичные репозитории пользователя **Greznish297477**
- Берёт последний Release каждого репозитория
- Показывает только те, у которых есть APK
- Поиск по названию / описанию / версии
- Страница приложения с описанием и changelog
- Кнопка «Скачать APK»
- Material 3 + тёмная тема
- Новые приложения появляются сами после публикации Release

## Как собрать APK автоматически (рекомендуется)

### 1. Создай репозиторий на GitHub

Создай новый репозиторий, например `GryazStore`.

### 2. Загрузи код

```bash
git clone https://github.com/ТВОЙ_ЮЗЕР/GryazStore.git
cd GryazStore

# Скопируй сюда все файлы из архива gryaz_store
# (lib/, android/, pubspec.yaml, .github/ и т.д.)

git add .
git commit -m "Initial commit - Gryaz Store"
git push origin main
```

### 3. Получи APK

**Способ А — через Actions (после каждого push):**
1. Открой вкладку **Actions** в репозитории
2. Выбери последний успешный workflow **Build APK**
3. Внизу скачай артефакт `gryaz-store-apk`

**Способ Б — через Release (красиво):**
```bash
git tag v1.0.0
git push origin v1.0.0
```
После этого в **Releases** появится готовый APK `GryazStore-v1.0.0.apk`.

### 4. Установка на Huawei Nova 11

1. Скачай APK
2. Настройки → Безопасность → Установка из внешних источников → разреши для «Файлы» / браузера / Telegram
3. Открой APK → Установить

## Локальная сборка (если есть Flutter)

```bash
flutter pub get
flutter run                  # запуск
flutter build apk --release  # сборка APK
```

APK будет здесь: `build/app/outputs/flutter-apk/app-release.apk`

## Структура

```
lib/
├── main.dart
├── models/app_info.dart
├── services/github_service.dart
└── screens/
    ├── home_screen.dart
    └── app_detail_screen.dart

.github/workflows/build-apk.yml   ← автоматическая сборка
```

## Как добавить новое приложение в магазин

1. Создай репозиторий с Android-приложением
2. Настрой GitHub Actions (как в MultiMail / aptechka)
3. Опубликуй Release с APK
4. В Gryaz Store нажми «Обновить» — приложение появится само
