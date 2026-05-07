// lib/screens/routines/routines_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import 'dart:io';
import 'active_workout_screen.dart';

const List<String> _days = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
];

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final grouped = <int, List<Routine>>{};
    for (final r in provider.routines) {
      grouped.putIfAbsent(r.dayOfWeek, () => []).add(r);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutinas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => _showHistory(context, provider),
            tooltip: 'Historial',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRoutineEditor(context, provider),
        icon: const Icon(Icons.add),
        label: const Text('Nueva rutina'),
      ),
      body: provider.routines.isEmpty
          ? const _EmptyState(
              icon: Icons.fitness_center_rounded,
              message: 'Sin rutinas aún\nCrea tu primera rutina',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                for (int day = 1; day <= 7; day++)
                  if (grouped.containsKey(day)) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, top: 8),
                      child: Text(
                        _days[day - 1],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor),
                      ),
                    ),
                    ...grouped[day]!.map((r) => _RoutineCard(
                          routine: r,
                          provider: provider,
                          onEdit: () => _showRoutineEditor(context, provider,
                              routine: r),
                          onDelete: () => provider.deleteRoutine(r.id),
                          onLog: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActiveWorkoutScreen(routine: r, provider: provider),
                            ),
                          ),
                        )),
                  ],
              ],
            ),
    );
  }

  void _showHistory(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const _BottomSheetHandle(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Historial de entrenamientos',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: provider.workoutLogs.isEmpty
                  ? const Center(child: Text('Sin historial aún'))
                  : ListView.builder(
                      controller: controller,
                      itemCount: provider.workoutLogs.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (ctx, i) {
                        final log = provider.workoutLogs[i];
                        final routine = provider.routines.firstWhere(
                          (r) => r.id == log.routineId,
                          orElse: () => Routine(
                              name: 'Rutina eliminada', dayOfWeek: 1),
                        );
                        return ListTile(
                          leading: const Icon(Icons.check_circle_rounded,
                              color: Colors.green),
                          title: Text(routine.name),
                          subtitle: Text(
                              '${log.date.day}/${log.date.month}/${log.date.year}'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoutineEditor(BuildContext context, AppProvider provider,
      {Routine? routine}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _RoutineEditorSheet(
        routine: routine,
        provider: provider,
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final Routine routine;
  final AppProvider provider;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLog;

  const _RoutineCard({
    required this.routine,
    required this.provider,
    required this.onEdit,
    required this.onDelete,
    required this.onLog,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context)
            .copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fitness_center_rounded,
                color: AppTheme.primaryColor, size: 20),
          ),
          title: Text(routine.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${routine.exercises.length} ejercicios'),
          trailing: ElevatedButton.icon(
            onPressed: onLog,
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: const Text('Iniciar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          children: [
            ...routine.exercises.map((e) => _ExerciseTile(exercise: e)),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onLog,
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Iniciar'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Eliminar rutina'),
                          content: Text(
                              '¿Eliminar "${routine.name}"?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancelar')),
                            TextButton(
                              onPressed: () {
                                onDelete();
                                Navigator.pop(ctx);
                              },
                              child: const Text('Eliminar',
                                  style:
                                      TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_rounded,
                        color: Colors.red, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  const _ExerciseTile({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: [
          if (exercise.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(exercise.imagePath!),
                  width: 48, height: 48, fit: BoxFit.cover),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image_rounded,
                  color: Colors.grey, size: 20),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14)),
                Text(
                  '${exercise.sets} series × ${exercise.reps} reps',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                if (exercise.lastLogged != null)
                  Text(
                    '🏆 Último: ${exercise.lastWeight?.toStringAsFixed(1) ?? "–"} kg '
                    '× ${exercise.lastReps ?? "–"} reps · ${exercise.lastLogged}',
                    style: TextStyle(color: Colors.green.shade600, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineEditorSheet extends StatefulWidget {
  final Routine? routine;
  final AppProvider provider;
  const _RoutineEditorSheet({this.routine, required this.provider});

  @override
  State<_RoutineEditorSheet> createState() => _RoutineEditorSheetState();
}

class _RoutineEditorSheetState extends State<_RoutineEditorSheet> {
  final _nameCtrl = TextEditingController();
  int _selectedDay = 1;
  final List<Exercise> _exercises = [];
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.routine != null) {
      _nameCtrl.text = widget.routine!.name;
      _selectedDay = widget.routine!.dayOfWeek;
      _exercises.addAll(widget.routine!.exercises);
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
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            const _BottomSheetHandle(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.routine == null
                        ? 'Nueva rutina'
                        : 'Editar rutina',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Guardar'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la rutina',
                      hintText: 'Ej: Pecho y tríceps',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Día de la semana',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List.generate(
                      7,
                      (i) => ChoiceChip(
                        label: Text(_days[i].substring(0, 2)),
                        selected: _selectedDay == i + 1,
                        onSelected: (v) {
                          if (v) setState(() => _selectedDay = i + 1);
                        },
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: _selectedDay == i + 1
                              ? Colors.white
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ejercicios',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton.icon(
                        onPressed: _addExercise,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Añadir'),
                      ),
                    ],
                  ),
                  ..._exercises.asMap().entries.map((entry) =>
                      _ExerciseEditor(
                        index: entry.key,
                        exercise: entry.value,
                        onDelete: () =>
                            setState(() => _exercises.removeAt(entry.key)),
                        onUpdate: (e) =>
                            setState(() => _exercises[entry.key] = e),
                        onPickImage: () => _pickImage(entry.key),
                      )),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addExercise() {
    final dummyRoutineId =
        widget.routine?.id ?? 'new_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _exercises.add(Exercise(
        routineId: dummyRoutineId,
        name: 'Ejercicio ${_exercises.length + 1}',
      ));
    });
  }

  Future<void> _pickImage(int index) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _exercises[index] = _exercises[index].copyWith(imagePath: picked.path);
      });
    }
  }

  void _save() {
    if (_nameCtrl.text.isEmpty) return;
    final routine = Routine(
      id: widget.routine?.id,
      name: _nameCtrl.text.trim(),
      dayOfWeek: _selectedDay,
      createdAt: widget.routine?.createdAt,
      exercises: _exercises
          .map((e) => Exercise(
                id: e.id,
                routineId: widget.routine?.id ?? e.routineId,
                name: e.name,
                sets: e.sets,
                reps: e.reps,
                weight: e.weight,
                imagePath: e.imagePath,
                notes: e.notes,
                orderIndex: e.orderIndex,
              ))
          .toList(),
    );
    if (widget.routine == null) {
      widget.provider.addRoutine(routine);
    } else {
      widget.provider.updateRoutine(routine);
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }
}

class _ExerciseEditor extends StatefulWidget {
  final int index;
  final Exercise exercise;
  final VoidCallback onDelete;
  final Function(Exercise) onUpdate;
  final VoidCallback onPickImage;

  const _ExerciseEditor({
    required this.index,
    required this.exercise,
    required this.onDelete,
    required this.onUpdate,
    required this.onPickImage,
  });

  @override
  State<_ExerciseEditor> createState() => _ExerciseEditorState();
}

class _ExerciseEditorState extends State<_ExerciseEditor> {
  late TextEditingController _nameCtrl;
  late TextEditingController _setsCtrl;
  late TextEditingController _repsCtrl;
  late TextEditingController _weightCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.exercise.name);
    _setsCtrl =
        TextEditingController(text: widget.exercise.sets.toString());
    _repsCtrl =
        TextEditingController(text: widget.exercise.reps.toString());
    _weightCtrl =
        TextEditingController(text: widget.exercise.weight.toString());
  }

  void _notify() {
    widget.onUpdate(widget.exercise.copyWith(
      name: _nameCtrl.text,
      sets: int.tryParse(_setsCtrl.text) ?? widget.exercise.sets,
      reps: int.tryParse(_repsCtrl.text) ?? widget.exercise.reps,
      weight:
          double.tryParse(_weightCtrl.text) ?? widget.exercise.weight,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: widget.onPickImage,
                  child: widget.exercise.imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                              File(widget.exercise.imagePath!),
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.grey.shade300),
                          ),
                          child: const Icon(Icons.add_photo_alternate_rounded,
                              color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    onChanged: (_) => _notify(),
                    decoration: const InputDecoration(
                      labelText: 'Nombre del ejercicio',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.red, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _NumberField(
                    label: 'Series',
                    ctrl: _setsCtrl,
                    onChanged: (_) => _notify()),
                const SizedBox(width: 8),
                _NumberField(
                    label: 'Reps',
                    ctrl: _repsCtrl,
                    onChanged: (_) => _notify()),
                const SizedBox(width: 8),
                _NumberField(
                    label: 'Peso (kg)',
                    ctrl: _weightCtrl,
                    onChanged: (_) => _notify(),
                    decimal: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final Function(String) onChanged;
  final bool decimal;

  const _NumberField({
    required this.label,
    required this.ctrl,
    required this.onChanged,
    this.decimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextField(
        controller: ctrl,
        onChanged: onChanged,
        keyboardType:
            TextInputType.numberWithOptions(decimal: decimal),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
        ),
      ),
    );
  }
}

class _BottomSheetHandle extends StatelessWidget {
  const _BottomSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          ),
        ],
      ),
    );
  }
}