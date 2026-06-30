import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/notification_helper.dart';
import '../../data/repositories/job_repository.dart';
import 'jobs_event.dart';
import 'jobs_state.dart';

class JobsBloc extends Bloc<JobsEvent, JobsState> {
  final JobRepository _jobRepository;

  JobsBloc(this._jobRepository) : super(JobsInitial()) {
    on<LoadJobs>(_onLoadJobs);
    on<AddJobRequested>(_onAddJob);
    on<UpdateJobStatusRequested>(_onUpdateJobStatus);
    on<DeleteJobRequested>(_onDeleteJob);
  }

  Future<void> _onLoadJobs(LoadJobs event, Emitter<JobsState> emit) async {
    if (state is! JobsLoaded) {
      emit(JobsLoading());
    }

    try {
      final cachedJobs = await _jobRepository.getJobsCached(event.clientId);
      if (cachedJobs.isNotEmpty) {
        emit(JobsLoaded(cachedJobs));
      }

      if (event.refreshFromServer || cachedJobs.isEmpty) {
        final serverJobs = await _jobRepository.fetchJobsFromServer(event.clientId);
        emit(JobsLoaded(serverJobs));
      }
    } catch (e) {
      emit(JobsError(e.toString()));
    }
  }

  Future<void> _onAddJob(AddJobRequested event, Emitter<JobsState> emit) async {
    try {
      await _jobRepository.addJob(event.job, event.imageFile);
      add(LoadJobs(clientId: event.job.clientId, refreshFromServer: false));

      // Trigger secure FCM V1 notification
      await NotificationHelper().triggerNotification(
        title: 'New Job Added',
        body: 'Part: ${event.job.description} | Cost: ${event.job.cost} EGP | By: ${event.job.recordedByName}',
        topic: 'workshop_updates',
      );
    } catch (e) {
      emit(JobsError(e.toString()));
    }
  }

  Future<void> _onUpdateJobStatus(UpdateJobStatusRequested event, Emitter<JobsState> emit) async {
    try {
      await _jobRepository.updateJobStatus(event.jobId, event.clientId, event.status);
      add(LoadJobs(clientId: event.clientId, refreshFromServer: false));

      // Trigger secure FCM V1 notification for status update
      await NotificationHelper().triggerNotification(
        title: 'Job Status Updated',
        body: 'A job status was updated to: ${event.status.replaceAll('_', ' ')}',
        topic: 'workshop_updates',
      );
    } catch (e) {
      emit(JobsError(e.toString()));
    }
  }

  Future<void> _onDeleteJob(DeleteJobRequested event, Emitter<JobsState> emit) async {
    try {
      await _jobRepository.deleteJob(event.jobId, event.clientId, event.cost);
      add(LoadJobs(clientId: event.clientId, refreshFromServer: false));
    } catch (e) {
      emit(JobsError(e.toString()));
    }
  }
}
