import 'package:flutter/material.dart';

class DailyAyahHomeWidget extends StatelessWidget {
  final int streak;
  final int ayahsRead;

  const DailyAyahHomeWidget({
    super.key,
    required this.streak,
    required this.ayahsRead,
  });

  @override
  Widget build(BuildContext context) {
    // Divine Theme Colors
    const Color primary = Color(0xFF1B5E20); // Deep Islamic Green
    const Color secondary = Color(0xFF2E7D32); // Rich Green
    const Color gold = Color(0xFFD4AF37); // Metallic Gold

    return Container(
      width: 320, // Standard-ish widget width
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary,
            secondary,
            Color(0xFF0F3D12), // Darker shade for depth
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gold.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Circles (Subtle background details)
          Positioned(
            top: -20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            right: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold.withOpacity(0.1),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Streak Section
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: gold,
                        size: 38,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$streak',
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 46,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Day Streak',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical Divider
                Container(
                  width: 2,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.05),
                        gold.withOpacity(0.6),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),

                // Ayahs Section
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        color: gold,
                        size: 36,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$ayahsRead',
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 46,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ayahs Read',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
