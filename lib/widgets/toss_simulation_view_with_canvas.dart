import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class TossSimulationViewWithCanvas extends StatefulWidget {
  final Function(int heads, int tails) onSimulationComplete;

  const TossSimulationViewWithCanvas({
    super.key,
    required this.onSimulationComplete,
  });

  @override
  _TossSimulationViewWithCanvasState createState() =>
      _TossSimulationViewWithCanvasState();
}

class _TossSimulationViewWithCanvasState
    extends State<TossSimulationViewWithCanvas> with TickerProviderStateMixin {
  int _headsCount = 0;
  int _tailsCount = 0;
  int _tossesRemaining = 100;
  bool _isSimulating = false;
  String _currentTossFace = '';
  bool _currentIsHeadsOutcome = false;

  AnimationController? _flipAnimationController;
  Animation<double>? _flipAnimation;

  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _flipAnimationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _flipAnimation =
        Tween(begin: 0.0, end: 1.0).animate(_flipAnimationController!)
          ..addListener(() {
            if(mounted) setState(() {});
          });

    startSimulation();
  }

  void startSimulation() {
    if(!mounted) return;
    setState(() {
      _isSimulating = true;
      _headsCount = 0;
      _tailsCount = 0;
      _tossesRemaining = 100;
      _currentTossFace = '';
    });

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if(!mounted) {
        timer.cancel();
        return;
      }
      if (_tossesRemaining > 0) {
        _currentIsHeadsOutcome = Random().nextBool();
        _flipAnimationController?.reset();
        _flipAnimationController?.forward().then((_) {
          if (mounted) {
            setState(() {
              if (_currentIsHeadsOutcome) {
                _headsCount++;
                _currentTossFace = 'Heads!';
              } else {
                _tailsCount++;
                _currentTossFace = 'Tails!';
              }
              _tossesRemaining--;
              if (_tossesRemaining == 0) {
                 _simulationTimer?.cancel();
                 _completeSimulation();
              }
            });
          }
        });
      } else {
        timer.cancel();
        _completeSimulation();
      }
    });
  }

  void _completeSimulation() {
    if (mounted) {
      setState(() {
        _isSimulating = false;
        _currentTossFace = 'Done!';
      });
      widget.onSimulationComplete(_headsCount, _tailsCount);
    }
  }


  @override
  void dispose() {
    _simulationTimer?.cancel();
    _flipAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 20.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text(
              _isSimulating ? 'Flipping Coins...' : 'Simulation Complete!',
              style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(
                painter: CoinPainter(
                  animationValue: _flipAnimation?.value ?? 0,
                  isHeads: _currentIsHeadsOutcome,
                  isSimulating: _isSimulating,
                ),
              ),
            ),
            if (_isSimulating && _currentTossFace.isNotEmpty && (_flipAnimationController?.isCompleted ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_currentTossFace, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
             if (!_isSimulating && _currentTossFace == 'Done!')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 30),
              ),
            const SizedBox(height: 20),
            if (_isSimulating)
              Column(
                children: [
                  LinearProgressIndicator(value: (100 - _tossesRemaining) / 100, backgroundColor: Colors.grey.shade300, valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary)),
                  const SizedBox(height: 8),
                  Text(
                    'Tosses Remaining: $_tossesRemaining',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildCountDisplay(context, 'Heads', _headsCount, Colors.orange.shade700),
                _buildCountDisplay(context, 'Tails', _tailsCount, Colors.blueGrey.shade700),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountDisplay(BuildContext context, String label, int count, Color color) {
    return Column(
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
        ),
        Text(
          '$count',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

class CoinPainter extends CustomPainter {
  final double animationValue;
  final bool isHeads;
  final bool isSimulating;

  CoinPainter({
    required this.animationValue,
    required this.isHeads,
    required this.isSimulating,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = min(centerX, centerY) * 0.9;

    double scaleX = cos(animationValue * pi);

    final String faceText = isHeads ? "H" : "T";
    final Color primaryFaceColor = isHeads ? Colors.amber[300]! : Colors.blueGrey[200]!;
    final Color secondaryFaceColor = isHeads ? Colors.amber[600]! : Colors.blueGrey[500]!;
    final Color edgeColor = Colors.grey[500]!;
    final Color textColor = Colors.black.withOpacity(0.75);


    if (!isSimulating && animationValue == 0.0) {
      paint.shader = RadialGradient(
        colors: [Colors.green[300]!, Colors.green[600]!],
         center: Alignment.center, radius: 0.7
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius));
      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
      
      TextPainter checkPainter = TextPainter(
        text: TextSpan(text: '✔', style: TextStyle(fontSize: radius * 0.7, color: Colors.white, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      );
      checkPainter.layout();
      checkPainter.paint(canvas, Offset(centerX - checkPainter.width / 2, centerY - checkPainter.height / 2));
      return;
    }

    if (scaleX.abs() < 0.08) { 
      paint.color = edgeColor;
      paint.style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(centerX, centerY), width: radius * 2 * 0.07, height: radius * 1.95),
          Radius.circular(radius * 0.07)
        ),
        paint
      );
    } else {
      paint.shader = RadialGradient(
        colors: [primaryFaceColor, secondaryFaceColor],
        stops: const [0.3, 1.0],
        center: Alignment.center, radius: 0.7
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius));
      
      canvas.save();
      canvas.translate(centerX, centerY);
      canvas.scale(scaleX.abs(), 1.0);
      canvas.translate(-centerX, -centerY);

      Path circlePath = Path()..addOval(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius));
      canvas.drawPath(circlePath, paint);
      
      Paint rimPaint = Paint()
        ..color = secondaryFaceColor.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.06;
      canvas.drawCircle(Offset(centerX, centerY), radius * 0.92, rimPaint);

      if ((animationValue <= 0.5 && scaleX > 0.05) || (animationValue > 0.5 && scaleX < -0.05)) {
        TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: faceText,
            style: TextStyle(
              fontSize: radius * 0.85,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(centerX - textPainter.width / 2, centerY - textPainter.height / 2),
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CoinPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.isHeads != isHeads ||
           oldDelegate.isSimulating != isSimulating;
  }
}