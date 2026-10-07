import 'dart:async';
import 'package:flutter/material.dart';

class AutoScrollSlider extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  final PageController? controller;

  final int currentIndex;

  final ValueChanged<int>? onPageChanged;
  final Duration interval;

  final bool Function(int index)? canAdvance;

  const AutoScrollSlider({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.currentIndex = 0,
    this.onPageChanged,
    this.interval = const Duration(seconds: 4),
    this.canAdvance,
  });

  @override
  State<AutoScrollSlider> createState() => _AutoScrollSliderState();
}

class _AutoScrollSliderState extends State<AutoScrollSlider> {
  late final PageController _ctrl;
  late final bool _ownsController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _ctrl = widget.controller!;
      _ownsController = false;
    } else {
      _ctrl = PageController();
      _ownsController = true;
    }
    if (widget.itemCount > 1) _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_ownsController) _ctrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) => _advance());
  }

  void _advance() {
    if (!mounted || widget.itemCount <= 1) return;
    final current = _ctrl.page?.round() ?? widget.currentIndex;
    if (widget.canAdvance != null && !widget.canAdvance!(current)) return;
    final next = (current + 1) % widget.itemCount;
    _ctrl.animateToPage(
      next,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int i) {
    widget.onPageChanged?.call(i);
    if (widget.itemCount > 1) _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.itemCount > 0
            ? PageView.builder(
                controller: _ctrl,
                itemCount: widget.itemCount,
                onPageChanged: _onPageChanged,
                itemBuilder: widget.itemBuilder,
              )
            : const SizedBox.shrink(),
        if (widget.itemCount > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: _SliderDots(
              count: widget.itemCount,
              currentIndex: widget.currentIndex,
            ),
          ),
      ],
    );
  }
}

// ─── Dot indicators ───────────────────────────────────────────────────────────

class _SliderDots extends StatelessWidget {
  final int count;
  final int currentIndex;
  const _SliderDots({required this.count, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white54,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
