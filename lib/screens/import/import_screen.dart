// lib/screens/import/import_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar / Exportar'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: '📥 Importar'),
            Tab(text: '📤 Exportar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _ImportTab(),
          _ExportTab(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }
}

// ── IMPORT TAB ────────────────────────────────────────────────────────────────

class _ImportTab extends StatefulWidget {
  @override
  State<_ImportTab> createState() => _ImportTabState();
}

class _ImportTabState extends State<_ImportTab> {
  final _jsonCtrl = TextEditingController();
  String? _error;
  String? _success;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prompt para IA
          Card(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('🤖', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text('Generar con IA',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Copia el prompt de abajo, pégalo en ChatGPT o Claude, '
                    'describe tu dieta o rutina y pega aquí el JSON que te devuelva.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PromptButton(
                          icon: '🍽️',
                          label: 'Prompt Dieta',
                          onTap: () => _showPrompt(context, _dietPrompt),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PromptButton(
                          icon: '🏋️',
                          label: 'Prompt Rutinas',
                          onTap: () => _showPrompt(context, _routinePrompt),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // JSON input
          const Text('Pegar JSON aquí',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _jsonCtrl,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: '{\n  "meals": [...],\n  "routines": [...]\n}',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () => setState(() {
                  _jsonCtrl.clear();
                  _error = null;
                  _success = null;
                }),
              ),
            ),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          const SizedBox(height: 8),

          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),

          if (_success != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(_success!,
                  style: const TextStyle(color: Colors.green, fontSize: 13)),
            ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : () => _import(provider),
              icon: _loading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download_rounded),
              label: Text(_loading ? 'Importando...' : 'Importar JSON'),
            ),
          ),
          const SizedBox(height: 24),

