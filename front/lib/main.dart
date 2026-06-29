import 'package:flutter/material.dart';
import 'package:Telnet/route/route_constants.dart';
import 'package:Telnet/route/router.dart';
import 'package:Telnet/services/token_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Chargez le token au démarrage
  await authService.loadToken();
  await dotenv.load();

  // route initiale
  final token = authService.authToken;
  final isTokenValid = token != null && !JwtDecoder.isExpired(token);
  //final initialRoute = isTokenValid ? entryPointScreenRoute : logInScreenRoute;
  final initialRoute = await _determineInitialRoute();
  runApp(MyApp(initialRoute: initialRoute));
}

Future<String> _determineInitialRoute() async {
  final token = authService.authToken;
  final isTokenValid = token != null && !JwtDecoder.isExpired(token);
  print(token);
  if (!isTokenValid) return logInScreenRoute;

  // Vérification avancée du statut resetPassword
  final requiresReset = await authService.checkPasswordResetStatus();
  print(requiresReset);
  if (requiresReset) return forcedProfileUpdateRoute;
  print('required');
  print(requiresReset);
  return entryPointScreenRoute;
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter',
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: initialRoute,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR')],
    );
  }
}
