import 'package:equatable/equatable.dart';
import '../../domain/models/client_model.dart';

abstract class ClientsState extends Equatable {
  const ClientsState();

  @override
  List<Object?> get props => [];
}

class ClientsInitial extends ClientsState {}

class ClientsLoading extends ClientsState {}

class ClientsLoaded extends ClientsState {
  final List<ClientModel> clients;
  final List<ClientModel> filteredClients;
  final String searchQuery;

  const ClientsLoaded({
    required this.clients,
    required this.filteredClients,
    this.searchQuery = '',
  });

  ClientsLoaded copyWith({
    List<ClientModel>? clients,
    List<ClientModel>? filteredClients,
    String? searchQuery,
  }) {
    return ClientsLoaded(
      clients: clients ?? this.clients,
      filteredClients: filteredClients ?? this.filteredClients,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [clients, filteredClients, searchQuery];
}

class ClientsError extends ClientsState {
  final String message;

  const ClientsError(this.message);

  @override
  List<Object?> get props => [message];
}
