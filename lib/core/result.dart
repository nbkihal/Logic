/// A tiny Result type for engine outcomes that can fail meaningfully
/// (a cycle, an illegal wire) without throwing.
///
/// Pure Dart: this file is imported by `domain/` and must stay Flutter-free.
sealed class Result<T, E> {
  const Result();

  const factory Result.ok(T value) = Ok<T, E>;
  const factory Result.err(E error) = Err<T, E>;

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  /// The value, or null when this is an [Err].
  T? get valueOrNull => switch (this) {
        Ok<T, E>(:final value) => value,
        Err<T, E>() => null,
      };

  /// The error, or null when this is an [Ok].
  E? get errorOrNull => switch (this) {
        Ok<T, E>() => null,
        Err<T, E>(:final error) => error,
      };

  R fold<R>(R Function(T value) onOk, R Function(E error) onErr) =>
      switch (this) {
        Ok<T, E>(:final value) => onOk(value),
        Err<T, E>(:final error) => onErr(error),
      };

  Result<R, E> map<R>(R Function(T value) transform) => switch (this) {
        Ok<T, E>(:final value) => Ok<R, E>(transform(value)),
        Err<T, E>(:final error) => Err<R, E>(error),
      };
}

final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);
  final T value;

  @override
  bool operator ==(Object other) =>
      other is Ok<T, E> && other.value == value;

  @override
  int get hashCode => Object.hash('Ok', value);

  @override
  String toString() => 'Ok($value)';
}

final class Err<T, E> extends Result<T, E> {
  const Err(this.error);
  final E error;

  @override
  bool operator ==(Object other) =>
      other is Err<T, E> && other.error == error;

  @override
  int get hashCode => Object.hash('Err', error);

  @override
  String toString() => 'Err($error)';
}
