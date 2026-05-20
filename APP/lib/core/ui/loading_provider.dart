import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoadingState {
  final bool isLoading;
  final String? message;

  const LoadingState({this.isLoading = false, this.message});

  LoadingState copyWith({bool? isLoading, String? message}) {
    return LoadingState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
    );
  }
}

class LoadingNotifier extends StateNotifier<LoadingState> {
  LoadingNotifier() : super(const LoadingState());

  void show({String? message}) {
    state = state.copyWith(isLoading: true, message: message);
  }

  void hide() {
    state = const LoadingState(isLoading: false, message: null);
  }
}

final loadingProvider = StateNotifierProvider<LoadingNotifier, LoadingState>((ref) {
  return LoadingNotifier();
});
