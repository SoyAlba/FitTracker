// lib/screens/diet/diet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import 'food_search_screen.dart';

const _days = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
];
const _mealTypes = ['Desayuno', 'Almuerzo', 'Comida', 'Merienda', 'Cena'];
const _mealTypeValues = ['breakfast', 'brunch', 'lunch', 'snack', 'dinner'];

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _selectedDay = DateTime.now().weekday;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dieta'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Menú semanal'),
            Tab(text: 'Lista compra'),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabCtrl,
        builder: (ctx, _) => _tabCtrl.index == 0
            ? FloatingActionButton.extended(
                onPressed: () => _showMealEditor(context, provider),
                icon: const Icon(Icons.add),
                label: const Text('Añadir comida'),
              )
            : FloatingActionButton.extended(
                onPressed: () {
                  provider.generateShoppingList();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('🛒 Lista generada'),
                        backgroundColor: Colors.green),
                  );
                },
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Generar lista'),
              ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _MenuTab(
            provider: provider,
            selectedDay: _selectedDay,
            onDayChanged: (d) => setState(() => _selectedDay = d),
            onEdit: (meal) => _showMealEditor(context, provider, meal: meal),
          ),
          _ShoppingTab(provider: provider),
        ],
      ),
    );
  }

  void _showMealEditor(BuildContext context, AppProvider provider,
      {Meal? meal}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) =>
          _MealEditorSheet(meal: meal, provider: provider, day: _selectedDay),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }
}

class _MenuTab extends StatelessWidget {
  final AppProvider provider;
  final int selectedDay;
  final Function(int) onDayChanged;
  final Function(Meal) onEdit;

  const _MenuTab({
    required this.provider,
    required this.selectedDay,
    required this.onDayChanged,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final dayMeals =
        provider.meals.where((m) => m.dayOfWeek == selectedDay).toList();
    final totalCals = dayMeals.fold(0, (s, m) => s + m.totalCalories);

    return Column(
      children: [
        // Day selector
        SizedBox(
          height: 56,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: 7,
            itemBuilder: (ctx, i) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(_days[i].substring(0, 2)),
                selected: selectedDay == i + 1,
                onSelected: (_) => onDayChanged(i + 1),
                selectedColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: selectedDay == i + 1 ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        // Calorie summary
        if (totalCals > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: Colors.orange, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$totalCals kcal totales',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.orange),
                ),
              ],
            ),
          ),

        Expanded(
          child: dayMeals.isEmpty
              ? Center(
                  child: Text(
                    'Sin comidas el ${_days[selectedDay - 1]}\nPulsa + para añadir',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: dayMeals.length,
                  itemBuilder: (ctx, i) => _MealCard(
                    meal: dayMeals[i],
                    onEdit: () => onEdit(dayMeals[i]),
                    onDelete: () => provider.deleteMeal(dayMeals[i].id),
                  ),
                ),
        ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MealCard(
      {required this.meal, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final typeIndex = _mealTypeValues.indexOf(meal.mealType);
    final typeName =
        typeIndex >= 0 ? _mealTypes[typeIndex] : meal.mealType;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(typeName,
                      style: const TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(meal.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600))),
                Text(
                  '${meal.totalCalories} kcal',
                  style: TextStyle(
                      color: Colors.orange.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_rounded,
                      size: 18, color: Colors.red),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            if (meal.items.isNotEmpty) ...[
              const Divider(height: 16),
              ...meal.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle,
                            size: 6, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(item.foodName,
                                style: const TextStyle(fontSize: 13))),
                        Text(
                          '${item.quantity}${item.unit} · ${item.calories}kcal',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
              _MacroBars(meal: meal),
            ],
          ],
        ),
      ),
    );
  }
}

class _MacroBars extends StatelessWidget {
  final Meal meal;
  const _MacroBars({required this.meal});

  @override
  Widget build(BuildContext context) {
    final p = meal.totalProtein;
    final c = meal.totalCarbs;
    final g = meal.totalFat;
    final total = p + c + g;
    if (total == 0) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _MacroBar(label: 'Proteína', value: p, total: total, color: Colors.red.shade400),
      const SizedBox(height: 5),
      _MacroBar(label: 'Carbos', value: c, total: total, color: Colors.amber.shade600),
      const SizedBox(height: 5),
      _MacroBar(label: 'Grasa', value: g, total: total, color: Colors.green.shade500),
    ]);
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double value, total;
  final Color color;
  const _MacroBar({required this.label, required this.value,
      required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = (value / total).clamp(0.0, 1.0);
    return Row(children: [
      SizedBox(width: 62,
          child: Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500))),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(width: 38,
          child: Text('${value.toStringAsFixed(0)}g',
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right)),
    ]);
  }
}

