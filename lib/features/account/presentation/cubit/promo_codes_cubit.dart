import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/promo_code_model.dart';
import '../../data/repositories/account_content_repository.dart';

// States
abstract class PromoCodesState extends Equatable {
  const PromoCodesState();
  @override
  List<Object> get props => [];
}

class PromoCodesInitial extends PromoCodesState {}

class PromoCodesLoading extends PromoCodesState {}

class PromoCodesLoaded extends PromoCodesState {
  final List<PromoCode> promoCodes;
  const PromoCodesLoaded(this.promoCodes);
  @override
  List<Object> get props => [promoCodes];
}

class PromoCodesError extends PromoCodesState {
  final String message;
  const PromoCodesError(this.message);
  @override
  List<Object> get props => [message];
}

// Cubit
class PromoCodesCubit extends Cubit<PromoCodesState> {
  final AccountContentRepository _repository;

  PromoCodesCubit(this._repository) : super(PromoCodesInitial());

  Future<void> loadPromoCodes() async {
    emit(PromoCodesLoading());
    try {
      final codes = await _repository.getPromoCodes();
      emit(PromoCodesLoaded(codes));
    } catch (e) {
      emit(PromoCodesError(e.toString()));
    }
  }
}
