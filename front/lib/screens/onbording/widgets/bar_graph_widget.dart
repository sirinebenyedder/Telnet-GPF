import 'dart:convert';
import 'package:Telnet/screens/onbording/widgets/custom_card_widget.dart';
import 'package:Telnet/services/api.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BarGraphData {
  final List<BarGraphItem> data;
  final List<String> labels;

  BarGraphData({required this.data, required this.labels});
}

class BarGraphItem {
  final String label;
  final Color color;
  final List<double> values; // Valeurs pour chaque jour

  BarGraphItem({
    required this.label,
    required this.color,
    required this.values,
  });
}

class BarGraphRepository {
  static Future<BarGraphData> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/project/dailyStats'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return BarGraphData(
          labels: List<String>.from(data['labels']),
          data: [
            BarGraphItem(
              label: 'Produits',
              color: Colors.blue,
              values: List<double>.from(data['products']),
            ),
            BarGraphItem(
              label: 'Achats (€)',
              color: Colors.green,
              values: List<double>.from(data['purchases']),
            ),
          ],
        );
      }
      throw Exception('Failed to load data');
    } catch (e) {
      print('Error fetching bar graph data: $e');
      throw e;
    }
  }
}

class BarGraphCard extends StatefulWidget {
  const BarGraphCard({super.key});

  @override
  State<BarGraphCard> createState() => _BarGraphCardState();
}

class _BarGraphCardState extends State<BarGraphCard> {
  late Future<BarGraphData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = BarGraphRepository.fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BarGraphData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('Aucune donnée disponible'));
        }

        final barGraphData = snapshot.data!;

        return GridView.builder(
          itemCount: barGraphData.data.length,
          shrinkWrap: true,
          physics: const ScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 12.0,
            childAspectRatio: 5 / 4,
          ),
          itemBuilder: (context, index) {
            final item = barGraphData.data[index];
            return CustomCard(
              padding: const EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        barGroups: _chartGroups(
                          values: item.values,
                          color: item.color,
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(
                                    barGraphData.labels[value.toInt()],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color.fromARGB(255, 226, 223, 223),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          // Zid des titres ken t7ib
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<BarChartGroupData> _chartGroups({
    required List<double> values,
    required Color color,
  }) {
    return values
        .asMap()
        .entries
        .map(
          (entry) => BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                width: 12,
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3.0),
                  topRight: Radius.circular(3.0),
                ),
              ),
            ],
          ),
        )
        .toList();
  }
}
