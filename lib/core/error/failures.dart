import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure(this.message);

  /// What went wrong, in plain language.
  final String message;

  /// What the user can do about it. Shown as a second line wherever an
  /// error surfaces; empty means there is nothing actionable to suggest.
  String get hint => '';

  @override
  List<Object?> get props => [message, hint];
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Motive could not read or write your saved data.']);

  @override
  String get hint => 'Your progress is still on this device — restart the app. If it keeps happening, reset progress in Me.';
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);

  @override
  String get hint => 'Check Wi-Fi or mobile data and try again. Text-only analysis works offline with the offline engine.';
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
