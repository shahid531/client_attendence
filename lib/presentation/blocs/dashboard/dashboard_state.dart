import 'package:equatable/equatable.dart';
import '../../../domain/entities/dashboard_stats.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitialState extends DashboardState {}

class DashboardLoadingState extends DashboardState {}

class DashboardLoadedState extends DashboardState {
  final DashboardStats stats;

  const DashboardLoadedState(this.stats);

  @override
  List<Object?> get props => [stats];
}

class DashboardErrorState extends DashboardState {
  final String message;

  const DashboardErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
