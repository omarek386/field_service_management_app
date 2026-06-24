import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../jobs/domain/entities/job.dart';
import '../../../jobs/presentation/bloc/jobs_bloc.dart';
import '../../../jobs/presentation/bloc/jobs_event.dart';
import '../../../jobs/presentation/bloc/jobs_state.dart';
import '../../../jobs/presentation/pages/job_details_page.dart';
import '../../../service_reports/data/datasources/reports_local_data_source.dart';
import '../../../service_reports/data/datasources/reports_remote_data_source.dart';
import '../../../service_reports/presentation/pages/service_history_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';

class DashboardPage extends StatefulWidget {
  final String technicianId;
  final String technicianName;

  const DashboardPage({
    super.key,
    required this.technicianId,
    required this.technicianName,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isOnline = true;
  int _unsyncedReportsCount = 0;
  late StreamSubscription<InternetConnectionStatus> _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Fetch jobs for technician
    context.read<JobsBloc>().add(FetchJobsEvent(widget.technicianId));

    // Listen to network changes
    _connectionSubscription = InternetConnectionChecker().onStatusChange.listen((status) {
      final online = status == InternetConnectionStatus.connected;
      setState(() {
        _isOnline = online;
      });
      if (online) {
        _triggerAutoSync();
      }
    });

    _checkSyncQueue();
  }

  Future<void> _checkSyncQueue() async {
    try {
      final queue = await ReportsLocalDataSourceImpl(Hive).getUnsyncedReports();
      if (mounted) {
        setState(() {
          _unsyncedReportsCount = queue.length;
        });
      }
    } catch (_) {}
  }

  Future<void> _triggerAutoSync() async {
    try {
      final localSource = ReportsLocalDataSourceImpl(Hive);
      final remoteSource = ReportsRemoteDataSourceImpl(FirebaseFirestore.instance);
      final unsynced = await localSource.getUnsyncedReports();
      if (unsynced.isNotEmpty) {
        for (var report in unsynced) {
          await remoteSource.submitReport(report);
          await localSource.markAsSynced(report.id);
        }
        await _checkSyncQueue();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offline reports successfully synced to Firestore!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Regularly refresh sync status
    _checkSyncQueue();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${widget.technicianName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Field Technician Portal',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Service History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ServiceHistoryPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log Out',
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isOnline)
            Container(
              color: Colors.redAccent,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Offline Mode - Local cache active',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          if (_unsyncedReportsCount > 0)
            Container(
              color: theme.colorScheme.primaryContainer,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sync_problem_rounded, color: theme.colorScheme.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '$_unsyncedReportsCount Service Report(s) pending sync',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (_isOnline)
                    TextButton(
                      onPressed: _triggerAutoSync,
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      child: const Text('Sync Now', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
          Expanded(
            child: BlocBuilder<JobsBloc, JobsState>(
              builder: (context, state) {
                if (state is JobsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is JobsLoaded) {
                  final jobs = state.jobs;
                  return _buildDashboardContent(context, jobs);
                } else if (state is JobsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 60, color: theme.colorScheme.error),
                        const SizedBox(height: 16),
                        Text('Failed to load jobs: ${state.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<JobsBloc>().add(FetchJobsEvent(widget.technicianId));
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(child: Text('No Jobs Found'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, List<Job> jobs) {
    final theme = Theme.of(context);
    final total = jobs.length;
    final pending = jobs.where((j) => j.status == 'pending').length;
    final active = jobs.where((j) => j.status == 'accepted' || j.status == 'in_progress').length;
    final completed = jobs.where((j) => j.status == 'completed').length;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<JobsBloc>().add(FetchJobsEvent(widget.technicianId));
      },
      child: Column(
        children: [
          // Statistics Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard('Total Jobs', total.toString(), Colors.blue, Icons.assignment_rounded),
                _buildStatCard('Pending', pending.toString(), Colors.orange, Icons.hourglass_empty_rounded),
                _buildStatCard('Active', active.toString(), Colors.purple, Icons.directions_run_rounded),
                _buildStatCard('Completed', completed.toString(), Colors.green, Icons.check_circle_outline_rounded),
              ],
            ),
          ),
          // Tab bar for categorizing list
          TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
            ],
          ),
          // Tab bar view (list of jobs)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildJobsList(jobs),
                _buildJobsList(jobs.where((j) => j.status == 'pending').toList()),
                _buildJobsList(jobs.where((j) => j.status == 'accepted' || j.status == 'in_progress').toList()),
                _buildJobsList(jobs.where((j) => j.status == 'completed').toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color, IconData icon) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    count,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsList(List<Job> filteredJobs) {
    if (filteredJobs.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(
            child: Text(
              'No jobs in this category.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredJobs.length,
      itemBuilder: (context, index) {
        final job = filteredJobs[index];
        return _buildJobCard(job);
      },
    );
  }

  Widget _buildJobCard(Job job) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(job.serviceDate);

    Color statusColor;
    switch (job.status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'accepted':
      case 'in_progress':
        statusColor = Colors.purple;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobDetailsPage(job: job),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job.serviceType,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      job.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Customer: ${job.customerName}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.serviceAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        formattedDate,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
