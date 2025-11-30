import 'dart:math';
import 'package:flutter/material.dart';

/// iOS 风格的抖动组件 (Jiggle Effect)
class ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool isEnabled;
  final Duration duration;
  final double deltaX;
  final double deltaY;
  final double curveValue;

  const ShakeWidget({
    super.key,
    required this.child,
    required this.isEnabled,
    this.duration = const Duration(milliseconds: 300),
    this.deltaX = 1.2,
    this.deltaY = 0.5,
    this.curveValue = 0.1, // 旋转角度 (radians)
  });

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _dxAnimation;
  late Animation<double> _dyAnimation;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // 随机化初始偏移，使多个组件抖动不同步
    if (widget.isEnabled) {
      _startShaking();
    }
  }

  @override
  void didUpdateWidget(covariant ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEnabled != oldWidget.isEnabled) {
      if (widget.isEnabled) {
        _startShaking();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  void _startShaking() {
    // 随机起始时间
    Future.delayed(Duration(milliseconds: _random.nextInt(100)), () {
      if (mounted && widget.isEnabled) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 构建动画
    // 使用 sine 曲线模拟抖动
    _rotationAnimation = Tween<double>(
      begin: -widget.curveValue * 0.02, 
      end: widget.curveValue * 0.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));

    // X轴轻微位移
    _dxAnimation = Tween<double>(
      begin: -widget.deltaX,
      end: widget.deltaX,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
    ));
    
    // Y轴轻微位移 (不同步)
     _dyAnimation = Tween<double>(
      begin: -widget.deltaY,
      end: widget.deltaY,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
    ));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!widget.isEnabled) return widget.child;
        
        return Transform.translate(
          offset: Offset(_dxAnimation.value, _dyAnimation.value),
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

