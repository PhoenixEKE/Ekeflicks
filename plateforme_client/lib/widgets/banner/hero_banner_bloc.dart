import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_ekeflicks/models/content_model.dart';

class HeroBannerCubit extends Cubit<int> {
  final List<Content> contents;
  final PageController pageController = PageController();
  final Duration interval;
  final bool autoPlay;

  Timer? _timer;
  bool _isAutoPlayActive;

  HeroBannerCubit(
    this.contents, {
    this.interval = const Duration(seconds: 5),
    this.autoPlay = true,
  }) : _isAutoPlayActive = autoPlay,
       super(0) {
    if (autoPlay) _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      if (!_isAutoPlayActive || pageController.positions.isEmpty) return;

      final nextPage = (state + 1) % contents.length;
      pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      emit(nextPage);
    });
  }

  void onPageChanged(int index) {
    if (index == state) return;
    emit(index);
  }

  void pauseAutoPlay() {
    _isAutoPlayActive = false;
    _timer?.cancel();
  }

  void resumeAutoPlay() {
    if (!_isAutoPlayActive) {
      _isAutoPlayActive = true;
      _startAutoPlay();
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    pageController.dispose();
    return super.close();
  }
}
