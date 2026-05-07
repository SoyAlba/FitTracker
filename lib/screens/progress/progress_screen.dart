// lib/screens/progress/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
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
        title: const Text('Progreso'),
        bottom: TabBar(controller: _tabCtrl, tabs: const [
          Tab(text: '📸 Fotos'),
          Tab(text: '📏 Medidas'),
        ]),
      ),
      body: TabBarView(controller: _tabCtrl, children: [
        _PhotosTab(),
        _MeasurementsTab(),
      ]),
    );
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }
}

// ── PHOTOS TAB ────────────────────────────────────────────────────────────────

class _PhotosTab extends StatefulWidget {
  @override State<_PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends State<_PhotosTab> {
  final _picker = ImagePicker();
  // For compare mode
  ProgressPhoto? _compareA;
  ProgressPhoto? _compareB;
  bool _compareMode = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final photos = provider.progressPhotos;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPhoto(context, provider),
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Añadir foto'),
      ),
      body: photos.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('📸', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text('Sin fotos de progreso',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Guarda fotos periódicamente\npara ver tu evolución',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            ]))
          : Column(children: [
              // Compare mode toggle
              if (photos.length >= 2)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(children: [
                    const Text('Modo comparar', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Switch(
                      value: _compareMode,
                      onChanged: (v) => setState(() {
                        _compareMode = v;
                        if (!v) { _compareA = null; _compareB = null; }
                      }),
                      activeThumbColor: AppTheme.primaryColor,
                    ),
                  ]),
                ),

              // Compare view
              if (_compareMode) ...[
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(children: [
                    Text(_compareA == null && _compareB == null
                        ? 'Selecciona 2 fotos para comparar'
                        : _compareA == null ? 'Selecciona la foto A'
                        : _compareB == null ? 'Selecciona la foto B'
                        : 'Comparando',
                        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                    if (_compareA != null && _compareB != null) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _ComparePhoto(photo: _compareA!, label: 'Antes')),
                        const SizedBox(width: 8),
                        Expanded(child: _ComparePhoto(photo: _compareB!, label: 'Después')),
                      ]),
                    ],
                  ]),
                ),
              ],

              // Photo grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (ctx, i) {
                    final photo = photos[i];
                    final isSelectedA = _compareA?.id == photo.id;
                    final isSelectedB = _compareB?.id == photo.id;
                    return GestureDetector(
                      onTap: () {
                        if (_compareMode) {
                          setState(() {
                            if (isSelectedA) { _compareA = null; }
                            else if (isSelectedB) { _compareB = null; }
                            else if (_compareA == null) { _compareA = photo; }
                            else { _compareB ??= photo; }
                          });
                        } else {
                          _showPhotoDetail(context, photo, provider);
                        }
                      },
                      child: Stack(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(File(photo.imagePath),
                              width: double.infinity, height: double.infinity,
                              fit: BoxFit.cover),
                        ),
                        // Date label
                        Positioned(bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                              gradient: LinearGradient(
                                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                                  colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent])),
                            child: Text(
                              '${photo.date.day}/${photo.date.month}/${photo.date.year}',
                              style: const TextStyle(color: Colors.white, fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          )),
                        // Compare selection badge
                        if (_compareMode)
                          Positioned(top: 8, right: 8,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: isSelectedA ? Colors.blue : isSelectedB ? Colors.green : Colors.white.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2)),
                              child: Center(child: Text(
                                isSelectedA ? 'A' : isSelectedB ? 'B' : '',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                              )),
                            )),
                      ]),
                    );
                  },
                ),
              ),
            ]),
    );
  }

  void _showPhotoDetail(BuildContext context, ProgressPhoto photo, AppProvider provider) {
    showDialog(context: context, builder: (ctx) => Dialog(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: Image.file(File(photo.imagePath), fit: BoxFit.cover)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Text('${photo.date.day}/${photo.date.month}/${photo.date.year}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (photo.notes != null) ...[
              const SizedBox(width: 8),
              Expanded(child: Text(photo.notes!,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12))),
            ],
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.red),
              onPressed: () {
                provider.deleteProgressPhoto(photo.id);
                Navigator.pop(ctx);
              },
            ),
          ]),
        ),
      ]),
    ));
  }

  Future<void> _addPhoto(BuildContext context, AppProvider provider) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final notesCtrl = TextEditingController();
    if (!context.mounted) return;
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Añadir nota (opcional)'),
      content: TextField(controller: notesCtrl,
          decoration: const InputDecoration(hintText: 'Ej: semana 4, -2kg...')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () {
          provider.addProgressPhoto(ProgressPhoto(
            date: DateTime.now(), imagePath: picked.path,
            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim()));
          Navigator.pop(ctx);
        }, child: const Text('Guardar')),
      ],
    ));
  }
}

