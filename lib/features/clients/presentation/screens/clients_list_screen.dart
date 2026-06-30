import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/screens/user_management_screen.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../domain/models/client_model.dart';
import '../bloc/clients_bloc.dart';
import '../bloc/clients_event.dart';
import '../bloc/clients_state.dart';
import 'add_client_dialog.dart';
import 'client_detail_screen.dart';
import '../../../employees/presentation/screens/employees_dashboard_screen.dart';

class ClientsListScreen extends StatefulWidget {
  final UserModel currentUser;
  final Function(Locale) onLanguageChanged;
  final Function(ThemeMode) onThemeChanged;
  final AuthRepository authRepository;

  const ClientsListScreen({
    super.key,
    required this.currentUser,
    required this.onLanguageChanged,
    required this.onThemeChanged,
    required this.authRepository,
  });

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  ClientModel? _selectedClient;
  final _searchController = TextEditingController();
  int _currentNavigationIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<ClientsBloc>().add(const LoadClients(refreshFromServer: true));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditClientDialog([ClientModel? client]) {
    showDialog(
      context: context,
      builder:
          (context) => AddClientDialog(
            client: client,
            onSave: (savedClient) {
              if (client == null) {
                context.read<ClientsBloc>().add(
                  AddClientRequested(savedClient),
                );
              } else {
                context.read<ClientsBloc>().add(
                  UpdateClientRequested(savedClient),
                );
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = widget.currentUser.role == 'admin';

    final Color accent = isDark ? const Color(0xFF46F0D2) : const Color(0xFF0D9488);
    final Color dividerColor = isDark ? const Color(0xFF2C2C45) : const Color(0xFFE2E8F0);

    // Sidebar navigation widget for tablet/desktop
    Widget customSidebar = Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          right: BorderSide(color: dividerColor),
        ),
      ),
      child: Column(
        children: [
          _sidebarHeader(user: widget.currentUser, isDark: isDark),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _sidebarItem(
                  icon: Icons.people_outline,
                  label: context.translate('clients'),
                  selected: _currentNavigationIndex == 0,
                  onTap: () {
                    setState(() {
                      _currentNavigationIndex = 0;
                    });
                    if (ResponsiveLayout.isMobile(context)) {
                      Navigator.pop(context);
                    }
                  },
                  isDark: isDark,
                  accent: accent,
                ),
                if (isAdmin) ...[
                  _sidebarItem(
                    icon: Icons.badge_outlined,
                    label: context.translate('employees'),
                    selected: _currentNavigationIndex == 1,
                    onTap: () {
                      setState(() {
                        _currentNavigationIndex = 1;
                      });
                      if (ResponsiveLayout.isMobile(context)) {
                        Navigator.pop(context);
                      }
                    },
                    isDark: isDark,
                    accent: accent,
                  ),
                  _sidebarItem(
                    icon: Icons.admin_panel_settings_outlined,
                    label: context.translate('users'),
                    selected: _currentNavigationIndex == 2,
                    onTap: () {
                      setState(() {
                        _currentNavigationIndex = 2;
                      });
                      if (ResponsiveLayout.isMobile(context)) {
                        Navigator.pop(context);
                      }
                    },
                    isDark: isDark,
                    accent: accent,
                  ),
                ],
                const SizedBox(height: 16),
                Divider(
                  color: dividerColor,
                  indent: 16,
                  endIndent: 16,
                ),
                const SizedBox(height: 8),
                _sidebarItem(
                  icon: isDark ? Icons.light_mode : Icons.dark_mode,
                  label: isDark ? context.translate('theme_light') : context.translate('theme_dark'),
                  selected: false,
                  onTap: () {
                    widget.onThemeChanged(isDark ? ThemeMode.light : ThemeMode.dark);
                  },
                  isDark: isDark,
                  accent: accent,
                ),
                _sidebarItem(
                  icon: Icons.translate,
                  label: context.translate('language'),
                  selected: false,
                  onTap: () {
                    final newLocale = Localizations.localeOf(context).languageCode == 'ar'
                        ? const Locale('en')
                        : const Locale('ar');
                    widget.onLanguageChanged(newLocale);
                  },
                  isDark: isDark,
                  accent: accent,
                ),
              ],
            ),
          ),
          _footerProfile(
            user: widget.currentUser,
            isDark: isDark,
            accent: accent,
            onLogout: () {
              context.read<AuthBloc>().add(LogoutRequested());
            },
          ),
        ],
      ),
    );

    Widget sidebar = Drawer(
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: customSidebar,
    );

    // List of clients with search bar
    Widget clientListContent = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${Localizations.localeOf(context).languageCode == 'ar' ? 'مرحباً،' : 'Hey,'} ',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.normal,
                            fontSize: 22,
                          ),
                        ),
                        Text(
                          widget.currentUser.name,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 22,
                          ),
                        ),
                        const Text('!', style: TextStyle(fontSize: 22)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'EEEE, MMM dd, yyyy',
                        Localizations.localeOf(context).languageCode,
                      ).format(DateTime.now()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                  ],
                ),
                if (ResponsiveLayout.isMobile(context))
                  Builder(
                    builder:
                        (context) => IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                context.read<ClientsBloc>().add(SearchClients(val));
              },
              decoration: InputDecoration(
                hintText: context.translate('search'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<ClientsBloc>().add(
                              const SearchClients(''),
                            );
                          },
                        )
                        : null,
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ClientsBloc, ClientsState>(
              builder: (context, state) {
                if (state is ClientsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ClientsError) {
                  return Center(child: Text(state.message));
                }
                if (state is ClientsLoaded) {
                  final clients = state.filteredClients;

                  if (_selectedClient != null) {
                    final idx = clients.indexWhere((c) => c.id == _selectedClient!.id);
                    if (idx == -1) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          _selectedClient = null;
                        });
                      });
                    } else {
                      final updated = clients[idx];
                      if (updated != _selectedClient) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            _selectedClient = updated;
                          });
                        });
                      }
                    }
                  }

                  if (clients.isEmpty) {
                    return Center(child: Text(context.translate('no_clients')));
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<ClientsBloc>().add(
                        const LoadClients(refreshFromServer: true),
                      );
                    },
                    child: ListView.builder(
                      itemCount: clients.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        final isSelected = _selectedClient?.id == client.id;

                        return Card(
                          color:
                              isSelected && !ResponsiveLayout.isMobile(context)
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer.withAlpha(40)
                                  : null,
                          child: ListTile(
                            title: Text(
                              client.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${client.phone} | ${client.company}',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${client.currentBalance} ${context.translate('currency')}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        client.currentBalance > 0
                                            ? (isDark
                                                ? const Color(0xFFFBE2B4)
                                                : Colors.red)
                                            : Colors.green,
                                  ),
                                ),
                                Text(
                                  context.translate('balance'),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            onTap: () {
                              if (ResponsiveLayout.isMobile(context)) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            ClientDetailScreen(client: client),
                                  ),
                                ).then((_) {
                                  // Reload to update any aggregates
                                  context.read<ClientsBloc>().add(
                                    const LoadClients(refreshFromServer: false),
                                  );
                                });
                              } else {
                                setState(() {
                                  _selectedClient = client;
                                });
                              }
                            },
                          ),
                        );
                      },
                    ),
                  );
                }
                return Container();
              },
            ),
          ),
        ],
      ),
    );

    return Container(
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
        drawer: ResponsiveLayout.isMobile(context) ? sidebar : null,
        body: ResponsiveLayout(
          mobile: Scaffold(
            backgroundColor: Colors.transparent,
            drawer: sidebar,
            body: _currentNavigationIndex == 0
                ? clientListContent
                : _currentNavigationIndex == 1
                    ? const EmployeesDashboardScreen()
                    : UserManagementScreen(authRepository: widget.authRepository),
            floatingActionButton: _currentNavigationIndex == 0
                ? FloatingActionButton(
                    onPressed: () => _showAddEditClientDialog(),
                    child: const Icon(Icons.add),
                  )
                : null,
          ),
          tablet: Row(
            children: [
              SizedBox(width: 250, child: customSidebar),
              VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
              Expanded(
                child: _currentNavigationIndex == 0
                    ? Row(
                        children: [
                          SizedBox(width: 320, child: clientListContent),
                          VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
                          Expanded(
                            child: _selectedClient == null
                                ? Center(child: Text(context.translate('no_data')))
                                : Scaffold(
                                    backgroundColor: Colors.transparent,
                                    body: ClientDetailScreen(
                                      client: _selectedClient!,
                                      isTabletOrDesktopLayout: true,
                                    ),
                                    key: ValueKey(_selectedClient!.id),
                                  ),
                          ),
                        ],
                      )
                    : _currentNavigationIndex == 1
                        ? const EmployeesDashboardScreen()
                        : UserManagementScreen(authRepository: widget.authRepository),
              ),
            ],
          ),
          desktop: Row(
            children: [
              SizedBox(width: 280, child: customSidebar),
              VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
              Expanded(
                child: _currentNavigationIndex == 0
                    ? Row(
                        children: [
                          SizedBox(width: 380, child: clientListContent),
                          VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
                          Expanded(
                            child: _selectedClient == null
                                ? Center(child: Text(context.translate('no_data')))
                                : Scaffold(
                                    backgroundColor: Colors.transparent,
                                    body: ClientDetailScreen(
                                      client: _selectedClient!,
                                      isTabletOrDesktopLayout: true,
                                    ),
                                    key: ValueKey(_selectedClient!.id),
                                  ),
                          ),
                        ],
                      )
                    : _currentNavigationIndex == 1
                        ? const EmployeesDashboardScreen()
                        : UserManagementScreen(authRepository: widget.authRepository),
              ),
            ],
          ),
        ),
        bottomNavigationBar: isAdmin && ResponsiveLayout.isMobile(context)
            ? Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1D1D30) : Colors.white,
                  border: Border(
                    top: BorderSide(color: isDark ? const Color(0xFF2C2C45) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentNavigationIndex,
                  onTap: (index) {
                    setState(() {
                      _currentNavigationIndex = index;
                    });
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: isDark ? const Color(0xFF46F0D2) : const Color(0xFF0D9488),
                  unselectedItemColor: isDark ? const Color(0xFF9090A0) : const Color(0xFF5D5D70),
                  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.people_outline),
                      label: context.translate('clients'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.badge_outlined),
                      label: context.translate('employees'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: context.translate('users'),
                    ),
                  ],
                ),
              )
            : null,
        floatingActionButton: ResponsiveLayout.isMobile(context) || _currentNavigationIndex == 1
            ? null
            : FloatingActionButton(
                onPressed: () => _showAddEditClientDialog(),
                child: const Icon(Icons.add),
              ),
      ),
    );
  }

  Widget _sidebarHeader({required UserModel user, required bool isDark}) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withAlpha(100),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Mr. ${user.name.split(' ')[0]} Dashboard',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isDark ? Colors.white : const Color(0xFF131321),
          ),
        ),
        const SizedBox(height: 18),
        Divider(
          color: isDark ? const Color(0xFF2C2C45) : const Color(0xFFE2E8F0),
          indent: 16,
          endIndent: 16,
          height: 1,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _sidebarItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
    required Color accent,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: selected
            ? (isDark ? const Color(0xFF1E203C) : accent.withAlpha(20))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? (isDark ? accent.withAlpha(80) : accent.withAlpha(100))
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        dense: true,
        leading: Icon(
          icon,
          color: selected
              ? (isDark ? Colors.white : accent)
              : (isDark ? const Color(0xFF9090A0) : const Color(0xFF5D5D70)),
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
            color: selected
                ? (isDark ? Colors.white : accent)
                : (isDark ? const Color(0xFF9090A0) : const Color(0xFF5D5D70)),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _footerProfile({
    required UserModel user,
    required bool isDark,
    required Color accent,
    required VoidCallback onLogout,
  }) {
    final initials = user.name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2C2C45) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark ? const Color(0xFF3B82F6) : accent.withAlpha(40),
            child: Text(
              initials,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF131321),
                  ),
                ),
                Text(
                  user.role.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF9090A0) : const Color(0xFF5D5D70),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red, size: 18),
            onPressed: onLogout,
            tooltip: 'Logout',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
