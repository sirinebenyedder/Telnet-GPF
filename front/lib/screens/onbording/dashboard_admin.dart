import 'package:Telnet/screens/onbording/widgets/dashboard_widget.dart';
import 'package:Telnet/screens/onbording/widgets/responsive.dart';
import 'package:Telnet/screens/onbording/widgets/side_menu_widget.dart';
import 'package:Telnet/screens/onbording/widgets/summary_widget.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop) Expanded(flex: 7, child: DashboardWidget()),
          ],
        ),
      ),
    );
  }
}
