import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/core/map_camera_follow.dart';

void main() {
  test('una interacción manual desactiva el seguimiento automático', () {
    final follow = CameraFollowController();

    follow.handleCameraMoveStarted();

    expect(follow.shouldAnimate, isFalse);
  });

  test('un movimiento programático no desactiva el seguimiento automático', () {
    final follow = CameraFollowController();

    follow.beginProgrammaticMove();
    follow.handleCameraMoveStarted();
    follow.endProgrammaticMove();

    expect(follow.shouldAnimate, isTrue);
  });
}
