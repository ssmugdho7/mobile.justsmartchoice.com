import 'package:flutter/material.dart';

/// Native animation rather than a screen-recording asset: no player, network
/// dependency, recorded phone UI or website-loading flash on startup.
class LaunchIntro extends StatefulWidget {
  const LaunchIntro({super.key, required this.onFinished, this.afterIntro});
  final VoidCallback onFinished;
  final Future<void> Function()? afterIntro;
  @override
  State<LaunchIntro> createState() => _LaunchIntroState();
}

class _LaunchIntroState extends State<LaunchIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _start(reducedMotion);
    });
  }

  Future<void> _start(bool reducedMotion) async {
    try {
      if (!reducedMotion) await _animation.forward().orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    // Keep the existing first-install permissions sequence. It must complete
    // before navigation becomes available, but never delay Flutter's first frame.
    await widget.afterIntro?.call();
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: Center(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final reveal = Curves.easeOutCubic.transform(
            (_animation.value / .24).clamp(0, 1),
          );
          return Opacity(
            opacity: reveal,
            child: Transform.scale(scale: .88 + .12 * reveal, child: child),
          );
        },
        child: Semantics(
          label: 'Opening Smart Choice',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 94,
                height: 94,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset(
                  'assets/brand/smart-choice-logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Smart Choice Contractors USA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
