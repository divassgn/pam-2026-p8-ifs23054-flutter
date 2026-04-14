// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/todo_provider.dart';
import 'providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => TodoProvider()),
      ],
      child: const DelcomTodosApp(),
    ),
  );
}

class DelcomTodosApp extends StatefulWidget {
  const DelcomTodosApp({super.key});

  @override
  State<DelcomTodosApp> createState() => _DelcomTodosAppState();
}

class _DelcomTodosAppState extends State<DelcomTodosApp> {
  late final _router = buildRouter(context);

  // Warna seed biru muda — dipakai SAMA untuk light & dark
  // sehingga identitas warna aplikasi konsisten di kedua mode.
  static const Color _seedColor = Color(0xFF29B6F6); // Light Blue 400

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;

    return MaterialApp.router(
      title: 'Delcom Todos',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,

      // ── Light Theme ─────────────────────────────────
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),

      // ── Dark Theme ──────────────────────────────────
      // Sama-sama pakai _seedColor agar warna biru muda
      // tetap konsisten saat mode gelap diaktifkan.
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      routerConfig: _router,
    );
  }
}
