import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../utils.dart';
import 'statistic_detail.dart';

class ScanDetailPage extends StatefulWidget {
  final Map<String, dynamic> scan;

  const ScanDetailPage({super.key, required this.scan});

  @override
  State<ScanDetailPage> createState() => _ScanDetailPageState();
}

class _ScanDetailPageState extends State<ScanDetailPage> {
  String _userName = 'Loading...';
  String _stepName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchExtraData();
  }

  Future<void> _fetchExtraData() async {
    final userId = widget.scan['user'] as String? ?? '';
    final stepId = widget.scan['step'] as String? ?? '';

    String userRes = 'Unknown User';
    String stepRes = 'Unknown Step';

    if (userId.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (doc.exists) {
          final d = doc.data();
          userRes = '${d?['name'] ?? ''} ${d?['surname'] ?? ''}'.trim();
          if (userRes.isEmpty) userRes = 'Unknown User';
        }
      } catch (e) {
        debugPrint('Error fetching user: $e');
      }
    }

    if (stepId.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('steps')
            .doc(stepId)
            .get();
        if (doc.exists) {
          stepRes = doc.data()?['name'] ?? 'Unknown Step';
        }
      } catch (e) {
        debugPrint('Error fetching step: $e');
      }
    }

    if (mounted) {
      setState(() {
        _userName = userRes;
        _stepName = stepRes;
      });
    }
  }

  String _v(dynamic value) {
    return (value == null || (value is String && value.trim().isEmpty))
        ? '—'
        : value.toString();
  }

  void _showSnackBarMessage(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: AppColors.buttonText)),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int status = widget.scan['status'] as int? ?? -1;
    final int progress = widget.scan['progress'] as int? ?? 0;
    final bool canDelete = status == 2 || status == -1;
    final bool canViewStats = status == 2;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.buttonText,
        leadingWidth: 72,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _v(widget.scan['name']),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'ID: ${_v(widget.scan['scanId'])}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.buttonTextSemiTransparent,
              ),
            ),
          ],
        ),
        actions: [
          if (canDelete)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _handleDelete(context),
              ),
            ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 40.0),
                decoration: const BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 35),
                            _buildProgressTimeline(context, status, progress),
                            const SizedBox(height: 70),
                            _buildInfoDetails(),
                          ],
                        ),
                      ),
                    ),
                    if (canViewStats) _buildActionButtons(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTimeline(
    BuildContext context,
    int status,
    int progress,
  ) {
    final steps = ['Received  ', '  Processing', 'Completed'];
    final icons = [
      Icons.inbox_rounded,
      Icons.sync_rounded,
      Icons.check_circle_rounded,
    ];

    double progressValue = progress / 100.0;
    int activeStep = status;
    if (status == 1 && progress == 100) {
      activeStep = 2;
    }
    if (status == 2) {
      progressValue = 1.0;
    }

    if (status == -1) {
      return Column(
        children: [
          _buildStepNode(Icons.warning_amber_rounded, true, isError: true),
          const SizedBox(height: 8),
          const Text(
            'An error occurred during processing.',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 8),
              _buildStepNode(icons[0], activeStep >= 0),
              _buildStepConnector(activeStep >= 1, 0),
              _buildStepNode(icons[1], activeStep >= 1),
              _buildStepConnector(
                activeStep == 2,
                activeStep == 1 ? progressValue : 0,
              ),
              _buildStepNode(icons[2], activeStep >= 2),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              bool isActive = activeStep >= index;
              return Text(
                steps[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive ? AppColors.primary : AppColors.unselected,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDetails() {
    final timestamp = widget.scan['timestamp'];
    final formattedTime = (timestamp is Timestamp)
        ? DateFormat('HH:mm:ss').format(timestamp.toDate())
        : '—';
    final formattedDate = (timestamp is Timestamp)
        ? DateFormat('dd/MM/yyyy').format(timestamp.toDate())
        : '—';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadows,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.file_copy_rounded, 'Step', _stepName),
          const Divider(),
          _buildInfoRow(Icons.person_rounded, 'User', _userName),
          const Divider(),
          _buildInfoRow(
            Icons.calendar_today_rounded,
            'Date of scan',
            formattedDate,
          ),
          const Divider(),
          _buildInfoRow(
            Icons.access_time_rounded,
            'Time of upload',
            formattedTime,
          ),
          const Divider(),
          _buildInfoRow(
            Icons.percent_rounded,
            'Progress',
            '${_v(widget.scan['progress'])}%',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildButton(
            'VIEW STATISTICS',
            onPressed: () => _handleViewStats(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode(IconData icon, bool isActive, {bool isError = false}) {
    final color = isError
        ? AppColors.error
        : (isActive ? AppColors.primary : AppColors.unselectedSemiTransparent);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Icon(icon, color: AppColors.buttonText, size: 18),
    );
  }

  Widget _buildStepConnector(bool isActive, double progress) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.unselectedSemiTransparent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: constraints.maxWidth * (isActive ? 1.0 : progress),
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _handleDelete(BuildContext context) {
    showConfirmationDialog(
      context,
      'Are you sure you want to delete this scan?',
      () async {
        try {
          await FirebaseStorage.instance
              .ref('scans/${widget.scan['scanId']}.ply')
              .delete();
          if (context.mounted) {
            _showSnackBarMessage(
              context,
              'Scan successfully deleted',
              isError: false,
            );
            Navigator.of(context).pop();
          }
        } catch (e) {
          debugPrint('Error deleting scan: $e');
          if (context.mounted) {
            _showSnackBarMessage(context, 'Failed to delete scan.');
          }
        }
      },
    );
  }

  Future<void> _handleViewStats(BuildContext context) async {
    try {
      final docId = _v(widget.scan['scanId']);
      final docSnapshot = await FirebaseFirestore.instance
          .collection('stats')
          .doc(docId)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final statsData = docSnapshot.data()!;
        final statsMap = {
          'name': widget.scan['name'] as String? ?? 'Unknown',
          'scanId': widget.scan['scanId'] as String? ?? 'Unknown',
          'accuracy': (statsData['accuracy'] as num?)?.toDouble() ?? 0.0,
          'min_deviation':
              (statsData['min_deviation'] as num?)?.toDouble() ?? 0.0,
          'max_deviation':
              (statsData['max_deviation'] as num?)?.toDouble() ?? 0.0,
          'avg_deviation':
              (statsData['avg_deviation'] as num?)?.toDouble() ?? 0.0,
          'std_deviation':
              (statsData['std_deviation'] as num?)?.toDouble() ?? 0.0,
          'ppwt': (statsData['ppwt'] as num?)?.toDouble() ?? 0.0,
        };
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => StatisticDetailPage(stats: statsMap),
            ),
          );
        }
      } else {
        if (context.mounted) {
          _showSnackBarMessage(context, 'No statistics available.');
        }
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      if (context.mounted) {
        _showSnackBarMessage(
          context,
          'An error occurred while fetching statistics.',
        );
      }
    }
  }
}
