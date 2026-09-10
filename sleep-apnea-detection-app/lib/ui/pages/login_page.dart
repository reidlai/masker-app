import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc/auth/auth_bloc.dart';
import '../../core/bloc/auth/auth_event.dart';
import '../../core/bloc/auth/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../organisms/brand_header_organism.dart';
import '../organisms/passkey_auth_card_organism.dart';
import '../organisms/security_badge_organism.dart';

class LoginPage extends StatelessWidget {
  final VoidCallback onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          onLoginSuccess();
        }
      },
      builder: (context, state) {
        final isAuthenticating = state is AuthInProgress;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Brand Header Organism
                  const BrandHeaderOrganism(),
                  const Spacer(),
                  // Passkey Auth Card Organism
                  PasskeyAuthCardOrganism(
                    isAuthenticating: isAuthenticating,
                    onAuthenticate: () {
                      context.read<AuthBloc>().add(const AuthPasskeySubmitted());
                    },
                  ),
                  // Non-success outcomes surface directly under the button that
                  // triggered them. AuthUnavailable = "not wired yet" (amber,
                  // not a fault); AuthFailure = a real authenticator error (red).
                  if (state is AuthUnavailable || state is AuthFailure) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        state is AuthUnavailable
                            ? state.message
                            : (state as AuthFailure).errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: state is AuthUnavailable
                              ? AppColors.warningAmber
                              : AppColors.dangerRed,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Security Badge Organism
                  const SecurityBadgeOrganism(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
