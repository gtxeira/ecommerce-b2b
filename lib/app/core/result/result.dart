/// Result/Either Pattern
sealed class Result<S, F> {
  bool get isSuccess => this is Success<S, F>;
  bool get isFailure => this is Failure<S, F>;

  S getOrThrow() {
    return switch (this) {
      Success(value: var v) => v,
      Failure(error: var e) => throw Exception('Called getOrThrow on Failure: $e'),
    };
  }

  S? getOrNull() {
    return switch (this) {
      Success(value: var v) => v,
      Failure() => null,
    };
  }

  F getFailureOrThrow() {
    return switch (this) {
      Success(value: var v) => throw Exception('Called getFailureOrThrow on Success: $v'),
      Failure(error: var e) => e,
    };
  }

  /// Transforma os dois caminhos (Success e Failure) em um único resultado final
  T fold<T>(T Function(F error) onFailure, T Function(S value) onSuccess) {
    return switch (this) {
      Success(value: var v) => onSuccess(v),
      Failure(error: var e) => onFailure(e),
    };
  }

  /// Transforma o valor de sucesso se ele existir
  Result<NewS, F> map<NewS>(NewS Function(S value) transform) {
    return switch (this) {
      Success(value: var v) => Success(transform(v)),
      Failure(error: var e) => Failure(e),
    };
  }
}

class Success<S, F> extends Result<S, F> {
  final S value;
  Success(this.value);
}

class Failure<S, F> extends Result<S, F> {
  final F error;
  Failure(this.error);
}
