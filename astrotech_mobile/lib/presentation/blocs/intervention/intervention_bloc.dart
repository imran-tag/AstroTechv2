import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/intervention.dart';
import '../../../domain/usecases/get_intervention_detail.dart';
import '../../../domain/usecases/get_interventions.dart';
import '../../../domain/usecases/update_intervention_status.dart';

// Events
abstract class InterventionEvent extends Equatable {
  const InterventionEvent();

  @override
  List<Object?> get props => [];
}

class LoadInterventions extends InterventionEvent {
  final bool forceRefresh;

  const LoadInterventions({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class LoadInterventionDetail extends InterventionEvent {
  final int id;
  final bool forceRefresh;

  const LoadInterventionDetail({required this.id, this.forceRefresh = false});

  @override
  List<Object?> get props => [id, forceRefresh];
}

class UpdateStatus extends InterventionEvent {
  final int interventionId;
  final String status;

  const UpdateStatus({required this.interventionId, required this.status});

  @override
  List<Object?> get props => [interventionId, status];
}

class ClearSelectedIntervention extends InterventionEvent {}

// States
abstract class InterventionState extends Equatable {
  const InterventionState();

  @override
  List<Object?> get props => [];
}

class InterventionInitial extends InterventionState {}

class InterventionLoading extends InterventionState {}

class InterventionsLoaded extends InterventionState {
  final List<Intervention> interventions;
  final bool isRefreshing;

  const InterventionsLoaded({
    required this.interventions,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [interventions, isRefreshing];
}

class InterventionDetailLoaded extends InterventionState {
  final Intervention intervention;
  final List<Intervention>? allInterventions;

  const InterventionDetailLoaded({
    required this.intervention,
    this.allInterventions,
  });

  @override
  List<Object?> get props => [intervention, allInterventions];
}

class InterventionError extends InterventionState {
  final String message;
  final List<Intervention>? cachedInterventions;

  const InterventionError({
    required this.message,
    this.cachedInterventions,
  });

  @override
  List<Object?> get props => [message, cachedInterventions];
}

// BLoC
class InterventionBloc extends Bloc<InterventionEvent, InterventionState> {
  final GetInterventions getInterventions;
  final GetInterventionDetail getInterventionDetail;
  final UpdateInterventionStatus updateInterventionStatus;

  List<Intervention>? _cachedInterventions;

  InterventionBloc({
    required this.getInterventions,
    required this.getInterventionDetail,
    required this.updateInterventionStatus,
  }) : super(InterventionInitial()) {
    on<LoadInterventions>(_onLoadInterventions);
    on<LoadInterventionDetail>(_onLoadInterventionDetail);
    on<UpdateStatus>(_onUpdateStatus);
    on<ClearSelectedIntervention>(_onClearSelectedIntervention);
  }

  Future<void> _onLoadInterventions(
    LoadInterventions event,
    Emitter<InterventionState> emit,
  ) async {
    // Show loading only if we don't have cached data
    if (_cachedInterventions == null || _cachedInterventions!.isEmpty) {
      emit(InterventionLoading());
    } else {
      emit(InterventionsLoaded(
        interventions: _cachedInterventions!,
        isRefreshing: true,
      ));
    }

    try {
      final interventions = await getInterventions(forceRefresh: event.forceRefresh);
      _cachedInterventions = interventions;
      emit(InterventionsLoaded(interventions: interventions));
    } catch (e) {
      emit(InterventionError(
        message: e.toString(),
        cachedInterventions: _cachedInterventions,
      ));
    }
  }

  Future<void> _onLoadInterventionDetail(
    LoadInterventionDetail event,
    Emitter<InterventionState> emit,
  ) async {
    emit(InterventionLoading());

    try {
      final intervention = await getInterventionDetail(
        event.id,
        forceRefresh: event.forceRefresh,
      );

      emit(InterventionDetailLoaded(
        intervention: intervention,
        allInterventions: _cachedInterventions,
      ));
    } catch (e) {
      emit(InterventionError(
        message: e.toString(),
        cachedInterventions: _cachedInterventions,
      ));
    }
  }

  Future<void> _onUpdateStatus(
    UpdateStatus event,
    Emitter<InterventionState> emit,
  ) async {
    try {
      await updateInterventionStatus(event.interventionId, event.status);

      // Refresh the intervention detail
      add(LoadInterventionDetail(id: event.interventionId, forceRefresh: true));
    } catch (e) {
      emit(InterventionError(
        message: 'Erreur lors de la mise à jour du statut: ${e.toString()}',
        cachedInterventions: _cachedInterventions,
      ));
    }
  }

  void _onClearSelectedIntervention(
    ClearSelectedIntervention event,
    Emitter<InterventionState> emit,
  ) {
    if (_cachedInterventions != null) {
      emit(InterventionsLoaded(interventions: _cachedInterventions!));
    } else {
      emit(InterventionInitial());
    }
  }
}
