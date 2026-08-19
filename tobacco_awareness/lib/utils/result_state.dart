/// Sealed Result State representing all possible asynchronous UI states
sealed class ResultState<T> {
  const ResultState();

  factory ResultState.initial() = ResultInitial<T>;
  factory ResultState.loading() = ResultLoading<T>;
  factory ResultState.success(T data) = ResultSuccess<T>;
  factory ResultState.failure(String message, {Object? error}) = ResultFailure<T>;
}

class ResultInitial<T> extends ResultState<T> {
  const ResultInitial();
}

class ResultLoading<T> extends ResultState<T> {
  const ResultLoading();
}

class ResultSuccess<T> extends ResultState<T> {
  final T data;
  const ResultSuccess(this.data);
}

class ResultFailure<T> extends ResultState<T> {
  final String message;
  final Object? error;
  const ResultFailure(this.message, {this.error});
}
