import 'guard_response.dart';

enum StatusFetchFailure {
  none,
  signatureMismatch,
  networkError,
  timeout,
}

class StatusFetchResult {
  final GuardResponse? response;
  final StatusFetchFailure failure;

  const StatusFetchResult({
    this.response,
    this.failure = StatusFetchFailure.none,
  });

  bool get isSignatureMismatch => failure == StatusFetchFailure.signatureMismatch;
}
