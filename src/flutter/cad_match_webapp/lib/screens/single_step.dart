import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared_utils.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:js_interop';

@JS('window.open')
external void openUrl(String url, String target);

// Funzione helper per recuperare il nome utente in modo asincrono
Future<String> getUsername(String userId) async {
  if (userId.isEmpty) {
    return 'Unknown User';
  }
  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (userDoc.exists) {
      final userData = userDoc.data();
      return '${userData?['name'] ?? 'Unknown User'} ${userData?['surname'] ?? 'Unknown User'}';
    }
  } catch (e) {
    // This can be ignored
  }
  return 'Unknown User';
}

// Funzione helper per normalizzare i valori
String _v(dynamic value) {
  return (value == null || (value is String && value.trim().isEmpty))
      ? '—'
      : value.toString();
}

class SingleStep extends StatefulWidget {
  final String stepId;
  final int userlevel;
  const SingleStep({super.key, required this.stepId, required this.userlevel});

  @override
  State<SingleStep> createState() => _SingleStepState();
}

class _SingleStepState extends State<SingleStep> {
  late Future<Map<String, dynamic>> _stepDataFuture;

  @override
  void initState() {
    super.initState();
    _stepDataFuture = _fetchStepData();
  }

  Future<void> _deleteStep() async {
    try {
      await FirebaseStorage.instance
          .ref()
          .child('steps/${widget.stepId}.step')
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Step deleted successfully.'),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        if (e.code == 'permission-denied') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'You do not have permission to delete this step.',
                ),
                backgroundColor: AppColors.red,
              ),
            );
          }
        } else if (e.code == 'object-not-found') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('The requested step was not found.'),
                backgroundColor: AppColors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting step: ${e.message}'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadStepFile() async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'steps/${widget.stepId}.step',
      );
      final url = await ref.getDownloadURL();
      openUrl(url, '_blank');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File download started successfully.'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('The requested step was not found.'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'An error occurred while downloading the file: ${e.message}',
              ),
              backgroundColor: AppColors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showResultDialog(context, 'Error', 'An unexpected error occurred: $e');
      }
    }
  }

  Future<Map<String, dynamic>> _fetchStepData() async {
    final stepDoc = await FirebaseFirestore.instance
        .collection('steps')
        .doc(widget.stepId)
        .get();

    if (!stepDoc.exists || stepDoc.data() == null) {
      throw Exception('Step not found.');
    }

    final data = stepDoc.data() as Map<String, dynamic>;
    final authorId = data['user'];
    final authorName = (authorId != null) ? await getUsername(authorId) : 'N/A';

    data['user'] = authorName;

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTopBar(context, title: 'STEP INFO'),
              const SizedBox(height: 24),
              FutureBuilder<Map<String, dynamic>>(
                future: _stepDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData) {
                    final data = snapshot.data!;

                    return LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            final widgets = [
                              buildInfoField(
                                label: 'Name',
                                value: _v(data['name']),
                                icon: Icons.abc,
                              ),
                              const SizedBox(height: 24),
                              buildInfoField(
                                label: 'Description',
                                value: _v(data['description']),
                                icon: Icons.description,
                              ),
                              const SizedBox(height: 24),
                              buildInfoField(
                                label: 'Author',
                                value: _v(data['user']),
                                icon: Icons.person,
                              ),
                              const SizedBox(height: 24),
                              buildInfoField(
                                label: 'ID',
                                value: widget.stepId,
                                icon: Icons.tag,
                              ),
                            ];

                            if (constraints.maxWidth > 800) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: widgets.sublist(0, 3),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: widgets.sublist(4),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: widgets,
                              );
                            }
                          },
                    );
                  } else {
                    return const Center(child: Text('Step not found.'));
                  }
                },
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  buildButton(
                    label: 'Download Step File',
                    icon: Icons.download,
                    onTap: () {
                      _downloadStepFile();
                    },
                  ),
                  if (widget.userlevel >= 1) const SizedBox(width: 12),
                  if (widget.userlevel >= 1)
                    buildButton(
                      label: 'Delete Step',
                      icon: Icons.delete,
                      backgroundColor: AppColors.red,
                      onTap: () => showConfirmationDialog(
                        context: context,
                        message:
                            'This action will permanently delete the step. All associated scans will not be affected.',
                        onConfirm: () {
                          _deleteStep();
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
