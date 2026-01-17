import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/features/location/data/address_model.dart';
import 'package:bourraq/features/location/data/address_service.dart';

/// Bottom Sheet لاختيار العنوان
class AddressPickerBottomSheet extends StatefulWidget {
  final Address? currentAddress;
  final Function(Address) onAddressSelected;

  const AddressPickerBottomSheet({
    super.key,
    this.currentAddress,
    required this.onAddressSelected,
  });

  /// عرض الـ Bottom Sheet
  static Future<void> show({
    required BuildContext context,
    Address? currentAddress,
    required Function(Address) onAddressSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressPickerBottomSheet(
        currentAddress: currentAddress,
        onAddressSelected: onAddressSelected,
      ),
    );
  }

  @override
  State<AddressPickerBottomSheet> createState() =>
      _AddressPickerBottomSheetState();
}

class _AddressPickerBottomSheetState extends State<AddressPickerBottomSheet> {
  final AddressService _addressService = AddressService();
  List<Address> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final addresses = await _addressService.getAddresses();
      if (mounted) {
        setState(() {
          _addresses = addresses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'home.delivering_to'.tr(),
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.background,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: AppColors.deepOlive,
                      ),
                    ),
                  )
                : _addresses.isEmpty
                ? _buildEmptyState()
                : _buildAddressList(),
          ),
          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.mapPin,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'addresses.no_addresses'.tr(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'addresses.add_first_address'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList() {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _addresses.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 20),
      itemBuilder: (context, index) {
        final address = _addresses[index];
        final isSelected = widget.currentAddress?.id == address.id;

        return _AddressListTile(
          address: address,
          isSelected: isSelected,
          onTap: () {
            widget.onAddressSelected(address);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            // Add Address Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/add-address');
                },
                icon: const Icon(LucideIcons.plus, size: 18),
                label: Text('addresses.add_address'.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.deepOlive,
                  side: const BorderSide(color: AppColors.deepOlive),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Manage Addresses Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/addresses');
                },
                icon: const Icon(LucideIcons.settings2, size: 18),
                label: Text('home.manage_addresses'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepOlive,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
}

/// عنصر عنوان في القائمة
class _AddressListTile extends StatelessWidget {
  final Address address;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddressListTile({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  IconData _getAddressIcon() {
    switch (address.addressType.toLowerCase()) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return LucideIcons.building2;
      default:
        return LucideIcons.mapPin;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.deepOlive.withOpacity(0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _getAddressIcon(),
          color: isSelected ? AppColors.deepOlive : AppColors.textSecondary,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Text(
            address.addressLabel,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.deepOlive : AppColors.textPrimary,
            ),
          ),
          if (address.isDefault) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.deepOlive.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'addresses.default'.tr(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.deepOlive,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        address.fullAddress,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isSelected
          ? Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.deepOlive,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.check,
                color: AppColors.white,
                size: 14,
              ),
            )
          : null,
    );
  }
}
