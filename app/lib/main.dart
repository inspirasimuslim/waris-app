import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'core/theme.dart';
import 'data/family_repository.dart';
import 'features/network/network_screen.dart';
import 'l10n/app_localizations.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  final repo = InMemoryFamilyRepository(
    familyId: 'local',
    file: File(p.join(dir.path, 'waris', 'family.json')),
  );
  await repo.load();

  runApp(
    ProviderScope(
      overrides: [familyRepositoryProvider.overrideWithValue(repo)],
      child: const WarisApp(),
    ),
  );
}

class WarisApp extends StatelessWidget {
  const WarisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => L.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: warisLightTheme(),
      darkTheme: warisDarkTheme(),
      themeMode: ThemeMode.system, // mod gelap dari hari pertama (SPEC 3.7)
      locale: const Locale('ms'), // Bahasa Melayu sebagai lalai (SPEC 3.8)
      supportedLocales: L.supportedLocales,
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const NetworkScreen(),
    );
  }
}
