import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/account_content_repository.dart';

// States
abstract class AreaRequestState extends Equatable {
  const AreaRequestState();
  @override
  List<Object> get props => [];
}

class AreaRequestInitial extends AreaRequestState {}

class AreaRequestSubmitting extends AreaRequestState {}

class AreaRequestSuccess extends AreaRequestState {}

class AreaRequestError extends AreaRequestState {
  final String message;
  const AreaRequestError(this.message);
  @override
  List<Object> get props => [message];
}

// Cubit
class AreaRequestCubit extends Cubit<AreaRequestState> {
  final AccountContentRepository _repository;

  AreaRequestCubit(this._repository) : super(AreaRequestInitial());

  Future<void> submitRequest({
    required String governorate,
    required String city,
    required String areaName,
    String? additionalInfo,
  }) async {
    emit(AreaRequestSubmitting());
    try {
      await _repository.submitAreaRequest(
        governorate: governorate,
        city: city,
        areaName: areaName,
        additionalInfo: additionalInfo,
      );
      emit(AreaRequestSuccess());
    } catch (e) {
      emit(AreaRequestError(e.toString()));
    }
  }
}
