import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/features/orders/presentation/cubit/order_rating_cubit.dart';

/// Screen for rating a delivered order
class OrderRatingScreen extends StatefulWidget {
  final String orderId;

  const OrderRatingScreen({super.key, required this.orderId});

  @override
  State<OrderRatingScreen> createState() => _OrderRatingScreenState();
}

class _OrderRatingScreenState extends State<OrderRatingScreen> {
  int _selectedRating = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return BlocProvider(
      create: (context) =>
          OrderRatingCubit(orderId: widget.orderId)..checkRatingStatus(),
      child: Scaffold(
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
            'orders.rate_order'.tr(),
            style: AppTextStyles.titleLarge,
          ),
          centerTitle: true,
        ),
        body: BlocConsumer<OrderRatingCubit, OrderRatingState>(
          listener: (context, state) {
            if (state is OrderRatingSubmitted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('orders.rating_submitted'.tr()),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
              context.pop(true); // Return true to indicate rating submitted
            } else if (state is OrderRatingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is OrderRatingLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is OrderRatingAlreadyRated) {
              return _buildAlreadyRated(state);
            }

            final isSubmitting = state is OrderRatingSubmitting;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Illustration
                  Image.asset(
                    'assets/images/feedback-illustration.png',
                    width: 180,
                    height: 180,
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'orders.rate_experience'.tr(),
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'orders.rate_description'.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Star Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      final isSelected = starIndex <= _selectedRating;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedRating = starIndex);
                          context.read<OrderRatingCubit>().setRating(starIndex);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: AnimatedScale(
                            scale: isSelected ? 1.2 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            child: Icon(
                              isSelected ? LucideIcons.star : LucideIcons.star,
                              size: 44,
                              color: isSelected
                                  ? Colors.amber
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Rating label
                  Text(
                    _getRatingLabel(_selectedRating),
                    style: AppTextStyles.labelLarge.copyWith(
                      color: _selectedRating > 0
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Comment field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'orders.rate_comment_hint'.tr(),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                      ),
                      onChanged: (value) {
                        context.read<OrderRatingCubit>().setComment(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting || _selectedRating == 0
                          ? null
                          : () {
                              context.read<OrderRatingCubit>().submitRating();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'orders.submit_rating'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Skip button
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'general.skip'.tr(),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAlreadyRated(OrderRatingAlreadyRated state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              child: const Icon(
                LucideIcons.circleCheckBig,
                size: 48,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'orders.already_rated'.tr(),
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Show the rating stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final isSelected = (index + 1) <= state.rating;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    LucideIcons.star,
                    size: 36,
                    color: isSelected ? Colors.amber : Colors.grey.shade300,
                  ),
                );
              }),
            ),

            if (state.comment != null && state.comment!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '"${state.comment}"',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('general.done'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'orders.rating_labels.1'.tr();
      case 2:
        return 'orders.rating_labels.2'.tr();
      case 3:
        return 'orders.rating_labels.3'.tr();
      case 4:
        return 'orders.rating_labels.4'.tr();
      case 5:
        return 'orders.rating_labels.5'.tr();
      default:
        return 'orders.rating_labels.default'.tr();
    }
  }
}
