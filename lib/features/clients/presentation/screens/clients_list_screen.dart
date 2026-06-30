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

    // Sidebar navigation widget for tablet/desktop
    Widget sidebar = Drawer(
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withAlpha(50),
                ),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(child: Icon(Icons.engineering)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.currentUser.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        context.translate(widget.currentUser.role),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: Text(context.translate('app_name')),
            selected: true,
            onTap: () {},
          ),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: Text(context.translate('users')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => UserManagementScreen(
                          authRepository: widget.authRepository,
                        ),
                  ),
                );
              },
            ),
          const Spacer(),
          ListTile(
            leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            title: Text(
              isDark
                  ? context.translate('theme_light')
                  : context.translate('theme_dark'),
            ),
            onTap: () {
              widget.onThemeChanged(isDark ? ThemeMode.light : ThemeMode.dark);
            },
          ),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(context.translate('language')),
            onTap: () {
              final newLocale =
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? const Locale('en')
                      : const Locale('ar');
              widget.onLanguageChanged(newLocale);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              context.translate('logout'),
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () {
              context.read<AuthBloc>().add(LogoutRequested());
            },
          ),
        ],
      ),
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
            : null,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: ResponsiveLayout.isMobile(context) ? sidebar : null,
        body: ResponsiveLayout(
          mobile: Scaffold(
            backgroundColor: Colors.transparent,
            drawer: sidebar,
            body: clientListContent,
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddEditClientDialog(),
            child: const Icon(Icons.add),
          ),
        ),
        tablet: Row(
          children: [
            SizedBox(width: 250, child: sidebar),
            VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
            SizedBox(width: 320, child: clientListContent),
            VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
            Expanded(
              child:
                  _selectedClient == null
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
        ),
        desktop: Row(
          children: [
            SizedBox(width: 280, child: sidebar),
            VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
            SizedBox(width: 380, child: clientListContent),
            VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
            Expanded(
              child:
                  _selectedClient == null
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
        ),
      ),
      floatingActionButton:
          ResponsiveLayout.isMobile(context)
              ? null
              : FloatingActionButton(
                onPressed: () => _showAddEditClientDialog(),
                child: const Icon(Icons.add),
              ),
    ),);
  }
}
