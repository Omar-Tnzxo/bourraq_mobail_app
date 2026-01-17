import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourraq/features/orders/data/order_rating_service.dart';

// ===== STATES =====

abstract class OrderRatingState extends Equatable {
  const OrderRatingState();

  @override
  List<Object?> get props => [];
}

class OrderRatingInitial extends OrderRatingState {}

class OrderRatingLoading extends OrderRatingState {}

class OrderRatingNotRated extends OrderRatingState {}

class OrderRatingAlreadyRated extends OrderRatingState {
  final int rating;
  final String? comment;

  const OrderRatingAlreadyRated({required this.rating, this.comment});

  @override
  List<Object?> get props => [rating, comment];
}

class OrderRatingSubmitting extends OrderRatingState {}

class OrderRatingSubmitted extends OrderRatingState {}

class OrderRatingError extends OrderRatingState {
  final String message;

  const OrderRatingError(this.message);

  @override
  List<Object?> get props => [message];
}

// ===== CUBIT =====

class OrderRatingCubit extends Cubit<OrderRatingState> {
  final OrderRatingService _ratingService = OrderRatingService();
  final String orderId;

  int _selectedRating = 0;
  String _comment = '';

  OrderRatingCubit({required this.orderId}) : super(OrderRatingInitial());

  int get selectedRating => _selectedRating;
  String get comment => _comment;

  /// Check if the order has been rated
  Future<void> checkRatingStatus() async {
    emit(OrderRatingLoading());

    final existingRating = await _ratingService.getOrderRating(orderId);

    if (existingRating != null) {
      emit(
        OrderRatingAlreadyRated(
          rating: existingRating['rating'] as int,
          comment: existingRating['comment'] as String?,
        ),
      );
    } else {
      emit(OrderRatingNotRated());
    }
  }

  /// Update selected rating
  void setRating(int rating) {
    _selectedRating = rating;
  }

  /// Update comment
  void setComment(String comment) {
    _comment = comment;
  }

  /// Submit the rating
  Future<void> submitRating() async {
    if (_selectedRating == 0) {
      emit(const OrderRatingError('يرجى اختيار تقييم'));
      return;
    }

    emit(OrderRatingSubmitting());

    // Get user ID from users table
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      emit(const OrderRatingError('يرجى تسجيل الدخول'));
      return;
    }

    // Get the user's public.users ID
    final userResponse = await Supabase.instance.client
        .from('users')
        .select('id')
        .eq('auth_user_id', authUser.id)
        .maybeSingle();

    if (userResponse == null) {
      emit(const OrderRatingError('لم يتم العثور على الحساب'));
      return;
    }

    final userId = userResponse['id'] as String;

    final success = await _ratingService.submitRating(
      orderId: orderId,
      userId: userId,
      rating: _selectedRating,
      comment: _comment.isEmpty ? null : _comment,
    );

    if (success) {
      emit(OrderRatingSubmitted());
    } else {
      emit(const OrderRatingError('فشل في إرسال التقييم، حاول مرة أخرى'));
    }
  }
}
