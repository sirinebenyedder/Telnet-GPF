import 'package:Telnet/screens/onbording/widgets/custom_card_widget.dart';
import 'package:Telnet/screens/onbording/widgets/responsive.dart';
import 'package:Telnet/services/api.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

//hethi awil chart feha 4 carreau

class ActivityDetailsCard extends StatefulWidget {
  const ActivityDetailsCard({super.key});

  @override
  State<ActivityDetailsCard> createState() => _ActivityDetailsCardState();
}

class _ActivityDetailsCardState extends State<ActivityDetailsCard> {
  late Future<void> _dataFuture;
  final ProjectDetails healthDetails = ProjectDetails();

  @override
  void initState() {
    super.initState();
    _dataFuture = healthDetails.fetchData();
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
          return _buildGrid();
        }
      },
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      itemCount: healthDetails.projectData.length,
      shrinkWrap: true,
      physics: const ScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.isMobile(context) ? 2 : 4,
        crossAxisSpacing: Responsive.isMobile(context) ? 12 : 15,
        mainAxisSpacing: 12.0,
      ),
      itemBuilder:
          (context, index) => CustomCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  healthDetails.projectData[index].icon,
                  width: 49,
                  height: 49,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 4),
                  child: Text(
                    healthDetails.projectData[index].value,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  healthDetails.projectData[index].title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color.fromARGB(255, 226, 223, 223), ////////////
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class ProjectDetails {
  List<DataItem> projectData = [
    DataItem(title: "Projets", value: "0", icon: "assets/icons/idea.png"),
    DataItem(title: "Pays", value: "0", icon: "assets/icons/long-distance.png"),
    DataItem(
      title: "Fournisseurs",
      value: "0",
      icon: "assets/icons/partnership.png",
    ),
    DataItem(title: "Factures", value: "0", icon: "assets/icons/bill.png"),
  ];

  Future<void> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/project/dashboardState'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Mise à jour des valeurs
        projectData[0].value = data['projectCount'].toString();
        projectData[1].value = data['countryCount'].toString();
        projectData[2].value = data['supplierCount'].toString();
        projectData[3].value = data['invoiceCount'].toString();
      } else {
        throw Exception(
          'Échec du chargement des données: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur lors de la récupération des données: $e');
      throw e; // Propager l'erreur pour que FutureBuilder puisse la gérer
    }
  }
}

class DataItem {
  final String title;
  String value;
  final String icon;

  DataItem({required this.title, required this.value, required this.icon});
}
