import 'package:flutter/material.dart';
import 'package:vidsnap/core/constants/colors.dart';

/// Animated splash screen with a polished, multi-stage animation.
///
/// Animation sequence:
///   1. Background gradient fades in (0–300ms)
///   2. App icon scales up + fades in with bounce (200–900ms)
///   3. "VidSnap" name slides up + fades in (600–1100ms)
///   4. Tagline fades in (900–1300ms)
///   5. Loading indicator fades in (1200–1500ms)
///   6. Hold briefly, then call onComplete (1800ms)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _masterController;
  late final Animation<double> _bgFade;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _nameFade;
  late final Animation<double> _taglineFade;
  late final Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();

    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Background fade: 0 → 0.17 (0–300ms)
    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.17, curve: Curves.easeOut),
      ),
    );

    // Icon scale: 0.11 → 0.50 (200–900ms) with bounce
    _iconScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.11, 0.50, curve: Curves.easeOutBack),
      ),
    );

    // Icon fade: 0.11 → 0.33 (200–600ms)
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.11, 0.33, curve: Curves.easeIn),
      ),
    );

    // Name slide up: 0.33 → 0.61 (600–1100ms)
    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.33, 0.61, curve: Curves.easeOutCubic),
      ),
    );

    // Name fade: 0.33 → 0.55 (600–1000ms)
    _nameFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.33, 0.55, curve: Curves.easeIn),
      ),
    );

    // Tagline fade: 0.50 → 0.72 (900–1300ms)
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.50, 0.72, curve: Curves.easeIn),
      ),
    );

    // Loader fade: 0.67 → 0.83 (1200–1500ms)
    _loaderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.67, 0.83, curve: Curves.easeIn),
      ),
    );

    _masterController.forward();

    // Complete after the full animation + a brief hold.
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _masterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _masterController,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        VidSnapColors.bgDark.withValues(alpha: _bgFade.value),
                        Color.lerp(
                          VidSnapColors.bgDark,
                          VidSnapColors.surfaceDark,
                          _bgFade.value * 0.5,
                        )!,
                      ]
                    : [
                        VidSnapColors.bgLight.withValues(alpha: _bgFade.value),
                        Color.lerp(
                          VidSnapColors.bgLight,
                          VidSnapColors.surfaceLight,
                          _bgFade.value * 0.5,
                        )!,
                      ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App icon with glow
                    Opacity(
                      opacity: _iconFade.value,
                      child: Transform.scale(
                        scale: _iconScale.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: VidSnapColors.accent
                                    .withValues(alpha: 0.4 * _iconFade.value),
                                blurRadius: 30,
                                spreadRadius: 2,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset(
                              'assets/icons/app_icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // App name
                    SlideTransition(
                      position: _nameSlide,
                      child: FadeTransition(
                        opacity: _nameFade,
                        child: Text(
                          'VidSnap',
                          style: TextStyle(
                            color: isDark
                                ? VidSnapColors.textOnDark
                                : VidSnapColors.textOnLight,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Tagline
                    FadeTransition(
                      opacity: _taglineFade,
                      child: Text(
                        'Download any video, fast',
                        style: TextStyle(
                          color: VidSnapColors.muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    // Loading indicator
                    FadeTransition(
                      opacity: _loaderFade,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          strokeCap: StrokeCap.round,
                          color: VidSnapColors.accent.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
