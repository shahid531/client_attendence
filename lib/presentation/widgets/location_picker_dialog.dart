import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../core/constants/app_colors.dart';

class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String? address;
  final String? placeName;

  const LocationPickerResult({
    required this.latitude,
    required this.longitude,
    this.address,
    this.placeName,
  });
}

class LocationPickerDialog extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLocationName;

  const LocationPickerDialog({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocationName,
  });

  static Future<LocationPickerResult?> show(
    BuildContext context, {
    double? initialLatitude,
    double? initialLongitude,
    String? initialLocationName,
  }) {
    return showModalBottomSheet<LocationPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LocationPickerDialog(
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
        initialLocationName: initialLocationName,
      ),
    );
  }

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  // Default coordinates (e.g. Mumbai, India if no initial provided)
  static const ll.LatLng _fallbackLocation = ll.LatLng(19.0760, 72.8777);

  final MapController _mapController = MapController();
  final Geocoding _geocoding = Geocoding();
  final Dio _dio = Dio();

  late ll.LatLng _currentSelectedLocation;
  String _currentAddress = 'Fetching address...';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  bool _isLocatingUser = false;
  bool _isDraggingMap = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _currentSelectedLocation = ll.LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
    } else {
      _currentSelectedLocation = _fallbackLocation;
    }

    if (widget.initialLocationName != null &&
        widget.initialLocationName!.isNotEmpty) {
      _currentAddress = widget.initialLocationName!;
    }

    _reverseGeocode(_currentSelectedLocation);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _reverseGeocode(ll.LatLng position) async {
    // 1. Try native geocoding first
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.name != null && p.name!.isNotEmpty && p.name != p.street)
            p.name!,
          if (p.street != null && p.street!.isNotEmpty) p.street!,
          if (p.subLocality != null && p.subLocality!.isNotEmpty)
            p.subLocality!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
            p.administrativeArea!,
          if (p.postalCode != null && p.postalCode!.isNotEmpty) p.postalCode!,
        ];

        if (parts.isNotEmpty) {
          setState(() {
            _currentAddress = parts.join(', ');
          });
          return;
        }
      }
    } catch (_) {
      // Fallback to OSM Nominatim reverse geocode
    }

    // 2. Fallback to OpenStreetMap Nominatim reverse API
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': position.latitude,
          'lon': position.longitude,
          'zoom': 18,
          'addressdetails': 1,
        },
        options: Options(
          headers: {'User-Agent': 'ClientAttendanceApp/1.0'},
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      if (response.data is Map && mounted) {
        final displayName = response.data['display_name']?.toString();
        if (displayName != null && displayName.isNotEmpty) {
          setState(() {
            _currentAddress = displayName;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _currentAddress =
            'Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)}';
      });
    }
  }

  Future<void> _searchLocationByName(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
    });

    // 1. Try Nominatim Place Search
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': trimmed,
          'format': 'json',
          'limit': 1,
        },
        options: Options(
          headers: {'User-Agent': 'ClientAttendanceApp/1.0'},
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.data is List && (response.data as List).isNotEmpty) {
        final first = (response.data as List).first;
        final lat = double.tryParse(first['lat']?.toString() ?? '');
        final lon = double.tryParse(first['lon']?.toString() ?? '');
        final displayName = first['display_name']?.toString();

        if (lat != null && lon != null && mounted) {
          final target = ll.LatLng(lat, lon);
          _updateSelectedLocation(target, animateMap: true, address: displayName);
          return;
        }
      }
    } catch (_) {
      // Fallback to native geocoding
    }

    // 2. Native geocoding fallback
    try {
      final locations = await _geocoding.locationFromAddress(trimmed);
      if (locations.isNotEmpty && mounted) {
        final loc = locations.first;
        final target = ll.LatLng(loc.latitude, loc.longitude);
        _updateSelectedLocation(target, animateMap: true);
        return;
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not find location for "$trimmed"'),
          backgroundColor: AppColors.dangerRose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocatingUser = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permission was denied.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied. Please enable them in system settings.';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final target = ll.LatLng(position.latitude, position.longitude);
      _updateSelectedLocation(target, animateMap: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Current location error: $e'),
            backgroundColor: AppColors.dangerRose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocatingUser = false;
        });
      }
    }
  }

  void _updateSelectedLocation(
    ll.LatLng newLocation, {
    bool animateMap = false,
    String? address,
  }) {
    setState(() {
      _currentSelectedLocation = newLocation;
      _isSearching = false;
      if (address != null && address.isNotEmpty) {
        _currentAddress = address;
      }
    });

    if (animateMap) {
      _mapController.move(newLocation, 15.0);
    }

    if (address == null) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 400), () {
        _reverseGeocode(newLocation);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final sheetHeight = mediaQuery.size.height * 0.88;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Interactive Flutter Map
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentSelectedLocation,
                initialZoom: 15.0,
                onPositionChanged: (camera, hasGesture) {
                  if (hasGesture) {
                    if (!_isDraggingMap) {
                      setState(() {
                        _isDraggingMap = true;
                      });
                    }
                    _currentSelectedLocation = camera.center;
                    _debounceTimer?.cancel();
                    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        setState(() {
                          _isDraggingMap = false;
                        });
                        _reverseGeocode(_currentSelectedLocation);
                      }
                    });
                  }
                },
                onTap: (tapPosition, point) {
                  _updateSelectedLocation(point, animateMap: true);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.idealake.clientattendance',
                ),
              ],
            ),
          ),

          // 2. Fixed Center Pin with Elevation & Drag Animation
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 38.0),
              child: AnimatedScale(
                scale: _isDraggingMap ? 1.25 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(2),
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: _isDraggingMap ? 12 : 8,
                      height: _isDraggingMap ? 4 : 3,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Top Header with Drag Handle & Location Search Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white.withValues(alpha: 0.95),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.75, 1.0],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle Bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Search Bar Row
                  Row(
                    children: [
                      // Search Input Field
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: _searchLocationByName,
                            decoration: InputDecoration(
                              hintText: 'Search place / address by name...',
                              hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13.5,
                              ),
                              prefixIcon: _isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            AppColors.primaryNavy,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.search_rounded,
                                      color: Color(0xFF64748B),
                                      size: 22,
                                    ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 18,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Search Button
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.primaryNavy.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                          ),
                          tooltip: 'Search Location',
                          onPressed: () =>
                              _searchLocationByName(_searchController.text),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Close Button
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF475569),
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  // Help Hint Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Drag map or search location name to position pin',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Floating Action Buttons (Current Location & Zoom)
          Positioned(
            right: 16,
            bottom: 230,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current GPS Location Button
                FloatingActionButton.small(
                  heroTag: 'btn_current_location',
                  onPressed: _isLocatingUser ? null : _getCurrentLocation,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryNavy,
                  elevation: 4,
                  child: _isLocatingUser
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryNavy,
                            ),
                          ),
                        )
                      : const Icon(Icons.my_location_rounded, size: 20),
                ),
                const SizedBox(height: 10),

                // Zoom In Button
                FloatingActionButton.small(
                  heroTag: 'btn_zoom_in',
                  onPressed: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(_currentSelectedLocation, zoom + 1);
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF475569),
                  elevation: 3,
                  child: const Icon(Icons.add_rounded, size: 20),
                ),
                const SizedBox(height: 6),

                // Zoom Out Button
                FloatingActionButton.small(
                  heroTag: 'btn_zoom_out',
                  onPressed: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(_currentSelectedLocation, zoom - 1);
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF475569),
                  elevation: 3,
                  child: const Icon(Icons.remove_rounded, size: 20),
                ),
              ],
            ),
          ),

          // 5. Bottom Selected Location Summary Card & Confirm Action
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Address Info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.primaryNavy,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selected Location',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currentAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Coordinates Chips Row (Lat & Long)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'LATITUDE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currentSelectedLocation.latitude
                                      .toStringAsFixed(6),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryNavy,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'LONGITUDE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currentSelectedLocation.longitude
                                      .toStringAsFixed(6),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryNavy,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Confirm Selection Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(
                            LocationPickerResult(
                              latitude: _currentSelectedLocation.latitude,
                              longitude: _currentSelectedLocation.longitude,
                              address: _currentAddress,
                              placeName: _searchQuery.isNotEmpty
                                  ? _searchQuery
                                  : null,
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          'Confirm Location & Coordinates',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
