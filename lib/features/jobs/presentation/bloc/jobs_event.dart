import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../domain/models/job_model.dart';

abstract class JobsEvent extends Equatable {
  const JobsEvent();

  @override
  List<Object?> get props => [];
}

class LoadJobs extends JobsEvent {
  final String clientId;
  final bool refreshFromServer;

  const LoadJobs({required this.clientId, this.refreshFromServer = false});

  @override
  List<Object?> get props => [clientId, refreshFromServer];
}

class AddJobRequested extends JobsEvent {
  final JobModel job;
  final File? imageFile;

  const AddJobRequested({required this.job, this.imageFile});

  @override
  List<Object?> get props => [job, imageFile];
}

class UpdateJobStatusRequested extends JobsEvent {
  final String jobId;
  final String clientId;
  final String status;

  const UpdateJobStatusRequested({
    required this.jobId,
    required this.clientId,
    required this.status,
  });

  @override
  List<Object?> get props => [jobId, clientId, status];
}

class DeleteJobRequested extends JobsEvent {
  final String jobId;
  final String clientId;
  final double cost;

  const DeleteJobRequested({
    required this.jobId,
    required this.clientId,
    required this.cost,
  });

  @override
  List<Object?> get props => [jobId, clientId, cost];
}
