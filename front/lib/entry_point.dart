import 'package:Telnet/screens/addUser/adduserscreentwo.dart';
import 'package:Telnet/screens/onbording/dashboard_admin.dart';
import 'package:Telnet/services/token_service.dart';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:Telnet/constants.dart';
import 'package:Telnet/route/screen_export.dart';

class EntryPoint extends StatefulWidget {
  final String? userId;
  final String? userRole;
  final String? viewOnlyProject;
  const EntryPoint({
    super.key,
    required this.userId,
    required this.userRole,
    this.viewOnlyProject,
  });

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  int _currentIndex = 1;
  bool _showUserCard = false;

  List<Widget> get _pages {
    final viewOnlyProject = widget.viewOnlyProject;
    print('Building pages with viewOnlyProject: $viewOnlyProject');

    switch (widget.userRole) {
      case 'PM':
        return [
          ProfileScreen(userId: widget.userId, userRole: widget.userRole),
          OnBordingScreen(
            userId: widget.userId,
            userRole: widget.userRole,
            viewOnlyProject: widget.viewOnlyProject,
          ),
          AddScreen(userId: widget.userId),
        ];
      case 'RF':
        return [
          ProfileScreen(userId: widget.userId, userRole: widget.userRole),
          OnBordingScreen(
            userId: widget.userId,
            userRole: widget.userRole,
            viewOnlyProject: widget.viewOnlyProject,
          ),
          AddUserScreen(userId: widget.userId),
        ];
      case 'Admin':
        return [
          ProfileScreen(userId: widget.userId, userRole: widget.userRole),

          //OnBordingScreenTwo(userId: widget.userId, userRole: widget.userRole),
          MainScreen(),
          AddUserScreenTwo(userId: widget.userId, userRole: widget.userRole),
        ];
      default:
        return [
          ProfileScreen(userId: widget.userId, userRole: widget.userRole),
          OnBordingScreen(userId: widget.userId, userRole: widget.userRole),
        ];
    }
  }

  void _handleAddButtonPressed() {
    setState(() {
      _currentIndex = 2;
      _showUserCard = true;
    });
  }

  @override
  void initState() {
    super.initState();
    print(
      'EntryPoint - viewOnlyProject: ${widget.viewOnlyProject}',
    ); // Debug ici
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkResetStatus();
    });
  }

  Future<void> _checkResetStatus() async {
    final authService = AuthService();
    final requiresReset = await authService.checkPasswordResetStatus();
    if (requiresReset && mounted) {
      Navigator.pushNamed(
        context,
        forcedProfileUpdateRoute,
        arguments: {'userId': widget.userId, 'userRole': widget.userRole},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800;

    SvgPicture svgIcon(String src, {Color? color}) {
      return SvgPicture.asset(
        src,
        height: 24,
        colorFilter: ColorFilter.mode(
          color ?? Theme.of(context).iconTheme.color!,
          BlendMode.srcIn,
        ),
      );
    }

    if (isLargeScreen) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 200,
              color:
                  Theme.of(context).brightness == Brightness.light
                      ? Colors.white
                      : const Color(0xFF101015),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec logo
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/logotelnet.png',
                          width: 55,
                          height: 55,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Text(
                            'Telnet',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Séparateur après l'en-tête
                  const SizedBox(height: 35),

                  // Éléments de navigation
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSideNavButton(
                          icon: "assets/icons/Category.svg",
                          label: "Suivi opérations",
                          index: 1,
                        ),
                        const SizedBox(height: 28),
                        if (_pages.length > 2)
                          _buildSideNavButton(
                            icon: "assets/icons/Edit-Bold.svg",
                            label: "Collaborateurs",
                            index: 2,
                            onTap: _handleAddButtonPressed,
                          ),
                        const SizedBox(height: 28),
                        _buildSideNavButton(
                          icon: "assets/icons/Profile.svg",
                          label: "Préférences",
                          index: 0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.grey.withOpacity(0.2),
            ),
            Expanded(
              child: PageTransitionSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation, secondaryAnimation) {
                  return FadeThroughTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    child: child,
                  );
                },
                child: _pages[_currentIndex],
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: PageTransitionSwitcher(
          duration: defaultDuration,
          transitionBuilder: (child, animation, secondaryAnimation) {
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          child: _pages[_currentIndex],
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          color:
              Theme.of(context).brightness == Brightness.light
                  ? Colors.white
                  : const Color(0xFF101015),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed:
                    () => setState(() {
                      _currentIndex = 0;
                      _showUserCard = false;
                    }),
                icon: svgIcon(
                  "assets/icons/Profile.svg",
                  color:
                      _currentIndex == 0
                          ? const Color.fromRGBO(123, 97, 255, 1)
                          : null,
                ),
              ),
              const SizedBox(width: 40),
              if (_pages.length > 2)
                IconButton(
                  onPressed: _handleAddButtonPressed,
                  icon: svgIcon(
                    "assets/icons/Edit-Bold.svg",
                    color: _currentIndex == 2 ? primaryColor : null,
                  ),
                ),
            ],
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: FloatingActionButton(
            onPressed:
                () => setState(() {
                  _currentIndex = 1;
                  _showUserCard = false;
                }),
            backgroundColor: const Color.fromRGBO(123, 97, 255, 1),
            elevation: 0.0,
            child: svgIcon("assets/icons/Category.svg", color: Colors.white),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );
    }
  }

  Widget _buildSideNavButton({
    required String icon,
    required String label,
    required int index,
    VoidCallback? onTap,
  }) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap:
          onTap ??
          () {
            setState(() {
              _currentIndex = index;
            });
          },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              width: 26,
              height: 26,
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).brightness == Brightness.light
                      ? Colors.black.withOpacity(0.7)
                      : Colors.white.withOpacity(0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).brightness == Brightness.light
                          ? Colors.black.withOpacity(0.7)
                          : Colors.white.withOpacity(0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
