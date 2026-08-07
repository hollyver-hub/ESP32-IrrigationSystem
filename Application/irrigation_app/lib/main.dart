import 'package:flutter/material.dart';
import 'screens/welcome.dart';
import 'constants/globals.dart' as globals;


final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const EveApp());
}

class EveApp extends StatelessWidget {
  const EveApp ({super.key});

@override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'E.V.E.',
          themeMode: currentMode,
          
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: globals.white_background_primary,
            cardColor: globals.white_background_secondary, 
            
            dialogBackgroundColor: globals.white_background_terciary, 
            canvasColor: globals.white_background_terciary, 

            appBarTheme: const AppBarTheme(
              backgroundColor: globals.white_background_secondary,
              iconTheme: IconThemeData(color: globals.white_background_text),
              titleTextStyle: TextStyle(color: globals.white_background_text, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: globals.white_background_text), 
              bodyMedium: TextStyle(color: Colors.black54), 
            ),
          ),
          
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: globals.black_background_primary,
            cardColor: globals.black_background_secondary,
            
            dialogBackgroundColor: globals.black_background_tertiary, 
            canvasColor: globals.black_background_tertiary,

            appBarTheme: const AppBarTheme(
              backgroundColor: globals.black_background_secondary,
              iconTheme: IconThemeData(color: globals.black_background_text),
              titleTextStyle: TextStyle(color: globals.black_background_text, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: globals.black_background_text), 
              bodyMedium: TextStyle(color: globals.black_background_text_secondary), 
            ),
          ),
          
          home: const WelcomeScreen(),
        );
      },
    );
  }
}
