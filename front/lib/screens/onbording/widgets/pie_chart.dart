import 'dart:convert';
import 'package:Telnet/services/api.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const cardBackgroundColor = Color(0xFF21222D);
const primaryColor = Color(0xFF2697FF);
const secondaryColor = Color(0xFFFFFFFF);
const backgroundColor = Color(0xFF15131C);
const selectionColor = Color(0xFF88B2AC);

const defaultPadding = 20.0;

class Chart extends StatefulWidget {
  const Chart({super.key});

  @override
  State<Chart> createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  List<Map<String, dynamic>> topItems = [];
  double totalQuantity = 0;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTopItems();
  }

  Future<void> _fetchTopItems() async {
    try {
      print('hey');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/project/global-top-items'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        setState(() {
          topItems = List<Map<String, dynamic>>.from(data['chartData']);
          totalQuantity = topItems.fold<double>(
            0,
            (sum, item) => sum + (item['value'] as int),
          );
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading chart data';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }

    if (topItems.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Couleurs pour les différentes sections
    const colors = [
      primaryColor,
      Color(0xFF26E5FF),
      Color(0xFFFFCF26),
      Color(0xFFEE2727),
      Color(0xFF8A2BE2),
      Color(0xFF7CFC00),
    ];

    // Préparation des données pour le graphique
    final pieData =
        topItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final percentage = (item['value'] as int) / totalQuantity * 100;

          return PieChartSectionData(
            color: colors[index % colors.length],
            value: percentage,
            showTitle: false,
            title: '${percentage.toStringAsFixed(1)}%',
            titleStyle: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            radius: 25 - (index * 3).toDouble(),
          );
        }).toList();

    // Préparation des labels
    final labels = topItems.map((item) => item['label'] as String).toList();

    return Container(
      color: const Color.fromARGB(255, 105, 105, 105), /////////////////////////
      height: 524,
      child: Column(
        children: [
          // Partie graphique circulaire (inchangée)
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 65,
                    startDegreeOffset: -90,
                    sections: pieData,
                  ),
                ),
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: defaultPadding),
                      Text(
                        "Total",
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          height: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${totalQuantity.toInt()} produits",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Titre
          const Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Text(
              "Produits les plus achetés",
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),

          // Liste des produits
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: ListView.builder(
                itemCount: pieData.length,
                itemBuilder: (context, index) {
                  final data = pieData[index];
                  final label = labels[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: data.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${data.value.toStringAsFixed(1)}%",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
