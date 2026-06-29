import 'dart:math';

import 'package:Telnet/screens/onbording/widgets/pie_chart.dart';
import 'package:Telnet/screens/onbording/widgets/custom_card_widget.dart';
import 'package:Telnet/services/api.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
/*
//
class LineData {
  final Map<int, String> bottomTitle;
  final Map<int, String> leftTitle;
  final List<FlSpot> spots;
  final Color selectionColor;

  LineData()
    : selectionColor = const Color(0xFF4CAF50), // Couleur verte pour les steps
      bottomTitle = {
        0: 'Jan',
        20: 'Feb',
        40: 'Mar',
        60: 'Apr',
        80: 'May',
        100: 'Jun',
        120: 'Jul',
      },
      leftTitle = {0: '0', 20: '2k', 40: '4k', 60: '6k', 80: '8k', 100: '10k'},
      spots = [
        FlSpot(0, 10),
        FlSpot(10, 15),
        FlSpot(20, 35),
        FlSpot(30, 25),
        FlSpot(40, 45),
        FlSpot(50, 55),
        FlSpot(60, 65),
        FlSpot(70, 75),
        FlSpot(80, 65),
        FlSpot(90, 85),
        FlSpot(100, 95),
        FlSpot(110, 85),
        FlSpot(120, 75),
      ];
}

//
class LineChartCard extends StatelessWidget {
  const LineChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    final data = LineData();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Steps Overview",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 16 / 6,
            child: LineChart(
              LineChartData(
                lineTouchData: const LineTouchData(handleBuiltInTouches: true),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return data.bottomTitle[value.toInt()] != null
                            ? SideTitleWidget(
                              child: Text(
                                data.bottomTitle[value.toInt()].toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                              meta: meta,
                              space: 8,
                              fitInside: SideTitleFitInsideData(
                                enabled: false,
                                distanceFromEdge: 0,
                                parentAxisSize: 0,
                                axisPosition: 0,
                              ),
                            )
                            : const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return data.leftTitle[value.toInt()] != null
                            ? SideTitleWidget(
                              child: Text(
                                data.leftTitle[value.toInt()].toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                              meta: meta,
                              space: 8,
                              fitInside: SideTitleFitInsideData(
                                enabled: false,
                                distanceFromEdge: 0,
                                parentAxisSize: 0,
                                axisPosition: 0,
                              ),
                            )
                            : const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    color: selectionColor,
                    barWidth: 2.5,
                    isCurved: true,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          selectionColor.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    dotData: const FlDotData(show: false),
                    spots: data.spots,
                  ),
                ],
                minX: 0,
                maxX: 120,
                maxY: 105,
                minY: -5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/
import 'package:Telnet/screens/onbording/widgets/custom_card_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LineData {
  final Map<int, String> bottomTitle;
  final Map<int, String> leftTitle;
  final List<FlSpot> spots;
  final Color selectionColor;

  LineData()
    : selectionColor = const Color.fromRGBO(123, 97, 255, 1),
      bottomTitle = {}, // Initialisé vide maintenant
      leftTitle = {}, // Initialisé vide maintenant
      spots = []; // Initialisé vide maintenant

  Future<void> fetchInvoiceData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/project/getMonthlyInvoiceStats'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Réinitialiser les données
        bottomTitle.clear();
        leftTitle.clear();
        spots.clear();

        double x = 0;
        const double interval = 20;

        // Trouver le maximum pour l'échelle Y
        double maxCount = 0;

        for (var i = 0; i < data.length; i++) {
          final monthData = data[i];
          bottomTitle[x.toInt()] = monthData['month'].substring(
            0,
            3,
          ); // Format court (Jan, Feb...)
          spots.add(FlSpot(x, monthData['count'].toDouble()));

          if (monthData['count'] > maxCount) {
            maxCount = monthData['count'].toDouble();
          }

          x += interval;
        }

        // Configurer l'échelle Y
        final yInterval = (maxCount / 5).ceilToDouble();
        for (double y = 0; y <= maxCount + yInterval; y += yInterval) {
          leftTitle[y.toInt()] = y.toInt().toString();
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération des stats de factures: $e');
      throw e;
    }
  } /*
  Future<void> fetchInvoiceData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/project/getMonthlyInvoiceStats'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        bottomTitle.clear();
        leftTitle.clear();
        spots.clear();

        double x = 0;
        const double interval = 20;
        double maxMonthlyCount = 0;

        // 1. Process monthly data and find maximum
        for (var i = 0; i < data.length; i++) {
          final monthData = data[i];
          final count = monthData['count'].toDouble();

          bottomTitle[x.toInt()] = monthData['month'].substring(0, 3);
          spots.add(FlSpot(x, count));

          if (count > maxMonthlyCount) maxMonthlyCount = count;
          x += interval;
        }

        // 2. Smart Y-axis scaling
        final double yMax = maxMonthlyCount * 1.1;
        final int niceInterval = _calculateNiceInterval(yMax);

        // 3. Generate non-duplicate Y labels
        for (double y = 0; y <= yMax; y += niceInterval) {
          leftTitle[y.toInt()] = y.toInt().toString();
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération: $e');
      throw e;
    }
  }

  // Helper function to calculate optimal intervals
  int _calculateNiceInterval(double maxValue) {
    final double roughInterval = maxValue / 5;
    final int magnitude =
        pow(10, roughInterval.floor().toString().length - 1).toInt();
    return (roughInterval / magnitude).ceil() * magnitude;
  }*/
}

class LineChartCard extends StatefulWidget {
  const LineChartCard({super.key});

  @override
  State<LineChartCard> createState() => _LineChartCardState();
}

class _LineChartCardState extends State<LineChartCard> {
  late final Future<void> _dataFuture;
  final LineData lineData = LineData();

  @override
  void initState() {
    super.initState();
    _dataFuture = lineData.fetchInvoiceData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        } else {
          return _buildChart();
        }
      },
    );
  }

  Widget _buildChart() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Factures par mois",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 16 / 6,
            child: LineChart(
              LineChartData(
                lineTouchData: const LineTouchData(handleBuiltInTouches: true),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return lineData.bottomTitle[value.toInt()] != null
                            ? SideTitleWidget(
                              child: Text(
                                lineData.bottomTitle[value.toInt()]!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color.fromARGB(255, 226, 223, 223),
                                ),
                              ),
                              meta: meta,
                              space: 8,
                            )
                            : const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return lineData.leftTitle[value.toInt()] != null
                            ? Text(
                              lineData.leftTitle[value.toInt()]!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color.fromARGB(255, 226, 223, 223),
                              ),
                            )
                            : const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    color: lineData.selectionColor,
                    barWidth: 2.5,
                    isCurved: true,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineData.selectionColor.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    dotData: const FlDotData(show: false),
                    spots: lineData.spots,
                  ),
                ],
                minX: 0,
                maxX:
                    lineData.spots.isNotEmpty
                        ? lineData.spots.last.x + 20
                        : 120,
                maxY:
                    lineData.leftTitle.keys.isNotEmpty
                        ? lineData.leftTitle.keys.last.toDouble() * 1.1
                        : 100,
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
