class CameraFollowController {
  bool _enabled = true;
  bool _programmaticMoveInProgress = false;

  bool get shouldAnimate => _enabled && !_programmaticMoveInProgress;

  void beginProgrammaticMove() {
    _programmaticMoveInProgress = true;
  }

  void endProgrammaticMove() {
    _programmaticMoveInProgress = false;
  }

  void handleCameraMoveStarted() {
    if (!_programmaticMoveInProgress) {
      _enabled = false;
    }
  }
}
