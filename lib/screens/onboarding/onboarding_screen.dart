// lib/screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String _gender = 'female';
  String _goal = 'lose';
  String _activity = 'moderate';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8, height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? AppTheme.primaryColor : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  _WelcomePage(onNext: _next),
                  _BasicInfoPage(nameCtrl: _nameCtrl, ageCtrl: _ageCtrl,
                      gender: _gender, onGenderChanged: (v) => setState(() => _gender = v), onNext: _next),
                  _BodyPage(heightCtrl: _heightCtrl, weightCtrl: _weightCtrl, onNext: _next),
                  _GoalPage(goal: _goal, activity: _activity,
                      onGoalChanged: (v) => setState(() => _goal = v),
                      onActivityChanged: (v) => setState(() => _activity = v),
                      onFinish: _finish),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _next() => _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);

  Future<void> _finish() async {
    final provider = context.read<AppProvider>();
    final profile = UserProfile(
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text),
      height: double.tryParse(_heightCtrl.text),
      gender: _gender, goal: _goal, activityLevel: _activity,
    );
    await provider.saveProfile(profile);
    final weight = double.tryParse(_weightCtrl.text);
    if (weight != null) {
      await provider.addWeightEntry(WeightEntry(date: DateTime.now(), weight: weight));
    }
    await provider.completeOnboarding();
    if (mounted) Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose(); _ageCtrl.dispose();
    _heightCtrl.dispose(); _weightCtrl.dispose();
    super.dispose();
  }
}

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 120, height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppTheme.primaryColor, Color(0xFF7B61FF)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(30)),
        child: const Center(child: Text('💪', style: TextStyle(fontSize: 56)))),
      const SizedBox(height: 32),
      const Text('Bienvenida a\nFitTracker', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Text('Tu app de fitness personal.\nSolo 1 minuto para configurarla.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5)),
      const SizedBox(height: 48),
      SizedBox(width: double.infinity,
        child: ElevatedButton(onPressed: onNext,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: const Text('Empezar →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
    ]),
  );
}

class _BasicInfoPage extends StatelessWidget {
  final TextEditingController nameCtrl, ageCtrl;
  final String gender;
  final Function(String) onGenderChanged;
  final VoidCallback onNext;
  const _BasicInfoPage({required this.nameCtrl, required this.ageCtrl,
      required this.gender, required this.onGenderChanged, required this.onNext});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(32),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('¿Cómo te llamas?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Cuéntanos sobre ti', style: TextStyle(color: Colors.grey.shade500)),
      const SizedBox(height: 32),
      TextField(controller: nameCtrl, autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Tu nombre', prefixIcon: Icon(Icons.person_rounded))),
      const SizedBox(height: 16),
      TextField(controller: ageCtrl, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Edad', prefixIcon: Icon(Icons.cake_rounded))),
      const SizedBox(height: 24),
      const Text('Sexo', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Row(children: [
        _GenderBtn(icon: '👩', label: 'Mujer', selected: gender == 'female',
            onTap: () => onGenderChanged('female')),
        const SizedBox(width: 12),
        _GenderBtn(icon: '👨', label: 'Hombre', selected: gender == 'male',
            onTap: () => onGenderChanged('male')),
      ]),
      const SizedBox(height: 40),
      SizedBox(width: double.infinity,
        child: ElevatedButton(onPressed: onNext,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: const Text('Siguiente →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
    ]),
  );
}

class _GenderBtn extends StatelessWidget {
  final String icon, label;
  final bool selected;
  final VoidCallback onTap;
  const _GenderBtn({required this.icon, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(onTap: onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppTheme.primaryColor : Colors.grey.shade200, width: 2)),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600)),
        ]))),
  );
}

class _BodyPage extends StatelessWidget {
  final TextEditingController heightCtrl, weightCtrl;
  final VoidCallback onNext;
  const _BodyPage({required this.heightCtrl, required this.weightCtrl, required this.onNext});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(32),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Tu cuerpo', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Para calcular tus calorías recomendadas', style: TextStyle(color: Colors.grey.shade500)),
      const SizedBox(height: 32),
      TextField(controller: heightCtrl, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Altura (cm)',
              prefixIcon: Icon(Icons.height_rounded), suffixText: 'cm')),
      const SizedBox(height: 16),
      TextField(controller: weightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Peso actual (kg)',
              prefixIcon: Icon(Icons.monitor_weight_outlined), suffixText: 'kg')),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text('Tu peso inicial se guardará automáticamente',
              style: TextStyle(color: Colors.blue.shade700, fontSize: 13))),
        ])),
      const SizedBox(height: 40),
      SizedBox(width: double.infinity,
        child: ElevatedButton(onPressed: onNext,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: const Text('Siguiente →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
    ]),
  );
}

class _GoalPage extends StatelessWidget {
  final String goal, activity;
  final Function(String) onGoalChanged, onActivityChanged;
  final VoidCallback onFinish;
  const _GoalPage({required this.goal, required this.activity,
      required this.onGoalChanged, required this.onActivityChanged, required this.onFinish});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(32),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Tu objetivo', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Ajustará tus calorías diarias recomendadas', style: TextStyle(color: Colors.grey.shade500)),
      const SizedBox(height: 24),
      _GoalCard(value: 'lose', icon: '🔥', title: 'Perder peso', subtitle: 'Déficit calórico',
          selected: goal == 'lose', onTap: () => onGoalChanged('lose')),
      _GoalCard(value: 'maintain', icon: '⚖️', title: 'Mantener peso', subtitle: 'Calorías de mantenimiento',
          selected: goal == 'maintain', onTap: () => onGoalChanged('maintain')),
      _GoalCard(value: 'gain', icon: '💪', title: 'Ganar músculo', subtitle: 'Superávit calórico',
          selected: goal == 'gain', onTap: () => onGoalChanged('gain')),
      const SizedBox(height: 20),
      const Text('Nivel de actividad', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: activity,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.directions_run_rounded)),
        items: const [
          DropdownMenuItem(value: 'sedentary', child: Text('Sedentario (sin ejercicio)')),
          DropdownMenuItem(value: 'light', child: Text('Ligero (1-2 días/semana)')),
          DropdownMenuItem(value: 'moderate', child: Text('Moderado (3-4 días/semana)')),
          DropdownMenuItem(value: 'active', child: Text('Activo (5+ días/semana)')),
          DropdownMenuItem(value: 'very_active', child: Text('Muy activo (2 veces/día)')),
        ],
        onChanged: (v) => onActivityChanged(v!),
      ),
      const SizedBox(height: 40),
      SizedBox(width: double.infinity,
        child: ElevatedButton(onPressed: onFinish,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: const Text('¡Empezar! ✓',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)))),
    ]),
  );
}

class _GoalCard extends StatelessWidget {
  final String value, icon, title, subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _GoalCard({required this.value, required this.icon, required this.title,
      required this.subtitle, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primaryColor.withOpacity(0.08) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? AppTheme.primaryColor : Colors.grey.shade200,
            width: selected ? 2 : 1)),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ])),
        if (selected) const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor),
      ])),
  );
}