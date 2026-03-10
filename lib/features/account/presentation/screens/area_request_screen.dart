import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/core/widgets/bourraq_header.dart';
import 'package:bourraq/features/account/presentation/cubit/area_request_cubit.dart';
import 'package:bourraq/features/account/data/repositories/account_content_repository.dart';

class AreaRequestScreen extends StatelessWidget {
  const AreaRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AreaRequestCubit(context.read<AccountContentRepository>()),
      child: const _AreaRequestView(),
    );
  }
}

class _AreaRequestView extends StatefulWidget {
  const _AreaRequestView();

  @override
  State<_AreaRequestView> createState() => _AreaRequestViewState();
}

class _AreaRequestViewState extends State<_AreaRequestView> {
  final _formKey = GlobalKey<FormState>();
  final _governorateController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  @override
  void dispose() {
    _governorateController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    context.read<AreaRequestCubit>().submitRequest(
      governorate: _governorateController.text.trim(),
      city: _cityController.text.trim(),
      areaName: _areaController.text.trim(),
      additionalInfo: _additionalInfoController.text.trim().isEmpty
          ? null
          : _additionalInfoController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocListener<AreaRequestCubit, AreaRequestState>(
      listener: (context, state) {
        if (state is AreaRequestSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('area_request.success'.tr()),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
          context.pop();
        } else if (state is AreaRequestError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(context, isArabic),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.mapPin,
                              color: AppColors.primaryGreen,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'area_request.desc'.tr(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Governorate Field
                      _buildFieldLabel('area_request.governorate'.tr()),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _governorateController,
                        hint: 'area_request.governorate_hint'.tr(),
                        icon: LucideIcons.building2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'area_request.governorate_required'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // City Field
                      _buildFieldLabel('area_request.city'.tr()),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _cityController,
                        hint: 'area_request.city_hint'.tr(),
                        icon: LucideIcons.building,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'area_request.city_required'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Area Name Field
                      _buildFieldLabel('area_request.area_name'.tr()),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _areaController,
                        hint: 'area_request.area_hint'.tr(),
                        icon: LucideIcons.navigation2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'area_request.area_required'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Additional Info Field
                      _buildFieldLabel('area_request.additional_info'.tr()),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _additionalInfoController,
                        hint: 'area_request.additional_info_hint'.tr(),
                        icon: LucideIcons.info,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 48),

                      // Submit Button
                      BlocBuilder<AreaRequestCubit, AreaRequestState>(
                        builder: (context, state) {
                          final isLoading = state is AreaRequestSubmitting;
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryGreen.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () => _submitRequest(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'common.send'.tr(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.5),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.primaryGreen.withValues(alpha: 0.6),
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primaryGreen,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isArabic) {
    return BourraqHeader(
      padding: const EdgeInsets.only(top: 16, bottom: 48, left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => context.pop(),
            child: Padding(
              padding: EdgeInsets.only(
                right: isArabic ? 0 : 12,
                left: isArabic ? 12 : 0,
              ),
              child: Icon(
                isArabic ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
                color: AppColors.accentYellow,
                size: 28,
              ),
            ),
          ),

          // Title
          Text(
            'area_request.title'.tr(),
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.accentYellow,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}