class _ShoppingTab extends StatelessWidget {
  final AppProvider provider;
  const _ShoppingTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.shoppingList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🛒', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Sin lista de compra\nPulsa "Generar lista" para crearla\nautomáticamente desde tus menús',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    final checked =
        provider.shoppingList.where((i) => i.isChecked).length;
    final total = provider.shoppingList.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total > 0 ? checked / total : 0,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation(Colors.green),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('$checked/$total',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 20),
                tooltip: 'Copiar lista',
                onPressed: () {
                  final lines = provider.shoppingList
                      .map((i) => '${i.isChecked ? '✓' : '☐'} ${i.itemName} — ${i.quantity.toStringAsFixed(0)} ${i.unit}')
                      .join('\n');
                  Clipboard.setData(ClipboardData(text: '🛒 Lista de la compra:\n$lines'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Lista copiada al portapapeles')));
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: provider.shoppingList.length,
            itemBuilder: (ctx, i) {
              final item = provider.shoppingList[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: CheckboxListTile(
                  value: item.isChecked,
                  onChanged: (_) =>
                      provider.toggleShoppingItem(item.id),
                  title: Text(
                    item.itemName,
                    style: TextStyle(
                      decoration: item.isChecked
                          ? TextDecoration.lineThrough
                          : null,
                      color: item.isChecked ? Colors.grey : null,
                    ),
                  ),
                  subtitle: Text(
                      '${item.quantity} ${item.unit}'),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MealEditorSheet extends StatefulWidget {
  final Meal? meal;
  final AppProvider provider;
  final int day;
  const _MealEditorSheet(
      {this.meal, required this.provider, required this.day});

  @override
  State<_MealEditorSheet> createState() => _MealEditorSheetState();
}

class _MealEditorSheetState extends State<_MealEditorSheet> {
  final _nameCtrl = TextEditingController();
  String _mealType = 'lunch';
  int _selectedDay = 1;
  final List<MealItem> _items = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.day;
    if (widget.meal != null) {
      _nameCtrl.text = widget.meal!.name;
      _mealType = widget.meal!.mealType;
      _selectedDay = widget.meal!.dayOfWeek ?? widget.day;
      _items.addAll(widget.meal!.items);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (ctx, controller) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.meal == null ? 'Nueva comida' : 'Editar comida',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Guardar')),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _mealType,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: List.generate(
                      _mealTypes.length,
                      (i) => DropdownMenuItem(
                          value: _mealTypeValues[i],
                          child: Text(_mealTypes[i])),
                    ),
                    onChanged: (v) => setState(() => _mealType = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedDay,
                    decoration: const InputDecoration(labelText: 'Día'),
                    items: List.generate(
                        7,
                        (i) => DropdownMenuItem(
                            value: i + 1, child: Text(_days[i]))),
                    onChanged: (v) => setState(() => _selectedDay = v!),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Alimentos',
                          style: TextStyle(
                              fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Añadir'),
                      ),
                    ],
                  ),
                  ..._items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(item.foodName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500)),
                                ),
                                Text('${item.calories} kcal',
                                    style: const TextStyle(
                                        color: Colors.orange)),
                                IconButton(
                                  onPressed: () =>
                                      setState(() => _items.removeAt(i)),
                                  icon: const Icon(Icons.close_rounded,
                                      size: 18, color: Colors.red),
                                ),
                              ],
                            ),
                            Text(
                              '${item.quantity} ${item.unit}'
                              '${item.protein != null ? ' · P:${item.protein!.toStringAsFixed(0)}g' : ''}'
                              '${item.carbs != null ? ' C:${item.carbs!.toStringAsFixed(0)}g' : ''}'
                              '${item.fat != null ? ' G:${item.fat!.toStringAsFixed(0)}g' : ''}',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodSearchScreen(
          mealId: widget.meal?.id ?? 'new',
          onAdd: (item) => setState(() => _items.add(item)),
        ),
      ),
    );
  }

  void _save() {
    if (_nameCtrl.text.isEmpty) return;
    final meal = Meal(
      id: widget.meal?.id,
      name: _nameCtrl.text.trim(),
      mealType: _mealType,
      dayOfWeek: _selectedDay,
      items: _items,
    );
    if (widget.meal == null) {
      widget.provider.addMeal(meal);
    } else {
      widget.provider.updateMeal(meal);
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }
}

class _AddFoodDialog extends StatefulWidget {
  final String mealId;
  final Function(MealItem) onAdd;
  const _AddFoodDialog({required this.mealId, required this.onAdd});

  @override
  State<_AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<_AddFoodDialog> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '100');
  final _unitCtrl = TextEditingController(text: 'g');
  final _calCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir alimento'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Alimento *')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Cantidad'))),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: _unitCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Unidad'))),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
                controller: _calCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Calorías *')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _proteinCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Proteína (g)'))),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: _carbsCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Carbos (g)'))),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: _fatCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Grasas (g)'))),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (_nameCtrl.text.isEmpty || _calCtrl.text.isEmpty) return;
            widget.onAdd(MealItem(
              mealId: widget.mealId,
              foodName: _nameCtrl.text.trim(),
              quantity: double.tryParse(_qtyCtrl.text) ?? 100,
              unit: _unitCtrl.text.trim().isEmpty ? 'g' : _unitCtrl.text,
              calories: int.tryParse(_calCtrl.text) ?? 0,
              protein: double.tryParse(_proteinCtrl.text),
              carbs: double.tryParse(_carbsCtrl.text),
              fat: double.tryParse(_fatCtrl.text),
            ));
            Navigator.pop(context);
          },
          child: const Text('Añadir'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }
}