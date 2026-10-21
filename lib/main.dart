import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agendamentos',
      home: const HomeScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // Fundo geral suave
        scaffoldBackgroundColor: const Color(0xFFF7F2EE),

        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF8B5E4D),
          onPrimary: Colors.white,
          secondary: Color(0xFF6F4E37),
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF2C2420),
          onSurfaceVariant: Color(0xFF4A3B32),
        ),

        // Tipografia com alto contraste e legibilidade
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF2C2420)),
          bodyMedium: TextStyle(color: Color(0xFF2C2420)),
          bodySmall: TextStyle(color: Color(0xFF4A3B32)),
          titleLarge: TextStyle(color: Color(0xFF2C2420), fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Color(0xFF2C2420), fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: Color(0xFF3D2F28)),
          headlineMedium: TextStyle(color: Color(0xFF2C2420), fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: Color(0xFF2C2420), fontWeight: FontWeight.bold),
        ),

        // Barra superior
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F2EE),
          foregroundColor: Color(0xFF4A342B),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF38251E),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(
            color: Color(0xFF4A342B),
          ),
        ),

        // Cards
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFFFF),
          elevation: 1,
          margin: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFFE2D5CC),
              width: 1,
            ),
          ),
        ),

        // ListTile theme com cores bem visíveis
        listTileTheme: const ListTileThemeData(
          textColor: Color(0xFF2C2420),
          iconColor: Color(0xFF8B5E4D),
          titleTextStyle: TextStyle(
            color: Color(0xFF2C2420),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          subtitleTextStyle: TextStyle(
            color: Color(0xFF5A4940),
            fontSize: 14,
          ),
        ),

        // Campos de texto
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          labelStyle: const TextStyle(
            color: Color(0xFF5A4940),
            fontWeight: FontWeight.w500,
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF7D6B62),
          ),
          prefixIconColor: const Color(0xFF6F4E37),
          suffixIconColor: const Color(0xFF6F4E37),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFD6C5BA),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFD6C5BA),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF8B5E4D),
              width: 2,
            ),
          ),
        ),

        // Botões principais
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5E4D),
            foregroundColor: Colors.white,
            elevation: 1,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Botões contornados
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6F4E37),
            side: const BorderSide(
              color: Color(0xFF8B5E4D),
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

