/*import 'package:Telnet/charts/pie_chart.dart';
import 'package:Telnet/screens/onbording/widgets/scheduled_widget.dart';
import 'package:Telnet/screens/onbording/widgets/summary_details.dart';

import 'package:flutter/material.dart';

class SummaryWidget extends StatelessWidget {
  const SummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: cardBackgroundColor),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            Chart(),
            Text(
              'Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            SummaryDetails(),
            SizedBox(height: 40),
            Scheduled(),
          ],
        ),
      ),
    );
  }
}
*/
import 'package:flutter/material.dart';

class SummaryWidget extends StatelessWidget {
  const SummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Prend toute la largeur
      height: 200, // Hauteur minimale ou ajustable
      decoration: BoxDecoration(
        color: Colors.white, // Couleur de fond
        borderRadius: BorderRadius.all(
          Radius.circular(12),
        ), // Optionnel, pour avoir des bords arrondis
      ),
      child: const Center(
        child: Text(
          '', // Rien à afficher, mais cela prend de la place
          style: TextStyle(color: Colors.transparent), // Le texte est invisible
        ),
      ),
    );
  }
}
