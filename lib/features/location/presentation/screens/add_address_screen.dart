import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
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
          if (_streetNameController.text.isEmpty && place.street != null) {
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
    // Validation
    if (_buildingNameController.text.isEmpty) {
      _showError('addresses.enter_building_name'.tr());
      return;
    }

    if (_phoneController.text.isEmpty) {
      _showError('addresses.enter_phone'.tr());
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
      final success = await _addressService.addAddress(
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

      if (success) {
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
        _showError('addresses.max_addresses_reached'.tr());
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

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isArabic ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'addresses.add_address'.tr(),
          style: AppTextStyles.titleLarge,
        ),
        centerTitle: true,
      ),
      body: Column(
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
            initialLocation: _selectedLocation,
            height: 220,
            onLocationChanged: (location, addressText) {
              setState(() {
                _selectedLocation = location;
                if (addressText != null) _addressText = addressText;
                if (_streetNameController.text.isEmpty && addressText != null) {
                  _streetNameController.text = addressText;
                }
              });
            },
            onAreaDetected: (area) {
              setState(() {
                _detectedArea = area;
                _isCheckingArea = false;
              });
            },
          ),
          // عرض حالة المنطقة
          _buildAreaStatusWidget(context.locale.languageCode == 'ar'),
        ],
      ),
    );
  }

  /// عرض حالة المنطقة (مدعومة أو غير مدعومة)
  Widget _buildAreaStatusWidget(bool isArabic) {
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

    if (_detectedArea != null) {
      // منطقة مدعومة ✅
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.circleCheck,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _detectedArea!.getName(isArabic ? 'ar' : 'en'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'location.delivery_fee_info'.tr(
                        namedArgs: {
                          'fee': _detectedArea!.deliveryFee.toStringAsFixed(0),
                        },
                      ),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
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
            children: List.generate(_labelOptions.length, (index) {
              final option = _labelOptions[index];
              final isSelected = _selectedLabelIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedLabelIndex = index),
                  child: Container(
                    margin: EdgeInsets.only(left: index > 0 ? 10 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGreen.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          option['icon'],
                          size: 28,
                          color: isSelected
                              ? AppColors.primaryGreen
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          option['labelKey'].toString().tr(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primaryGreen
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
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
                  horizontal: 12,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.info,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'location.select_supported_area'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade700,
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
                  backgroundColor: canSave
                      ? AppColors.primaryGreen
                      : Colors.grey.shade400,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'common.save_address'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: canSave ? Colors.white : Colors.grey.shade600,
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
