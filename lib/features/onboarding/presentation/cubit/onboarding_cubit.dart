import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../game/domain/entities/psych_field.dart';
import '../../../game/domain/usecases/game_usecases.dart';

class OnboardingState extends Equatable {
  const OnboardingState({
    this.step = 0,
    this.picked = const ['ms', 'mm'],
    this.fields = const [],
    this.forward = true,
  });

  static const steps = 3;

  final int step;
  final List<String> picked;
  final List<PsychField> fields;

  /// Direction of the last step change, used for the slide animation.
  final bool forward;

  bool get canContinue => step != 1 || picked.isNotEmpty;
  bool get isLast => step == steps - 1;

  OnboardingState copyWith({int? step, List<String>? picked, List<PsychField>? fields, bool? forward}) => OnboardingState(
        step: step ?? this.step,
        picked: picked ?? this.picked,
        fields: fields ?? this.fields,
        forward: forward ?? this.forward,
      );

  @override
  List<Object?> get props => [step, picked, fields, forward];
}

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({required this._getCatalog, List<String>? initialPicked})
      : super(OnboardingState(picked: initialPicked ?? const ['ms', 'mm']));

  final GetCatalog _getCatalog;

  Future<void> load() async {
    final result = await _getCatalog(const NoParams());
    result.match((_) {}, (catalog) => emit(state.copyWith(fields: catalog.fields)));
  }

  /// Moves forward; returns true when onboarding is complete.
  bool next() {
    if (!state.canContinue) return false;
    if (state.isLast) return true;
    emit(state.copyWith(step: state.step + 1, forward: true));
    return false;
  }

  void back() {
    if (state.step > 0) emit(state.copyWith(step: state.step - 1, forward: false));
  }

  void toggle(String fieldId) {
    final on = state.picked.contains(fieldId);
    emit(state.copyWith(picked: on ? (List.of(state.picked)..remove(fieldId)) : [...state.picked, fieldId]));
  }
}
