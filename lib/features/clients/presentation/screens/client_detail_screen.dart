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
    _jobsBloc = JobsBloc(JobRepository())
      ..add(LoadJobs(clientId: widget.client.id, refreshFromServer: true));
    _paymentsBloc = PaymentsBloc(PaymentRepository())
      ..add(LoadPayments(clientId: widget.client.id, refreshFromServer: true));
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
        const SnackBar(
            content: Text('Please wait until jobs and payments load completely.')),
      );
    }
  }

  Widget _buildJobImage(String url,
      {double? width, double? height, BoxFit fit = BoxFit.cover}) {
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
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image),
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
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.broken_image),
    );
  }

  // ── Status color by job state ──────────────────────────────────────────────
  Color _statusColor(String status, bool isDark) {
    switch (status) {
      case 'received':
        return isDark ? const Color(0xFF93C5FD) : const Color(0xFF3B82F6);
      case 'in_progress':
        return isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706);
      case 'completed':
        return isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669);
      case 'delivered':
        return isDark ? const Color(0xFF46F0D2) : const Color(0xFF0F766E);
      default:
        return isDark ? const Color(0xFF9090A0) : const Color(0xFF6B7280);
    }
  }

  // ── Payment method icon ────────────────────────────────────────────────────
  IconData _paymentIcon(String method) {
    switch (method) {
      case 'cash':
        return Icons.payments_outlined;
      case 'bank_transfer':
        return Icons.account_balance_outlined;
      case 'check':
        return Icons.receipt_long_outlined;
      default:
        return Icons.attach_money_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd  HH:mm');
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = isDark ? const Color(0xFF46F0D2) : const Color(0xFF0D9488);
    final Color cardBg = isDark ? const Color(0xFF1D1D30) : Colors.white;
    final Color subtleText =
        isDark ? const Color(0xFF9090A0) : const Color(0xFF5D5D70);
    final Color dividerColor =
        isDark ? const Color(0xFF2C2C45) : const Color(0xFFE2E8F0);

    // Avatar initials
    final initials = widget.client.name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    // ── Profile Header ─────────────────────────────────────────────────────
    final Widget profileHeader = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1D1D30), const Color(0xFF252540)]
              : [Colors.white, const Color(0xFFF1F5F9)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Gradient avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF46F0D2), const Color(0xFF0F766E)]
                          : [const Color(0xFF0D9488), const Color(0xFF134E4A)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Name + contact
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.client.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF131321),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 13, color: subtleText),
                          const SizedBox(width: 4),
                          Text(widget.client.phone,
                              style: TextStyle(fontSize: 13, color: subtleText)),
                          if (widget.client.company.isNotEmpty) ...[
                            Text('  ·  ',
                                style: TextStyle(color: subtleText)),
                            Icon(Icons.business_outlined,
                                size: 13, color: subtleText),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.client.company,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    TextStyle(fontSize: 13, color: subtleText),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Share button
                Container(
                  decoration: BoxDecoration(
                    color: accent.withAlpha(isDark ? 30 : 18),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.ios_share_outlined, color: accent),
                    onPressed: _sharePdfStatement,
                    tooltip: 'Share Statement',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(color: dividerColor, height: 1),
            const SizedBox(height: 16),
            // Stats row
            IntrinsicHeight(
              child: Row(
                children: [
                  _statColumn(
                    context,
                    label: context.translate('total_cost'),
                    value: '${widget.client.totalJobsCost}',
                    valueColor:
                        isDark ? Colors.white : const Color(0xFF131321),
                    isDark: isDark,
                  ),
                  VerticalDivider(color: dividerColor, width: 1),
                  _statColumn(
                    context,
                    label: context.translate('total_paid'),
                    value: '${widget.client.totalPaidAmount}',
                    valueColor: const Color(0xFF22C55E),
                    isDark: isDark,
                  ),
                  VerticalDivider(color: dividerColor, width: 1),
                  _statColumn(
                    context,
                    label: context.translate('balance'),
                    value: '${widget.client.currentBalance}',
                    valueColor: widget.client.currentBalance > 0
                        ? (isDark ? const Color(0xFFFBE2B4) : Colors.red)
                        : const Color(0xFF22C55E),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _jobsBloc),
        BlocProvider.value(value: _paymentsBloc),
      ],
      child: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF131321), Color(0xFF1F1F35), Color(0xFF131321)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF7F7FA), Color(0xFFFFFFFF), Color(0xFFF7F7FA)],
                ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: widget.isTabletOrDesktopLayout
              ? null
              : AppBar(
                  title: Text(
                    widget.client.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF131321),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: IconThemeData(
                    color: isDark ? Colors.white : const Color(0xFF131321),
                  ),
                ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: profileHeader,
              ),
              const SizedBox(height: 8),
              // Custom pill tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1D1D30) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dividerColor),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: accent,
                  unselectedLabelColor: subtleText,
                  indicator: BoxDecoration(
                    color: accent.withAlpha(isDark ? 30 : 18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.build_outlined, size: 16),
                          const SizedBox(width: 6),
                          Text(context.translate('jobs'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment_outlined, size: 16),
                          const SizedBox(width: 6),
                          Text(context.translate('payments'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ── Jobs Tab ───────────────────────────────────────────
                    BlocBuilder<JobsBloc, JobsState>(
                      builder: (context, state) {
                        if (state is JobsLoading) {
                          return Center(
                              child: CircularProgressIndicator(color: accent));
                        }
                        if (state is JobsLoaded) {
                          final jobs = state.jobs;
                          if (jobs.isEmpty) {
                            return _emptyState(
                              context,
                              icon: Icons.build_outlined,
                              label: context.translate('no_jobs'),
                              isDark: isDark,
                              accent: accent,
                            );
                          }
                          return ListView.builder(
                            itemCount: jobs.length,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemBuilder: (context, index) {
                              final job = jobs[index];
                              final statusColor =
                                  _statusColor(job.status, isDark);
                              return Container(
                                margin: const EdgeInsets.only(top: 10),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: dividerColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withAlpha(isDark ? 30 : 8),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                      dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    tilePadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    childrenPadding: EdgeInsets.zero,
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: _buildJobImage(job.imageUrl,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover),
                                      ),
                                    ),
                                    title: Text(
                                      job.description,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF131321),
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          // Cost chip
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: accent
                                                  .withAlpha(isDark ? 25 : 18),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${job.cost} ${context.translate('currency')}',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: accent),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          // Status chip
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color:
                                                  statusColor.withAlpha(25),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              context.translate(
                                                  'job_status_${job.status}'),
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: statusColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    children: [
                                      Divider(color: dividerColor, height: 1),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (job.imageUrl.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 14),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: _buildJobImage(
                                                    job.imageUrl,
                                                    width: double.infinity,
                                                    height: 180,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            _infoRow(
                                              Icons.calendar_today_outlined,
                                              '${context.translate('date')}: ${dateFormat.format(job.date)}',
                                              subtleText,
                                            ),
                                            const SizedBox(height: 6),
                                            _infoRow(
                                              Icons.person_outline,
                                              '${context.translate('worker')}: ${job.recordedByName}',
                                              subtleText,
                                            ),
                                            const SizedBox(height: 14),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child:
                                                      DropdownButtonFormField<
                                                          String>(
                                                    value: job.status,
                                                    decoration: InputDecoration(
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 12,
                                                              vertical: 8),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        borderSide: BorderSide(
                                                            color:
                                                                dividerColor),
                                                      ),
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        borderSide: BorderSide(
                                                            color:
                                                                dividerColor),
                                                      ),
                                                    ),
                                                    items: [
                                                      'received',
                                                      'in_progress',
                                                      'completed',
                                                      'delivered',
                                                    ]
                                                        .map(
                                                          (s) => DropdownMenuItem(
                                                            value: s,
                                                            child: Text(
                                                              context.translate(
                                                                  'job_status_$s'),
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          13),
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                                    onChanged: (newStatus) {
                                                      if (newStatus != null) {
                                                        context
                                                            .read<JobsBloc>()
                                                            .add(
                                                              UpdateJobStatusRequested(
                                                                jobId: job.id,
                                                                clientId: widget
                                                                    .client.id,
                                                                status:
                                                                    newStatus,
                                                              ),
                                                            );
                                                      }
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.red
                                                        .withAlpha(18),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: IconButton(
                                                    icon: const Icon(
                                                        Icons.delete_outline,
                                                        color: Colors.red),
                                                    onPressed: () {
                                                      context
                                                          .read<JobsBloc>()
                                                          .add(
                                                            DeleteJobRequested(
                                                              jobId: job.id,
                                                              clientId: widget
                                                                  .client.id,
                                                              cost: job.cost,
                                                            ),
                                                          );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // ── Payments Tab ───────────────────────────────────────
                    BlocBuilder<PaymentsBloc, PaymentsState>(
                      builder: (context, state) {
                        if (state is PaymentsLoading) {
                          return Center(
                              child: CircularProgressIndicator(color: accent));
                        }
                        if (state is PaymentsLoaded) {
                          final payments = state.payments;
                          if (payments.isEmpty) {
                            return _emptyState(
                              context,
                              icon: Icons.payment_outlined,
                              label: context.translate('no_payments'),
                              isDark: isDark,
                              accent: accent,
                            );
                          }
                          return ListView.builder(
                            itemCount: payments.length,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemBuilder: (context, index) {
                              final pay = payments[index];
                              return Container(
                                margin: const EdgeInsets.only(top: 10),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: dividerColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withAlpha(isDark ? 30 : 8),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      // Method icon container
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF22C55E)
                                              .withAlpha(25),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                            _paymentIcon(pay.paymentMethod),
                                            color: const Color(0xFF22C55E),
                                            size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      // Amount + method + date
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${pay.amount} ${context.translate('currency')}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF131321),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${context.translate(pay.paymentMethod)}  ·  ${dateFormat.format(pay.date)}',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: subtleText),
                                            ),
                                            if (pay.notes.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(pay.notes,
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: subtleText,
                                                      fontStyle:
                                                          FontStyle.italic)),
                                            ],
                                          ],
                                        ),
                                      ),
                                      // Delete
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.withAlpha(18),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 20),
                                          onPressed: () {
                                            context
                                                .read<PaymentsBloc>()
                                                .add(DeletePaymentRequested(
                                                  paymentId: pay.id,
                                                  clientId: widget.client.id,
                                                  amount: pay.amount,
                                                ));
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1D1D30) : Colors.white,
              border: Border(top: BorderSide(color: dividerColor)),
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addPayment,
                        icon: const Icon(Icons.payment_outlined, size: 18),
                        label: Text(context.translate('add_payment')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accent,
                          side: BorderSide(color: accent.withAlpha(100)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _addJob,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(context.translate('add_job')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: isDark
                              ? const Color(0xFF131321)
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Reusable stat column ──────────────────────────────────────────────────
  Widget _statColumn(
    BuildContext context, {
    required String label,
    required String value,
    required Color valueColor,
    required bool isDark,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: valueColor),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color:
                  isDark ? const Color(0xFF9090A0) : const Color(0xFF5D5D70),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable info row ─────────────────────────────────────────────────────
  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: TextStyle(fontSize: 13, color: color))),
      ],
    );
  }

  // ── Empty state placeholder ───────────────────────────────────────────────
  Widget _emptyState(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isDark,
    required Color accent,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: accent.withAlpha(isDark ? 30 : 18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: accent),
          ),
          const SizedBox(height: 16),
          Text(label,
              style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? const Color(0xFF9090A0)
                      : const Color(0xFF5D5D70))),
        ],
      ),
    );
  }
}
