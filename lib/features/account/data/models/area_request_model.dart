import 'package:equatable/equatable.dart';

class AreaRequest extends Equatable {
  final String id;
  final String? userId;
  final String governorate;
  final String city;
  final String areaName;
  final String? additionalInfo;
  final String status; // 'pending', 'reviewed', 'approved', 'rejected'
  final DateTime createdAt;

  const AreaRequest({
    required this.id,
    this.userId,
    required this.governorate,
    required this.city,
    required this.areaName,
    this.additionalInfo,
    required this.status,
    required this.createdAt,
  });

  factory AreaRequest.fromJson(Map<String, dynamic> json) {
    return AreaRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      governorate: json['governorate'] as String,
      city: json['city'] as String,
      areaName: json['area_name'] as String,
      additionalInfo: json['additional_info'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'governorate': governorate,
      'city': city,
      'area_name': areaName,
      'additional_info': additionalInfo,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    governorate,
    city,
    areaName,
    additionalInfo,
    status,
    createdAt,
  ];
}
