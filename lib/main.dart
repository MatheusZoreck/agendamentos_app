import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async{
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
      home:  const HomeScreen(),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('pt', 'BR'),
      ],

      

theme: ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  // Fundo geral
  scaffoldBackgroundColor: const Color(0xFFF5EAE2),

  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFD7B9A9),
    brightness: Brightness.light,
    primary: const Color(0xFFD7B9A9),
    secondary: const Color(0xFFA98779),
    surface: const Color(0xFFFFFCF8),
  ),

  // Barra superior
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF5EAE2),
    foregroundColor: Color(0xFF6F554B),
    elevation: 0,
    centerTitle: false,
  ),

  // Cards
  cardTheme: CardThemeData(
    color: const Color(0xFFFFFCF8),
    elevation: 0,
    margin: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(
        color: Color(0xFFE8DAD0),
      ),
    ),
  ),

  // Campos de texto
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFFFFCF8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFE2D1C6),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFE2D1C6),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFA98779),
        width: 1.5,
      ),
    ),
  ),

  // Botões principais
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFA98779),
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
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