          // Format reference
          _FormatReference(),
        ],
      ),
    );
  }

  void _showPrompt(BuildContext context, String prompt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Prompt para IA',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: prompt));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Copiado al portapapeles')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copiar'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(prompt,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _import(AppProvider provider) async {
    final raw = _jsonCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Pega un JSON primero');
      return;
    }
    setState(() { _loading = true; _error = null; _success = null; });

    try {
      // Try to extract JSON from markdown code blocks if present
      String jsonStr = raw;
      final codeMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(raw);
      if (codeMatch != null) jsonStr = codeMatch.group(1)!.trim();

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      int mealsImported = 0;
      int routinesImported = 0;

      // Import meals
      if (data.containsKey('meals')) {
        final meals = data['meals'] as List;
        for (final m in meals) {
          final items = <MealItem>[];
          if (m['items'] != null) {
            for (final item in (m['items'] as List)) {
              items.add(MealItem(
                mealId: 'import',
                foodName: item['foodName']?.toString() ?? item['nombre']?.toString() ?? '',
                quantity: _toDouble(item['quantity'] ?? item['cantidad'] ?? 100),
                unit: item['unit']?.toString() ?? item['unidad']?.toString() ?? 'g',
                calories: _toInt(item['calories'] ?? item['calorias'] ?? 0),
                protein: _toDoubleNull(item['protein'] ?? item['proteina']),
                carbs: _toDoubleNull(item['carbs'] ?? item['carbohidratos']),
                fat: _toDoubleNull(item['fat'] ?? item['grasas']),
              ));
            }
          }
          final meal = Meal(
            name: m['name']?.toString() ?? m['nombre']?.toString() ?? 'Comida importada',
            mealType: _parseMealType(m['mealType'] ?? m['tipo'] ?? 'lunch'),
            dayOfWeek: _toInt(m['dayOfWeek'] ?? m['dia'] ?? 1),
            items: items,
          );
          await provider.addMeal(meal);
          mealsImported++;
        }
      }

      // Import routines
      if (data.containsKey('routines') || data.containsKey('rutinas')) {
        final routines = (data['routines'] ?? data['rutinas']) as List;
        for (final r in routines) {
          final exercises = <Exercise>[];
          final exList = (r['exercises'] ?? r['ejercicios']) as List? ?? [];
          for (int i = 0; i < exList.length; i++) {
            final e = exList[i];
            exercises.add(Exercise(
              routineId: 'import',
              name: e['name']?.toString() ?? e['nombre']?.toString() ?? 'Ejercicio',
              sets: _toInt(e['sets'] ?? e['series'] ?? 3),
              reps: _toInt(e['reps'] ?? e['repeticiones'] ?? 10),
              weight: _toDouble(e['weight'] ?? e['peso'] ?? 0),
              notes: e['notes']?.toString() ?? e['notas']?.toString(),
              orderIndex: i,
            ));
          }
          final routine = Routine(
            name: r['name']?.toString() ?? r['nombre']?.toString() ?? 'Rutina importada',
            dayOfWeek: _parseDayOfWeek(r['dayOfWeek'] ?? r['dia'] ?? 1),
            exercises: exercises,
          );
          await provider.addRoutine(routine);
          routinesImported++;
        }
      }

      setState(() {
        _loading = false;
        _success = '✅ Importado: $mealsImported comidas, $routinesImported rutinas';
        _jsonCtrl.clear();
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'JSON inválido: $e\n\nAsegúrate de copiar el JSON completo que devuelve la IA.';
      });
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  double? _toDoubleNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  int _toInt(dynamic v) => _toDouble(v).round();

  String _parseMealType(dynamic v) {
    final s = v.toString().toLowerCase();
    if (s.contains('desayuno') || s.contains('breakfast')) return 'breakfast';
    if (s.contains('almuerzo') || s.contains('brunch')) return 'brunch';
    if (s.contains('cena') || s.contains('dinner')) return 'dinner';
    if (s.contains('merienda') || s.contains('snack')) return 'snack';
    return 'lunch';
  }

  int _parseDayOfWeek(dynamic v) {
    if (v is int) return v.clamp(1, 7);
    final s = v.toString().toLowerCase();
    const days = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    final i = days.indexWhere((d) => s.contains(d));
    return i >= 0 ? i + 1 : int.tryParse(s)?.clamp(1, 7) ?? 1;
  }

  static const _dietPrompt = '''Necesito que me generes un JSON con mi plan de dieta semanal.

DESCRIBE TU DIETA AQUÍ (reemplaza este texto):
Ejemplo: "Quiero una dieta de 2000 kcal para ganar músculo. Desayuno avena con leche y fruta. Almuerzo pollo con arroz. Cena verduras con proteína..."

El JSON debe tener EXACTAMENTE este formato:
{
  "meals": [
    {
      "name": "Desayuno",
      "mealType": "breakfast",
      "dayOfWeek": 1,
      "items": [
        {
          "foodName": "Avena",
          "quantity": 80,
          "unit": "g",
          "calories": 300,
          "protein": 10,
          "carbs": 54,
          "fat": 6
        }
      ]
    }
  ]
}

REGLAS:
- mealType debe ser: breakfast, brunch, lunch, snack o dinner
- dayOfWeek: 1=Lunes, 2=Martes, ..., 7=Domingo
- quantity y unit son la cantidad real del alimento
- calories, protein, carbs, fat son para esa cantidad (no por 100g)
- Devuelve SOLO el JSON, sin explicaciones ni markdown''';

  static const _routinePrompt = '''Necesito que me generes un JSON con mis rutinas de gym.

DESCRIBE TUS RUTINAS AQUÍ (reemplaza este texto):
Ejemplo: "Entreno 4 días. Lunes pecho y tríceps: press banca, aperturas, fondos. Martes espalda y bíceps: dominadas, remo, curl..."

El JSON debe tener EXACTAMENTE este formato:
{
  "routines": [
    {
      "name": "Pecho y Tríceps",
      "dayOfWeek": 1,
      "exercises": [
        {
          "name": "Press banca",
          "sets": 4,
          "reps": 10,
          "weight": 60,
          "notes": "Agarre medio"
        }
      ]
    }
  ]
}

REGLAS:
- dayOfWeek: 1=Lunes, 2=Martes, ..., 7=Domingo
- weight en kg (pon 0 si no sabes el peso)
- sets y reps son números enteros
- notes es opcional
- Devuelve SOLO el JSON, sin explicaciones ni markdown''';

  @override
  void dispose() {
    _jsonCtrl.dispose();
    super.dispose();
  }
}

class _PromptButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  const _PromptButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text('$icon $label', style: const TextStyle(fontSize: 13)),
      );
}

