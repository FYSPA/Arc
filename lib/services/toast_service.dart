import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

import '../core/broken_icons.dart';
import '../data/models/track.dart';

/// In-app, app-styled toasts rendered by Flutter (not Android system
/// notifications). Used for ephemeral notices like "this track has no Canvas".
class ToastService {
  ToastService._();
  static final ToastService inst = ToastService._();

  /// Track ids for which the "no canvas" notice was already shown this session,
  /// so it appears only once per track.
  final Set<int> _shownNoCanvas = {};

  /// Shows a top-centered toast with the app's own styling.
  void showTop(
    String message, {
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    BotToast.showCustomNotification(
      align: Alignment.topCenter,
      duration: duration,
      toastBuilder: (_) => _AppToast(message: message, icon: icon),
    );
  }

  /// Shows the "this song has no Canvas" notice once per track per session.
  void showNoCanvas(ArcTrack track) {
    if (_shownNoCanvas.contains(track.id)) return;
    _shownNoCanvas.add(track.id);
    showTop('Esta canción no tiene Canvas', icon: Broken.video_slash);
  }
}

class _AppToast extends StatelessWidget {
  final String message;
  final IconData? icon;

  const _AppToast({required this.message, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
