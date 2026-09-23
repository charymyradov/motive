import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/analysis.dart';
import '../../domain/usecases/analyzer_usecases.dart';

// ── Events ──────────────────────────────────────────────────────────────

sealed class AnalyzerEvent extends Equatable {
  const AnalyzerEvent();
  @override
  List<Object?> get props => [];
}

class AnalyzerStarted extends AnalyzerEvent {
  const AnalyzerStarted();
}

class AnalyzerTextChanged extends AnalyzerEvent {
  const AnalyzerTextChanged(this.text);
  final String text;
  @override
  List<Object?> get props => [text];
}

class AnalyzerImageAttached extends AnalyzerEvent {
  const AnalyzerImageAttached(this.bytes, this.mimeType);
  final Uint8List bytes;
  final String mimeType;
  @override
  List<Object?> get props => [bytes.length, mimeType];
}

class AnalyzerImageCleared extends AnalyzerEvent {
  const AnalyzerImageCleared();
}

class AnalyzerSubmitted extends AnalyzerEvent {
  const AnalyzerSubmitted();
}

class AnalyzerHistoryOpened extends AnalyzerEvent {
  const AnalyzerHistoryOpened(this.analysis);
  final Analysis analysis;
  @override
  List<Object?> get props => [analysis];
}

class AnalyzerHistoryDeleted extends AnalyzerEvent {
  const AnalyzerHistoryDeleted(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class AnalyzerReset extends AnalyzerEvent {
  const AnalyzerReset();
}

// ── State ───────────────────────────────────────────────────────────────

class AttachedImage extends Equatable {
  const AttachedImage(this.bytes, this.mimeType);
  final Uint8List bytes;
  final String mimeType;
  @override
  List<Object?> get props => [bytes, mimeType];
}

enum AnalyzerStatus { idle, loading, success, failure }

class AnalyzerState extends Equatable {
  const AnalyzerState({
    this.text = '',
    this.image,
    this.status = AnalyzerStatus.idle,
    this.result,
    this.error,
    this.history = const [],
  });

  final String text;
  final AttachedImage? image;
  final AnalyzerStatus status;
  final Analysis? result;
  final String? error;
  final List<Analysis> history;

  bool get canSubmit => (text.trim().isNotEmpty || image != null) && status != AnalyzerStatus.loading;

  AnalyzerState copyWith({
    String? text,
    AttachedImage? Function()? image,
    AnalyzerStatus? status,
    Analysis? Function()? result,
    String? Function()? error,
    List<Analysis>? history,
  }) {
    return AnalyzerState(
      text: text ?? this.text,
      image: image != null ? image() : this.image,
      status: status ?? this.status,
      result: result != null ? result() : this.result,
      error: error != null ? error() : this.error,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [text, image, status, result, error, history];
}

// ── Bloc ────────────────────────────────────────────────────────────────

class AnalyzerBloc extends Bloc<AnalyzerEvent, AnalyzerState> {
  AnalyzerBloc({
    required AnalyzePost analyzePost,
    required this._getHistory,
    required DeleteAnalysis deleteAnalysis,
  })  : _analyze = analyzePost,
        _delete = deleteAnalysis,
        super(const AnalyzerState()) {
    on<AnalyzerStarted>((e, emit) => _loadHistory(emit));
    on<AnalyzerTextChanged>((e, emit) => emit(state.copyWith(text: e.text)));
    on<AnalyzerImageAttached>((e, emit) => emit(state.copyWith(image: () => AttachedImage(e.bytes, e.mimeType))));
    on<AnalyzerImageCleared>((e, emit) => emit(state.copyWith(image: () => null)));
    on<AnalyzerSubmitted>(_onSubmitted);
    on<AnalyzerHistoryOpened>((e, emit) => emit(state.copyWith(
          status: AnalyzerStatus.success,
          result: () => e.analysis,
          error: () => null,
        )));
    on<AnalyzerHistoryDeleted>(_onDeleted);
    on<AnalyzerReset>((e, emit) => emit(AnalyzerState(history: state.history)));
  }

  final AnalyzePost _analyze;
  final GetAnalysisHistory _getHistory;
  final DeleteAnalysis _delete;

  Future<void> _loadHistory(Emitter<AnalyzerState> emit) async {
    final result = await _getHistory(const NoParams());
    result.match((_) {}, (list) => emit(state.copyWith(history: list)));
  }

  Future<void> _onSubmitted(AnalyzerSubmitted event, Emitter<AnalyzerState> emit) async {
    if (!state.canSubmit) return;
    emit(state.copyWith(status: AnalyzerStatus.loading, result: () => null, error: () => null));
    final result = await _analyze(AnalysisRequest(
      text: state.text,
      imageBytes: state.image?.bytes,
      imageMimeType: state.image?.mimeType,
    ));
    await result.match(
      (f) async => emit(state.copyWith(status: AnalyzerStatus.failure, error: () => f.message)),
      (analysis) async {
        emit(state.copyWith(status: AnalyzerStatus.success, result: () => analysis));
        await _loadHistory(emit);
      },
    );
  }

  Future<void> _onDeleted(AnalyzerHistoryDeleted event, Emitter<AnalyzerState> emit) async {
    await _delete(event.id);
    if (state.result?.id == event.id) {
      emit(state.copyWith(status: AnalyzerStatus.idle, result: () => null));
    }
    await _loadHistory(emit);
  }
}
