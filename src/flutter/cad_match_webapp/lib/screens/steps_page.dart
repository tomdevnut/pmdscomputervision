import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'new_step.dart';
import 'single_step.dart';
import '../shared_utils.dart';

class StepsPage extends StatefulWidget {
  final int level;

  const StepsPage({super.key, required this.level});

  @override
  State<StepsPage> createState() => _StepsPageState();
}

class _StepsPageState extends State<StepsPage> {
  String _truncateDescription(String description, {int wordLimit = 10}) {
    if (description.isEmpty) {
      return 'No description available.';
    }
    List<String> words = description.split(' ');
    if (words.length <= wordLimit) {
      return description;
    }
    return '${words.sublist(0, wordLimit).join(' ')}...';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'STEPS',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.level > 0)
              buildAddButton(context, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StepUpload()),
                );
              }),
          ],
        ),
        const SizedBox(height: 20),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('steps')
                .orderBy('name')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong.'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No steps found.'));
              }

              final steps = snapshot.data!.docs;

              return ListView.separated(
                itemCount: steps.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final stepDoc = steps[index];
                  final data = stepDoc.data() as Map<String, dynamic>;

                  final String title = data['name'] ?? 'No Title';
                  final String description = data['description'] ?? '';

                  return buildListItem(
                    title: title,
                    subtitle: _truncateDescription(
                      description,
                    ),
                    icon: Icons.file_copy_rounded,
                    hasArrow: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SingleStep(stepId: stepDoc.id, userlevel: widget.level),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
