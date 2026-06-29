/*import 'package:Telnet/screens/profile/profil_card.dart';
import 'package:flutter/material.dart';

class ForcedProfileUpdateCard extends StatelessWidget {
  final String userId;

  const ForcedProfileUpdateCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null, // Supprime complètement l'AppBar
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Sécurité requise',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vous devez mettre à jour votre mot de passe avant de continuer',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ProfileCard(
                  titleText: 'Mise à jour de sécurité',
                  isForcedUpdate: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}*/
import 'package:Telnet/screens/profile/profil_card.dart';
import 'package:flutter/material.dart';

class ForcedProfileUpdateCard extends StatelessWidget {
  final String userId;

  const ForcedProfileUpdateCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop:
          () async => false, // Empêche le retour par le bouton back du système
      child: Scaffold(
        // Suppression complète de l'AppBar
        appBar: null,
        // Alternative : AppBar transparent sans boutons
        // appBar: AppBar(
        //   backgroundColor: Colors.transparent,
        //   elevation: 0,
        //   automaticallyImplyLeading: false, // Supprime le bouton retour
        //   toolbarHeight: 0, // Hauteur 0 pour le rendre invisible
        // ),
        body: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 60,
                    ), // Plus d'espace en haut sans AppBar
                    Icon(
                      Icons.security,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Sécurité requise',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Vous devez mettre à jour votre mot de passe avant de continuer',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ProfileCard(
                      titleText: 'Mise à jour de sécurité',
                      isForcedUpdate: true,
                    ),
                    const SizedBox(height: 24),
                    // Message informatif supplémentaire
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Cette mise à jour est obligatoire pour maintenir la sécurité de votre compte.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
