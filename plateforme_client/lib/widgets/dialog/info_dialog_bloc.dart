import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:app_ekeflicks/models/content_model.dart';

abstract class InfoDialogState {}

class InfoDialogInitial extends InfoDialogState {}

class InfoDialogReady extends InfoDialogState {
  final VideoPlayerController controller;
  InfoDialogReady(this.controller);
}

class InfoDialogError extends InfoDialogState {
  final String message;
  InfoDialogError(this.message);
}

class InfoDialogCubit extends Cubit<InfoDialogState> {
  final Content content;
  late VideoPlayerController _controller;

  InfoDialogCubit(this.content) : super(InfoDialogInitial()) {
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.network(
        content.videoUrl,
      );
      
      await _controller.initialize();
      emit(InfoDialogReady(_controller));
    } catch (e) {
      emit(InfoDialogError('Erreur de chargement de la vidéo'));
    }
  }

  void togglePlayback() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    emit(InfoDialogReady(_controller));
  }

  @override
  Future<void> close() {
    _controller.dispose();
    return super.close();
  }
}
