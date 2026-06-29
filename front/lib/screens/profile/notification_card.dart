import 'package:flutter/material.dart';
import 'package:Telnet/constants.dart';

class NotificationCard extends StatelessWidget {
  final dynamic notification;
  final bool showActions;
  final Future<void> Function(bool)? onRespond;
  final Color? cardColor;
  final bool isCurrentUserSender;
  final bool isCurrentUserRecipient;

  const NotificationCard({
    Key? key,
    required this.notification,
    this.showActions = false,
    this.onRespond,
    this.cardColor,
    this.isCurrentUserSender = false,
    required this.isCurrentUserRecipient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extraction sécurisée des données
    final String title = notification['title']?.toString() ?? 'Notification';
    final String message =
        notification['message']?.toString() ?? 'Pas de détails';
    final String createdAt =
        notification['createdAt']?.toString() ?? 'Date inconnue';
    final String? respondedAt = notification['respondedAt']?.toString();
    final String type = notification['type']?.toString() ?? '';

    // Extraction des informations
    final sender =
        notification['sender'] is Map ? notification['sender'] : null;
    final recipient =
        notification['recipient'] is Map ? notification['recipient'] : null;
    final senderName = sender?['name']?.toString() ?? 'Expéditeur inconnu';
    final recipientName =
        recipient?['name']?.toString() ?? 'Destinataire inconnu';

    // Métadonnées
    final metadata =
        notification['metadata'] is Map ? notification['metadata'] : null;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: defaultPadding),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isCurrentUserRecipient ? Colors.red : Colors.transparent,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec titre et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _getNotificationTitle(type, title),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(context),
              ],
            ),

            const SizedBox(height: 8),

            // Information expéditeur/destinataire
            Text(
              isCurrentUserSender ? 'À: $recipientName' : 'De: $senderName',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),

            const SizedBox(height: 8),

            // Message principal
            Text(message, style: Theme.of(context).textTheme.bodyMedium),

            // Affichage des métadonnées spécifiques au type de notification
            ..._buildMetadataWidgets(context, type, metadata),

            const SizedBox(height: 8),

            // Pied de carte
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date de création
                Text(
                  'Demandé le: ${_formatDate(createdAt)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),

                //
                if (respondedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Répondu: ${_formatDate(respondedAt)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ),

                // Boutons d'action
                if (showActions &&
                    onRespond != null &&
                    notification['status'] == 'pending')
                  _buildActionButtons(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Titre personnalisé selon le type de notification
  String _getNotificationTitle(String type, String defaultTitle) {
    switch (type) {
      case 'PROJECT_CREATION':
        return 'Demande de création de projet';
      case 'BUDGET_REQUEST':
        return 'Demande d\'augmentation de budget';
      case 'PROJECT_REVIEW':
        return 'Demande de consultation de projet';
      default:
        return defaultTitle;
    }
  }

  // Construction des widgets spécifiques au type de notification
  List<Widget> _buildMetadataWidgets(
    BuildContext context,
    String type,
    dynamic metadata,
  ) {
    if (metadata == null) return [];

    final List<Widget> widgets = [];
    final spacer = const SizedBox(height: 8);

    switch (type) {
      case 'PROJECT_CREATION':
        // Informations spécifiques à la création de projet
        final String? projectName = metadata['projectName']?.toString();
        final String? budget = metadata['budget']?.toString();
        final String? currency = metadata['currency']?.toString();
        final String? country = metadata['country']?.toString();
        final String? startDate = metadata['startDate']?.toString();

        if (projectName != null) {
          widgets.add(spacer);
          widgets.add(_buildInfoRow(context, 'Projet', projectName));
        }

        if (budget != null && currency != null) {
          widgets.add(spacer);
          widgets.add(_buildInfoRow(context, 'Budget', '$budget $currency'));
        }

        if (country != null) {
          widgets.add(spacer);
          widgets.add(_buildInfoRow(context, 'Pays', country));
        }

        if (startDate != null) {
          widgets.add(spacer);
          widgets.add(
            _buildInfoRow(context, 'Date de début', _formatDate(startDate)),
          );
        }
        break;

      case 'BUDGET_REQUEST':
        // Informations spécifiques à la demande d'augmentation de budget
        final String? projectName = metadata['projectName']?.toString();
        final double? currentBudget =
            metadata['currentBudget'] is num
                ? (metadata['currentBudget'] as num).toDouble()
                : null;
        final double? requestedAmount =
            metadata['requestedAmount'] is num
                ? (metadata['requestedAmount'] as num).toDouble()
                : metadata['amount'] is num
                ? (metadata['amount'] as num).toDouble()
                : null;
        final String? currency = metadata['currency']?.toString();

        if (projectName != null) {
          widgets.add(spacer);
          widgets.add(_buildInfoRow(context, 'Projet', projectName));
        }

        if (currentBudget != null && currency != null) {
          widgets.add(spacer);
          widgets.add(
            _buildInfoRow(context, 'Budget actuel', '$currentBudget $currency'),
          );
        }

        if (requestedAmount != null && currency != null) {
          widgets.add(spacer);
          widgets.add(
            _buildInfoRow(
              context,
              'Montant demandé',
              '$requestedAmount $currency',
            ),
          );
        }
        break;

      case 'PROJECT_REVIEW':
        // Informations spécifiques à la demande de revue
        final String? projectName = metadata['projectName']?.toString();
        final String? reviewNote = metadata['reviewNote']?.toString();
        final String? requestedAt = metadata['requestedAt']?.toString();

        if (projectName != null) {
          widgets.add(spacer);
          widgets.add(
            _buildInfoRow(context, 'Projet à consulter', projectName),
          );
        }

        if (reviewNote != null && reviewNote.isNotEmpty) {
          widgets.add(spacer);
          widgets.add(_buildInfoRow(context, 'Note', reviewNote));
        }

        if (requestedAt != null) {
          widgets.add(spacer);
          widgets.add(
            _buildInfoRow(context, 'Demandé le', _formatDate(requestedAt)),
          );
        }
        break;

      default:
        // Pour d'autres types de notifications ou des métadonnées génériques
        metadata.forEach((key, value) {
          if (value != null && !['projectId'].contains(key)) {
            // Si on rencontre un projectId, essayer de trouver un nom de projet associé
            if (key == 'projectId') {
              final String? projectName = metadata['projectName']?.toString();
              if (projectName != null) {
                widgets.add(spacer);
                widgets.add(_buildInfoRow(context, 'Projet', projectName));
              }
            } else {
              widgets.add(spacer);
              widgets.add(
                _buildInfoRow(context, _formatKey(key), value.toString()),
              );
            }
          }
        });
    }

    return widgets;
  }

  // Formater une clé de métadonnée pour affichage
  String _formatKey(String key) {
    // Convertir camelCase en mots séparés avec première lettre majuscule
    final formattedKey = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );

    return formattedKey.substring(0, 1).toUpperCase() +
        formattedKey.substring(1);
  }

  // Créer une ligne d'information avec libellé et valeur
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final status = notification['status']?.toString() ?? 'pending';
    final color =
        status == 'approved'
            ? Colors.green
            : status == 'rejected'
            ? Colors.red
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status == 'approved'
            ? 'Accepté'
            : status == 'rejected'
            ? 'Rejeté'
            : 'En attente',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => onRespond!(false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Refuser', style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => onRespond!(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Accepter'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
