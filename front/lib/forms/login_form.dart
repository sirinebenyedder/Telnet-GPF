import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../constants.dart';

/*class LogInForm extends StatelessWidget {
  const LogInForm({super.key, required this.formKey});

  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            onSaved: (emal) {
              // Email
            },
            validator: emaildValidator.call,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "Email address",
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: defaultPadding * 0.75,
                ),
                child: SvgPicture.asset(
                  "assets/icons/Message.svg",
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    Theme.of(
                      context,
                    ).textTheme.bodyLarge!.color!.withOpacity(0.3),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: defaultPadding),
          TextFormField(
            onSaved: (pass) {
              // Password
            },
            validator: passwordValidator.call,
            obscureText: true,
            decoration: InputDecoration(
              hintText: "Password",
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: defaultPadding * 0.75,
                ),
                child: SvgPicture.asset(
                  "assets/icons/Lock.svg",
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    Theme.of(
                      context,
                    ).textTheme.bodyLarge!.color!.withOpacity(0.3),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/
import 'package:flutter/material.dart';
import '../theme/login_theme.dart'; // Ajustez le chemin selon votre structure

class LoginForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final FormFieldValidator<String>? emailValidator;
  final FormFieldValidator<String>? passwordValidator;
  //
  final bool obscurePassword; // Nouveau paramètre
  final VoidCallback togglePasswordVisibility; // Nouveau paramètre
  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    this.emailValidator,
    this.passwordValidator,
    //obsecure
    required this.obscurePassword,
    required this.togglePasswordVisibility,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          TextFormField(
            controller: widget.emailController,
            focusNode: widget.emailFocusNode,
            obscureText: false,
            decoration: InputDecoration(
              labelText: 'Adresse email',
              labelStyle: loginTheme.textTheme.bodySmall,
              hintText: 'Entrer votre adresse email',
              hintStyle: loginTheme.textTheme.bodySmall,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: loginTheme.colorScheme.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF1F4F8), width: 2),
                borderRadius: BorderRadius.circular(40),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF1F4F8), width: 2),
                borderRadius: BorderRadius.circular(40),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF1F4F8), width: 2),
                borderRadius: BorderRadius.circular(40),
              ),
              filled: true,
              fillColor: loginTheme.scaffoldBackgroundColor,
              contentPadding: EdgeInsetsDirectional.fromSTEB(16, 24, 0, 24),
            ),
            style: loginTheme.textTheme.bodyMedium,
            validator: widget.emailValidator,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: widget.passwordController,
            focusNode: widget.passwordFocusNode,
            obscureText: widget.obscurePassword,
            //obscureText: true,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              labelStyle: loginTheme.textTheme.bodySmall,
              hintText: 'Entrer votre mot de passe',
              hintStyle: loginTheme.textTheme.bodySmall,
              suffixIcon: IconButton(
                icon: Icon(
                  widget.obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed:
                    widget
                        .togglePasswordVisibility, // Appel de la fonction pour basculer
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: loginTheme.colorScheme.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF1F4F8), width: 2),
                borderRadius: BorderRadius.circular(40),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF1F4F8), width: 2),
                borderRadius: BorderRadius.circular(40),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF1F4F8), width: 2),
                borderRadius: BorderRadius.circular(40),
              ),
              filled: true,
              fillColor: loginTheme.scaffoldBackgroundColor,
              contentPadding: EdgeInsetsDirectional.fromSTEB(16, 24, 0, 24),
            ),
            style: loginTheme.textTheme.bodyMedium,
            validator: widget.passwordValidator,
          ),
        ],
      ),
    );
  }
}
