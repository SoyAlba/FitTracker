// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../progress/progress_screen.dart';

const _dayNames = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final today = DateTime.now();
    final dayName = _dayNames[today.weekday];
    final name = provider.profile.name;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name != null ? 'Hola, $name 👋' : 'Hola 👋',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('$dayName · ${today.day}/${today.month}/${today.year}',
                      style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, Color(0xFF7B61FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // 1. Agua — siempre arriba
                _WaterCard(provider: provider),
                const SizedBox(height: 16),

                // 2. Calorías y proteína del día
                _CalorieGoalCard(provider: provider),
                const SizedBox(height: 16),

                // 3. Stats rápidos (peso, entrenos, racha)
                _QuickStatsRow(provider: provider),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── AGUA ─────────────────────────────────────────────────────────────────────

class _WaterCard extends StatelessWidget {
  final AppProvider provider;
  const _WaterCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final pct = (provider.todayWaterMl / provider.waterGoalMl).clamp(0.0, 1.0);
    final done = provider.todayWaterMl >= provider.waterGoalMl;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('💧', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            const Text('Agua', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            Text(_waterLabel(provider.todayWaterMl, provider.waterGoalMl),
                style: TextStyle(
                    color: done ? Colors.blue : Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: done ? FontWeight.bold : FontWeight.normal)),
            if (done) ...[
              const SizedBox(width: 4),
              const Text('✅', style: TextStyle(fontSize: 12)),
            ],
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: Colors.blue.shade50,
              valueColor: AlwaysStoppedAnimation(done ? Colors.blue : Colors.blue.shade300),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _WaterButton(ml: 250,  label: '250ml', onTap: provider.addWater),
              _WaterButton(ml: 330,  label: '330ml', onTap: provider.addWater),
              _WaterButton(ml: 500,  label: '½L',    onTap: provider.addWater),
              _WaterButton(ml: 1000, label: '1L',    onTap: provider.addWater),
            ],
          ),
        ]),
      ),
    );
  }

  String _waterLabel(int current, int goal) {
    String fmt(int ml) => ml >= 1000
        ? '${(ml / 1000).toStringAsFixed(ml % 1000 == 0 ? 0 : 1)}L'
        : '${ml}ml';
    return '${fmt(current)} / ${fmt(goal)}';
  }
}

class _WaterButton extends StatelessWidget {
  final int ml;
  final String label;
  final void Function(int) onTap;
  const _WaterButton({required this.ml, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: () => onTap(ml),
    style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        side: const BorderSide(color: Colors.blue)),
    child: Text('+$label', style: const TextStyle(fontSize: 12, color: Colors.blue)),
  );
}

// ── CALORÍAS ──────────────────────────────────────────────────────────────────

class _CalorieGoalCard extends StatelessWidget {
  final AppProvider provider;
  const _CalorieGoalCard({required this.provider});

  void _showEditor(BuildContext context) {
    final kcalCtrl = TextEditingController(
        text: provider.dailyCalorieGoal?.toString() ?? '');
    final protCtrl = TextEditingController(
        text: provider.dailyProteinGoal?.toString() ?? '');
    final isCustom = provider.profile.customCalorieGoal != null ||
        provider.profile.customProteinGoal != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const Text('Objetivo diario', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Déjalo en blanco para usar el cálculo automático',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 16),
          TextField(
            controller: kcalCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Calorías (kcal)',
              hintText: 'Ej: 2000',
              prefixIcon: Icon(Icons.local_fire_department_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: protCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Proteína (g)',
              hintText: 'Ej: 150',
              prefixIcon: Icon(Icons.fitness_center_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            if (isCustom) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    provider.profile.customCalorieGoal = null;
                    provider.profile.customProteinGoal = null;
                    provider.saveProfile(provider.profile);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Usar automático'),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final kcal = int.tryParse(kcalCtrl.text.trim());
                  final prot = int.tryParse(protCtrl.text.trim());
                  provider.profile.customCalorieGoal = kcal;
                  provider.profile.customProteinGoal = prot;
                  provider.saveProfile(provider.profile);
                  Navigator.pop(ctx);
                },
                child: const Text('Guardar'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kcalGoal = provider.dailyCalorieGoal;
    final kcalToday = provider.todayCalories;
    final protGoal = provider.dailyProteinGoal;
    final protToday = provider.todayProtein;
    final isCustom = provider.profile.customCalorieGoal != null;

    if (kcalGoal == null) {
      return Card(
        color: AppTheme.primaryColor.withOpacity(0.05),
        child: ListTile(
          leading: const Text('🎯', style: TextStyle(fontSize: 24)),
          title: const Text('Configura tu objetivo calórico',
              style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text(
            'Toca el lápiz para introducirlo manualmente, o rellena tu perfil en Ajustes para el cálculo automático.',
          ),
          isThreeLine: true,
          trailing: IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
            onPressed: () => _showEditor(context),
          ),
        ),
      );
    }

    final remaining = kcalGoal - kcalToday;
    final isOver = remaining < 0;
    final kcalPct = (kcalToday / kcalGoal).clamp(0.0, 1.0);
    final protPct = protGoal != null ? (protToday / protGoal).clamp(0.0, 1.0) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('🎯', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            const Text('Objetivo de hoy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(width: 4),
            if (!isCustom)
              const Tooltip(
                message: 'Calculado con Harris-Benedict:\n'
                    'tu edad, altura, peso actual,\nnivel de actividad y objetivo.',
                triggerMode: TooltipTriggerMode.tap,
                child: Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
              ),
            if (isCustom)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('manual', style: TextStyle(fontSize: 10, color: AppTheme.primaryColor)),
              ),
            const Spacer(),
            // Botón editar
            GestureDetector(
              onTap: () => _showEditor(context),
              child: const Icon(Icons.edit_rounded, size: 16, color: Colors.grey),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOver ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isOver
                    ? '+${(-remaining)} kcal extra'
                    : remaining == 0 ? '¡Objetivo!' : '$remaining kcal restantes',
                style: TextStyle(
                    color: isOver ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          ]),
          const SizedBox(height: 14),

          // Barra calorías
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('$kcalToday',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                Text(' / $kcalGoal kcal',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: kcalPct, minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                      isOver ? Colors.red : Colors.orange),
                ),
              ),
            ])),
          ]),

          // Barra proteína
          if (protGoal != null) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('💪 ${protToday.toStringAsFixed(0)}g',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(' / ${protGoal}g proteína',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ]),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: protPct, minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(Colors.red),
                  ),
                ),
              ])),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ── QUICK STATS ───────────────────────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  final AppProvider provider;
  const _QuickStatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    final lastWeight = provider.lastWeightEntry;
    final workoutsThisWeek = provider.workoutsThisWeek;

    return Row(children: [
      _StatCard(
        icon: '⚖️',
        value: lastWeight != null ? '${lastWeight.weight} kg' : '—',
        label: 'Último peso',
        color: AppTheme.primaryColor,
      ),
      const SizedBox(width: 12),
      _StatCard(
        icon: '🏋️',
        value: '$workoutsThisWeek',
        label: 'Entrenos esta semana',
        color: Colors.green,
      ),
      const SizedBox(width: 12),
      _StatCard(
        icon: '🍽️',
        value: '${provider.todayCalories}',
        label: 'kcal hoy',
        color: Colors.orange,
      ),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String icon, value, label;
  final Color color;
  const _StatCard({
    required this.icon, required this.value,
    required this.label, required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(
            fontSize: 9, color: Colors.grey.shade500),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}