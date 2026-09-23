import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../core/constants/app_colors.dart';
import '../../core/di/injection_container.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../domain/entities/client_location.dart';
import '../../domain/usecases/admin/create_location_usecase.dart';

class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? placeName;
  final String? clientName;
  final double? allowedRadius;
  final ClientLocation? createdLocation;

  const LocationPickerResult({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.placeName,
    this.clientName,
    this.allowedRadius,
    this.createdLocation,
  });
}

class LocationPickerDialog extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLocationName;
  final String? initialClientName;
  final double? initialRadius;
  final bool enableCreateLocation;

  const LocationPickerDialog({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocationName,
    this.initialClientName,
    this.initialRadius,
    this.enableCreateLocation = true,
  });

  static Future<LocationPickerResult?> show(
    BuildContext context, {
    double? initialLatitude,
    double? initialLongitude,
    String? initialLocationName,
    String? initialClientName,
    double? initialRadius,
    bool enableCreateLocation = true,
  }) {
    return showModalBottomSheet<LocationPickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LocationPickerDialog(
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
        initialLocationName: initialLocationName,
        initialClientName: initialClientName,
        initialRadius: initialRadius,
        enableCreateLocation: enableCreateLocation,
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
  String? _currentCity;
  final TextEditingController _searchController = TextEditingController();
  late final TextEditingController _clientNameController;
  late final TextEditingController _radiusController;

  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _clientNameFocusNode = FocusNode();
  final FocusNode _radiusFocusNode = FocusNode();

  bool _isSearching = false;
  bool _isLocatingUser = false;
  bool _isDraggingMap = false;
  bool _isCreatingLocation = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _clientNameController = TextEditingController(
      text: widget.initialClientName ?? '',
    );
    _radiusController = TextEditingController(
      text: widget.initialRadius != null
          ? widget.initialRadius.toString()
          : '100.0',
    );

    _clientNameFocusNode.addListener(_onFocusChange);
    _radiusFocusNode.addListener(_onFocusChange);

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

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _clientNameFocusNode.removeListener(_onFocusChange);
    _radiusFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    _clientNameFocusNode.dispose();
    _radiusFocusNode.dispose();
    _searchController.dispose();
    _clientNameController.dispose();
    _radiusController.dispose();
    _dio.close();
    super.dispose();
  }

  String? _extractCityFallback(String address) {
    if (address.trim().isEmpty) return null;
    final parts = address
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length < 2) return null;

    // Address often formatted as: [Street, Area, Subdistrict, City, State, Pin, Country]
    // Filter out country and pure pincodes
    final filtered = parts.where((p) {
      final lower = p.toLowerCase();
      return lower != 'india' && !RegExp(r'^\d{5,6}$').hasMatch(p);
    }).toList();

    if (filtered.isEmpty) return null;

    // If we have at least 2 remaining components: (e.g. ..., City, State)
    if (filtered.length >= 2) {
      // Pick component before state
      final candidate = filtered[filtered.length - 2]
          .replaceAll(RegExp(r'\b\d{5,6}\b'), '')
          .trim();
      if (candidate.isNotEmpty &&
          !candidate.toLowerCase().contains('subdistrict') &&
          !candidate.toLowerCase().contains('tehsil') &&
          !candidate.toLowerCase().contains('taluka')) {
        return candidate;
      }
    }
    return filtered.last.replaceAll(RegExp(r'\b\d{5,6}\b'), '').trim();
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

        final detectedCity = p.locality?.isNotEmpty == true
            ? p.locality
            : (p.subAdministrativeArea?.isNotEmpty == true
                ? p.subAdministrativeArea
                : (p.administrativeArea?.isNotEmpty == true
                    ? p.administrativeArea
                    : null));

        if (parts.isNotEmpty) {
          final fullAddress = parts.join(', ');
          setState(() {
            _currentAddress = fullAddress;
            _currentCity = detectedCity ?? _extractCityFallback(fullAddress);
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
        final data = response.data as Map;
        final displayName = data['display_name']?.toString();
        String? detectedCity;
        if (data['address'] is Map) {
          final addr = data['address'] as Map;
          detectedCity = addr['city']?.toString() ??
              addr['town']?.toString() ??
              addr['city_district']?.toString() ??
              addr['municipality']?.toString() ??
              addr['village']?.toString() ??
              addr['county']?.toString() ??
              addr['state_district']?.toString();
        }
        if (displayName != null && displayName.isNotEmpty) {
          setState(() {
            _currentAddress = displayName;
            _currentCity = detectedCity ?? _extractCityFallback(displayName);
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _currentAddress =
            'Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)}';
        _currentCity = null;
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
          'addressdetails': 1,
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
        String? searchCity;
        if (first['address'] is Map) {
          final addr = first['address'] as Map;
          searchCity = addr['city']?.toString() ??
              addr['town']?.toString() ??
              addr['city_district']?.toString() ??
              addr['municipality']?.toString() ??
              addr['village']?.toString() ??
              addr['county']?.toString() ??
              addr['state_district']?.toString();
        }

        if (lat != null && lon != null && mounted) {
          final target = ll.LatLng(lat, lon);
          _updateSelectedLocation(
            target,
            animateMap: true,
            address: displayName,
            city: searchCity,
          );
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
    String? city,
  }) {
    setState(() {
      _currentSelectedLocation = newLocation;
      _isSearching = false;
      if (address != null && address.isNotEmpty) {
        _currentAddress = address;
      }
      if (city != null && city.isNotEmpty) {
        _currentCity = city;
      } else {
        _currentCity = null;
      }
    });

    if (animateMap) {
      _mapController.move(newLocation, 15.0);
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _reverseGeocode(newLocation);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final sheetHeight = mediaQuery.size.height * 0.90;
    final bottomInset = mediaQuery.viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: sheetHeight,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // 1. Interactive Map Viewport (Expanded)
                Expanded(
                  child: Stack(
                    children: [
                      // Interactive Flutter Map
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
                                _debounceTimer =
                                    Timer(const Duration(milliseconds: 300), () {
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
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.idealake.clientattendance',
                            ),
                          ],
                        ),
                      ),

                      // 2. Fixed Center Pin with Elevation & Alignment to Map Center
                      Center(
                        child: IgnorePointer(
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // Ground anchor pulse & target dot (at exact center 0,0)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryNavy,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.primaryNavy.withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              // Pin Marker floating with bottom tip pointing directly to the anchor dot (0,0)
                              Transform.translate(
                                offset: Offset(0, _isDraggingMap ? -28 : -21),
                                child: AnimatedScale(
                                  scale: _isDraggingMap ? 1.15 : 1.0,
                                  duration: const Duration(milliseconds: 150),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryNavy,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.location_on,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      // Pin needle tip pointing straight down
                                      CustomPaint(
                                        size: const Size(10, 7),
                                        painter: _PinNeedlePainter(
                                          color: AppColors.primaryNavy,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 3. Floating Action Buttons (Current Location & Zoom)
                      Positioned(
                        bottom: 16,
                        right: 16,
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

                      // 4. Top Header with Drag Handle & Location Search Bar
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
                                        focusNode: _searchFocusNode,
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
                                          setState(() {});
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
                                          color: AppColors.primaryNavy
                                              .withValues(alpha: 0.25),
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
                                      border:
                                          Border.all(color: const Color(0xFFE2E8F0)),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
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
                    ],
                  ),
                ),

                // 2. Bottom Details Card
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: const Border(
                      top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location Address Info
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2F6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppColors.primaryNavy,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Selected Location Address',
                                      style: TextStyle(
                                        fontSize: 11,
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
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    if (_currentCity != null &&
                                        _currentCity!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryNavy
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.location_city_rounded,
                                              size: 13,
                                              color: AppColors.primaryNavy,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                'City: $_currentCity',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.primaryNavy,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Coordinates Chips Row (Lat & Long)
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'LAT: ',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          _currentSelectedLocation.latitude
                                              .toStringAsFixed(5),
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryNavy,
                                            fontFamily: 'monospace',
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'LNG: ',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          _currentSelectedLocation.longitude
                                              .toStringAsFixed(5),
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryNavy,
                                            fontFamily: 'monospace',
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (widget.enableCreateLocation) ...[
                            const SizedBox(height: 10),

                            // Client Name Input Field
                            const Text(
                              'Client Name',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: TextFormField(
                                controller: _clientNameController,
                                focusNode: _clientNameFocusNode,
                                enabled: !_isCreatingLocation,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Global Enterprise Corp',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.business_rounded,
                                    color: AppColors.primaryNavy,
                                    size: 18,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Allowed Radius Input Field
                            const Text(
                              'Allowed Radius (meters)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: TextFormField(
                                controller: _radiusController,
                                focusNode: _radiusFocusNode,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                enabled: !_isCreatingLocation,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 100.0',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.radar_rounded,
                                    color: AppColors.primaryNavy,
                                    size: 18,
                                  ),
                                  suffixText: 'meters',
                                  suffixStyle: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),

                          // Confirm Selection Button
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: _isCreatingLocation
                                  ? null
                                  : _handleConfirmLocation,
                              icon: _isCreatingLocation
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                              label: Text(
                                _isCreatingLocation
                                    ? 'Saving Location...'
                                    : 'Confirm Location & Coordinates',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryNavy,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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
          ),
        ),
      ),
    );
  }

  Future<void> _handleConfirmLocation() async {
    if (!widget.enableCreateLocation) {
      Navigator.of(context).pop(
        LocationPickerResult(
          latitude: _currentSelectedLocation.latitude,
          longitude: _currentSelectedLocation.longitude,
          address: _currentAddress,
          city: _currentCity,
          clientName: widget.initialClientName,
          allowedRadius: widget.initialRadius,
        ),
      );
      return;
    }

    await _confirmAndCreateLocation();
  }

  Future<void> _confirmAndCreateLocation() async {
    FocusScope.of(context).unfocus();

    final clientName = _clientNameController.text.trim();
    if (clientName.isEmpty) {
      SnackbarHelper.showError(context, 'Please enter client name');
      return;
    }

    final radiusText = _radiusController.text.trim();
    final radius = double.tryParse(radiusText);
    if (radius == null || radius <= 0) {
      SnackbarHelper.showError(context, 'Please enter a valid radius (e.g. 100)');
      return;
    }

    setState(() {
      _isCreatingLocation = true;
    });

    try {
      final createLocationUseCase = sl<CreateLocationUseCase>();
      final result = await createLocationUseCase(
        CreateLocationParams(
          clientName: clientName,
          locationName: clientName,
          address: _currentAddress,
          city: _currentCity,
          latitude: _currentSelectedLocation.latitude,
          longitude: _currentSelectedLocation.longitude,
          allowedRadius: radius,
        ),
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _isCreatingLocation = false;
          });
          SnackbarHelper.showError(context, failure.message);
        },
        (createdLocation) {
          setState(() {
            _isCreatingLocation = false;
          });
          SnackbarHelper.showSuccess(context, 'Location created successfully');
          Navigator.of(context).pop(
            LocationPickerResult(
              latitude: createdLocation.latitude ?? _currentSelectedLocation.latitude,
              longitude: createdLocation.longitude ?? _currentSelectedLocation.longitude,
              address: createdLocation.address ?? _currentAddress,
              city: _currentCity,
              clientName: createdLocation.clientName ?? clientName,
              allowedRadius: createdLocation.allowedRadius ?? radius,
              createdLocation: createdLocation,
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreatingLocation = false;
        });
        SnackbarHelper.showError(context, 'Failed to create location: $e');
      }
    }
  }
}

class _PinNeedlePainter extends CustomPainter {
  final Color color;
  const _PinNeedlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinNeedlePainter oldDelegate) =>
      oldDelegate.color != color;
}
