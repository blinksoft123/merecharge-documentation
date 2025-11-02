import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../widgets/simple_splash.dart';

class SplashScreen extends StatefulWidget {
  final bool useSimpleVersion;
  
  const SplashScreen({super.key, this.useSimpleVersion = true});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _fadeController;
  
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _backgroundFadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
    _navigateAfterDelay();
  }

  void _initializeAnimations() {
    // Animation du logo (scale + rotation)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Animation du texte
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Animation de fade out
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Logo scale animation avec bounce
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Logo rotation légère
    _logoRotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    ));

    // Animation du texte (slide up)
    _textSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    // Animation fade du texte
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));

    // Animation de fade out globale
    _backgroundFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
  }

  void _startAnimationSequence() async {
    // Démarrer l'animation du logo
    _logoController.forward();
    
    // Attendre un peu puis démarrer l'animation du texte
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();
  }

  void _navigateAfterDelay() async {
    // Attendre 3 secondes au total
    await Future.delayed(const Duration(milliseconds: 3000));
    
    // Commencer le fade out
    await _fadeController.forward();
    
    if (!mounted) return;
    
    // Vérifier l'état d'authentification
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si la version simple est demandée, l'utiliser directement
    if (widget.useSimpleVersion) {
      return SimpleSplash(
        onComplete: () {
          if (!mounted) return;
          
          // Vérifier l'état d'authentification
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.home);
          } else {
            Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
          }
        },
      );
    }
    
    // Version complexe avec animations multiples
    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          return Opacity(
            opacity: _backgroundFadeAnimation.value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                    AppColors.white,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  
                  // Logo animé
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScaleAnimation.value,
                        child: Transform.rotate(
                          angle: _logoRotationAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Nom de l'app animé
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _textSlideAnimation.value),
                        child: Opacity(
                          opacity: _textFadeAnimation.value,
                          child: Column(
                            children: [
                              Text(
                                'Merecharge',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rechargez en toute simplicité',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const Spacer(flex: 2),
                  
                  // Indicateur de chargement
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textFadeAnimation.value,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 60),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const Spacer(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}