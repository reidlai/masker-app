import 'package:flutter/material.dart';
import '../../core/permissions/ble_permission_service.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/app_button.dart';

/// `MOB_BLE_PERMISSION_PRIMER` — one-time onboarding screen shown after login
/// and before the tab shell, gated live on permission status by the caller
/// (never a persisted "seen it" flag). Hands off to the native OS Bluetooth
/// permission dialog(s).
///
/// Has exactly one CTA and no skip/decline path: whatever the OS dialog
/// result (granted, denied, partial, or permanently denied), tapping it
/// always advances past the primer — it never re-blocks itself. Recovery
/// from a denial happens downstream, on `MeasurementPage`'s blocked state.
class BlePermissionPrimerPage extends StatefulWidget {
  final VoidCallback onPrimed;
  final BlePermissionService? permissionService;

  const BlePermissionPrimerPage({
    super.key,
    required this.onPrimed,
    this.permissionService,
  });

  @override
  State<BlePermissionPrimerPage> createState() => _BlePermissionPrimerPageState();
}

class _BlePermissionPrimerPageState extends State<BlePermissionPrimerPage> {
  late final BlePermissionService _permissionService;
  bool _isRequesting = false;
  final FocusNode _headlineFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _permissionService = widget.permissionService ?? const BlePermissionService();
    // Screen-reader "explore by touch" can land anywhere first — request
    // initial accessibility focus on the rationale so it's announced before
    // the CTA, regardless of where the user first touches.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _headlineFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _headlineFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleAllowTap() async {
    if (_isRequesting) return;
    setState(() {
      _isRequesting = true;
    });

    try {
      await _permissionService.requestPermission();
    } catch (_) {
      // Ignored — whatever the OS dialog result or any error requesting it,
      // the primer never re-blocks itself, so there is nothing more to do
      // here than let `finally` advance below.
    } finally {
      // Whatever the OS dialog result (or any error requesting it), the
      // primer never re-blocks itself — it always advances.
      widget.onPrimed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentGreen.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.accentGreen, width: 2),
                ),
                child: Semantics(
                  excludeSemantics: true,
                  child: const Icon(Icons.bluetooth, color: AppColors.accentGreen, size: 40),
                ),
              ),
              const SizedBox(height: 16),
              Focus(
                focusNode: _headlineFocusNode,
                child: const Text(
                  "Bluetooth Access Needed",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "To find your D-BAND sensor and keep monitoring active overnight, allow Bluetooth access.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const Spacer(),
              AppButton(
                label: "Allow Bluetooth Access",
                isLoading: _isRequesting,
                variant: AppButtonVariant.primary,
                icon: const Icon(Icons.bluetooth, color: Colors.white),
                onPressed: _handleAllowTap,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
