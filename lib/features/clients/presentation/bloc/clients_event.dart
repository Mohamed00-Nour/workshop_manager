import 'package:equatable/equatable.dart';
import '../../domain/models/client_model.dart';

abstract class ClientsEvent extends Equatable {
  const ClientsEvent();

  @override
  List<Object?> get props => [];
}

class LoadClients extends ClientsEvent {
  final bool refreshFromServer;
  const LoadClients({this.refreshFromServer = false});

  @override
  List<Object?> get props => [refreshFromServer];
}

class SearchClients extends ClientsEvent {
  final String query;
  const SearchClients(this.query);

  @override
  List<Object?> get props => [query];
}

class AddClientRequested extends ClientsEvent {
  final ClientModel client;
  const AddClientRequested(this.client);

  @override
  List<Object?> get props => [client];
}

class UpdateClientRequested extends ClientsEvent {
  final ClientModel client;
  const UpdateClientRequested(this.client);

  @override
  List<Object?> get props => [client];
}

class DeleteClientRequested extends ClientsEvent {
  final String clientId;
  const DeleteClientRequested(this.clientId);

  @override
  List<Object?> get props => [clientId];
}
