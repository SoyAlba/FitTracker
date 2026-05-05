// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';
import 'screens/home/home_screen.dart';
import 'screens/routines/routines_screen.dart';
import 'screens/weight/weight_screen.dart';
import 'screens/diet/diet_screen.dart';
import 'screens/reminders/reminders_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/import/import_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: const FitTrackerApp(),
    ),
  );
}

class FitTrackerApp extends StatelessWidget {
  const FitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return MaterialApp(
      title: 'FitTracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: provider.themeMode,
      routes: {'/home': (_) => const MainNavigation()},
      home: provider.onboardingDone
          ? const MainNavigation()
          : const OnboardingScreen(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Diagnóstico completo al arrancar
    final hasNotif = await NotificationService.instance.hasNotificationPermission();
    final canExact = await NotificationService.instance.canScheduleExactAlarms();
    debugPrint('🔍 DIAGNÓSTICO NOTIFICACIONES:');
    debugPrint('  - Permiso notificaciones: $hasNotif');
    debugPrint('  - Puede alarmas exactas: $canExact');
    debugPrint('  - Canal Kotlin: com.example.fittracker/permissions');

    if (!hasNotif) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('🔔 Activar notificaciones'),
          content: const Text(
            'FitTracker necesita permiso para enviarte recordatorios de gym, agua, suplementos y pesaje.\n\n'
            'Sin este permiso las alarmas no sonarán.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ahora no'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Activar'),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        await NotificationService.instance.requestNotificationPermission();
      }
    }

    if (!canExact && mounted) {
      debugPrint('⚠️ Sin permiso de alarmas exactas — abriendo ajustes');
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('⏰ Permiso necesario'),
          content: const Text(
            'Para que los recordatorios suenen a la hora exacta, necesitas activar "Alarmas y recordatorios" para FitTracker.\n\nSe abrirán los ajustes del sistema.'
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await NotificationService.instance.openExactAlarmSettings();
              },
              child: const Text('Abrir ajustes'),
            ),
          ],
        ),
      );
    }
  }

  static const _pages = [
    HomeScreen(),
    RoutinesScreen(),
    WeightScreen(),
    DietScreen(),
    RemindersScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center_rounded), label: 'Rutinas'),
          NavigationDestination(icon: Icon(Icons.monitor_weight_outlined),
              selectedIcon: Icon(Icons.monitor_weight_rounded), label: 'Peso'),
          NavigationDestination(icon: Icon(Icons.restaurant_outlined),
              selectedIcon: Icon(Icons.restaurant_rounded), label: 'Dieta'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications_rounded), label: 'Alarmas'),
          NavigationDestination(icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded), label: 'Ajustes'),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              mini: true,
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ImportExportScreen())),
              tooltip: 'Importar / Exportar',
              child: const Icon(Icons.download_rounded),
            )
          : null,
    );
  }
}