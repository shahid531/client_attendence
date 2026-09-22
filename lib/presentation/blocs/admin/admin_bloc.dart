import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/entities/client_location.dart';
import '../../../domain/usecases/admin/create_employee_usecase.dart';
import '../../../domain/usecases/admin/create_location_usecase.dart';
import '../../../domain/usecases/admin/get_employees_usecase.dart';
import '../../../domain/usecases/admin/get_locations_usecase.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final CreateEmployeeUseCase createEmployeeUseCase;
  final CreateLocationUseCase createLocationUseCase;
  final GetEmployeesUseCase getEmployeesUseCase;
  final GetLocationsUseCase getLocationsUseCase;

  AdminBloc({
    required this.createEmployeeUseCase,
    required this.createLocationUseCase,
    required this.getEmployeesUseCase,
    required this.getLocationsUseCase,
  }) : super(const AdminInitialState()) {
    on<LoadEmployeesEvent>(_onLoadEmployees);
    on<LoadLocationsEvent>(_onLoadLocations);
    on<CreateLocationSubmittedEvent>(_onCreateLocationSubmitted);
    on<CreateEmployeeSubmittedEvent>(_onCreateEmployeeSubmitted);
    on<ResetAdminStateEvent>(_onResetAdminState);
  }

  Future<void> _onLoadEmployees(
    LoadEmployeesEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(EmployeesLoadingState(
      employees: state.employees,
      locations: state.locations,
      isLoadingLocations: state.isLoadingLocations,
      locationsError: state.locationsError,
    ));

    final result = await getEmployeesUseCase(
      GetEmployeesParams(name: event.name),
    );

    result.fold(
      (failure) => emit(
        EmployeesErrorState(
          failure.message,
          employees: state.employees,
          locations: state.locations,
          isLoadingLocations: state.isLoadingLocations,
          locationsError: state.locationsError,
        ),
      ),
      (employees) => emit(
        EmployeesLoadedState(
          employees: employees,
          locations: state.locations,
          isLoadingLocations: state.isLoadingLocations,
          locationsError: state.locationsError,
        ),
      ),
    );
  }

  Future<void> _onLoadLocations(
    LoadLocationsEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(LocationsLoadingState(
      employees: state.employees,
      isLoadingEmployees: state.isLoadingEmployees,
      employeesError: state.employeesError,
      locations: state.locations,
    ));

    final result = await getLocationsUseCase(NoParams());

    result.fold(
      (failure) => emit(
        LocationsErrorState(
          failure.message,
          employees: state.employees,
          isLoadingEmployees: state.isLoadingEmployees,
          employeesError: state.employeesError,
          locations: state.locations,
        ),
      ),
      (locations) => emit(
        LocationsLoadedState(
          employees: state.employees,
          isLoadingEmployees: state.isLoadingEmployees,
          employeesError: state.employeesError,
          locations: locations,
        ),
      ),
    );
  }

  Future<void> _onCreateLocationSubmitted(
    CreateLocationSubmittedEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(CreateLocationLoadingState(
      employees: state.employees,
      locations: state.locations,
      isLoadingEmployees: state.isLoadingEmployees,
      employeesError: state.employeesError,
      isLoadingLocations: state.isLoadingLocations,
      locationsError: state.locationsError,
    ));

    final result = await createLocationUseCase(
      CreateLocationParams(
        clientName: event.clientName,
        locationName: event.locationName,
        address: event.address,
        latitude: event.latitude,
        longitude: event.longitude,
        allowedRadius: event.allowedRadius,
      ),
    );

    result.fold(
      (failure) => emit(
        CreateLocationFailureState(
          failure.message,
          employees: state.employees,
          locations: state.locations,
          isLoadingEmployees: state.isLoadingEmployees,
          employeesError: state.employeesError,
          isLoadingLocations: state.isLoadingLocations,
          locationsError: state.locationsError,
        ),
      ),
      (location) {
        final updatedLocations = List<ClientLocation>.from(state.locations);
        updatedLocations.insert(0, location);

        emit(
          CreateLocationSuccessState(
            createdLocation: location,
            employees: state.employees,
            locations: updatedLocations,
            isLoadingEmployees: state.isLoadingEmployees,
            employeesError: state.employeesError,
            isLoadingLocations: false,
            locationsError: null,
          ),
        );
      },
    );
  }

  Future<void> _onCreateEmployeeSubmitted(
    CreateEmployeeSubmittedEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoadingState(
      employees: state.employees,
      locations: state.locations,
    ));

    final result = await createEmployeeUseCase(
      CreateEmployeeParams(
        email: event.email,
        employeeId: event.employeeId,
        fullName: event.fullName,
        locationId: event.locationId,
        locationName: event.locationName,
        latitude: event.latitude,
        longitude: event.longitude,
        role: event.role,
        contactNumber: event.contactNumber,
        reportingManagerEmployeeId: event.reportingManagerEmployeeId,
      ),
    );

    result.fold(
      (failure) => emit(
        AdminFailureState(
          failure.message,
          employees: state.employees,
          locations: state.locations,
        ),
      ),
      (employee) {
        emit(
          CreateEmployeeSuccessState(
            employee: employee,
            employees: state.employees,
            locations: state.locations,
          ),
        );
        // Automatically refresh employees list so newly created employee is available
        add(const LoadEmployeesEvent(isRefresh: true));
      },
    );
  }

  void _onResetAdminState(
    ResetAdminStateEvent event,
    Emitter<AdminState> emit,
  ) {
    emit(AdminInitialState(
      employees: state.employees,
      locations: state.locations,
    ));
  }
}
