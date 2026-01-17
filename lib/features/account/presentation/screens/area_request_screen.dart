import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
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
        appBar: AppBar(
          title: Text(
            'area_request.title'.tr(),
            style: AppTextStyles.titleMedium,
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isArabic ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
              color: AppColors.textPrimary,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
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
                      color: AppColors.primaryGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        color: AppColors.primaryGreen,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'area_request.desc'.tr(),
                          style: TextStyle(
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
                  maxLines: 4,
                ),
                const SizedBox(height: 48),

                // Submit Button
                BlocBuilder<AreaRequestCubit, AreaRequestState>(
                  builder: (context, state) {
                    final isLoading = state is AreaRequestSubmitting;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () => _submitRequest(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
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
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
