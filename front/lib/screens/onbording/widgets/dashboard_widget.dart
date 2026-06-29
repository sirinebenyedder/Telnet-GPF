import 'package:Telnet/screens/onbording/widgets/activity_details_card.dart';
import 'package:Telnet/screens/onbording/widgets/bar_graph_widget.dart';
import 'package:Telnet/screens/onbording/widgets/line_chart_card.dart';
import 'package:Telnet/screens/onbording/widgets/responsive.dart';
import 'package:flutter/material.dart';

import 'package:Telnet/screens/onbording/widgets/pie_chart.dart';

class DashboardWidget extends StatelessWidget {
  const DashboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Partie gauche
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    const SizedBox(height: 18),
                    const ActivityDetailsCard(),
                    const SizedBox(height: 18),
                    const LineChartCard(),
                    const SizedBox(height: 18),
                    const BarGraphCard(),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ),

          // Partie droite
          if (Responsive.isDesktop(context))
            Expanded(
              flex: 1,
              child: Container(
                color: const Color.fromARGB(255, 246, 246, 250),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Chart(), //  PieChart
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
