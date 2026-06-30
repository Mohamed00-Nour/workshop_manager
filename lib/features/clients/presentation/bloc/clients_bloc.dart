import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/client_repository.dart';
import 'clients_event.dart';
import 'clients_state.dart';

class ClientsBloc extends Bloc<ClientsEvent, ClientsState> {
  final ClientRepository _clientRepository;

  ClientsBloc(this._clientRepository) : super(ClientsInitial()) {
    on<LoadClients>(_onLoadClients);
    on<SearchClients>(_onSearchClients);
    on<AddClientRequested>(_onAddClient);
    on<UpdateClientRequested>(_onUpdateClient);
    on<DeleteClientRequested>(_onDeleteClient);
  }

  Future<void> _onLoadClients(LoadClients event, Emitter<ClientsState> emit) async {
    // Show cached clients first if loading from initial state
    if (state is! ClientsLoaded) {
      emit(ClientsLoading());
    }

    try {
      // 1. Fetch cached clients for instant display
      final cachedClients = await _clientRepository.getClientsCached();
      if (cachedClients.isNotEmpty) {
        emit(ClientsLoaded(clients: cachedClients, filteredClients: cachedClients));
      }

      // 2. Fetch from server to get updates (if requested or if cache is empty)
      if (event.refreshFromServer || cachedClients.isEmpty) {
        final serverClients = await _clientRepository.fetchClientsFromServer();
        emit(ClientsLoaded(clients: serverClients, filteredClients: serverClients));
      }
    } catch (e) {
      emit(ClientsError(e.toString()));
    }
  }

  void _onSearchClients(SearchClients event, Emitter<ClientsState> emit) {
    final currentState = state;
    if (currentState is ClientsLoaded) {
      final query = event.query.toLowerCase().trim();
      if (query.isEmpty) {
        emit(currentState.copyWith(filteredClients: currentState.clients, searchQuery: ''));
      } else {
        final filtered = currentState.clients.where((client) {
          final nameMatch = client.name.toLowerCase().contains(query);
          final phoneMatch = client.phone.contains(query);
          final companyMatch = client.company.toLowerCase().contains(query);
          return nameMatch || phoneMatch || companyMatch;
        }).toList();
        emit(currentState.copyWith(filteredClients: filtered, searchQuery: query));
      }
    }
  }

  Future<void> _onAddClient(AddClientRequested event, Emitter<ClientsState> emit) async {
    try {
      await _clientRepository.addClient(event.client);
      add(const LoadClients(refreshFromServer: false));
    } catch (e) {
      emit(ClientsError(e.toString()));
    }
  }

  Future<void> _onUpdateClient(UpdateClientRequested event, Emitter<ClientsState> emit) async {
    try {
      await _clientRepository.updateClient(event.client);
      add(const LoadClients(refreshFromServer: false));
    } catch (e) {
      emit(ClientsError(e.toString()));
    }
  }

  Future<void> _onDeleteClient(DeleteClientRequested event, Emitter<ClientsState> emit) async {
    try {
      await _clientRepository.deleteClient(event.clientId);
      add(const LoadClients(refreshFromServer: false));
    } catch (e) {
      emit(ClientsError(e.toString()));
    }
  }
}
