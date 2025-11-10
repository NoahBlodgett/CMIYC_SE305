import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cache_me_if_you_can/mock/mock_data.dart' as mock;

class ProgressWidget extends StatefulWidget {
  final double progress;
  final String goalLabel;
  final String value;
  final Color color;
  final double size;
  final Duration wavePeriod;
  final bool animate;
  final bool lowPower;
  final double amplitudeFactor;

  const ProgressWidget({
    super.key,
    required this.progress,
    required this.goalLabel,
    required this.value,
    required this.color,
    this.size = 160,
    this.wavePeriod = const Duration(seconds: 20),
    this.animate = true,
    this.lowPower = false,
    this.amplitudeFactor = 0.03,
  });

  @override
  State<ProgressWidget> createState() => _ProgressWidgetState();
}

class CaloriesProgressLoader extends StatefulWidget {
  final String userId;
  final DateTime? date;
  final Color color;
  final double size;
  final bool animate;
  final bool lowPower;
  final Duration wavePeriod;
  final double amplitudeFactor;
  final bool showCenterText;
  final Widget Function(BuildContext context, int total, int target)?
  bottomBuilder;

  const CaloriesProgressLoader({
    super.key,
    required this.userId,
    this.date,
    this.color = const Color(0xFF64B5F6),
    this.size = 160,
    this.animate = true,
    this.lowPower = false,
    this.wavePeriod = const Duration(seconds: 20),
    this.amplitudeFactor = 0.03,
    this.showCenterText = true,
    this.bottomBuilder,
  });

  @override
  State<CaloriesProgressLoader> createState() => _CaloriesProgressLoaderState();
}

class _CaloriesProgressLoaderState extends State<CaloriesProgressLoader> {
  int? _totalCalories;
  int? _targetCalories;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final logs = await mock.fetchNutritionLogs(limit: 20);
      Map<String, dynamic>? latest;
      DateTime latestDate = DateTime.fromMillisecondsSinceEpoch(0);
      for (final m in logs) {
        final dStr = m['date']?.toString();
        if (dStr == null) continue;
        final parts = dStr.split('-');
        if (parts.length == 3) {
          final year = int.tryParse(parts[0]) ?? 0;
          final month = int.tryParse(parts[1]) ?? 1;
          final day = int.tryParse(parts[2]) ?? 1;
          final dt = DateTime(year, month, day);
          if (dt.isAfter(latestDate)) {
            latestDate = dt;
            latest = Map<String, dynamic>.from(m);
          }
        }
      }

      latest ??= logs.isNotEmpty ? Map<String, dynamic>.from(logs.first) : null;

      if (!mounted) return;
      if (latest == null) {
        setState(() {
          _loading = false;
          _error = StateError('No nutrition logs available');
        });
        return;
      }

      final total = (latest['totalCalories'] is num)
          ? (latest['totalCalories'] as num).toInt()
          : int.tryParse(latest['totalCalories']?.toString() ?? '');
      final target = (latest['targetCalories'] is num)
          ? (latest['targetCalories'] as num).toInt()
          : int.tryParse(latest['targetCalories']?.toString() ?? '');

      setState(() {
        _totalCalories = total ?? 0;
        _targetCalories = (target == null || target <= 0) ? 2500 : target;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_error != null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: Text(
            '—',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ),
      );
    }

    final total = _totalCalories ?? 0;
    final target = (_targetCalories == null || _targetCalories! <= 0)
        ? 2500
        : _targetCalories!;
    final progress = target == 0 ? 0.0 : (total / target).clamp(0.0, 1.0);
    final value = '$total / $target';

    final circle = ProgressWidget(
      progress: progress,
      goalLabel: widget.showCenterText ? 'kcal today' : '',
      value: widget.showCenterText ? value : '',
      color: widget.color,
      size: widget.size,
      wavePeriod: widget.wavePeriod,
      animate: widget.animate,
      lowPower: widget.lowPower,
      amplitudeFactor: widget.amplitudeFactor,
    );

    if (widget.bottomBuilder != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          circle,
          const SizedBox(height: 8),
          widget.bottomBuilder!(context, total, target),
        ],
      );
    }

    return circle;
  }
}

class _ProgressWidgetState extends State<ProgressWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? _waveCtrl;
  Timer? _timer;
  final ValueNotifier<double> _phaseNotifier = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveCtrl?.dispose();
    _phaseNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate ||
        oldWidget.lowPower != widget.lowPower ||
        oldWidget.wavePeriod != widget.wavePeriod) {
      _setupAnimation();
    }
  }

  void _setupAnimation() {
    _timer?.cancel();
    _waveCtrl?.stop();
    _waveCtrl?.dispose();
    _waveCtrl = null;

    if (!widget.animate) {
      _phaseNotifier.value = 0;
      return;
    }

    if (widget.lowPower) {
      const frameInterval = Duration(milliseconds: 200);
      final deltaPerTick =
          (2 * math.pi) *
          frameInterval.inMilliseconds /
          widget.wavePeriod.inMilliseconds;
      _phaseNotifier.value = 0;
      _timer = Timer.periodic(frameInterval, (_) {
        double next = _phaseNotifier.value + deltaPerTick;
        if (next >= 2 * math.pi) next -= 2 * math.pi;
        _phaseNotifier.value = next;
      });
    } else {
      _waveCtrl = AnimationController(vsync: this, duration: widget.wavePeriod)
        ..repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final valueFont = 32.0 * (size / 160.0);
    final labelFont = 18.0 * (size / 160.0);
    Widget painted(double phase) {
      return RepaintBoundary(
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _WavePainter(
                progress: widget.progress.clamp(0.0, 1.0),
                phase: widget.animate ? phase : 0,
                amplitudeFactor: widget.animate ? widget.amplitudeFactor : 0,
                color: widget.color,
                backgroundColor: Colors.grey[200]!,
                borderColor: Colors.grey,
                borderWidth: 2.0,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.value,
                  style: TextStyle(
                    fontSize: valueFont,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  widget.goalLabel,
                  style: TextStyle(fontSize: labelFont, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (!widget.animate) {
      return SizedBox(width: size, height: size, child: painted(0));
    }

    if (widget.lowPower) {
      return SizedBox(
        width: size,
        height: size,
        child: ValueListenableBuilder<double>(
          valueListenable: _phaseNotifier,
          builder: (context, phase, child) => painted(phase),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _waveCtrl!,
        builder: (context, child) => painted(_waveCtrl!.value * 2 * math.pi),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double phase;
  final double amplitudeFactor;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;

  _WavePainter({
    required this.progress,
    required this.phase,
    required this.amplitudeFactor,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.clipPath(clipPath);

    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final amplitude = size.height * amplitudeFactor;
    final baseline = size.height * (1.0 - progress);
    final wavelength = size.width;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, baseline);
    for (double x = 0; x <= size.width; x += 1.0) {
      final y =
          baseline +
          amplitude * math.sin(2 * math.pi * (x / wavelength) + phase);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();

    final wavePaint = Paint()..color = color;
    canvas.drawPath(path, wavePaint);

    canvas.restore();
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..color = borderColor;
    canvas.drawCircle(center, radius - borderWidth / 2, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) {
    return old.progress != progress ||
        old.phase != phase ||
        old.color != color ||
        old.amplitudeFactor != amplitudeFactor;
  }
}
