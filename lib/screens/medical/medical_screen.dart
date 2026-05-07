// lib/screens/medical/medical_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/notification_service.dart';

const _types = ['injection', 'supplement', 'medication'];
const _typeLabels = ['Inyección', 'Suplemento', 'Medicación'];
const _typeIcons = ['💉', '💊', '🏥'];
const _frequencies = ['daily', 'weekly', 'custom'];
const _freqLabels = ['Diario', 'Semanal', 'Personalizado'];

class MedicalScreen extends StatelessWidget {
  const MedicalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Avisos médicos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context, provider),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo aviso'),
      ),
      body: provider.medicalReminders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💉', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    'Sin recordatorios médicos\nCrea tu primer aviso',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: Colors.grey.shade400, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: provider.medicalReminders.length,
              itemBuilder: (ctx, i) {
                final r = provider.medicalReminders[i];
                final typeIdx = _types.indexOf(r.type);
                final icon = typeIdx >= 0 ? _typeIcons[typeIdx] : '🏥';
                final label =
                    typeIdx >= 0 ? _typeLabels[typeIdx] : r.type;
                final freqIdx = _frequencies.indexOf(r.frequency);
                final freqLabel =
                    freqIdx >= 0 ? _freqLabels[freqIdx] : r.frequency;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Text(icon,
                        style: const TextStyle(fontSize: 28)),
                    title: Text(r.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '$label · $freqLabel · ${r.time}'
                        '${r.notes != null && r.notes!.isNotEmpty ? '\n${r.notes}' : ''}'),
                    isThreeLine: r.notes != null && r.notes!.isNotEmpty,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: r.isActive,
                          onChanged: (v) {
                            r.isActive = v;
                            provider.updateMedicalReminder(r);
                          },
                          activeThumbColor: Colors.green,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded,
                              color: Colors.red, size: 20),
                          onPressed: () async {
                            if (r.notificationId != null) {
                              await NotificationService.instance
                                  .cancelNotification(r.notificationId!);
                            }
                            provider.deleteMedicalReminder(r.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showEditor(BuildContext context, AppProvider provider,
      {MedicalReminder? reminder}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) =>
          _MedicalEditorSheet(reminder: reminder, provider: provider),
    );
  }
}

class _MedicalEditorSheet extends StatefulWidget {
  final MedicalReminder? reminder;
  final AppProvider provider;
  const _MedicalEditorSheet({this.reminder, required this.provider});

  @override
  State<_MedicalEditorSheet> createState() => _MedicalEditorSheetState();
}

class _MedicalEditorSheetState extends State<_MedicalEditorSheet> {
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = 'supplement';
  String _frequency = 'daily';
  TimeOfDay _time = TimeOfDay.now();

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            alignment: Alignment.center,
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.reminder == null ? 'Nuevo aviso' : 'Editar aviso',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Guardar')),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre *',
              hintText: 'Ej: Vitamina D, Testosterona...',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: List.generate(
                    _types.length,
                    (i) => DropdownMenuItem(
                        value: _types[i],
                        child: Text('${_typeIcons[i]} ${_typeLabels[i]}')),
                  ),
                  onChanged: (v) => setState(() => _type = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _frequency,
                  decoration: const InputDecoration(labelText: 'Frecuencia'),
                  items: List.generate(
                    _frequencies.length,
                    (i) => DropdownMenuItem(
                        value: _frequencies[i],
                        child: Text(_freqLabels[i])),
                  ),
                  onChanged: (v) => setState(() => _frequency = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final t = await showTimePicker(
                  context: context, initialTime: _time);
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const Spacer(),
                  const Text('Cambiar hora',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
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
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Guardar aviso'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    final timeStr =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

    int? notifId;
    try {
      notifId = await NotificationService.instance.scheduleMedicalReminder(
        name: _nameCtrl.text.trim(),
        type: _type,
        hour: _time.hour,
        minute: _time.minute,
        daily: _frequency == 'daily',
      );
    } catch (_) {}

    final reminder = MedicalReminder(
      id: widget.reminder?.id,
      name: _nameCtrl.text.trim(),
      type: _type,
      frequency: _frequency,
      time: timeStr,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      notificationId: notifId,
    );

    if (widget.reminder == null) {
      widget.provider.addMedicalReminder(reminder);
    } else {
      widget.provider.updateMedicalReminder(reminder);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}
