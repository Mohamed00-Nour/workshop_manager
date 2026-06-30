import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/pdf_generator.dart';
import '../../../jobs/data/repositories/job_repository.dart';
import '../../../jobs/presentation/bloc/jobs_bloc.dart';
import '../../../jobs/presentation/bloc/jobs_event.dart';
import '../../../jobs/presentation/bloc/jobs_state.dart';
import '../../../jobs/presentation/screens/add_job_screen.dart';
import '../../../payments/data/repositories/payment_repository.dart';
import '../../../payments/presentation/bloc/payments_bloc.dart';
import '../../../payments/presentation/bloc/payments_event.dart';
import '../../../payments/presentation/bloc/payments_state.dart';
import '../../../payments/presentation/screens/add_payment_dialog.dart';
import '../../domain/models/client_model.dart';

class ClientDetailScreen extends StatefulWidget {
  final ClientModel client;
  final bool isTabletOrDesktopLayout;

  const ClientDetailScreen({
    super.key,
    required this.client,
    this.isTabletOrDesktopLayout = false,
  });

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late JobsBloc _jobsBloc;
  late PaymentsBloc _paymentsBloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _jobsBloc = JobsBloc(JobRepository())..add(LoadJobs(clientId: widget.client.id, refreshFromServer: true));
    _paymentsBloc = PaymentsBloc(PaymentRepository())..add(LoadPayments(clientId: widget.client.id, refreshFromServer: true));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _jobsBloc.close();
    _paymentsBloc.close();
    super.dispose();
  }

  void _addJob() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: _jobsBloc,
          child: AddJobScreen(clientId: widget.client.id),
        ),
      ),
    );
  }

  void _addPayment() {
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: _paymentsBloc,
        child: AddPaymentDialog(clientId: widget.client.id),
      ),
    );
  }

  Future<void> _sharePdfStatement() async {
    // Generate statement from state
    final jobsState = _jobsBloc.state;
    final paymentsState = _paymentsBloc.state;
    
    if (jobsState is JobsLoaded && paymentsState is PaymentsLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.translate('loading'))),
      );
      await PdfGenerator.generateAndShareStatement(
        client: widget.client,
        jobs: jobsState.jobs,
        payments: paymentsState.payments,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait until jobs and payments load completely.')),
      );
    }
  }

  Widget _buildJobImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (url.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.build));
    }
    if (url.startsWith('data:image/') || !url.startsWith('http')) {
      try {
        final base64String = url.contains(',') ? url.split(',').last : url;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
        );
      } catch (e) {
        return const Icon(Icons.broken_image);
      }
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    Widget profileHeader = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1D1D30), const Color(0xFF23233C)]
              : [Colors.white, const Color(0xFFF1F5F9)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C45) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.client.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.client.phone}  |  ${widget.client.company}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark ? const Color(0xFF9090A0) : const Color(0xFF5D5D70),
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF46F0D2).withAlpha(30) : const Color(0xFF0F766E).withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.share_outlined,
                      color: isDark ? const Color(0xFF46F0D2) : const Color(0xFF0F766E),
                    ),
                    onPressed: _sharePdfStatement,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: isDark ? const Color(0xFF2C2C45) : const Color(0xFFE2E8F0)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${widget.client.totalJobsCost} ${context.translate('currency')}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF131321),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.translate('total_cost'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? const Color(0xFF9090A0) : const Color(0xFF5D5D70),
                          ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${widget.client.totalPaidAmount} ${context.translate('currency')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.translate('total_paid'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? const Color(0xFF9090A0) : const Color(0xFF5D5D70),
                          ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${widget.client.currentBalance} ${context.translate('currency')}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: widget.client.currentBalance > 0
                            ? (isDark ? const Color(0xFFFBE2B4) : Colors.red)
                            : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.translate('balance'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? const Color(0xFF9090A0) : const Color(0xFF5D5D70),
                          ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _jobsBloc),
        BlocProvider.value(value: _paymentsBloc),
      ],
      child: Scaffold(
        appBar: widget.isTabletOrDesktopLayout
            ? null
            : AppBar(
                title: Text(widget.client.name),
              ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: profileHeader,
            ),
            TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              indicatorColor: primaryColor,
              tabs: [
                Tab(icon: const Icon(Icons.build_outlined), text: context.translate('jobs')),
                Tab(icon: const Icon(Icons.payment_outlined), text: context.translate('payments')),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Jobs List tab
                  BlocBuilder<JobsBloc, JobsState>(
                    builder: (context, state) {
                      if (state is JobsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is JobsLoaded) {
                        final jobs = state.jobs;
                        if (jobs.isEmpty) {
                          return Center(child: Text(context.translate('no_jobs')));
                        }
                        return ListView.builder(
                          itemCount: jobs.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final job = jobs[index];
                            return Card(
                              child: ExpansionTile(
                                leading: SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: _buildJobImage(
                                    job.imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: Text(job.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    '${context.translate('cost')}: ${job.cost} EGP | ${context.translate('status')}: ${context.translate('job_status_${job.status}')}'),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (job.imageUrl.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 12.0),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: _buildJobImage(
                                                job.imageUrl,
                                                width: double.infinity,
                                                height: 200,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        Text('${context.translate('date')}: ${dateFormat.format(job.date)}'),
                                        const SizedBox(height: 4),
                                        Text('${context.translate('worker')}: ${job.recordedByName}'),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            // Toggle Status buttons
                                            DropdownButton<String>(
                                              value: job.status,
                                              items: ['received', 'in_progress', 'completed', 'delivered']
                                                  .map((s) => DropdownMenuItem(
                                                        value: s,
                                                        child: Text(context.translate('job_status_$s')),
                                                      ))
                                                  .toList(),
                                              onChanged: (newStatus) {
                                                if (newStatus != null) {
                                                  context.read<JobsBloc>().add(
                                                        UpdateJobStatusRequested(
                                                          jobId: job.id,
                                                          clientId: widget.client.id,
                                                          status: newStatus,
                                                        ),
                                                  );
                                                }
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                                              onPressed: () {
                                                context.read<JobsBloc>().add(
                                                      DeleteJobRequested(
                                                        jobId: job.id,
                                                        clientId: widget.client.id,
                                                        cost: job.cost,
                                                      ),
                                                );
                                              },
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        );
                      }
                      return Container();
                    },
                  ),
                  
                  // Payments List tab
                  BlocBuilder<PaymentsBloc, PaymentsState>(
                    builder: (context, state) {
                      if (state is PaymentsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is PaymentsLoaded) {
                        final payments = state.payments;
                        if (payments.isEmpty) {
                          return Center(child: Text(context.translate('no_payments')));
                        }
                        return ListView.builder(
                          itemCount: payments.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final pay = payments[index];
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  child: Icon(Icons.attach_money),
                                ),
                                title: Text('${pay.amount} ${context.translate('currency')}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    '${context.translate(pay.paymentMethod)} | ${dateFormat.format(pay.date)} \n${pay.notes}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {
                                    context.read<PaymentsBloc>().add(
                                          DeletePaymentRequested(
                                            paymentId: pay.id,
                                            clientId: widget.client.id,
                                            amount: pay.amount,
                                          ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      }
                      return Container();
                    },
                  ),
                ],
              ),
            )
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addPayment,
                    icon: const Icon(Icons.payment),
                    label: Text(context.translate('add_payment')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addJob,
                    icon: const Icon(Icons.add),
                    label: Text(context.translate('add_job')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
