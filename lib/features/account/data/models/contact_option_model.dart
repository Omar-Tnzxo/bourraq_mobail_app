import 'package:equatable/equatable.dart';

/// Represents a contact option (WhatsApp, Facebook, Email, etc.)
/// that can be displayed in the contact options sheet.
class ContactOption extends Equatable {
  final String id;
  final String type;
  final String titleAr;
  final String titleEn;
  final String value;
  final String? iconName;
  final int displayOrder;
  final bool isActive;

  const ContactOption({
    required this.id,
    required this.type,
    required this.titleAr,
    required this.titleEn,
    required this.value,
    this.iconName,
    required this.displayOrder,
    required this.isActive,
  });

  factory ContactOption.fromJson(Map<String, dynamic> json) {
    return ContactOption(
      id: json['id'] as String,
      type: json['type'] as String,
      titleAr: json['title_ar'] as String,
      titleEn: json['title_en'] as String,
      value: json['value'] as String,
      iconName: json['icon_name'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Returns the localized title based on language code
  String getTitle(String languageCode) {
    return languageCode == 'ar' ? titleAr : titleEn;
  }

  /// Generates the appropriate launch URL based on the contact type
  String getLaunchUrl() {
    switch (type) {
      case 'whatsapp':
        // Clean the phone number and format for WhatsApp
        final phone = value.replaceAll(RegExp(r'[^\d+]'), '');
        return 'https://wa.me/$phone';
      case 'email':
        return 'mailto:$value';
      case 'phone':
        final phone = value.replaceAll(RegExp(r'[^\d+]'), '');
        return 'tel:$phone';
      case 'facebook':
      case 'instagram':
      case 'twitter':
      case 'website':
      default:
        // For social media and websites, value is already a URL
        return value;
    }
  }

  @override
  List<Object?> get props => [
    id,
    type,
    titleAr,
    titleEn,
    value,
    iconName,
    displayOrder,
    isActive,
  ];
}
