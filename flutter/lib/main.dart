import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/ble/ble_receiver_service.dart';
import 'core/bloc/auth/auth_bloc.dart';
import 'core/theme/app_theme.dart';
import 'ui/pages/login_page.dart';
import 'ui/pages/main_container_page.dart';

void main() {
  // Ensure the Flutter Engine C++ bridge and native platform channels (BLE/MethodChannels)
  // are fully initialized before running background services or async setup prior to runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // Instantiate and boot the background BLE receiver service singleton on app launch.
  // This starts listening to physical BLE hardware / simulation drivers and exposes a central
  // RxDart BehaviorSubject<double> reactive stream for downstream calibration & sleep monitoring.
  BleReceiverService();

  runApp(const MaskerApp());
}

class MaskerApp extends StatefulWidget {
  const MaskerApp({super.key});

  @override
  State<MaskerApp> createState() => _MaskerAppState();
}

class _MaskerAppState extends State<MaskerApp> {
  bool _isLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => AuthBloc(),
      child: MaterialApp(
        title: 'Sleep Apnea Detection App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: _isLoggedIn
            ? const MainContainerPage()
            : LoginPage(
                onLoginSuccess: () {
                  setState(() {
                    _isLoggedIn = true;
                  });
                },
              ),
      ),
    );
  }
}
