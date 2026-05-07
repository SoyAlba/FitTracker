// lib/screens/diet/food_search_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/models.dart';

class FoodSearchScreen extends StatefulWidget {
  final String mealId;
  final Function(MealItem) onAdd;
  const FoodSearchScreen({super.key, required this.mealId, required this.onAdd});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _searchCtrl = TextEditingController();
  List<_FoodResult> _results = [];
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar alimento')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ej: pollo, arroz, leche...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search_rounded),
                        onPressed: _search,
                      ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (_results.isEmpty && !_loading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔍', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    Text(
                      'Busca un alimento\npor nombre o marca',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => _showManualEntry(context),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Añadir manualmente'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _results.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == _results.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: OutlinedButton.icon(
                        onPressed: () => _showManualEntry(context),
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('No encuentro lo que busco — añadir manualmente'),
                      ),
                    );
                  }
                  final food = _results[i];
                  return _FoodResultCard(
                    food: food,
                    onAdd: (qty, unit) {
                      final factor = qty / 100;
                      widget.onAdd(MealItem(
                        mealId: widget.mealId,
                        foodName: food.name,
                        quantity: qty,
                        unit: unit,
                        calories: (food.caloriesPer100 * factor).round(),
                        protein: food.proteinPer100 != null ? food.proteinPer100! * factor : null,
                        carbs: food.carbsPer100 != null ? food.carbsPer100! * factor : null,
                        fat: food.fatPer100 != null ? food.fatPer100! * factor : null,
                      ));
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _error = null; _results = []; });

    // Intento 1: OpenFoodFacts (tiene productos españoles y europeos)
    try {
      final url = Uri.parse(
        'https://world.openfoodfacts.org/cgi/search.pl'
        '?search_terms=${Uri.encodeComponent(q)}'
        '&search_simple=1&action=process&json=1&page_size=20'
        '&fields=product_name,brands,nutriments,quantity'
        '&lc=es',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'FitTracker/1.0 (Android)',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = data['products'] as List? ?? [];
        final results = <_FoodResult>[];
        for (final p in products) {
          final name = (p['product_name'] ?? '').toString().trim();
          if (name.isEmpty) continue;
          final n = p['nutriments'] ?? {};
          final cal = _toDouble(n['energy-kcal_100g'] ?? n['energy-kcal'] ?? 0);
          if (cal <= 0) continue;
          results.add(_FoodResult(
            name: name,
            brand: (p['brands'] ?? '').toString().trim(),
            caloriesPer100: cal,
            proteinPer100: _toDouble(n['proteins_100g']),
            carbsPer100: _toDouble(n['carbohydrates_100g']),
            fatPer100: _toDouble(n['fat_100g']),
          ));
        }
        if (results.isNotEmpty) {
          setState(() { _results = results; _loading = false; });
          return;
        }
      }
    } catch (_) {}

    // Intento 2: API USDA FoodData Central (muy fiable, sin key para búsquedas básicas)
    try {
      final url = Uri.parse(
        'https://api.nal.usda.gov/fdc/v1/foods/search'
        '?query=${Uri.encodeComponent(q)}'
        '&pageSize=20'
        '&api_key=DEMO_KEY',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final foods = data['foods'] as List? ?? [];
        final results = <_FoodResult>[];
        for (final f in foods) {
          final name = (f['description'] ?? '').toString().trim();
          if (name.isEmpty) continue;
          final nutrients = (f['foodNutrients'] as List? ?? []);
          double cal = 0, protein = 0, carbs = 0, fat = 0;
          for (final n in nutrients) {
            final id = n['nutrientId'] ?? n['nutrientNumber'];
            final val = _toDouble(n['value']);
            switch (id.toString()) {
              case '1008': case '208': cal = val;
              case '1003': case '203': protein = val;
              case '1005': case '205': carbs = val;
              case '1004': case '204': fat = val;
            }
          }
          if (cal <= 0) continue;
          results.add(_FoodResult(
            name: name,
            brand: (f['brandOwner'] ?? f['brandName'] ?? '').toString().trim(),
            caloriesPer100: cal,
            proteinPer100: protein > 0 ? protein : null,
            carbsPer100: carbs > 0 ? carbs : null,
            fatPer100: fat > 0 ? fat : null,
          ));
        }
        setState(() { _results = results; _loading = false; });
        if (results.isEmpty) setState(() => _error = 'Sin resultados. Prueba con otro nombre o añade manualmente.');
        return;
      }
    } catch (_) {}

    // Ambas APIs fallaron
    setState(() {
      _loading = false;
      _error = 'Sin conexión a internet o las APIs no responden.\nUsa la entrada manual.';
    });
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  void _showManualEntry(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ManualFoodEntry(
        mealId: widget.mealId,
        onAdd: (item) {
          widget.onAdd(item);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}

class _FoodResult {
  final String name;
  final String brand;
  final double caloriesPer100;
  final double? proteinPer100;
  final double? carbsPer100;
  final double? fatPer100;

  _FoodResult({
    required this.name,
    required this.brand,
    required this.caloriesPer100,
    this.proteinPer100,
    this.carbsPer100,
    this.fatPer100,
  });
}

class _FoodResultCard extends StatefulWidget {
  final _FoodResult food;
  final Function(double qty, String unit) onAdd;
  const _FoodResultCard({required this.food, required this.onAdd});

  @override
  State<_FoodResultCard> createState() => _FoodResultCardState();
}

class _FoodResultCardState extends State<_FoodResultCard> {
  double _qty = 100;

  @override
  Widget build(BuildContext context) {
    final f = widget.food;
    final factor = _qty / 100;
    final cal = (f.caloriesPer100 * factor).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      if (f.brand.isNotEmpty)
                        Text(f.brand,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$cal kcal',
                      style: const TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (f.proteinPer100 != null)
                  _MacroBadge('P', (f.proteinPer100! * factor).toStringAsFixed(1), Colors.red),
                if (f.carbsPer100 != null)
                  _MacroBadge('C', (f.carbsPer100! * factor).toStringAsFixed(1), Colors.amber),
                if (f.fatPer100 != null)
                  _MacroBadge('G', (f.fatPer100! * factor).toStringAsFixed(1), Colors.green),
                const Text(' por ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                Text('${_qty.toStringAsFixed(0)}g',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _qty,
                    min: 10,
                    max: 500,
                    divisions: 49,
                    label: '${_qty.toStringAsFixed(0)}g',
                    onChanged: (v) => setState(() => _qty = v),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => widget.onAdd(_qty, 'g'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Text('Añadir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroBadge(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
        child: Text('$label:${value}g',
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      );
}

class _ManualFoodEntry extends StatefulWidget {
  final String mealId;
  final Function(MealItem) onAdd;
  const _ManualFoodEntry({required this.mealId, required this.onAdd});

  @override
  State<_ManualFoodEntry> createState() => _ManualFoodEntryState();
}

class _ManualFoodEntryState extends State<_ManualFoodEntry> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '100');
  final _unitCtrl = TextEditingController(text: 'g');
  final _calCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const Text('Añadir manualmente',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Alimento *')),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _unitCtrl,
                decoration: const InputDecoration(labelText: 'Unidad'))),
          ]),
          const SizedBox(height: 8),
          TextField(controller: _calCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calorías *')),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _proteinCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Proteína (g)'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _carbsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Carbos (g)'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _fatCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Grasas (g)'))),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_nameCtrl.text.isEmpty || _calCtrl.text.isEmpty) return;
                widget.onAdd(MealItem(
                  mealId: widget.mealId,
                  foodName: _nameCtrl.text.trim(),
                  quantity: double.tryParse(_qtyCtrl.text) ?? 100,
                  unit: _unitCtrl.text.isEmpty ? 'g' : _unitCtrl.text,
                  calories: int.tryParse(_calCtrl.text) ?? 0,
                  protein: double.tryParse(_proteinCtrl.text),
                  carbs: double.tryParse(_carbsCtrl.text),
                  fat: double.tryParse(_fatCtrl.text),
                ));
              },
              child: const Text('Añadir'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _qtyCtrl, _unitCtrl, _calCtrl, _proteinCtrl, _carbsCtrl, _fatCtrl]) {
      c.dispose();
    }
    super.dispose();
  }
}