import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'scan_kit_controller.dart';

/// Callback invoked when the [ScanKitView] platform view has been created.
///
/// Provides a [ScanKitController] to control scanning, streaming, and export.
typedef ScanKitViewCreatedCallback = void Function(ScanKitController controller);

/// A widget that displays the AR camera feed for 3D scanning.
///
/// Only supported on iOS. On other platforms, displays an unsupported message.
///
/// Use the [onViewCreated] callback to obtain a [ScanKitController] for
/// controlling the scanning session.
class ScanKitView extends StatefulWidget {
  /// Called when the platform view has been created.
  final ScanKitViewCreatedCallback? onViewCreated;

  const ScanKitView({super.key, this.onViewCreated});

  @override
  State<ScanKitView> createState() => _ScanKitViewState();
}

class _ScanKitViewState extends State<ScanKitView> {
  ScanKitController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const Center(
        child: Text('ScanKit is only supported on iOS'),
      );
    }

    return UiKitView(
      viewType: 'dev.jorgeferrarice.scankit/ar_view',
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }

  void _onPlatformViewCreated(int viewId) {
    _controller = ScanKitController(viewId);
    widget.onViewCreated?.call(_controller!);
  }
}
