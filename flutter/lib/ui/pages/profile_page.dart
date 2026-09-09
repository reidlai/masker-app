import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../organisms/profile_form.dart';

/// Settings edit host for the medical profile. The form itself lives in
/// [ProfileForm] (shared with the onboarding wizard's Medical Profile step);
/// this page only supplies the Settings chrome — an AppBar with a tick that
/// drives the form's `save()` through a [GlobalKey].
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalKey<ProfileFormState> _formKey = GlobalKey<ProfileFormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Medical Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.accentGreen),
            onPressed: () => _formKey.currentState?.save(),
          ),
        ],
      ),
      body: SafeArea(child: ProfileForm(key: _formKey)),
    );
  }
}
