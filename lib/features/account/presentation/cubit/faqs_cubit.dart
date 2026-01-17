import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/faq_model.dart';
import '../../data/repositories/account_content_repository.dart';

// States
abstract class FaqsState extends Equatable {
  const FaqsState();
  @override
  List<Object> get props => [];
}

class FaqsInitial extends FaqsState {}

class FaqsLoading extends FaqsState {}

class FaqsLoaded extends FaqsState {
  final List<Faq> faqs;
  const FaqsLoaded(this.faqs);
  @override
  List<Object> get props => [faqs];
}

class FaqsError extends FaqsState {
  final String message;
  const FaqsError(this.message);
  @override
  List<Object> get props => [message];
}

// Cubit
class FaqsCubit extends Cubit<FaqsState> {
  final AccountContentRepository _repository;

  FaqsCubit(this._repository) : super(FaqsInitial());

  Future<void> loadFaqs() async {
    emit(FaqsLoading());
    try {
      final faqs = await _repository.getFaqs();
      emit(FaqsLoaded(faqs));
    } catch (e) {
      emit(FaqsError(e.toString()));
    }
  }
}
