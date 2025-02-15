import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationStateNotifier extends StateNotifier<int> {
  NavigationStateNotifier() : super(0); 

  void updateIndex(int newIndex) {
    state = newIndex; 
  }
}

final navigationProvider = StateNotifierProvider<NavigationStateNotifier, int>((ref) {
  return NavigationStateNotifier();
});
