import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/dashboard/get_dashboard_stats_usecase.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardStatsUseCase getDashboardStatsUseCase;

  DashboardBloc({required this.getDashboardStatsUseCase})
      : super(DashboardInitialState()) {
    on<LoadDashboardStatsEvent>(_onLoadDashboardStats);
  }

  Future<void> _onLoadDashboardStats(
    LoadDashboardStatsEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoadingState());
    final result = await getDashboardStatsUseCase(NoParams());

    result.fold(
      (failure) => emit(DashboardErrorState(failure.message)),
      (stats) => emit(DashboardLoadedState(stats)),
    );
  }
}
