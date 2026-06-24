import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../jobs/domain/entities/job.dart';
import '../../../jobs/presentation/bloc/jobs_bloc.dart';
import '../../../jobs/presentation/bloc/jobs_event.dart';
import '../../domain/entities/service_report.dart';
import '../bloc/report_bloc.dart';
import '../bloc/report_event.dart';
import '../bloc/report_state.dart';

class CreateReportPage extends StatefulWidget {
  final Job job;

  const CreateReportPage({super.key, required this.job});

  @override
  State<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends State<CreateReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _findingsController = TextEditingController();
  final _actionsController = TextEditingController();
  final _remarksController = TextEditingController();
  String? _gpsCoordinates;
  String? _evidenceImagePath;

  @override
  void dispose() {
    _findingsController.dispose();
    _actionsController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final report = ServiceReport(
        id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
        jobId: widget.job.id,
        findings: _findingsController.text.trim(),
        actionsTaken: _actionsController.text.trim(),
        completionNotes: _remarksController.text.trim(),
        timestamp: DateTime.now(),
        gpsCoordinates: _gpsCoordinates,
        evidenceImagePath: _evidenceImagePath,
      );

      context.read<ReportBloc>().add(SubmitReportEvent(report));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Service Report'),
      ),
      body: BlocConsumer<ReportBloc, ReportState>(
        listener: (context, state) {
          if (state is ReportSubmitSuccess) {
            // Trigger job update locally and in Firestore
            context.read<JobsBloc>().add(
                  UpdateJobStatusEvent(
                    jobId: widget.job.id,
                    status: 'completed',
                  ),
                );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Report submitted successfully!'),
                backgroundColor: theme.colorScheme.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );

            // Pop back to dashboard
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (state is ReportSubmitFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Submission failed: ${state.message}'),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Job: ${widget.job.serviceType}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Customer: ${widget.job.customerName}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const Divider(height: 32),

                  // Findings
                  TextFormField(
                    controller: _findingsController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Service Findings & Issues',
                      alignLabelWithHint: true,
                      hintText: 'Describe issues, damages, or anomalies found...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please provide service findings';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Actions Taken
                  TextFormField(
                    controller: _actionsController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Actions Taken & Repairs',
                      alignLabelWithHint: true,
                      hintText: 'Describe procedures, parts replaced, or actions completed...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please list actions taken during service';
                      }
                      return null;
                    },
                  ),
                  // GPS Location Section
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _gpsCoordinates = "31.9539° N, 35.9106° E";
                            });
                          },
                          icon: const Icon(Icons.location_on_outlined),
                          label: const Text('Capture Location (GPS)'),
                        ),
                      ),
                      if (_gpsCoordinates != null) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(_gpsCoordinates!),
                          onDeleted: () {
                            setState(() {
                              _gpsCoordinates = null;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Evidence Photo Section
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _evidenceImagePath = "evidence_photo_capture_${DateTime.now().millisecondsSinceEpoch}.jpg";
                            });
                          },
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Add Evidence Image'),
                        ),
                      ),
                      if (_evidenceImagePath != null) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: const Text('Image Attached'),
                          onDeleted: () {
                            setState(() {
                              _evidenceImagePath = null;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Completion Notes
                  TextFormField(
                    controller: _remarksController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Completion Remarks',
                      alignLabelWithHint: true,
                      hintText: 'Add extra details, comments, or client feedback...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Submit Button
                  ElevatedButton(
                    onPressed: state is ReportSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    child: state is ReportSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Submit & Close Job',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
