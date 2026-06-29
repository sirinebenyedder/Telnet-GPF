import 'package:Telnet/services/project_api.dart';
import 'package:flutter/material.dart';
import 'package:Telnet/constants.dart';

class PmRequestCard extends StatefulWidget {
  final String titleText;
  const PmRequestCard({super.key, required this.titleText});

  @override
  State<PmRequestCard> createState() => _PmRequestCardState();
}

class _PmRequestCardState extends State<PmRequestCard> {
  String? _selectedProjectId;
  List<Map<String, dynamic>> _colleagueProjects = [];
  bool _isLoading = true;
  final TextEditingController _messageController = TextEditingController();
  // Ajoutez ce contrôleur dans votre état
  final TextEditingController _reviewNoteController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadColleagueProjects();
  }

  Future<void> _loadColleagueProjects() async {
    try {
      setState(() => _isLoading = true);
      final projectApi = ProjectApi(); // Instanciation correcte
      final projects = await projectApi.getColleagueProjects();
      print('projet');
      print(projects);
      setState(() {
        _colleagueProjects =
            projects.map((project) {
              return {
                '_id': project['_id'],
                'name': project['name'],
                'managerName':
                    project['manager']['name'], // Ajout du nom du manager
              };
            }).toList();
        print(projects);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(defaultPadding),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Demander à un collègue',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Demande de consultation de projet',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Projet à consulter',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.folder),
                      ),
                      items:
                          _colleagueProjects.map((project) {
                            return DropdownMenuItem<String>(
                              value: project['_id'],
                              child: RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: [
                                    TextSpan(
                                      text: project['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          '(Chef Projet: ${project['managerName']})',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                      selectedItemBuilder: (BuildContext context) {
                        return _colleagueProjects.map((project) {
                          return Text(
                            project['name'],
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          );
                        }).toList();
                      },
                      onChanged: (String? value) {
                        setState(() {
                          _selectedProjectId = value;
                        });
                      },
                    ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reviewNoteController,
                  decoration: InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.note),
                  ),
                  maxLines: 2,
                  minLines: 2,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_selectedProjectId == null ||
                          _reviewNoteController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Veuillez sélectionner un projet et écrire un message',
                            ),
                          ),
                        );
                        return;
                      }

                      try {
                        final projectApi = ProjectApi();
                        await projectApi.sendProjectReviewRequest(
                          projectId: _selectedProjectId!,
                          reviewNote: _reviewNoteController.text,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Demande envoyée avec succès'),
                          ),
                        );

                        setState(() => _selectedProjectId = null);
                        _reviewNoteController.clear();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur: ${e.toString()}')),
                        );
                      }
                    },
                    child: const Text('Envoyer la demande'),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
