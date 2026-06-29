import 'package:flutter/material.dart';

class DecoratedCircles extends StatelessWidget {
  final Color color;
  final AlignmentGeometry mainAlignment;

  const DecoratedCircles({
    super.key,
    this.color = const Color(0x334B39EF),
    this.mainAlignment = const AlignmentDirectional(-1, -1),
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mainAlignment,
      child: Container(
        width: 190,
        height: 190,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(95),
        ),
        alignment: const AlignmentDirectional(0.8, 0.3),
        child: Align(
          alignment: const AlignmentDirectional(-0.99, -0.96),
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(90),
            ),
            alignment: const AlignmentDirectional(0.8, 0.3),
            child: Align(
              alignment: const AlignmentDirectional(-0.74, -0.93),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(75),
                ),
                alignment: const AlignmentDirectional(0.8, 0.3),
                child: Align(
                  alignment: const AlignmentDirectional(-0.44, -0.86),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    alignment: const AlignmentDirectional(0.8, 0.3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
