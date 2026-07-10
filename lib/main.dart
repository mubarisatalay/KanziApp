import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // The session is loaded asynchronously by authStateProvider (reads the stored
  // JWT and calls /auth/me). No backend SDK to initialize here anymore.
  runApp(
    const ProviderScope(
      child: KanziApp(),
    ),
  );
}
