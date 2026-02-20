import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bourraq/features/pages/data/models/app_page_model.dart';
import 'package:bourraq/features/pages/data/repositories/pages_repository.dart';

// States
abstract class PagesState extends Equatable {
  const PagesState();

  @override
  List<Object> get props => [];
}

class PagesInitial extends PagesState {}

class PagesLoading extends PagesState {}

class PagesLoaded extends PagesState {
  final AppPageModel page;

  const PagesLoaded(this.page);

  @override
  List<Object> get props => [page];
}

class PagesError extends PagesState {
  final String message;

  const PagesError(this.message);

  @override
  List<Object> get props => [message];
}

// Cubit
class PagesCubit extends Cubit<PagesState> {
  final PagesRepository _repository;

  PagesCubit(this._repository) : super(PagesInitial());

  Future<void> loadPage(String slug) async {
    emit(PagesLoading());
    try {
      final page = await _repository.getPageBySlug(slug);
      emit(PagesLoaded(page));
    } catch (e) {
      emit(PagesError(e.toString()));
    }
  }
}
