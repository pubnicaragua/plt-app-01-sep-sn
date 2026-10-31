import 'package:flutter/material.dart';

Future<void> waitForRouteDismissal() async {
  await WidgetsBinding.instance.endOfFrame;
}

Future<T?> showDialogAndWaitForDismissal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) async {
  final result = await showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
  await waitForRouteDismissal();
  return result;
}
