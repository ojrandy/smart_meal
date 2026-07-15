import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to onboarding after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF188241), // Top left green
              Color(0xFF289A45), // Middle green
              Color(0xFF86B93F), // Bottom right yellowish green
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center glow behind logo
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      blurRadius: 100,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), duration: 2.seconds)
               .fade(begin: 0.5, end: 1.0, duration: 2.seconds),
            ),
            
            // Main Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                
                // Logo
                Image.asset(
                  'assets/images/app logo.png',
                  width: 140,
                  height: 140,
                ).animate()
                 .fade(duration: 800.ms)
                 .scale(duration: 800.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: 16),
                
                // SmartMeal AI Text
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1.5,
                    ),
                    children: const [
                      TextSpan(
                        text: 'SmartMeal ',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: 'AI',
                        style: TextStyle(color: Color(0xFFFF6B00)), // Vibrant orange matching logo
                      ),
                    ],
                  ),
                ).animate().fade(delay: 400.ms, duration: 600.ms).slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
                
                const SizedBox(height: 12),
                
                // Subtitle
                Text(
                  'AI POWERED FOOD COMPANION',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fade(delay: 600.ms, duration: 600.ms),
                
                const SizedBox(height: 50),
                
                // 3 Dots Loading Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                    ).animate(onPlay: (controller) => controller.repeat())
                     .fadeIn(duration: 400.ms, delay: (index * 200).ms)
                     .fadeOut(duration: 400.ms, delay: ((index * 200) + 400).ms);
                  }),
                ).animate().fade(delay: 1000.ms),
                
                const Spacer(flex: 2),
                
                // Bottom Text
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 2,
                    ),
                    children: const [
                      TextSpan(
                        text: 'BY OJ ',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: 'TECH',
                        style: TextStyle(color: Color(0xFFFF6B00)), 
                      ),
                    ],
                  ),
                ).animate().fade(delay: 800.ms),
                
                const SizedBox(height: 48),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
