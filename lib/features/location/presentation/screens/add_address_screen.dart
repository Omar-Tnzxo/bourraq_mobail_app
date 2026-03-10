import 'package:flutter/material.dart';
import 'package:bourraq/core/widgets/bourraq_widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/core/widgets/bourraq_header.dart';
import 'package:bourraq/features/location/data/address_service.dart';
import 'package:bourraq/features/location/data/area_service.dart';
import 'package:bourraq/features/location/data/area_model.dart';
import 'package:bourraq/features/location/presentation/widgets/enhanced_map_widget.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final AddressService _addressService = AddressService();
  final AreaService _areaService = AreaService();

  // Controllers
  final TextEditingController _buildingNameController = TextEditingController();
  final TextEditingController _streetNameController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _customLabelController = TextEditingController();

  // موقع افتراضي - 6 أكتوبر، مصر
  LatLng _selectedLocation = const LatLng(29.9602, 30.9271);
  String _addressText = '';
  bool _isLoading = false;
  bool _isCheckingArea = false;
  bool _isInitialLocationObtained =
      false; // لتتبع إذا تم الحصول على الموقع الفعلي
  Key _mapKey = UniqueKey(); // لإجبار الخريطة على إعادة البناء

  // المنطقة المكتشفة
  Area? _detectedArea;

  // تسمية العنوان (حقل واحد مدمج)
  int _selectedLabelIndex = 0;
  final List<Map<String, dynamic>> _labelOptions = [
    {'icon': LucideIcons.house, 'labelKey': 'addresses.home', 'type': 'home'},
    {
      'icon': LucideIcons.briefcase,
      'labelKey': 'addresses.work',
      'type': 'work',
    },
    {
      'icon': LucideIcons.mapPin,
      'labelKey': 'addresses.other',
      'type': 'other',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
    // Request GPS permission immediately when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermissionPersistently();
    });
  }

  /// Request location permission persistently until granted or permanently denied
  Future<void> _requestLocationPermissionPersistently() async {
    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are off, will be handled when user tries to save
        return;
      }

      // 2. Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      // 3. If denied, request permission (shows native dialog)
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // 4. If permanently denied, can't do anything from here
      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // 5. If granted, get current location and update map
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        await _getCurrentLocationAndUpdate();
      }
    } catch (e) {
      print('❌ [Location] Error in permission request: $e');
    }
  }

  /// Get current location and update the map
  Future<void> _getCurrentLocationAndUpdate() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      final newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = newLocation;
        _isInitialLocationObtained = true; // تم الحصول على الموقع الفعلي
        _mapKey =
            UniqueKey(); // إجبار الخريطة على إعادة البناء مع الموقع الجديد
      });

      // Get address and check area
      _getAddressFromLocation(newLocation);
      _checkAreaForLocation(newLocation);
    } catch (e) {
      // إذا فشل الحصول على الموقع، نعتبر أن الموقع الحالي هو المختار
      if (mounted) {
        setState(() {
          _isInitialLocationObtained = true;
        });
        _checkAreaForLocation(_selectedLocation);
      }
    }
  }

  @override
  void dispose() {
    _buildingNameController.dispose();
    _streetNameController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();
    _phoneController.dispose();
    _landmarkController.dispose();
    _customLabelController.dispose();
    super.dispose();
  }

  /// جلب رقم هاتف المستخدم من قاعدة البيانات
  Future<void> _loadUserPhone() async {
    try {
      final authId = Supabase.instance.client.auth.currentUser?.id;
      if (authId == null) return;

      final response = await Supabase.instance.client
          .from('users')
          .select('phone')
          .eq('auth_user_id', authId)
          .maybeSingle();

      if (response != null && response['phone'] != null) {
        setState(() {
          _phoneController.text = response['phone'] as String;
        });
      }
    } catch (e) {
      // مستخدم Google بدون رقم هاتف - الحقل سيبقى فارغ
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

        if (place.street != null && place.street!.isNotEmpty) {
          parts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          parts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }

        setState(() {
          // Use locale-appropriate separator
          final separator = context.locale.languageCode == 'ar' ? '، ' : ', ';
          _addressText = parts.join(separator);
          if (place.street != null && place.street!.isNotEmpty) {
            _streetNameController.text = place.street!;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _addressText = 'addresses.location_selected'.tr());
      }
    }
  }

  /// التحقق من المنطقة للموقع المحدد
  Future<void> _checkAreaForLocation(LatLng location) async {
    if (!mounted) return;
    setState(() => _isCheckingArea = true);

    try {
      final area = await _areaService.detectAreaFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (!mounted) return;
      setState(() {
        _detectedArea = area;
        _isCheckingArea = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingArea = false);
      }
    }
  }

  Future<void> _saveAddress() async {
    // التحقق من الحصول على الموقع أولاً
    if (!_isInitialLocationObtained) {
      _showLocationRequiredDialog();
      return;
    }

    // Validation
    if (_buildingNameController.text.isEmpty) {
      _showError('addresses.enter_building_name'.tr());
      return;
    }

    if (_phoneController.text.isEmpty) {
      _showError('addresses.enter_phone'.tr());
      return;
    }

    if (_detectedArea == null) {
      _showError('addresses.out_of_delivery_area'.tr());
      return;
    }

    // تحديد التسمية والنوع
    final selectedOption = _labelOptions[_selectedLabelIndex];
    String label;
    String addressType = selectedOption['type'];

    if (_selectedLabelIndex == 2 && _customLabelController.text.isNotEmpty) {
      label = _customLabelController.text;
    } else {
      label = selectedOption['labelKey'].toString().tr();
    }

    setState(() => _isLoading = true);

    try {
      final result = await _addressService.addAddress(
        addressLabel: label,
        addressType: addressType,
        streetName: _streetNameController.text.isNotEmpty
            ? _streetNameController.text
            : _addressText,
        buildingName: _buildingNameController.text,
        floorNumber: _floorController.text.isNotEmpty
            ? _floorController.text
            : null,
        apartmentNumber: _apartmentController.text.isNotEmpty
            ? _apartmentController.text
            : null,
        landmark: _landmarkController.text.isNotEmpty
            ? _landmarkController.text
            : null,
        phone: _phoneController.text,
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        areaId: _detectedArea?.id,
      );

      if (result == AddressService.resultSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('addresses.address_saved'.tr()),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
          context.pop();
        }
      } else {
        // عرض رسالة خطأ محددة حسب نوع المشكلة
        if (result == AddressService.resultMaxReached) {
          _showError('addresses.max_addresses_reached'.tr());
        } else {
          // لأي خطأ آخر، نعرض رسالة عامة ودية
          _showError('addresses.error_saving_address'.tr());
        }
      }
    } catch (e) {
      _showError('addresses.error_saving_address'.tr());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showLocationRequiredDialog() {
    BourraqDialog.show(
      context,
      title: 'addresses.location_required'.tr(),
      message: 'addresses.location_required_message'.tr(),
      confirmLabel: 'map.open_settings'.tr(),
      cancelLabel: 'common.cancel'.tr(),
      icon: LucideIcons.mapPin,
      onConfirm: () async {
        Navigator.pop(context);
        // فتح إعدادات الموقع في الهاتف مباشرة
        await Geolocator.openLocationSettings();
        // إعادة محاولة الحصول على الموقع بعد العودة
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          _requestLocationPermissionPersistently();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Premium Curved Header
          BourraqHeader(
            child: Row(
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Icon(
                      isArabic ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
                      color: AppColors.accentYellow,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Title
                Expanded(
                  child: Text(
                    'addresses.add_address'.tr(),
                    style: const TextStyle(
                      color: AppColors.accentYellow,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // === الخريطة ===
                        _buildMapSection(),

                        const SizedBox(height: 24),

                        // === تسمية العنوان (حقل واحد مدمج) ===
                        _buildAddressLabelSection(isArabic),

                        const SizedBox(height: 20),

                        // === حقول العنوان ===
                        _buildInputSection(),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // === زر الحفظ ===
                _buildSaveButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'addresses.delivery_location'.tr(),
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          EnhancedMapWidget(
            key: _mapKey,
            initialLocation: _selectedLocation,
            height: 220,
            onLocationChanged: (location, addressText) {
              setState(() {
                _selectedLocation = location;
                _isInitialLocationObtained = true; // المستخدم اختار موقع يدوياً
                if (addressText != null) _addressText = addressText;
                if (addressText != null && addressText.isNotEmpty) {
                  _streetNameController.text = addressText;
                }
              });
            },
            onAreaDetected: (area) {
              setState(() {
                _detectedArea = area;
                _isCheckingArea = false;
                _isInitialLocationObtained = true; // تم اكتشاف المنطقة
              });
            },
          ),
          // عرض حالة المنطقة
          _buildAreaStatusWidget(context.locale.languageCode == 'ar'),
        ],
      ),
    );
  }

  /// عرض حالة المنطقة (فقط إذا كانت غير مدعومة)
  Widget _buildAreaStatusWidget(bool isArabic) {
    // إذا لم يتم الحصول على الموقع الفعلي بعد، أظهر رسالة انتظار الموقع
    if (!_isInitialLocationObtained) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'addresses.getting_location'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading indicator while checking area
    if (_isCheckingArea) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                'location.checking_area'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If area is supported, show nothing (no area name or delivery fee)
    if (_detectedArea != null) {
      return const SizedBox.shrink();
    }

    // منطقة غير مدعومة ❌
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.circleAlert,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'location.area_not_supported'.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/area-request'),
                icon: Icon(LucideIcons.mapPinPlus, size: 18),
                label: Text('location.request_area_support'.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressLabelSection(bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'addresses.address_type'.tr(),
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Label options
          Row(
            children: [
              for (int i = 0; i < _labelOptions.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedLabelIndex = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _selectedLabelIndex == i
                            ? AppColors.deepOlive
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedLabelIndex == i
                              ? AppColors.deepOlive
                              : AppColors.borderLight,
                          width: 1.5,
                        ),
                        boxShadow: _selectedLabelIndex == i
                            ? [
                                BoxShadow(
                                  color: AppColors.deepOlive.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _labelOptions[i]['icon'],
                            size: 30,
                            color: _selectedLabelIndex == i
                                ? AppColors.accentYellow
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _labelOptions[i]['labelKey'].toString().tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedLabelIndex == i
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: _selectedLabelIndex == i
                                  ? AppColors.accentYellow
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // حقل التسمية المخصصة
          if (_selectedLabelIndex == 2) ...[
            const SizedBox(height: 12),
            _buildInputField(
              controller: _customLabelController,
              hint: 'addresses.custom_label_hint'.tr(),
              icon: LucideIcons.tag,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'addresses.address_details'.tr(),
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // اسم المبنى (إجباري)
          _buildInputField(
            controller: _buildingNameController,
            hint: 'addresses.building_name_required'.tr(),
            icon: LucideIcons.building2,
          ),

          // اسم الشارع
          _buildInputField(
            controller: _streetNameController,
            hint: 'addresses.street_name'.tr(),
            icon: LucideIcons.navigation,
          ),

          // رقم الدور والشقة
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _floorController,
                  hint: 'addresses.floor_number'.tr(),
                  isSmall: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  controller: _apartmentController,
                  hint: 'addresses.apartment_number'.tr(),
                  isSmall: true,
                ),
              ),
            ],
          ),

          // رقم الهاتف (إجباري)
          _buildInputField(
            controller: _phoneController,
            hint: 'addresses.phone_required'.tr(),
            icon: LucideIcons.phone,
            keyboardType: TextInputType.phone,
          ),

          // علامة مميزة (اختياري)
          _buildInputField(
            controller: _landmarkController,
            hint: 'addresses.landmark_optional'.tr(),
            icon: LucideIcons.mapPin,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    bool isSmall = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType:
            keyboardType ??
            (isSmall ? TextInputType.number : TextInputType.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIcon: icon != null
              ? Icon(icon, color: AppColors.textSecondary, size: 20)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    // تعطيل الزر إذا كان الموقع غير مدعوم أو جاري التحقق
    final bool canSave =
        !_isLoading && !_isCheckingArea && _detectedArea != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // رسالة تحذير إذا كان الموقع غير مدعوم
            if (_detectedArea == null && !_isCheckingArea) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.deepOlive.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.deepOlive.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.circleAlert,
                      size: 20,
                      color: AppColors.deepOlive,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'location.select_supported_area'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepOlive,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: canSave ? _saveAddress : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepOlive,
                  disabledBackgroundColor: AppColors.deepOlive.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accentYellow,
                        ),
                      )
                    : Text(
                        'common.save_address'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: canSave
                              ? AppColors.accentYellow
                              : AppColors.white.withOpacity(0.5),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
