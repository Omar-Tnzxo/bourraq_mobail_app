import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/features/location/data/area_model.dart';
import 'package:bourraq/features/location/data/area_service.dart';

/// Enhanced Map Widget with controls, search, and area visualization
class EnhancedMapWidget extends StatefulWidget {
  final LatLng initialLocation;
  final Function(LatLng location, String? addressText) onLocationChanged;
  final Function(Area? area)? onAreaDetected;
  final double height;

  const EnhancedMapWidget({
    super.key,
    required this.initialLocation,
    required this.onLocationChanged,
    this.onAreaDetected,
    this.height = 220,
  });

  @override
  State<EnhancedMapWidget> createState() => _EnhancedMapWidgetState();
}

class _EnhancedMapWidgetState extends State<EnhancedMapWidget>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final AreaService _areaService = AreaService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late LatLng _selectedLocation;
  String _addressText = '';
  double _currentZoom = 15.0;
  bool _isSearching = false;
  bool _isGettingLocation = false;
  List<Area> _supportedAreas = [];
  List<Location> _searchResults = [];
  Timer? _searchDebounce;

  // Animation
  late AnimationController _markerAnimController;
  late Animation<double> _markerBounce;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _loadSupportedAreas();
    _getAddressFromLocation(_selectedLocation);

    // Marker bounce animation
    _markerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _markerBounce = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _markerAnimController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _markerAnimController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSupportedAreas() async {
    final areas = await _areaService.getSupportedAreas();
    if (mounted) {
      setState(() => _supportedAreas = areas);
    }
  }

  Future<void> _getAddressFromLocation(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.street?.isNotEmpty ?? false) parts.add(place.street!);
        if (place.subLocality?.isNotEmpty ?? false)
          parts.add(place.subLocality!);
        if (place.locality?.isNotEmpty ?? false) parts.add(place.locality!);

        final separator = context.locale.languageCode == 'ar' ? '، ' : ', ';
        setState(() => _addressText = parts.join(separator));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _addressText = 'map.location_selected'.tr());
      }
    }

    // Notify parent
    widget.onLocationChanged(_selectedLocation, _addressText);

    // Detect area
    _detectArea();
  }

  Future<void> _detectArea() async {
    final area = await _areaService.detectAreaFromCoordinates(
      _selectedLocation.latitude,
      _selectedLocation.longitude,
    );
    widget.onAreaDetected?.call(area);
  }

  void _onMapTap(TapPosition tapPosition, LatLng location) {
    // Animate marker
    _markerAnimController.forward().then((_) {
      _markerAnimController.reverse();
    });

    setState(() => _selectedLocation = location);
    _getAddressFromLocation(location);
  }

  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) return;
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('map.location_disabled'.tr());
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('map.location_denied'.tr());
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('map.location_denied_forever'.tr());
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      final newLocation = LatLng(position.latitude, position.longitude);
      setState(() => _selectedLocation = newLocation);
      _mapController.move(newLocation, 16);
      _getAddressFromLocation(newLocation);
    } catch (e) {
      _showError('map.location_error'.tr());
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _zoomIn() {
    _currentZoom = (_currentZoom + 1).clamp(3.0, 18.0);
    _mapController.move(_mapController.camera.center, _currentZoom);
  }

  void _zoomOut() {
    _currentZoom = (_currentZoom - 1).clamp(3.0, 18.0);
    _mapController.move(_mapController.camera.center, _currentZoom);
  }

  void _centerOnPin() {
    _mapController.move(_selectedLocation, _currentZoom);
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullscreenMapPage(
          location: _selectedLocation,
          areas: _supportedAreas,
          onLocationSelected: (location) {
            setState(() => _selectedLocation = location);
            _mapController.move(location, _currentZoom);
            _getAddressFromLocation(location);
          },
        ),
      ),
    );
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    // Need at least 3 characters
    if (query.length < 3) return;

    _searchDebounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      setState(() => _isSearching = true);

      try {
        // Try multiple search variations
        List<Location> results = [];

        // Try with Egypt context first
        try {
          results = await locationFromAddress('$query, مصر');
        } catch (_) {}

        // If no results, try without context
        if (results.isEmpty) {
          try {
            results = await locationFromAddress('$query, Egypt');
          } catch (_) {}
        }

        // If still no results, try query alone
        if (results.isEmpty) {
          try {
            results = await locationFromAddress(query);
          } catch (_) {}
        }

        if (mounted) {
          setState(() {
            _searchResults = results.take(5).toList();
            _isSearching = false;
          });

          // Show message if no results
          if (results.isEmpty && query.length >= 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('map.no_results'.tr()),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSearching = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('map.search_error'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  void _selectSearchResult(Location location) {
    final newLocation = LatLng(location.latitude, location.longitude);
    setState(() {
      _selectedLocation = newLocation;
      _searchResults = [];
      _searchController.clear();
    });
    _searchFocusNode.unfocus();
    _mapController.move(newLocation, 16);
    _getAddressFromLocation(newLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Box
        _buildSearchBox(),

        const SizedBox(height: 8),

        // Map Container
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedLocation,
                  initialZoom: _currentZoom,
                  onTap: _onMapTap,
                  onPositionChanged: (pos, _) {
                    if (pos.zoom != null) _currentZoom = pos.zoom!;
                  },
                ),
                children: [
                  // Tile Layer
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.bourraq',
                  ),

                  // Supported Areas Circles
                  if (_supportedAreas.isNotEmpty)
                    CircleLayer(
                      circles: _supportedAreas
                          .map(
                            (area) => CircleMarker(
                              point: LatLng(area.latitude, area.longitude),
                              radius: area.radiusKm * 1000, // meters
                              color: AppColors.primaryGreen.withOpacity(0.05),
                              borderColor: AppColors.primaryGreen.withOpacity(
                                0.2,
                              ),
                              borderStrokeWidth: 1.5,
                              useRadiusInMeter: true,
                            ),
                          )
                          .toList(),
                    ),

                  // Marker
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation,
                        width: 60,
                        height: 70,
                        child: AnimatedBuilder(
                          animation: _markerAnimController,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(0, _markerBounce.value),
                            child: child,
                          ),
                          child: _buildAnimatedMarker(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Controls
              _buildMapControls(),

              // Address Preview
              _buildAddressPreview(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'map.search_hint'.tr(),
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              prefixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(
                      LucideIcons.search,
                      color: AppColors.textSecondary,
                    ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = []);
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),

        // Search Results
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: _searchResults.map((result) {
                return ListTile(
                  dense: true,
                  leading: const Icon(LucideIcons.mapPin, size: 18),
                  title: Text(
                    '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}',
                    style: AppTextStyles.bodySmall,
                  ),
                  onTap: () => _selectSearchResult(result),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildAnimatedMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pin Icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(LucideIcons.mapPin, color: Colors.white, size: 24),
        ),
        // Pointer
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Shadow
        Container(
          width: 20,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: 8,
      top: 8,
      child: Column(
        children: [
          // Fullscreen
          _buildControlButton(
            icon: LucideIcons.maximize2,
            onTap: _openFullscreen,
            tooltip: 'map.fullscreen'.tr(),
          ),
          const SizedBox(height: 6),
          // Center on Pin
          _buildControlButton(
            icon: LucideIcons.crosshair,
            onTap: _centerOnPin,
            tooltip: 'map.center_on_pin'.tr(),
          ),
          const SizedBox(height: 6),
          // My Location
          _buildControlButton(
            icon: _isGettingLocation ? null : LucideIcons.locate,
            isLoading: _isGettingLocation,
            onTap: _getCurrentLocation,
            tooltip: 'map.my_location'.tr(),
          ),
          const SizedBox(height: 6),
          // Zoom In
          _buildControlButton(
            icon: LucideIcons.plus,
            onTap: _zoomIn,
            tooltip: 'map.zoom_in'.tr(),
          ),
          const SizedBox(height: 6),
          // Zoom Out
          _buildControlButton(
            icon: LucideIcons.minus,
            onTap: _zoomOut,
            tooltip: 'map.zoom_out'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    IconData? icon,
    required VoidCallback onTap,
    String? tooltip,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, size: 18, color: AppColors.deepOlive),
        ),
      ),
    );
  }

  Widget _buildAddressPreview() {
    if (_addressText.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: 8,
      left: 8,
      right: 56,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
          ],
        ),
        child: Row(
          children: [
            Icon(LucideIcons.mapPin, size: 16, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _addressText,
                style: AppTextStyles.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Fullscreen Map Page
// ============================================

class _FullscreenMapPage extends StatefulWidget {
  final LatLng location;
  final List<Area> areas;
  final Function(LatLng) onLocationSelected;

  const _FullscreenMapPage({
    required this.location,
    required this.areas,
    required this.onLocationSelected,
  });

  @override
  State<_FullscreenMapPage> createState() => _FullscreenMapPageState();
}

class _FullscreenMapPageState extends State<_FullscreenMapPage>
    with SingleTickerProviderStateMixin {
  late LatLng _selectedLocation;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  double _currentZoom = 16.0;
  bool _isSearching = false;
  bool _isGettingLocation = false;
  List<Location> _searchResults = [];
  Timer? _searchDebounce;

  // Animation
  late AnimationController _markerAnimController;
  late Animation<double> _markerBounce;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.location;

    _markerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _markerBounce = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _markerAnimController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _markerAnimController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng location) {
    _markerAnimController.forward().then(
      (_) => _markerAnimController.reverse(),
    );
    setState(() => _selectedLocation = location);
  }

  void _confirmLocation() {
    widget.onLocationSelected(_selectedLocation);
    Navigator.pop(context);
  }

  void _zoomIn() {
    _currentZoom = (_currentZoom + 1).clamp(3.0, 18.0);
    _mapController.move(_mapController.camera.center, _currentZoom);
  }

  void _zoomOut() {
    _currentZoom = (_currentZoom - 1).clamp(3.0, 18.0);
    _mapController.move(_mapController.camera.center, _currentZoom);
  }

  void _centerOnPin() {
    _mapController.move(_selectedLocation, _currentZoom);
  }

  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) return;
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      final newLocation = LatLng(position.latitude, position.longitude);
      setState(() => _selectedLocation = newLocation);
      _mapController.move(newLocation, 16);
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() => _isSearching = true);

      try {
        final results = await locationFromAddress('$query, Egypt');
        if (mounted) {
          setState(() {
            _searchResults = results.take(5).toList();
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _selectSearchResult(Location location) {
    final newLocation = LatLng(location.latitude, location.longitude);
    setState(() {
      _selectedLocation = newLocation;
      _searchResults = [];
      _searchController.clear();
    });
    FocusScope.of(context).unfocus();
    _mapController.move(newLocation, 16);
  }

  Widget _buildAnimatedMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(LucideIcons.mapPin, color: Colors.white, size: 28),
        ),
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Container(
          width: 24,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData? icon,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, size: 22, color: AppColors.deepOlive),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // Fullscreen Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: _currentZoom,
              onTap: _onMapTap,
              onPositionChanged: (pos, _) {
                if (pos.zoom != null) _currentZoom = pos.zoom!;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bourraq',
              ),
              // Supported Areas Circles
              if (widget.areas.isNotEmpty)
                CircleLayer(
                  circles: widget.areas
                      .map(
                        (area) => CircleMarker(
                          point: LatLng(area.latitude, area.longitude),
                          radius: area.radiusKm * 1000,
                          color: AppColors.primaryGreen.withOpacity(0.05),
                          borderColor: AppColors.primaryGreen.withOpacity(0.2),
                          borderStrokeWidth: 1.5,
                          useRadiusInMeter: true,
                        ),
                      )
                      .toList(),
                ),
              // Animated Marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 70,
                    height: 85,
                    child: AnimatedBuilder(
                      animation: _markerAnimController,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _markerBounce.value),
                        child: child,
                      ),
                      child: _buildAnimatedMarker(),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Search Box
          Positioned(
            top: topPadding + 8,
            left: 60,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'map.search_hint'.tr(),
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      prefixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const Icon(
                              LucideIcons.search,
                              color: AppColors.textSecondary,
                            ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                // Search Results
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: _searchResults.map((result) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(LucideIcons.mapPin, size: 18),
                          title: Text(
                            '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}',
                            style: AppTextStyles.bodySmall,
                          ),
                          onTap: () => _selectSearchResult(result),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          // Close button
          Positioned(
            top: topPadding + 8,
            left: isArabic ? null : 12,
            right: isArabic ? 12 : null,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 4,
              child: IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Controls (right side)
          Positioned(
            right: 12,
            top: topPadding + 70,
            child: Column(
              children: [
                _buildControlButton(
                  icon: LucideIcons.crosshair,
                  onTap: _centerOnPin,
                ),
                const SizedBox(height: 8),
                _buildControlButton(
                  icon: _isGettingLocation ? null : LucideIcons.locate,
                  isLoading: _isGettingLocation,
                  onTap: _getCurrentLocation,
                ),
                const SizedBox(height: 8),
                _buildControlButton(icon: LucideIcons.plus, onTap: _zoomIn),
                const SizedBox(height: 8),
                _buildControlButton(icon: LucideIcons.minus, onTap: _zoomOut),
              ],
            ),
          ),

          // Confirm button
          Positioned(
            bottom: bottomPadding + 16,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: _confirmLocation,
              icon: const Icon(LucideIcons.check),
              label: Text('common.confirm'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
