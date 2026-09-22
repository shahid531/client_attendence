import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../domain/entities/client_location.dart';
import '../blocs/admin/admin_bloc.dart';
import '../blocs/admin/admin_event.dart';
import '../blocs/admin/admin_state.dart';
import 'location_employees_page.dart';

class ClientLocationsPage extends StatefulWidget {
  const ClientLocationsPage({super.key});

  @override
  State<ClientLocationsPage> createState() => _ClientLocationsPageState();
}

class _ClientLocationsPageState extends State<ClientLocationsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminBloc>().add(const LoadLocationsEvent());
      context.read<AdminBloc>().add(const LoadEmployeesEvent());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  List<ClientLocation> _filterLocations(List<ClientLocation> locations) {
    if (_searchQuery.isEmpty) return locations;

    return locations.where((loc) {
      final clientName = (loc.clientName ?? '').toLowerCase();
      final city = (loc.city ?? '').toLowerCase();
      final locationName = loc.locationName.toLowerCase();
      final address = (loc.address ?? '').toLowerCase();
      final locationId = loc.locationId.toLowerCase();

      return clientName.contains(_searchQuery) ||
          city.contains(_searchQuery) ||
          locationName.contains(_searchQuery) ||
          address.contains(_searchQuery) ||
          locationId.contains(_searchQuery);
    }).toList();
  }

  String _getCityDisplay(ClientLocation loc) {
    if (loc.city != null && loc.city!.trim().isNotEmpty) {
      return loc.city!.trim();
    }
    if (loc.address != null && loc.address!.trim().isNotEmpty) {
      return loc.address!.trim();
    }
    return 'Not Specified';
  }

  String _getClientNameDisplay(ClientLocation loc) {
    if (loc.clientName != null && loc.clientName!.trim().isNotEmpty) {
      return loc.clientName!.trim();
    }
    if (loc.locationName.trim().isNotEmpty) {
      return loc.locationName.trim();
    }
    return 'Client Location';
  }

  void _navigateToLocationEmployees(ClientLocation loc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationEmployeesPage(location: loc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryNavy = AppColors.primaryNavy;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<AdminBloc>().add(const LoadLocationsEvent(isRefresh: true));
          context.read<AdminBloc>().add(const LoadEmployeesEvent(isRefresh: true));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Title & Subtitle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Client Locations',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage client sites and geo-fenced attendance locations',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              _buildSearchBar(),
              const SizedBox(height: 16),

              // BLoC Consumer for Locations List
              BlocConsumer<AdminBloc, AdminState>(
                listener: (context, state) {
                  if (state is LocationsErrorState) {
                    SnackbarHelper.showError(context, state.error);
                  }
                },
                builder: (context, state) {
                  if (state.isLoadingLocations && state.locations.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: primaryNavy),
                            SizedBox(height: 14),
                            Text(
                              'Loading locations...',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state.locationsError != null && state.locations.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Color(0xFFDC2626)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.locationsError!,
                                  style: const TextStyle(
                                    color: Color(0xFFB91C1C),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                context
                                    .read<AdminBloc>()
                                    .add(const LoadLocationsEvent(isRefresh: true));
                              },
                              child: const Text(
                                'Retry',
                                style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final filtered = _filterLocations(state.locations);

                  if (filtered.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 48, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_off_outlined,
                            size: 48,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No locations matching "$_searchQuery"'
                                : 'No client locations found',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Try searching by a different client name or city'
                                : 'Tap "Add Location" to register a new client site.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Locations Count & Search Info
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Showing ${filtered.length} ${filtered.length == 1 ? "Location" : "Locations"}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            if (state.isLoadingLocations)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    primaryNavy,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Location Cards List
                      ...filtered.map((loc) => _buildLocationCard(loc, primaryNavy)),
                      const SizedBox(height: 60), // Spacing for FAB
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search by Client Name or City...',
          hintStyle: const TextStyle(
            color: AppColors.textLight,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard(ClientLocation loc, Color primaryNavy) {
    final clientName = _getClientNameDisplay(loc);
    final city = _getCityDisplay(loc);
    final isStatusActive = (loc.status ?? 'ACTIVE').toUpperCase() == 'ACTIVE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToLocationEmployees(loc),
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 4px Accent Stripe
                Container(
                  width: 4,
                  color: isStatusActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                ),
                // Card Body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Client Name and Status Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                clientName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(
                              label: isStatusActive ? 'Active' : 'Inactive',
                              icon: isStatusActive
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined,
                              bgColor: isStatusActive
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFF1F5F9),
                              textColor: isStatusActive
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFF64748B),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // City Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_city_rounded,
                              size: 15,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                city,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF475569),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
