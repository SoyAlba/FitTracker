// lib/screens/reminders/reminders_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';

const _types = ['injection', 'supplement', 'medication', 'protein', 'water', 'gym', 'shopping', 'weight', 'custom'];
const _typeLabels = ['Inyección', 'Suplemento', 'Medicación', 'Proteína', 'Agua', 'Gym', 'Lista compra', 'Pesaje', 'Personalizado'];
const _typeIcons = ['💉', '💊', '🏥', '🥤', '💧', '🏋️', '🛒', '⚖️', '🔔'];
const _frequencies = ['daily', 'weekly', 'weekdays', 'weekends', 'custom'];
const _freqLabels = ['Cada día', 'Semanal', 'Entre semana', 'Fines de semana', 'Días custom'];
const _dayNames = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do'];

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> with WidgetsBindingObserver {
  bool _notifOk = true;
  bool _exactOk = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Se llama automáticamente al volver desde los Ajustes del sistema
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final notif = await NotificationService.instance.hasNotificationPermission();
    final exact = await NotificationService.instance.canScheduleExactAlarms();
    if (mounted) setState(() { _notifOk = notif; _exactOk = exact; });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final grouped = <String, List<MedicalReminder>>{};
    for (final r in provider.medicalReminders) {
      grouped.putIfAbsent(r.type, () => []).add(r);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            tooltip: 'Notificación de prueba',
            onPressed: () async {
              await NotificationService.instance.sendTestNotification();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🔔 ¿Ha llegado la notificación?')));
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context, provider),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: Column(children: [

        // Banner 1: permiso de notificaciones
        if (!_notifOk)
          _PermissionBanner(
            color: Colors.red.shade50,
            icon: '🚫',
            text: 'Las notificaciones están desactivadas. Las alarmas no sonarán.',
            buttonLabel: 'Activar',
            onTap: () async {
              await NotificationService.instance.requestNotificationPermission();
              _checkPermissions();
            },
          ),

        // Banner 2: permiso de alarmas exactas (Android 12+)
        if (!_exactOk)
          _PermissionBanner(
            color: Colors.orange.shade50,
            icon: '⏰',
            text: 'Permiso de alarma exacta desactivado — las notificaciones llegarán tarde o nunca.',
            buttonLabel: 'Activar',
            onTap: () async {
              await NotificationService.instance.openExactAlarmSettings();
            },
          ),

        Expanded(
          child: provider.medicalReminders.isEmpty
              ? const _EmptyState()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    for (final type in _types)
                      if (grouped.containsKey(type)) ...[
                        _SectionHeader(type: type),
                        ...grouped[type]!.map((r) => _ReminderCard(
                              reminder: r,
                              provider: provider,
                              onEdit: () => _showEditor(context, provider, reminder: r),
                            )),
                        const SizedBox(height: 8),
                      ],
                  ],
                ),
        ),
      ]),
    );
  }

  void _showEditor(BuildContext context, AppProvider provider, {MedicalReminder? reminder}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ReminderEditorSheet(reminder: reminder, provider: provider),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  final Color color;
  final String icon, text, buttonLabel;
  final VoidCallback onTap;
  const _PermissionBanner({
    required this.color, required this.icon,
    required this.text, required this.buttonLabel, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Container(
    color: color,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(children: [
      Text(icon, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      TextButton(onPressed: onTap, child: Text(buttonLabel)),
    ]),
  );
}

class _SectionHeader extends StatelessWidget {
  final String type;
  const _SectionHeader({required this.type});

  @override
  Widget build(BuildContext context) {
    final idx = _types.indexOf(type);
    final icon = idx >= 0 ? _typeIcons[idx] : '🔔';
    final label = idx >= 0 ? _typeLabels[idx] : type;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final MedicalReminder reminder;
  final AppProvider provider;
  final VoidCallback onEdit;

  const _ReminderCard({required this.reminder, required this.provider, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final typeIdx = _types.indexOf(reminder.type);
    final icon = typeIdx >= 0 ? _typeIcons[typeIdx] : '🔔';
    final freqIdx = _frequencies.indexOf(reminder.frequency);
    final freqLabel = freqIdx >= 0 ? _freqLabels[freqIdx] : reminder.frequency;

    List<String> dayLabels = [];
    if (reminder.days != null && reminder.days!.isNotEmpty) {
      try {
        final days = reminder.days!.split(',').map((d) => int.tryParse(d.trim()) ?? 0).toList();
        dayLabels = days.where((d) => d >= 1 && d <= 7).map((d) => _dayNames[d - 1]).toList();
      } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 26)),
        title: Text(reminder.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$freqLabel · ${reminder.time}'),
            if (dayLabels.isNotEmpty)
              Text(dayLabels.join(', '),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            if (reminder.notes != null && reminder.notes!.isNotEmpty)
              Text(reminder.notes!,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: reminder.isActive,
              onChanged: (v) {
                reminder.isActive = v;
                provider.updateMedicalReminder(reminder);
              },
              activeThumbColor: Colors.green,
            ),
            PopupMenuButton(
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Eliminar', style: TextStyle(color: Colors.red))),
              ],
              onSelected: (v) async {
                if (v == 'edit') {
                  onEdit();
                } else {
                  if (reminder.notificationId != null) {
                    await NotificationService.instance.cancelNotification(reminder.notificationId!);
                  }
                  provider.deleteMedicalReminder(reminder.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderEditorSheet extends StatefulWidget {
  final MedicalReminder? reminder;
  final AppProvider provider;
  const _ReminderEditorSheet({this.reminder, required this.provider});

  @override
  State<_ReminderEditorSheet> createState() => _ReminderEditorSheetState();
}

class _ReminderEditorSheetState extends State<_ReminderEditorSheet> {
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = 'supplement';
  String _frequency = 'daily';
  TimeOfDay _time = TimeOfDay.now();
  final List<bool> _selectedDays = List.filled(7, false);

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      final r = widget.reminder!;
      _nameCtrl.text = r.name;
      _notesCtrl.text = r.notes ?? '';
      _type = r.type;
      _frequency = r.frequency;
      final parts = r.time.split(':');
      _time = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      );
      if (r.days != null && r.days!.isNotEmpty) {
        try {
          final days = r.days!.split(',').map((d) => int.tryParse(d.trim()) ?? 0).toList();
          for (final d in days) {
            if (d >= 1 && d <= 7) _selectedDays[d - 1] = true;
          }
        } catch (_) {}
      }
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
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            _Handle(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.reminder == null ? 'Nuevo recordatorio' : 'Editar recordatorio',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(onPressed: _save, icon: const Icon(Icons.save_rounded), label: const Text('Guardar')),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  // Tipo
                  const Text('Tipo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_types.length, (i) => ChoiceChip(
                      label: Text('${_typeIcons[i]} ${_typeLabels[i]}'),
                      selected: _type == _types[i],
                      onSelected: (v) {
                        if (v) {
                          setState(() {
                          _type = _types[i];
                          if (_nameCtrl.text.isEmpty) _nameCtrl.text = _typeLabels[i];
                        });
                        }
                      },
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(color: _type == _types[i] ? Colors.white : null, fontSize: 12),
                    )),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre *'),
                    autofocus: widget.reminder == null,
                  ),
                  const SizedBox(height: 12),
                  // Hora
                  GestureDetector(
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: _time);
                      if (t != null) setState(() => _time = t);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text(
                            '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          const Spacer(),
                          const Text('Cambiar hora', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Frecuencia
                  DropdownButtonFormField<String>(
                    initialValue: _frequency,
                    decoration: const InputDecoration(labelText: 'Frecuencia'),
                    items: List.generate(_frequencies.length,
                        (i) => DropdownMenuItem(value: _frequencies[i], child: Text(_freqLabels[i]))),
                    onChanged: (v) => setState(() => _frequency = v!),
                  ),
                  // Días custom
                  if (_frequency == 'custom') ...[
                    const SizedBox(height: 12),
                    const Text('Días', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(7, (i) => GestureDetector(
                        onTap: () => setState(() => _selectedDays[i] = !_selectedDays[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _selectedDays[i] ? AppTheme.primaryColor : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(_dayNames[i],
                              style: TextStyle(
                                  color: _selectedDays[i] ? Colors.white : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      )),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notas (opcional)',
                      hintText: 'Dosis, instrucciones...',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: _save, child: const Text('Guardar recordatorio')),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    final timeStr = '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
    final daysStr = _frequency == 'custom'
        ? _selectedDays.asMap().entries.where((e) => e.value).map((e) => '${e.key + 1}').join(',')
        : null;

    int? notifId;
    try {
      final customDaysList = _frequency == 'custom'
          ? _selectedDays.asMap().entries.where((e) => e.value).map((e) => e.key + 1).toList()
          : null;
      notifId = await NotificationService.instance.scheduleReminder(
        name: _nameCtrl.text.trim(),
        type: _type,
        hour: _time.hour,
        minute: _time.minute,
        frequency: _frequency,
        customDays: customDaysList,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }

    final reminder = MedicalReminder(
      id: widget.reminder?.id,
      name: _nameCtrl.text.trim(),
      type: _type,
      frequency: _frequency,
      time: timeStr,
      days: daysStr,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      notificationId: notifId,
    );

    if (widget.reminder == null) {
      widget.provider.addMedicalReminder(reminder);
    } else {
      widget.provider.updateMedicalReminder(reminder);
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        width: 40, height: 4,
        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔔', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Sin recordatorios\nCrea alarmas para gym, agua,\ninyecciones, suplementos...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
          ],
        ),
      );
}