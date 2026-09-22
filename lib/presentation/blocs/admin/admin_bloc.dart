import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/entities/client_location.dart';
import '../../../domain/usecases/admin/bulk_upload_employees_usecase.dart';
import '../../../domain/usecases/admin/create_employee_usecase.dart';
import '../../../domain/usecases/admin/create_location_usecase.dart';
import '../../../domain/usecases/admin/download_bulk_upload_sample_usecase.dart';
import '../../../domain/usecases/admin/get_employees_usecase.dart';
import '../../../domain/usecases/admin/get_locations_usecase.dart';
import '../../../domain/usecases/admin/update_location_usecase.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final CreateEmployeeUseCase createEmployeeUseCase;
  final CreateLocationUseCase createLocationUseCase;
  final UpdateLocationUseCase updateLocationUseCase;
  final GetEmployeesUseCase getEmployeesUseCase;
  final GetLocationsUseCase getLocationsUseCase;
  final DownloadBulkUploadSampleUseCase downloadBulkUploadSampleUseCase;
  final BulkUploadEmployeesUseCase bulkUploadEmployeesUseCase;

  AdminBloc({
    required this.createEmployeeUseCase,
    required this.createLocationUseCase,
    required this.updateLocationUseCase,
    required this.getEmployeesUseCase,
    required this.getLocationsUseCase,
    required this.downloadBulkUploadSampleUseCase,
    required this.bulkUploadEmployeesUseCase,
  }) : super(const AdminInitialState()) {
    on<LoadEmployeesEvent>(_onLoadEmployees);
    on<LoadLocationsEvent>(_onLoadLocations);
    on<CreateLocationSubmittedEvent>(_onCreateLocationSubmitted);
    on<UpdateLocationSubmittedEvent>(_onUpdateLocationSubmitted);
    on<CreateEmployeeSubmittedEvent>(_onCreateEmployeeSubmitted);
    on<DownloadBulkSampleEvent>(_onDownloadBulkSample);
    on<BulkUploadEmployeesEvent>(_onBulkUploadEmployees);
    on<ResetBulkUploadStateEvent>(_onResetBulkUploadState);
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

    final result = await getLocationsUseCase(
      GetLocationsParams(
        clientName: event.clientName,
        city: event.city,
      ),
    );

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
        city: event.city,
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

  Future<void> _onUpdateLocationSubmitted(
    UpdateLocationSubmittedEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(UpdateLocationLoadingState(
      employees: state.employees,
      locations: state.locations,
      isLoadingEmployees: state.isLoadingEmployees,
      employeesError: state.employeesError,
      isLoadingLocations: state.isLoadingLocations,
      locationsError: state.locationsError,
    ));

    final result = await updateLocationUseCase(
      UpdateLocationParams(
        id: event.id,
        clientName: event.clientName,
        locationName: event.locationName,
        address: event.address,
        city: event.city,
        latitude: event.latitude,
        longitude: event.longitude,
        allowedRadius: event.allowedRadius,
        halfDayHrs: event.halfDayHrs,
        fullDayHrs: event.fullDayHrs,
        status: event.status,
      ),
    );

    result.fold(
      (failure) => emit(
        UpdateLocationFailureState(
          failure.message,
          employees: state.employees,
          locations: state.locations,
          isLoadingEmployees: state.isLoadingEmployees,
          employeesError: state.employeesError,
          isLoadingLocations: state.isLoadingLocations,
          locationsError: state.locationsError,
        ),
      ),
      (updatedLocation) {
        final updatedLocations = state.locations.map((loc) {
          if (loc.id != null &&
              updatedLocation.id != null &&
              loc.id == updatedLocation.id) {
            return updatedLocation;
          }
          if (loc.locationId == updatedLocation.locationId) {
            return updatedLocation;
          }
          return loc;
        }).toList();

        emit(
          UpdateLocationSuccessState(
            updatedLocation: updatedLocation,
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

  Future<void> _onDownloadBulkSample(
    DownloadBulkSampleEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(BulkSampleDownloadLoadingState(
      employees: state.employees,
      locations: state.locations,
      isLoadingEmployees: state.isLoadingEmployees,
      employeesError: state.employeesError,
      isLoadingLocations: state.isLoadingLocations,
      locationsError: state.locationsError,
    ));

    final result = await downloadBulkUploadSampleUseCase(NoParams());

    result.fold(
      (failure) => emit(
        BulkSampleDownloadFailureState(
          failure.message,
          employees: state.employees,
          locations: state.locations,
          isLoadingEmployees: state.isLoadingEmployees,
          employeesError: state.employeesError,
          isLoadingLocations: state.isLoadingLocations,
          locationsError: state.locationsError,
        ),
      ),
      (filePath) => emit(
        BulkSampleDownloadSuccessState(
          filePath: filePath,
          employees: state.employees,
          locations: state.locations,
          isLoadingEmployees: state.isLoadingEmployees,
          employeesError: state.employeesError,
          isLoadingLocations: state.isLoadingLocations,
          locationsError: state.locationsError,
        ),
      ),
    );
  }

  Future<void> _onBulkUploadEmployees(
    BulkUploadEmployeesEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(BulkUploadLoadingState(
      employees: state.employees,
      locations: state.locations,
      isLoadingEmployees: state.isLoadingEmployees,
      employeesError: state.employeesError,
      isLoadingLocations: state.isLoadingLocations,
      locationsError: state.locationsError,
    ));

    final result = await bulkUploadEmployeesUseCase(
      BulkUploadParams(
        filePath: event.filePath,
        fileName: event.fileName,
        fileBytes: event.fileBytes,
      ),
    );

    result.fold(
      (failure) => emit(
        BulkUploadFailureState(
          failure.message,
          employees: state.employees,
          locations: state.locations,
          isLoadingEmployees: state.isLoadingEmployees,
          employeesError: state.employeesError,
          isLoadingLocations: state.isLoadingLocations,
          locationsError: state.locationsError,
        ),
      ),
      (response) {
        final message = response['message']?.toString() ?? 'Employees uploaded successfully';
        final data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;

        emit(
          BulkUploadSuccessState(
            message: message,
            data: data,
            employees: state.employees,
            locations: state.locations,
            isLoadingEmployees: state.isLoadingEmployees,
            employeesError: state.employeesError,
            isLoadingLocations: state.isLoadingLocations,
            locationsError: state.locationsError,
          ),
        );
        // Refresh employees list
        add(const LoadEmployeesEvent(isRefresh: true));
      },
    );
  }

  void _onResetBulkUploadState(
    ResetBulkUploadStateEvent event,
    Emitter<AdminState> emit,
  ) {
    emit(AdminInitialState(
      employees: state.employees,
      locations: state.locations,
    ));
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
