import 'package:flutter/material.dart';

class CustomPageRoute extends PageRouteBuilder {
  final Widget page;

  CustomPageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: Duration(milliseconds: 1000),
        reverseTransitionDuration: Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var enterCurve = Curves.fastOutSlowIn;
          var slideTween = Tween<Offset>(
            begin: Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: enterCurve));

          // élastique
          var scaleTween = Tween<double>(begin: 0.7, end: 1.0).chain(
            CurveTween(curve: Interval(0.0, 0.7, curve: Curves.elasticOut)),
          );

          // rotation
          var rotateTween = Tween<double>(
            begin: 0.05,
            end: 0.0,
          ).chain(CurveTween(curve: enterCurve));

          // 4. Opacité
          var opacityTween = Tween<double>(begin: 0.0, end: 1.0);

          // Combinaison ta3 les animation
          var slideAnimation = animation.drive(slideTween);
          var scaleAnimation = animation.drive(scaleTween);
          var rotateAnimation = animation.drive(rotateTween);
          var opacityAnimation = animation.drive(opacityTween);

          // Animation  page li9dima
          var exitTween = Tween<double>(begin: 1.0, end: 0.9);
          var exitAnimation = secondaryAnimation.drive(exitTween);

          return Stack(
            children: [
              // page li9dima
              Transform.scale(
                scale: exitAnimation.value,
                child: Opacity(
                  opacity: exitAnimation.value * 0.7,
                  child: child,
                ),
              ),

              //page jdida
              SlideTransition(
                position: slideAnimation,
                child: FadeTransition(
                  opacity: opacityAnimation,
                  child: Transform.scale(
                    scale: scaleAnimation.value,
                    child: Transform.rotate(
                      angle: rotateAnimation.value,
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
}
