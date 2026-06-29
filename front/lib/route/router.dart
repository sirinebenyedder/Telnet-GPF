import 'package:Telnet/route/screen_export.dart';
import 'package:Telnet/screens/auth/verify_code_screen.dart';
import 'package:Telnet/screens/profile/forcedprofileupdate.dart';
import 'package:flutter/material.dart';
import 'package:Telnet/services/token_service.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final userId = authService.decodedToken?['userId'];
    final userRole = authService.decodedToken?['role'];
    switch (settings.name) {
      case onbordingScreenRoute:
        final arguments = settings.arguments as Map<String, dynamic>?;
        final viewOnlyProject = arguments?['viewOnlyProject'];
        return MaterialPageRoute(
          builder:
              (_) => OnBordingScreen(
                userId: userId,
                userRole: userRole,
                viewOnlyProject: viewOnlyProject,
              ),
        );
      case logInScreenRoute:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case profileScreenRoute:
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(userId: userId, userRole: userRole),
        );
      case addScreenRoute:
        return MaterialPageRoute(builder: (_) => AddScreen(userId: userId));
      case entryPointScreenRoute:
        final arguments = settings.arguments as Map<String, dynamic>?;
        final viewOnlyProject = arguments?['viewOnlyProject'];
        return MaterialPageRoute(
          builder:
              (_) => EntryPoint(
                userId: userId,
                userRole: userRole,
                viewOnlyProject: viewOnlyProject,
              ),
        );
      case passwordResetScreenRoute: ////////////hethi eli na7ineha
        // Récupérer l'email depuis les arguments
        final String email = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => PasswordResetScreen(email: email),
        );
      case forcedProfileUpdateRoute:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                appBar: AppBar(title: Text('Mise à jour requise')),
                body: ForcedProfileUpdateCard(
                  userId: authService.decodedToken?['userId'],
                ),
              ),
        );
      case newVerifyCodeScreenRouter:
        // Récupérer l'email depuis les arguments
        final String email = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => VerifyCodeScreen(email: email),
        );
      case newPasswordScreenRoute:
        // Récupérer les arguments comme Map
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder:
              (_) => NewPasswordScreen(
                email: args['email'] as String,
                code: args['code'] as String,
              ),
        );

      case addUserScreenRoute:
        return MaterialPageRoute(
          builder:
              (_) => AddUserScreen(
                userId: userId, //userRole: userRole
              ),
        );
      default:
        // Par défaut, redirigez vers l'écran de connexion
        return MaterialPageRoute(builder: (_) => LoginScreen());
    }
  }
}
