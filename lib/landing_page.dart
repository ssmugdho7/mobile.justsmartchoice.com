import 'package:flutter/material.dart';

/// Rebuilt as scalable artwork so the supplied menu stays sharp on any device.
class LandingBrand extends StatelessWidget {
  const LandingBrand({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Smart Choice Contractors',
    image: true,
    child: ExcludeSemantics(
      child: SizedBox(
        width: 206,
        height: 106,
        child: Column(
          children: [
            SizedBox(
              width: 184,
              height: 47,
              child: CustomPaint(painter: _Roof()),
            ),
            const FittedBox(
              child: Text(
                'Smart Choice',
                style: TextStyle(
                  fontFamily: 'LandingSerif',
                  fontWeight: FontWeight.bold,
                  fontSize: 34,
                  height: 1,
                  color: Color(0xffdddddd),
                ),
              ),
            ),
            const Row(
              children: [
                Expanded(
                  child: Divider(color: Color(0xff008b75), thickness: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'CONTRACTORS',
                  style: TextStyle(
                    fontFamily: 'LandingSerif',
                    fontSize: 11,
                    color: Color(0xffdddddd),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _Roof extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 184, size.height / 47);
    final paint = Paint()..color = const Color(0xff008b75);
    canvas.drawPath(
      Path()
        ..moveTo(5, 44)
        ..lineTo(67, 1)
        ..lineTo(82, 6)
        ..lineTo(82, 21)
        ..lineTo(116, 9)
        ..lineTo(177, 43)
        ..lineTo(116, 17)
        ..lineTo(61, 43)
        ..lineTo(61, 22)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_Roof oldDelegate) => false;
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
          final compact = constraints.maxHeight < 650;
          return Stack(
            fit: StackFit.expand,
            children: [
              SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        28,
                        compact ? 40 : 58,
                        28,
                        22,
                      ),
                      child: Column(
                        children: [
                          const LandingBrand(),
                          SizedBox(height: compact ? 28 : 44),
                          for (final action in <(String, VoidCallback)>[
                            ('Employee Login', onEmployee),
                            ('Client Login', onClient),
                            ('Book an Appointment', onAppointment),
                            ('Contact Us', onContact),
                            ('Toolbox', onToolbox),
                            ('Shop', onShop),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
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
                                    minimumSize: const Size(
                                      double.infinity,
                                      52,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 16,
                                    ),
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    textStyle: const TextStyle(
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
