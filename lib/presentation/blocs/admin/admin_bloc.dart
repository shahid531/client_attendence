import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/admin/create_employee_usecase.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final CreateEmployeeUseCase createEmployeeUseCase;

  AdminBloc({
    required this.createEmployeeUseCase,
  }) : super(AdminInitialState()) {
    on<CreateEmployeeSubmittedEvent>(_onCreateEmployeeSubmitted);
    on<ResetAdminStateEvent>(_onResetAdminState);
  }

  Future<void> _onCreateEmployeeSubmitted(
    CreateEmployeeSubmittedEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoadingState());

    final result = await createEmployeeUseCase(
      CreateEmployeeParams(
        email: event.email,
        employeeId: event.employeeId,
        fullName: event.fullName,
        locationId: event.locationId,
        role: event.role,
        contactNumber: event.contactNumber,
        reportingManagerEmployeeId: event.reportingManagerEmployeeId,
      ),
    );

    result.fold(
      (failure) => emit(AdminFailureState(failure.message)),
      (employee) => emit(CreateEmployeeSuccessState(employee: employee)),
    );
  }

  void _onResetAdminState(
    ResetAdminStateEvent event,
    Emitter<AdminState> emit,
  ) {
    emit(AdminInitialState());
  }
}
