import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:puked/generated/l10n/app_localizations.dart';
import 'package:puked/features/main/presentation/main_screen.dart';
import 'package:puked/features/settings/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  runApp(
    UncontrolledProviderScope(container: container, child: const PukedApp()),
  );
}

class PukedApp extends ConsumerStatefulWidget {
  const PukedApp({super.key});

  @override
  ConsumerState<PukedApp> createState() => _PukedAppState();
}

class _PukedAppState extends ConsumerState<PukedApp> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    const fontFallback = [
      'Heiti SC',
      'Microsoft YaHei',
      'Source Han Sans SC',
      'Noto Sans CJK SC',
      'sans-serif',
    ];

    final baseTheme = ThemeData(
      useMaterial3: true,
      fontFamilyFallback: fontFallback,
    );

    return MaterialApp(
      title: 'Cola Cup Simulator',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh'),
        Locale('en'),
      ],
      locale: settings.locale,
      theme: baseTheme.copyWith(
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: const Color(0xFF248A3D),
          secondary: const Color(0xFF4CAF50),
        ),
      ),
      darkTheme: baseTheme.copyWith(
        brightness: Brightness.dark,
        colorScheme: baseTheme.colorScheme.copyWith(
          brightness: Brightness.dark,
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF81C784),
        ),
      ),
      themeMode: settings.themeMode,
      home: const MainScreen(),
    );
  }
}