class _FormatReference extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Ver formato JSON de referencia',
          style: TextStyle(fontSize: 13, color: Colors.grey)),
      children: [
        Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '// Puedes incluir meals, routines o ambos\n'
            '{\n'
            '  "meals": [{\n'
            '    "name": "Nombre comida",\n'
            '    "mealType": "breakfast|lunch|dinner|snack",\n'
            '    "dayOfWeek": 1,  // 1=Lunes...7=Domingo\n'
            '    "items": [{\n'
            '      "foodName": "Alimento",\n'
            '      "quantity": 100,\n'
            '      "unit": "g",\n'
            '      "calories": 200,\n'
            '      "protein": 20,\n'
            '      "carbs": 15,\n'
            '      "fat": 5\n'
            '    }]\n'
            '  }],\n'
            '  "routines": [{\n'
            '    "name": "Pecho",\n'
            '    "dayOfWeek": 1,\n'
            '    "exercises": [{\n'
            '      "name": "Press banca",\n'
            '      "sets": 4,\n'
            '      "reps": 10,\n'
            '      "weight": 60\n'
            '    }]\n'
            '  }]\n'
            '}',
            style: TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ),
      ],
    );
  }
}

// ── EXPORT TAB ────────────────────────────────────────────────────────────────

class _ExportTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exporta tus datos para hacer copia de seguridad o importarlos en otro dispositivo.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _ExportCard(
            icon: '🍽️',
            title: 'Exportar dieta',
            subtitle: '${provider.meals.length} comidas configuradas',
            onExport: () => _exportAndCopy(context, _exportMeals(provider)),
          ),
          const SizedBox(height: 12),
          _ExportCard(
            icon: '🏋️',
            title: 'Exportar rutinas',
            subtitle: '${provider.routines.length} rutinas configuradas',
            onExport: () => _exportAndCopy(context, _exportRoutines(provider)),
          ),
          const SizedBox(height: 12),
          _ExportCard(
            icon: '📦',
            title: 'Exportar todo',
            subtitle: 'Dieta + rutinas juntas',
            onExport: () => _exportAndCopy(context, _exportAll(provider)),
          ),
        ],
      ),
    );
  }

  String _exportMeals(AppProvider provider) {
    final meals = provider.meals.map((m) => {
      'name': m.name,
      'mealType': m.mealType,
      'dayOfWeek': m.dayOfWeek,
      'items': m.items.map((i) => {
        'foodName': i.foodName,
        'quantity': i.quantity,
        'unit': i.unit,
        'calories': i.calories,
        if (i.protein != null) 'protein': i.protein,
        if (i.carbs != null) 'carbs': i.carbs,
        if (i.fat != null) 'fat': i.fat,
      }).toList(),
    }).toList();
    return const JsonEncoder.withIndent('  ').convert({'meals': meals});
  }

  String _exportRoutines(AppProvider provider) {
    final routines = provider.routines.map((r) => {
      'name': r.name,
      'dayOfWeek': r.dayOfWeek,
      'exercises': r.exercises.map((e) => {
        'name': e.name,
        'sets': e.sets,
        'reps': e.reps,
        'weight': e.weight,
        if (e.notes != null) 'notes': e.notes,
      }).toList(),
    }).toList();
    return const JsonEncoder.withIndent('  ').convert({'routines': routines});
  }

  String _exportAll(AppProvider provider) {
    final meals = jsonDecode(_exportMeals(provider))['meals'];
    final routines = jsonDecode(_exportRoutines(provider))['routines'];
    return const JsonEncoder.withIndent('  ').convert({
      'meals': meals,
      'routines': routines,
    });
  }

  void _exportAndCopy(BuildContext context, String json) {
    Clipboard.setData(ClipboardData(text: json));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('✅ Copiado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('JSON copiado al portapapeles. Puedes pegarlo en un archivo de texto o enviártelo.'),
            const SizedBox(height: 12),
            Container(
              height: 150,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: SingleChildScrollView(
                child: Text(json.length > 500 ? '${json.substring(0, 500)}...' : json,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onExport;

  const _ExportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Text(icon, style: const TextStyle(fontSize: 28)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          trailing: ElevatedButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copiar JSON'),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          ),
        ),
      );
}