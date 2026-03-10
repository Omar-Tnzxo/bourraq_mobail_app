import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/core/widgets/bourraq_widgets.dart';
import 'package:bourraq/features/location/data/address_model.dart';
import 'package:bourraq/features/location/data/address_service.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final AddressService _addressService = AddressService();
  List<Address> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    final addresses = await _addressService.getAddresses();
    setState(() {
      _addresses = addresses;
      _isLoading = false;
    });
  }

  Future<void> _setAsDefault(String addressId) async {
    await _addressService.setDefaultAddress(addressId);
    await _loadAddresses();
  }

  Future<void> _deleteAddress(String addressId) async {
    final confirmed = await _showDeleteConfirmation();
    if (confirmed) {
      await _addressService.deleteAddress(addressId);
      await _loadAddresses();
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await BourraqDialog.show(
          context,
          title: 'addresses.delete_address'.tr(),
          message: 'addresses.delete_address_confirm'.tr(),
          confirmLabel: 'common.delete'.tr(),
          cancelLabel: 'common.cancel'.tr(),
          icon: LucideIcons.trash2,
          isDangerous: true,
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final canAddMore = _addresses.length < AddressService.maxAddresses;

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
                    'addresses.my_addresses'.tr(),
                    style: const TextStyle(
                      color: AppColors.accentYellow,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                // Add Button (if can add more)
                if (canAddMore)
                  GestureDetector(
                    onTap: () async {
                      await context.push('/add-address');
                      _loadAddresses();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.plus,
                        color: AppColors.accentYellow,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _addresses.isEmpty
                ? _buildEmptyState()
                : _buildAddressList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.mapPinOff,
                size: 48,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'addresses.no_addresses'.tr(),
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'addresses.add_first_address'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await context.push('/add-address');
                  _loadAddresses();
                },
                icon: const Icon(LucideIcons.mapPin),
                label: Text('addresses.add_address'.tr()),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList() {
    return RefreshIndicator(
      onRefresh: _loadAddresses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _addresses.length + 1,
        itemBuilder: (context, index) {
          if (index == _addresses.length) {
            return _buildAddButton();
          }
          return _buildAddressCard(_addresses[index]);
        },
      ),
    );
  }

  Widget _buildAddressCard(Address address) {
    final locale = context.locale.languageCode;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: address.isDefault
            ? Border.all(color: AppColors.deepOlive, width: 2)
            : Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _setAsDefault(address.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: address.isDefault
                      ? AppColors.deepOlive
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getAddressIcon(address.addressLabel),
                  color: address.isDefault
                      ? AppColors.accentYellow
                      : AppColors.textSecondary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label + Default badge
                    Row(
                      children: [
                        Text(
                          address.addressLabel,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.deepOlive,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'addresses.default'.tr(),
                              style: const TextStyle(
                                color: AppColors.accentYellow,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    Text(
                      address.getFullAddress(locale),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Building details
                    if (address.getBuildingDetails(locale) != null &&
                        address.getBuildingDetails(locale)!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        address.getBuildingDetails(locale)!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Actions menu
              PopupMenuButton<String>(
                icon: Icon(
                  LucideIcons.ellipsisVertical,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                offset: const Offset(0, 40),
                onSelected: (value) {
                  switch (value) {
                    case 'default':
                      _setAsDefault(address.id);
                      break;
                    case 'delete':
                      _deleteAddress(address.id);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (!address.isDefault)
                    PopupMenuItem(
                      value: 'default',
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.star,
                            size: 18,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'addresses.set_as_default'.tr(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.trash2,
                          size: 18,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'common.delete'.tr(),
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    final canAddMore = _addresses.length < AddressService.maxAddresses;
    if (!canAddMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'addresses.max_addresses_reached'.tr(),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () async {
          await context.push('/add-address');
          _loadAddresses();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.5),
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.circlePlus,
                color: AppColors.primaryGreen,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'addresses.add_address'.tr(),
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAddressIcon(String label) {
    final lowerLabel = label.toLowerCase();
    if (lowerLabel.contains('home') ||
        lowerLabel.contains('منزل') ||
        lowerLabel.contains('المنزل') ||
        lowerLabel.contains('بيت')) {
      return LucideIcons.house;
    } else if (lowerLabel.contains('work') ||
        lowerLabel.contains('عمل') ||
        lowerLabel.contains('العمل') ||
        lowerLabel.contains('شغل')) {
      return LucideIcons.briefcase;
    } else if (lowerLabel.contains('gym') || lowerLabel.contains('جيم')) {
      return LucideIcons.dumbbell;
    }
    return LucideIcons.mapPin;
  }
}
