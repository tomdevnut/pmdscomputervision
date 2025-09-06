import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:js_interop';
import '../shared_utils.dart';
import 'statistics.dart';
import 'package:intl/intl.dart';

@JS('window.open')
external void openUrl(String url, String target);

// Funzioni per recuperare dati utente e step in modo asincrono
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
    // Si potrebbe loggare l'errore per il debug
  }
  return 'Unknown User';
}

Future<String> getStepName(String stepId) async {
  if (stepId.isEmpty) {
    return 'Unknown or Deleted Step';
  }
  try {
    final stepDoc = await FirebaseFirestore.instance
        .collection('steps')
        .doc(stepId)
        .get();
    if (stepDoc.exists) {
      final stepData = stepDoc.data();
      return stepData?['name'] ?? 'Unknown Step';
    }
  } catch (e) {
    // Si potrebbe loggare l'errore per il debug
  }
  return 'Unknown or Deleted Step';
}

class SingleScan extends StatefulWidget {
  final String scanid;
  const SingleScan({super.key, required this.scanid});

  @override
  State<SingleScan> createState() => _SingleScanState();
}

class _SingleScanState extends State<SingleScan> {
  // Variabili di stato con valori iniziali
  bool isCompleted = false;
  bool canDelete = false;
  late Future<DocumentSnapshot> _scanDataFuture;
  // Nuove variabili per salvare i dati asincroni
  String _username = 'Loading...';
  String _stepName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _scanDataFuture = _fetchScanData();
    _scanDataFuture.then((snapshot) async {
      if (mounted && snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final int status = data['status'] ?? -1;

        // Recupera i nomi utente e step in modo asincrono
        final username = await getUsername(data['user']);
        final stepName = await getStepName(data['step']);

        setState(() {
          isCompleted = status == 2;
          canDelete = status == -1 || status == 2;
          _username = username;
          _stepName = stepName;
        });
      }
    });
  }

  Future<DocumentSnapshot> _fetchScanData() async {
    return FirebaseFirestore.instance
        .collection('scans')
        .doc(widget.scanid)
        .get();
  }

  Future<void> _deleteScan() async {
    try {
      await FirebaseStorage.instance
          .ref()
          .child('scans/${widget.scanid}.ply')
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scan deleted successfully.'),
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
                  'You do not have permission to delete this scan.',
                ),
                backgroundColor: AppColors.red,
              ),
            );
          }
        } else if (e.code == 'object-not-found') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('The requested scan was not found.'),
                backgroundColor: AppColors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting scan: ${e.message}'),
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

  Future<void> _downloadScanFile() async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'scans/${widget.scanid}.ply',
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
      if (mounted) {
        if (e.code == 'permission-denied') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'You do not have permission to download this scan.',
                ),
                backgroundColor: AppColors.red,
              ),
            );
          }
        } else if (e.code == 'object-not-found') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('The requested scan was not found.'),
                backgroundColor: AppColors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error downloading scan: ${e.message}'),
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
              buildTopBar(context, title: 'SCAN INFO'),
              const SizedBox(height: 24),
              FutureBuilder<DocumentSnapshot>(
                future: _scanDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final int status = data['status'] ?? -1;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final widgets = [
                          buildInfoField(
                            label: 'Name',
                            value: data['name'] ?? 'N/A',
                            icon: Icons.abc,
                          ),
                          const SizedBox(height: 24),
                          buildInfoField(
                            label: 'Date',
                            value: data['timestamp'] != null
                                ? DateFormat('yyyy-MM-dd, HH:mm').format(
                                    (data['timestamp'] as Timestamp).toDate())
                                : 'N/A',
                            icon: Icons.calendar_today,
                          ),
                          const SizedBox(height: 24),
                          buildInfoField(
                            label: 'User',
                            value: _username,
                            icon: Icons.person,
                          ),
                          const SizedBox(height: 24),
                          buildInfoField(
                            label: 'Status',
                            value: getStatusText(status),
                            icon: Icons.check_circle,
                          ),
                          const SizedBox(height: 24),
                          buildInfoField(
                            label: 'Step',
                            value: _stepName,
                            icon: Icons.file_copy,
                          ),
                          const SizedBox(height: 24),
                          buildInfoField(
                            label: 'Progress',
                            value: data['progress'] != null
                                ? '${data['progress']}%'
                                : 'N/A',
                            icon: Icons.data_usage,
                          ),
                          const SizedBox(height: 24),
                          buildInfoField(
                            label: 'ID',
                            value: widget.scanid,
                            icon: Icons.tag,
                          ),
                        ];

                        if (constraints.maxWidth > 800) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: widgets.sublist(0, 7),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: widgets.sublist(8, 13),
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
                    return const Center(child: Text('Scan not found.'));
                  }
                },
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  buildButton(
                    label: 'Download Scan File',
                    icon: Icons.download,
                    onTap: _downloadScanFile,
                  ),
                  const SizedBox(width: 12),
                  buildButton(
                    label: 'Open Statistics',
                    icon: Icons.bar_chart,
                    backgroundColor: isCompleted
                        ? AppColors.secondary
                        : AppColors.disabledButton,
                    onTap: isCompleted
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    Statistics(scanid: widget.scanid),
                              ),
                            );
                          }
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'The file is still being processed. Please wait until it has finished.',
                                ),
                                backgroundColor: AppColors.red,
                              ),
                            );
                          },
                  ),
                  const SizedBox(width: 12),
                  buildButton(
                    label: 'Delete Scan',
                    backgroundColor: canDelete
                        ? AppColors.red
                        : AppColors.disabledButton,
                    onTap: canDelete
                        ? () => showConfirmationDialog(
                            context: context,
                            message:
                                'This action will permanently delete the scan and its data from the database. Are you sure?',
                            onConfirm: _deleteScan,
                          )
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'You must wait until the file has finished processing before it can be deleted.',
                                ),
                                backgroundColor: AppColors.red,
                              ),
                            );
                          },
                    icon: Icons.delete,
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
