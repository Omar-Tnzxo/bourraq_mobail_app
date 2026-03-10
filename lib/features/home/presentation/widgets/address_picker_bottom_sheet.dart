import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/widgets/bourraq_widgets.dart';
import 'package:bourraq/features/location/data/address_model.dart';
import 'package:bourraq/features/location/data/address_service.dart';

/// A premium address picker bottom sheet that matches the Bourraq design system.
/// Uses [BourraqBottomSheet] as a container.
class AddressPickerBottomSheet extends StatefulWidget {
  final Address? currentAddress;
  final Function(Address) onAddressSelected;

  const AddressPickerBottomSheet({
    super.key,
    this.currentAddress,
    required this.onAddressSelected,
  });

  /// Show the address picker sheet.
  static Future<dynamic> show({
    required BuildContext context,
    Address? currentAddress,
    required Function(Address) onAddressSelected,
  }) {
    return BourraqBottomSheet.show(
      context: context,
      title: 'home.delivering_to'.tr(),
      actions: [
        // Settings/Manage Button
        GestureDetector(
          onTap: () => Navigator.pop(context, 'manage_addresses'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: const Icon(
              LucideIcons.settings2,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        // Add Address Button
        Expanded(
          child: BourraqButton(
            label: 'addresses.add_address'.tr(),
            icon: LucideIcons.plus,
            onPressed: () => Navigator.pop(context, 'add_address'),
            backgroundColor: AppColors.accentYellow,
            foregroundColor: AppColors.deepOlive,
          ),
        ),
      ],
      child: AddressPickerBottomSheet(
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.accentYellow),
        ),
      );
    }

    if (_addresses.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _addresses.map((address) {
        final isSelected = widget.currentAddress?.id == address.id;
        return _AddressListTile(
          address: address,
          isSelected: isSelected,
          onTap: () {
            widget.onAddressSelected(address);
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            LucideIcons.mapPin,
            size: 64,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'addresses.no_addresses'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// A specific tile for the address selection sheet.
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.lightGreen.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Selection Checkmark (Left)
            if (isSelected)
              Icon(LucideIcons.check, color: AppColors.accentYellow, size: 28)
            else
              const SizedBox(width: 28),

            const SizedBox(width: 16),

            // Text Info (Middle)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (address.isDefault) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentYellow.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.accentYellow.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            'addresses.default'.tr(),
                            style: const TextStyle(
                              color: AppColors.accentYellow,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        address.addressLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.fullAddress,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Type Icon (Right)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.accentYellow,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                _getAddressIcon(),
                color: AppColors.deepOlive,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
