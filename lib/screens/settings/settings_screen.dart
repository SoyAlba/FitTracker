// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Perfil'),
            Tab(text: 'App'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _ProfileTab(),
          _AppSettingsTab(),
        ],
      ),
    );
  }
}

// ── PERFIL ────────────────────────────────────────────────────────────────────

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();
  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  String _gender = 'female';
  String _goal = 'maintain';
  String _activityLevel = 'moderate';
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    if (!_initialized) {
      _nameCtrl.text = provider.profile.name ?? '';
      _ageCtrl.text = provider.profile.age?.toString() ?? '';
      _heightCtrl.text = provider.profile.height?.toString() ?? '';
      _gender = provider.profile.gender ?? 'female';
      _goal = provider.profile.goal ?? 'maintain';
      _activityLevel = provider.profile.activityLevel ?? 'moderate';
      _initialized = true;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
              labelText: 'Nombre', prefixIcon: Icon(Icons.person_rounded)),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(
            controller: _ageCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Edad'),
          )),
          const SizedBox(width: 12),
          Expanded(child: TextField(
            controller: _heightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Altura (cm)'),
          )),
        ]),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _gender,
          decoration: const InputDecoration(labelText: 'Sexo'),
          items: const [
            DropdownMenuItem(value: 'female', child: Text('Femenino')),
            DropdownMenuItem(value: 'male', child: Text('Masculino')),
            DropdownMenuItem(value: 'other', child: Text('Otro')),
          ],
          onChanged: (v) => setState(() => _gender = v!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _goal,
          decoration: const InputDecoration(labelText: 'Objetivo'),
          items: const [
            DropdownMenuItem(value: 'lose', child: Text('Perder peso')),
            DropdownMenuItem(value: 'maintain', child: Text('Mantenimiento')),
            DropdownMenuItem(value: 'gain', child: Text('Ganar músculo')),
          ],
          onChanged: (v) => setState(() => _goal = v!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _activityLevel,
          decoration: const InputDecoration(labelText: 'Nivel de actividad'),
          items: const [
            DropdownMenuItem(value: 'sedentary', child: Text('Sedentario')),
            DropdownMenuItem(value: 'light', child: Text('Ligero')),
            DropdownMenuItem(value: 'moderate', child: Text('Moderado')),
            DropdownMenuItem(value: 'active', child: Text('Activo')),
            DropdownMenuItem(value: 'very_active', child: Text('Muy activo')),
          ],
          onChanged: (v) => setState(() => _activityLevel = v!),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              provider.saveProfile(UserProfile(
                name: _nameCtrl.text.isEmpty ? null : _nameCtrl.text,
                age: int.tryParse(_ageCtrl.text),
                height: double.tryParse(_heightCtrl.text),
                gender: _gender,
                goal: _goal,
                activityLevel: _activityLevel,
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Perfil guardado'),
                    backgroundColor: Colors.green),
              );
            },
            icon: const Icon(Icons.save_rounded),
            label: const Text('Guardar perfil'),
          ),
        ),
      ]),
    );
  }
}

// ── APP SETTINGS ──────────────────────────────────────────────────────────────

class _AppSettingsTab extends StatefulWidget {
  const _AppSettingsTab();
  @override
  State<_AppSettingsTab> createState() => _AppSettingsTabState();
}

class _AppSettingsTabState extends State<_AppSettingsTab> {
  int _waterGoal = 2000;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    _waterGoal = provider.waterGoalMl;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        // ── Apariencia ────────────────────────────────────────────────────
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Apariencia',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _ThemeButton(
                icon: Icons.wb_sunny_rounded, label: 'Claro',
                selected: provider.themeMode == ThemeMode.light,
                onTap: () => provider.setThemeMode(ThemeMode.light),
              ),
              _ThemeButton(
                icon: Icons.dark_mode_rounded, label: 'Oscuro',
                selected: provider.themeMode == ThemeMode.dark,
                onTap: () => provider.setThemeMode(ThemeMode.dark),
              ),
              _ThemeButton(
                icon: Icons.settings_suggest_rounded, label: 'Auto',
                selected: provider.themeMode == ThemeMode.system,
                onTap: () => provider.setThemeMode(ThemeMode.system),
              ),
            ]),
          ]),
        )),

        const SizedBox(height: 16),

        // ── Objetivo de agua ──────────────────────────────────────────────
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Objetivo de agua',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(children: [
              Text('$_waterGoal ml',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Expanded(child: Slider(
                value: _waterGoal.toDouble(),
                min: 500, max: 5000, divisions: 18,
                label: '${_waterGoal}ml',
                onChanged: (v) {
                  setState(() => _waterGoal = v.round());
                  provider.setWaterGoal(v.round());
                },
              )),
            ]),
          ]),
        )),

        const SizedBox(height: 16),

        // ── Notificaciones ────────────────────────────────────────────────
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Notificaciones',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Configura las alarmas en la pestaña Recordatorios 🔔',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_off_rounded, color: Colors.red),
              title: const Text('Cancelar todas las alarmas',
                  style: TextStyle(color: Colors.red)),
              subtitle: const Text('Elimina todas las notificaciones programadas'),
              onTap: () async {
                await NotificationService.instance.cancelAllNotifications();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🔕 Notificaciones canceladas')),
                  );
                }
              },
            ),
          ]),
        )),

        const SizedBox(height: 16),

        // ── Borrar datos ──────────────────────────────────────────────────
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Borrar datos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Estas acciones no se pueden deshacer',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 8),
            _DeleteTile(
              icon: '🍽️', label: 'Borrar todas las comidas',
              onConfirm: () => provider.clearMeals(),
            ),
            _DeleteTile(
              icon: '⚖️', label: 'Borrar historial de peso',
              onConfirm: () => provider.clearWeightEntries(),
            ),
            _DeleteTile(
              icon: '🏋️', label: 'Borrar todas las rutinas',
              onConfirm: () => provider.clearRoutines(),
            ),
            _DeleteTile(
              icon: '🔔', label: 'Borrar todos los recordatorios',
              onConfirm: () async {
                await provider.clearReminders();
                await NotificationService.instance.cancelAllNotifications();
              },
            ),
            const Divider(height: 24),
            _DeleteTile(
              icon: '💣', label: 'BORRAR TODOS LOS DATOS',
              isDestructive: true,
              onConfirm: () async {
                await provider.clearAllData();
                await NotificationService.instance.cancelAllNotifications();
              },
            ),
          ]),
        )),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ── WIDGETS ───────────────────────────────────────────────────────────────────

class _ThemeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(icon, color: selected ? Colors.white : Colors.grey, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            color: selected ? Colors.white : Colors.grey,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          )),
        ]),
      ),
    );
  }
}

class _DeleteTile extends StatelessWidget {
  final String icon, label;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const _DeleteTile({
    required this.icon,
    required this.label,
    required this.onConfirm,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Text(icon, style: const TextStyle(fontSize: 20)),
    title: Text(label, style: TextStyle(
      color: isDestructive ? Colors.red : Colors.red.shade700,
      fontWeight: isDestructive ? FontWeight.bold : FontWeight.normal,
      fontSize: isDestructive ? 14 : 13,
    )),
    trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
    onTap: () => showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$icon $label'),
        content: Text(isDestructive
            ? '¿Segura? Se borrarán TODOS los datos. Esta acción no tiene vuelta atrás.'
            : '¿Segura que quieres borrar estos datos? No se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$icon Datos borrados')),
              );
            },
            child: const Text('Borrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}