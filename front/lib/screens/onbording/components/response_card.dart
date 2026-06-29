import 'package:flutter/material.dart';

class ConfirmationCard extends StatelessWidget {
  final bool isSuccess;
  final String message;

  const ConfirmationCard({
    super.key,
    required this.isSuccess,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 50,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color:
                      isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
