// lib/screens/routines/active_workout_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class ActiveWorkoutScreen extends StatefulWidget {
  final Routine routine;
  final AppProvider provider;
  const ActiveWorkoutScreen({super.key, required this.routine, required this.provider});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late String _workoutLogId;
  int _currentExerciseIdx = 0;
  Timer? _restTimer;
  int _restSeconds = 0;
  bool _restActive = false;
  // sets data: list of {reps, weight, completed}
  late List<List<Map<String, dynamic>>> _allSets;
  late Stopwatch _stopwatch;
  late Timer _timer;
  int _elapsed = 0;

  @override
  void initState() {
    super.initState();
    _workoutLogId = _uuid.v4();
    _allSets = widget.routine.exercises.map((ex) => List.generate(
      ex.sets,
      (i) => {
        'reps': ex.reps,
        'weight': ex.lastWeight ?? ex.weight,
        'completed': false,
      },
    )).toList();
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed = _stopwatch.elapsed.inSeconds);
    });
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() { _restSeconds = seconds; _restActive = true; });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restSeconds <= 0) {
        t.cancel();
        setState(() => _restActive = false);
      } else {
        setState(() => _restSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _stopwatch.stop();
    _restTimer?.cancel();
    super.dispose();
  }

  Exercise get _currentExercise => widget.routine.exercises[_currentExerciseIdx];

  String get _timeStr {
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int get _completedSets => _allSets[_currentExerciseIdx].where((s) => s['completed'] == true).length;

  @override
  Widget build(BuildContext context) {
    final ex = _currentExercise;
    final sets = _allSets[_currentExerciseIdx];
    final isLast = _currentExerciseIdx == widget.routine.exercises.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        foregroundColor: Colors.white,
        title: Text(widget.routine.name, style: const TextStyle(color: Colors.white)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('⏱ $_timeStr',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_currentExerciseIdx + 1) / widget.routine.exercises.length,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
            minHeight: 3,
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Exercise counter
                Text(
                  'Ejercicio ${_currentExerciseIdx + 1} de ${widget.routine.exercises.length}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Exercise name
                Text(
                  ex.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Exercise image
                _ExerciseImage(exercise: ex),
                const SizedBox(height: 16),

                // Last performance badge
                if (ex.lastWeight != null && ex.lastLogged != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Text(
                      '🏆 Última vez: ${ex.lastWeight!.toStringAsFixed(1)} kg · ${ex.lastLogged}',
                      style: const TextStyle(color: Colors.amber, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Sets table
                _SetsTable(
                  sets: sets,
                  exercise: ex,
                  onSetChanged: (i, field, value) {
                    setState(() => sets[i][field] = value);
                  },
                  onSetCompleted: (i) {
                    final wasCompleted = sets[i]['completed'] as bool;
                    setState(() => sets[i]['completed'] = !wasCompleted);
                    _saveCurrentSets();
                    if (!wasCompleted) _startRestTimer(90);
                  },
                ),
                const SizedBox(height: 24),

                // Rest Timer
                const SizedBox(height: 16),
                _RestTimerBar(
                  isActive: _restActive,
                  seconds: _restSeconds,
                  onStart: _startRestTimer,
                ),
                const SizedBox(height: 8),

                // Notes
                if (ex.notes != null && ex.notes!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('📝', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(ex.notes!,
                            style: const TextStyle(color: Colors.white70, fontSize: 13))),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Exercises list (mini nav)
                _ExercisePills(
                  exercises: widget.routine.exercises,
                  currentIdx: _currentExerciseIdx,
                  allSets: _allSets,
                  onTap: (i) => setState(() => _currentExerciseIdx = i),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),

          // Bottom buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            color: const Color(0xFF0F0F1A),
            child: Row(
              children: [
                if (_currentExerciseIdx > 0)
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentExerciseIdx--),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('← Anterior'),
                    ),
                  ),
                if (_currentExerciseIdx > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: isLast ? _finishWorkout : _nextExercise,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLast ? Colors.green : AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      isLast ? '✅ Finalizar entreno' : 'Siguiente →',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCurrentSets() async {
    final ex = _currentExercise;
    await widget.provider.saveWorkoutSets(
        _workoutLogId, ex.id, ex.name, _allSets[_currentExerciseIdx]);
  }

  void _nextExercise() async {
    await _saveCurrentSets();
    setState(() => _currentExerciseIdx++);
  }

  void _finishWorkout() async {
    await _saveCurrentSets();
    final log = WorkoutLog(
      id: _workoutLogId,
      routineId: widget.routine.id,
      date: DateTime.now(),
      durationMinutes: _elapsed ~/ 60,
    );
    await widget.provider.logWorkout(log);

    if (mounted) {
      _timer.cancel();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('🎉 ¡Entreno completado!',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Duración: $_timeStr',
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              Text('${widget.routine.exercises.length} ejercicios',
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('¡Genial!', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }
}

class _ExerciseImage extends StatelessWidget {
  final Exercise exercise;
  const _ExerciseImage({required this.exercise});

  @override
  Widget build(BuildContext context) {
    if (exercise.imagePath != null && File(exercise.imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(File(exercise.imagePath!),
            height: 180, width: double.infinity, fit: BoxFit.cover),
      );
    }
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏋️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(exercise.name,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SetsTable extends StatelessWidget {
  final List<Map<String, dynamic>> sets;
  final Exercise exercise;
  final Function(int, String, dynamic) onSetChanged;
  final Function(int) onSetCompleted;

  const _SetsTable({
    required this.sets,
    required this.exercise,
    required this.onSetChanged,
    required this.onSetCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(width: 36, child: Text('Serie', style: TextStyle(color: Colors.white38, fontSize: 12))),
                Expanded(child: Text('Reps', style: TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center)),
                Expanded(child: Text('Peso (kg)', style: TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center)),
                SizedBox(width: 44, child: Text('✓', style: TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center)),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          ...List.generate(sets.length, (i) => _SetRow(
            setNumber: i + 1,
            setData: sets[i],
            onRepsChanged: (v) => onSetChanged(i, 'reps', v),
            onWeightChanged: (v) => onSetChanged(i, 'weight', v),
            onCompleted: () => onSetCompleted(i),
          )),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final int setNumber;
  final Map<String, dynamic> setData;
  final Function(int) onRepsChanged;
  final Function(double) onWeightChanged;
  final VoidCallback onCompleted;

  const _SetRow({
    required this.setNumber,
    required this.setData,
    required this.onRepsChanged,
    required this.onWeightChanged,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final completed = setData['completed'] as bool;
    return Container(
      color: completed ? Colors.green.withOpacity(0.08) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text('$setNumber',
                style: TextStyle(
                    color: completed ? Colors.green : Colors.white60,
                    fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _NumberStepper(
              value: setData['reps'] as int,
              onChanged: onRepsChanged,
              completed: completed,
            ),
          ),
          Expanded(
            child: _WeightStepper(
              value: (setData['weight'] as num).toDouble(),
              onChanged: onWeightChanged,
              completed: completed,
            ),
          ),
          SizedBox(
            width: 44,
            child: GestureDetector(
              onTap: onCompleted,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: completed ? Colors.green : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: completed ? Colors.green : Colors.white24,
                        width: 2),
                  ),
                  child: completed
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberStepper extends StatelessWidget {
  final int value;
  final Function(int) onChanged;
  final bool completed;
  const _NumberStepper({required this.value, required this.onChanged, required this.completed});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepBtn(icon: Icons.remove, onTap: value > 1 ? () => onChanged(value - 1) : null, completed: completed),
          const SizedBox(width: 4),
          Text('$value', style: TextStyle(
              color: completed ? Colors.green : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15)),
          const SizedBox(width: 4),
          _StepBtn(icon: Icons.add, onTap: () => onChanged(value + 1), completed: completed),
        ],
      );
}

class _WeightStepper extends StatefulWidget {
  final double value;
  final Function(double) onChanged;
  final bool completed;
  const _WeightStepper({required this.value, required this.onChanged, required this.completed});

  @override
  State<_WeightStepper> createState() => _WeightStepperState();
}

class _WeightStepperState extends State<_WeightStepper> {
  late TextEditingController _ctrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _fmt(widget.value));
  }

  @override
  void didUpdateWidget(_WeightStepper old) {
    super.didUpdateWidget(old);
    if (!_editing && old.value != widget.value) {
      _ctrl.text = _fmt(widget.value);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String _fmt(double v) => v == 0 ? '0' : v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

  void _commit() {
    final v = double.tryParse(_ctrl.text.replaceAll(',', '.'));
    if (v != null && v >= 0) {
      widget.onChanged(v);
    } else {
      _ctrl.text = _fmt(widget.value);
    }
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _StepBtn(icon: Icons.remove,
          onTap: widget.value >= 2.5 ? () => widget.onChanged(widget.value - 2.5) : null,
          completed: widget.completed),
      const SizedBox(width: 4),
      // Toca el número → teclado numérico
      GestureDetector(
        onTap: () {
          setState(() { _editing = true; _ctrl.text = _fmt(widget.value); });
          Future.delayed(const Duration(milliseconds: 50), () {
            _ctrl.selection = TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
          });
        },
        child: _editing
            ? SizedBox(
                width: 56,
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                  onSubmitted: (_) => _commit(),
                  onTapOutside: (_) => _commit(),
                ),
              )
            : Container(
                constraints: const BoxConstraints(minWidth: 44),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white24, width: 1)),
                ),
                child: Text(
                  widget.value == 0 ? 'PC' : _fmt(widget.value),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.completed ? Colors.green : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
      ),
      const SizedBox(width: 4),
      _StepBtn(icon: Icons.add, onTap: () => widget.onChanged(widget.value + 2.5), completed: widget.completed),
    ],
  );
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool completed;
  const _StepBtn({required this.icon, required this.onTap, required this.completed});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: completed ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: onTap == null ? Colors.white24 : Colors.white70),
        ),
      );
}

class _ExercisePills extends StatelessWidget {
  final List<Exercise> exercises;
  final int currentIdx;
  final List<List<Map<String, dynamic>>> allSets;
  final Function(int) onTap;

  const _ExercisePills({
    required this.exercises,
    required this.currentIdx,
    required this.allSets,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Todos los ejercicios',
            style: TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(exercises.length, (i) {
            final done = allSets[i].every((s) => s['completed'] == true);
            final active = i == currentIdx;
            return GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.primaryColor
                      : done
                          ? Colors.green.withOpacity(0.2)
                          : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active ? AppTheme.primaryColor : Colors.transparent),
                ),
                child: Text(
                  '${done ? '✓ ' : ''}${exercises[i].name}',
                  style: TextStyle(
                      color: active ? Colors.white : done ? Colors.green : Colors.white54,
                      fontSize: 11,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _RestTimerBar extends StatelessWidget {
  final bool isActive;
  final int seconds;
  final Function(int) onStart;
  const _RestTimerBar({required this.isActive, required this.seconds, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isActive
          ? Row(children: [
              const Text('⏸️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Descanso: ${seconds}s',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: seconds / 90,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(
                        seconds > 30 ? Colors.green : seconds > 10 ? Colors.orange : Colors.red),
                    minHeight: 6,
                  ),
                ),
              ])),
              TextButton(
                onPressed: () => onStart(0),
                child: const Text('Saltar', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ])
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⏱️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                const Text('Descanso:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(width: 8),
                ...[60, 90, 120].map((s) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () => onStart(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text('${s}s',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                  ),
                )),
              ],
            ),
    );
  }
}