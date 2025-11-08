import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// FeatureLoadingPage
/// Supports two modes:
/// 1. Timed navigation (destination provided, no waitFor): cycles messages then navigates.
/// 2. Future-driven navigation (waitFor + destinationBuilder): waits for backend result, ensuring
///    at least minVisualDuration (if supplied) before navigating, showing staged messages meanwhile.
class FeatureLoadingPage extends StatefulWidget {
  final String animationAsset;
  final List<String> messages; // Typically 2
  final Duration messageDuration; // Duration per message
  final Widget? destination; // Used for simple timed mode
  final bool replace; // pushReplacement vs push
  final Future<dynamic>? waitFor; // Backend future to await (Exercise & Diet)
  final Widget Function(dynamic result)? destinationBuilder; // Builds destination with future result
  final Duration? minVisualDuration; // Guarantees minimum screen time even if future is fast

  const FeatureLoadingPage({
    super.key,
    required this.animationAsset,
    required this.messages,
    required this.messageDuration,
    this.destination,
    this.replace = true,
    this.waitFor,
    this.destinationBuilder,
    this.minVisualDuration,
  });

  @override
  State<FeatureLoadingPage> createState() => _FeatureLoadingPageState();
}

class _FeatureLoadingPageState extends State<FeatureLoadingPage> {
  int _messageIndex = 0;
  Timer? _swapTimer;
  Timer? _navTimer; // Only used in timed mode
  late final DateTime _startTime;
  bool _futureDone = false;
  dynamic _futureResult;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _setupMessageRotation();
    _maybeAttachFuture();
  }

  void _setupMessageRotation() {
    if (widget.messages.length > 1) {
      _swapTimer = Timer(widget.messageDuration, () {
        if (mounted) setState(() => _messageIndex = 1);
      });
    }
    // Timed mode (no future): navigate after total duration
    if (widget.waitFor == null) {
      final total = widget.messageDuration * widget.messages.length;
      _navTimer = Timer(total, () => _navigate());
    }
  }

  void _maybeAttachFuture() {
    if (widget.waitFor == null) return;
    widget.waitFor!.then((value) {
      if (!mounted) return;
      _futureDone = true;
      _futureResult = value;
      _attemptFutureNavigation();
    }).catchError((error) {
      if (!mounted) return;
      // Still proceed; destination can handle null/error state
      _futureDone = true;
      _futureResult = null;
      _attemptFutureNavigation();
    });
  }

  void _attemptFutureNavigation() {
    if (!_futureDone) return;
    final minDur = widget.minVisualDuration;
    if (minDur != null) {
      final elapsed = DateTime.now().difference(_startTime);
      final remaining = minDur - elapsed;
      if (remaining > Duration.zero) {
        Future.delayed(remaining, () => _navigate(withFuture: true));
        return;
      }
    }
    _navigate(withFuture: true);
  }

  void _navigate({bool withFuture = false}) {
    if (!mounted) return;
    Widget? target = widget.destination;
    if (withFuture && widget.destinationBuilder != null) {
      target = widget.destinationBuilder!(_futureResult);
    }
    if (target == null) return;
    final route = MaterialPageRoute(builder: (_) => target!);
    if (widget.replace) {
      Navigator.of(context).pushReplacement(route);
    } else {
      Navigator.of(context).push(route);
    }
  }

  @override
  void dispose() {
    _swapTimer?.cancel();
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentMessage = widget.messages[_messageIndex.clamp(0, widget.messages.length - 1)];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 200,
                child: Lottie.asset(
                  widget.animationAsset,
                  repeat: true,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                child: Text(
                  currentMessage,
                  key: ValueKey(currentMessage),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
