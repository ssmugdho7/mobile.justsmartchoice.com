import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared brand asset used by the home screen, opening screen and drawer.
class LandingBrand extends StatelessWidget {
  const LandingBrand({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Smart Choice Contractors',
    image: true,
    child: ExcludeSemantics(
      child: Image.asset(
        'assets/brand/smart-choice-logo.png',
        width: 240,
        height: 115,
        fit: BoxFit.contain,
      ),
    ),
  );
}

class LandingBackground extends StatelessWidget {
  const LandingBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xff090a09), Color(0xff161715), Color(0xff080908)],
      ),
    ),
    child: CustomPaint(painter: _Texture(), child: child),
  );
}

class _Texture extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x06ffffff)
      ..strokeWidth = .5;
    for (double x = -size.height; x < size.width; x += 6) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Texture oldDelegate) => false;
}

class LandingPage extends StatelessWidget {
  const LandingPage({
    super.key,
    required this.onEmployee,
    required this.onClient,
    required this.onAppointment,
    required this.onContact,
    required this.onToolbox,
    required this.onShop,
    required this.onSettings,
  });
  final VoidCallback onEmployee,
      onClient,
      onAppointment,
      onContact,
      onToolbox,
      onShop,
      onSettings;
  @override
  Widget build(BuildContext context) => LandingBackground(
    child: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = math
              .min(constraints.maxWidth / 375, constraints.maxHeight / 700)
              .clamp(.9, 1.1);
          return Stack(
            fit: StackFit.expand,
            children: [
              SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        24 * scale,
                        56 * scale,
                        24 * scale,
                        24 * scale,
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 240 * scale,
                            height: 115 * scale,
                            child: const FittedBox(child: LandingBrand()),
                          ),
                          SizedBox(height: 28 * scale),
                          for (final (index, action)
                              in <(String, VoidCallback)>[
                                ('Employee Login', onEmployee),
                                ('Client Login', onClient),
                                ('Book an Appointment', onAppointment),
                                ('Contact Us', onContact),
                                ('Toolbox', onToolbox),
                                ('Shop', onShop),
                              ].indexed)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: index == 5 ? 0 : 12,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(9),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xffff880b),
                                      Color(0xffaa4300),
                                    ],
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x20ff880b),
                                      blurRadius: 18,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: action.$2,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(double.infinity, 52),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14 * scale,
                                      vertical: 14,
                                    ),
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    textStyle: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: Text(
                                    action.$1,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 12,
                child: IconButton.filled(
                  tooltip: 'App settings',
                  onPressed: onSettings,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xff2b2c2a),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.settings, size: 20),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
