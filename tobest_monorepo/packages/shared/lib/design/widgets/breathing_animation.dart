// packages/shared/lib/design/widgets/breathing_animation.dart
//
// Breathing Animation — تُستخدم كـ:
// 1. Rest Timer بعد كل سِت
// 2. Loading/Sync indicator في كل التطبيق
// 3. Splash Screen
// 4. Subscription Pending Screen
// دائرة تكبر 4 ثواني (شهيق) وتصغر 4 ثواني (زفير)

import 'package:flutter/material.dart';
import 'package:shared/design/tokens.dart';

/// Animation التنفس المشتركة في كل التطبيق
///
/// [size] الحجم الأساسي للدائرة
/// [color] لون الدائرة (افتراضي: Primary)
/// [showText] عرض نص شهيق/زفير
/// [onPhaseChange] callback عند تغيير مرحلة التنفس
class BreathingAnimation extends StatefulWidget {
  const BreathingAnimation({
    super.key,
    this.size = 120,
    this.color,
    this.showText = true,
    this.inhaleTextAr = 'شهيق...',
    this.exhaleTextAr = 'زفير...',
    this.inhaleTextEn = 'Inhale...',
    this.exhaleTextEn = 'Exhale...',
    this.isRtl = true,
    this.onPhaseChange,
  });

  final double size;
  final Color? color;
  final bool showText;
  final String inhaleTextAr;
  final String exhaleTextAr;
  final String inhaleTextEn;
  final String exhaleTextEn;
  final bool isRtl;
  final void Function(bool isInhale)? onPhaseChange;

  @override
  State<BreathingAnimation> createState() => _BreathingAnimationState();
}

class _BreathingAnimationState extends State<BreathingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool _isInhale = true;

  @override
  void initState() {
    super.initState();

    // 4 ثواني للشهيق، 4 ثواني للزفير = 8 ثواني دورة كاملة
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    // الحجم يكبر للضعف عند الشهيق ويعود عند الزفير
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.7, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50, // شهيق — 4 ثواني
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.7)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50, // زفير — 4 ثواني
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.5),
        weight: 50,
      ),
    ]).animate(_controller);

    // تتبع مرحلة الشهيق/الزفير
    _controller.addListener(() {
      final newIsInhale = _controller.value < 0.5;
      if (newIsInhale != _isInhale) {
        setState(() => _isInhale = newIsInhale);
        widget.onPhaseChange?.call(_isInhale);
      }
    });

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final phaseTextAr = _isInhale ? widget.inhaleTextAr : widget.exhaleTextAr;
    final phaseTextEn = _isInhale ? widget.inhaleTextEn : widget.exhaleTextEn;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width:  widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.15),
                    border: Border.all(
                      color: color.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width:  widget.size * 0.5,
                      height: widget.size * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        if (widget.showText) ...[
          const SizedBox(height: AppSpacing.md),
          AnimatedSwitcher(
            duration: AppDurations.normal,
            child: Text(
              widget.isRtl ? phaseTextAr : phaseTextEn,
              key: ValueKey(_isInhale),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Timer + Breathing Animation للراحة بين السيتات
class RestTimerWidget extends StatefulWidget {
  const RestTimerWidget({
    super.key,
    required this.durationSeconds,
    required this.onComplete,
    this.onSkip,
    this.isRtl = true,
  });

  final int durationSeconds;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;
  final bool isRtl;

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget> {
  late int _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.durationSeconds;
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_remaining > 0) {
        setState(() => _remaining--);
        _startTimer();
      } else {
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BreathingAnimation(
          size: 160,
          isRtl: widget.isRtl,
        ),

        const SizedBox(height: AppSpacing.xl),

        // العداد التنازلي
        Text(
          _formatTime(_remaining),
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        Text(
          widget.isRtl ? 'وقت الراحة' : 'Rest Time',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // زر تخطي
        TextButton.icon(
          onPressed: () {
            widget.onSkip?.call();
            widget.onComplete();
          },
          icon: const Icon(Icons.skip_next),
          label: Text(widget.isRtl ? 'تخطي' : 'Skip'),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