class _ComparePhoto extends StatelessWidget {
  final ProgressPhoto photo;
  final String label;
  const _ComparePhoto({required this.photo, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    const SizedBox(height: 6),
    ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(aspectRatio: 0.75,
          child: Image.file(File(photo.imagePath), fit: BoxFit.cover))),
    const SizedBox(height: 4),
    Text('${photo.date.day}/${photo.date.month}/${photo.date.year}',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
  ]);
}

// ── MEASUREMENTS TAB ──────────────────────────────────────────────────────────

class _MeasurementsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMeasurement(context, provider),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Registrar medidas'),
      ),
      body: provider.measurements.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('📏', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text('Sin medidas registradas',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Registra cintura, pecho, cadera...\npara seguir tu progreso real',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: provider.measurements.length,
              itemBuilder: (ctx, i) {
                final m = provider.measurements[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text('${m.date.day}/${m.date.month}/${m.date.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                          onPressed: () => provider.deleteMeasurement(m.id),
                          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Wrap(spacing: 12, runSpacing: 8, children: [
                        if (m.waist != null) _MeasBadge('👗 Cintura', m.waist!, Colors.pink),
                        if (m.chest != null) _MeasBadge('💪 Pecho', m.chest!, Colors.blue),
                        if (m.hips != null) _MeasBadge('🍑 Cadera', m.hips!, Colors.orange),
                        if (m.bicep != null) _MeasBadge('💪 Bícep', m.bicep!, Colors.purple),
                        if (m.thigh != null) _MeasBadge('🦵 Muslo', m.thigh!, Colors.teal),
                        if (m.neck != null) _MeasBadge('🔵 Cuello', m.neck!, Colors.indigo),
                      ]),
                      if (m.notes != null) ...[
                        const SizedBox(height: 8),
                        Text(m.notes!, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ]),
                  ),
                );
              },
            ),
    );
  }

  void _showAddMeasurement(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _MeasurementForm(provider: provider),
    );
  }
}

class _MeasBadge extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MeasBadge(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
    child: Text('$label: ${value.toStringAsFixed(1)} cm',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

class _MeasurementForm extends StatefulWidget {
  final AppProvider provider;
  const _MeasurementForm({required this.provider});
  @override State<_MeasurementForm> createState() => _MeasurementFormState();
}

class _MeasurementFormState extends State<_MeasurementForm> {
  final _waistCtrl = TextEditingController();
  final _chestCtrl = TextEditingController();
  final _hipsCtrl = TextEditingController();
  final _bicepCtrl = TextEditingController();
  final _thighCtrl = TextEditingController();
  final _neckCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(margin: const EdgeInsets.only(bottom: 12), width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const Text('Registrar medidas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _MeasField('Cintura', 'cm', _waistCtrl)),
            const SizedBox(width: 12),
            Expanded(child: _MeasField('Pecho', 'cm', _chestCtrl)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _MeasField('Cadera', 'cm', _hipsCtrl)),
            const SizedBox(width: 12),
            Expanded(child: _MeasField('Bícep', 'cm', _bicepCtrl)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _MeasField('Muslo', 'cm', _thighCtrl)),
            const SizedBox(width: 12),
            Expanded(child: _MeasField('Cuello', 'cm', _neckCtrl)),
          ]),
          const SizedBox(height: 12),
          TextField(controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notas (opcional)')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity,
            child: ElevatedButton(onPressed: _save, child: const Text('Guardar medidas'))),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _save() {
    final m = BodyMeasurement(
      date: DateTime.now(),
      waist: double.tryParse(_waistCtrl.text),
      chest: double.tryParse(_chestCtrl.text),
      hips: double.tryParse(_hipsCtrl.text),
      bicep: double.tryParse(_bicepCtrl.text),
      thigh: double.tryParse(_thighCtrl.text),
      neck: double.tryParse(_neckCtrl.text),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    widget.provider.addMeasurement(m);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    for (final c in [_waistCtrl, _chestCtrl, _hipsCtrl, _bicepCtrl, _thighCtrl, _neckCtrl, _notesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }
}

class _MeasField extends StatelessWidget {
  final String label, suffix;
  final TextEditingController ctrl;
  const _MeasField(this.label, this.suffix, this.ctrl);
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label, suffixText: suffix),
  );
}