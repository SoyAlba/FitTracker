// lib/screens/weight/weight_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});
  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progreso físico'),
        bottom: TabBar(controller: _tabCtrl, tabs: const [
          Tab(text: '⚖️ Peso'),
          Tab(text: '📏 Medidas'),
          Tab(text: '🔥 Calorías'),
        ]),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabCtrl,
        builder: (_, __) {
          if (_tabCtrl.index == 0) {
            return FloatingActionButton.extended(
              onPressed: () => _showAddEntry(context, provider),
              icon: const Icon(Icons.add), label: const Text('Registrar peso'),
            );
          } else if (_tabCtrl.index == 1) {
            return FloatingActionButton.extended(
              onPressed: () => _showAddMeasurement(context, provider),
              icon: const Icon(Icons.add), label: const Text('Registrar medidas'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      body: TabBarView(controller: _tabCtrl, children: [
        _WeightTab(provider: provider),
        _MeasurementsTab(provider: provider),
        _CaloriesTab(provider: provider),
      ]),
    );
  }

  void _showAddEntry(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _WeightEntryForm(provider: provider),
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

// ── WEIGHT TAB ────────────────────────────────────────────────────────────────

class _WeightTab extends StatelessWidget {
  final AppProvider provider;
  const _WeightTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final entries = provider.weightEntries;
    if (entries.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('⚖️', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text('Sin registros de peso', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
      ]));
    }

    final latest = entries.last;
    final first = entries.first;
    final diff = latest.weight - first.weight;
    final bmi = provider.profile.bmi(latest.weight);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Summary cards
        Row(children: [
          _SummaryCard(label: 'Actual', value: '${latest.weight} kg', color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          _SummaryCard(
            label: diff <= 0 ? 'Perdido' : 'Ganado',
            value: '${diff.abs().toStringAsFixed(1)} kg',
            color: diff <= 0 ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 10),
          if (bmi != null)
            _SummaryCard(
              label: 'IMC',
              value: bmi.toStringAsFixed(1),
              color: bmi < 18.5 || bmi >= 25 ? Colors.orange : Colors.green,
            ),
        ]),
        const SizedBox(height: 20),

        // Weight chart
        if (entries.length > 1) ...[
          const Text('Evolución del peso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Card(child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: SizedBox(height: 180, child: _WeightChart(entries: entries)),
          )),
          const SizedBox(height: 20),
        ],

        // History
        const Text('Historial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        ...entries.reversed.map((e) => _WeightEntryCard(
          entry: e,
          allEntries: entries,
          onDelete: () => provider.deleteWeightEntry(e.id),
        )),
      ],
    );
  }
}

// ── WEIGHT ENTRY CARD con foto ampliable y comparativa ───────────────────────

class _WeightEntryCard extends StatelessWidget {
  final WeightEntry entry;
  final List<WeightEntry> allEntries;
  final VoidCallback onDelete;

  const _WeightEntryCard({
    required this.entry,
    required this.allEntries,
    required this.onDelete,
  });

  bool get _hasPhoto => entry.imagePath != null && File(entry.imagePath!).existsSync();

  // Entrada más reciente con foto (diferente a esta)
  WeightEntry? get _latestWithPhoto {
    final others = allEntries
        .where((e) => e.id != entry.id && e.imagePath != null && File(e.imagePath!).existsSync())
        .toList();
    if (others.isEmpty) return null;
    others.sort((a, b) => b.date.compareTo(a.date));
    return others.first;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _hasPhoto ? () => _openDetail(context) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            // Foto miniatura
            if (_hasPhoto)
              GestureDetector(
                onTap: () => _openDetail(context),
                child: Hero(
                  tag: 'weight_photo_${entry.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(entry.imagePath!),
                        width: 60, height: 60, fit: BoxFit.cover),
                  ),
                ),
              )
            else
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(entry.weight.toStringAsFixed(0),
                    style: const TextStyle(color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            const SizedBox(width: 12),

            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${entry.weight} kg',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${entry.date.day}/${entry.date.month}/${entry.date.year}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              if (entry.fatPercentage != null || entry.musclePercentage != null)
                Wrap(spacing: 6, children: [
                  if (entry.fatPercentage != null)
                    _MiniTag('${entry.fatPercentage!.toStringAsFixed(1)}% grasa', Colors.orange),
                  if (entry.musclePercentage != null)
                    _MiniTag('${entry.musclePercentage!.toStringAsFixed(1)}% músculo', Colors.red),
                ]),
            ])),

            // Acciones
            Column(mainAxisSize: MainAxisSize.min, children: [
              if (_hasPhoto && _latestWithPhoto != null)
                IconButton(
                  icon: const Icon(Icons.compare_rounded, color: AppTheme.primaryColor, size: 20),
                  tooltip: 'Comparar con la más reciente',
                  onPressed: () => _openCompare(context),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                onPressed: onDelete,
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text('${entry.weight} kg · ${entry.date.day}/${entry.date.month}/${entry.date.year}'),
        ),
        body: Center(
          child: InteractiveViewer(
            child: Hero(
              tag: 'weight_photo_${entry.id}',
              child: Image.file(File(entry.imagePath!)),
            ),
          ),
        ),
      ),
    ));
  }

  void _openCompare(BuildContext context) {
    final other = _latestWithPhoto!;
    // Determinar cuál es antes y cuál es después
    final isEntryOlder = entry.date.isBefore(other.date);
    final before = isEntryOlder ? entry : other;
    final after = isEntryOlder ? other : entry;
    final diffKg = after.weight - before.weight;

    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            const Text('Comparativa', style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: diffKg <= 0 ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${diffKg > 0 ? "+" : ""}${diffKg.toStringAsFixed(1)} kg',
                style: TextStyle(
                  color: diffKg <= 0 ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(ctx),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Row(children: [
            Expanded(child: _ComparePhotoPanel(entry: before, label: 'Antes')),
            const SizedBox(width: 8),
            Expanded(child: _ComparePhotoPanel(entry: after, label: 'Después')),
          ]),
        ),
      ]),
    ));
  }
}

class _ComparePhotoPanel extends StatelessWidget {
  final WeightEntry entry;
  final String label;
  const _ComparePhotoPanel({required this.entry, required this.label});

  @override
  Widget build(BuildContext context) => Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(label, style: const TextStyle(color: Colors.white70,
          fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10)),
        child: Text('${entry.weight} kg',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    ]),
    const SizedBox(height: 6),
    ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 0.75,
        child: Image.file(File(entry.imagePath!), fit: BoxFit.cover),
      ),
    ),
    const SizedBox(height: 4),
    Text('${entry.date.day}/${entry.date.month}/${entry.date.year}',
        style: const TextStyle(color: Colors.white54, fontSize: 10)),
  ]);
}

class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniTag(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

class _WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  const _WeightChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final spots = entries.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), e.value.weight)).toList();
    final minY = entries.map((e) => e.weight).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = entries.map((e) => e.weight).reduce((a, b) => a > b ? a : b) + 2;

    return LineChart(LineChartData(
      minY: minY, maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 40,
          getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(0)}kg',
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
        )),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 24,
          interval: (entries.length / 4).ceilToDouble().clamp(1, double.infinity),
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= entries.length) return const SizedBox.shrink();
            final d = entries[i].date;
            return Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 9, color: Colors.grey));
          },
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [LineChartBarData(
        spots: spots,
        isCurved: true, curveSmoothness: 0.3,
        color: AppTheme.primaryColor,
        barWidth: 3,
        dotData: FlDotData(
          show: true,
          getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 4, color: AppTheme.primaryColor,
              strokeWidth: 2, strokeColor: Colors.white),
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor.withOpacity(0.3), AppTheme.primaryColor.withOpacity(0.0)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
      )],
    ));
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ]),
    ),
  );
}

// ── MEASUREMENTS TAB ─────────────────────────────────────────────────────────

class _MeasurementsTab extends StatefulWidget {
  final AppProvider provider;
  const _MeasurementsTab({required this.provider});
  @override State<_MeasurementsTab> createState() => _MeasurementsTabState();
}

class _MeasurementsTabState extends State<_MeasurementsTab> {
  String _selected = 'waist';
  static const _fields = {
    'waist': ('👗', 'Cintura', Colors.pink),
    'chest': ('💪', 'Pecho', Colors.blue),
    'hips': ('🍑', 'Cadera', Colors.orange),
    'bicep': ('💪', 'Bícep', Colors.purple),
    'thigh': ('🦵', 'Muslo', Colors.teal),
    'neck': ('🔵', 'Cuello', Colors.indigo),
  };

  double? _getValue(BodyMeasurement m, String field) => switch (field) {
    'waist' => m.waist, 'chest' => m.chest, 'hips' => m.hips,
    'bicep' => m.bicep, 'thigh' => m.thigh, 'neck' => m.neck, _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final measurements = widget.provider.measurements;
    if (measurements.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('📏', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text('Sin medidas registradas', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
        const SizedBox(height: 8),
        Text('Registra cintura, pecho, cadera...\npara ver tu progreso real',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      ]));
    }

    final fieldData = _fields[_selected]!;
    final dataPoints = measurements.reversed
        .where((m) => _getValue(m, _selected) != null)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _fields.entries.map((e) {
              final selected = _selected == e.key;
              return GestureDetector(
                onTap: () => setState(() => _selected = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? (e.value.$3 as Color) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${e.value.$1} ${e.value.$2}',
                      style: TextStyle(
                          color: selected ? Colors.white : Colors.grey.shade600,
                          fontSize: 13, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Chart
        if (dataPoints.length > 1) Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: SizedBox(height: 160, child: _MeasurementChart(
              data: dataPoints, field: _selected,
              color: fieldData.$3 as Color,
              getValue: _getValue,
            )),
          ),
        ),

        if (dataPoints.isNotEmpty) ...[
          const SizedBox(height: 12),
          // Latest vs first
          Row(children: [
            _SummaryCard(label: 'Actual',
                value: '${_getValue(dataPoints.last, _selected)!.toStringAsFixed(1)} cm',
                color: fieldData.$3 as Color),
            const SizedBox(width: 10),
            Builder(builder: (ctx) {
              if (dataPoints.length < 2) return const SizedBox.shrink();
              final diff = _getValue(dataPoints.last, _selected)! - _getValue(dataPoints.first, _selected)!;
              return _SummaryCard(
                label: diff <= 0 ? '📉 Reducido' : '📈 Aumentado',
                value: '${diff.abs().toStringAsFixed(1)} cm',
                color: diff <= 0 ? Colors.green : Colors.orange,
              );
            }),
          ]),
        ],

        const SizedBox(height: 16),
        const Text('Historial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),

        ...measurements.map((m) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('${m.date.day}/${m.date.month}/${m.date.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                  onPressed: () => widget.provider.deleteMeasurement(m.id),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6, children: [
                if (m.waist != null) _MeasBadge('Cintura', m.waist!, Colors.pink),
                if (m.chest != null) _MeasBadge('Pecho', m.chest!, Colors.blue),
                if (m.hips != null) _MeasBadge('Cadera', m.hips!, Colors.orange),
                if (m.bicep != null) _MeasBadge('Bícep', m.bicep!, Colors.purple),
                if (m.thigh != null) _MeasBadge('Muslo', m.thigh!, Colors.teal),
                if (m.neck != null) _MeasBadge('Cuello', m.neck!, Colors.indigo),
              ]),
            ]),
          ),
        )),
      ],
    );
  }
}

class _MeasurementChart extends StatelessWidget {
  final List<BodyMeasurement> data;
  final String field;
  final Color color;
  final double? Function(BodyMeasurement, String) getValue;
  const _MeasurementChart({required this.data, required this.field,
      required this.color, required this.getValue});

  @override
  Widget build(BuildContext context) {
    final spots = data.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), getValue(e.value, field)!)).toList();
    final vals = spots.map((s) => s.y);
    final minY = vals.reduce((a, b) => a < b ? a : b) - 2;
    final maxY = vals.reduce((a, b) => a > b ? a : b) + 2;

    return LineChart(LineChartData(
      minY: minY, maxY: maxY,
      gridData: FlGridData(show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36,
            getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                style: const TextStyle(fontSize: 10, color: Colors.grey)))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= data.length) return const SizedBox.shrink();
              final d = data[i].date;
              return Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 9, color: Colors.grey));
            })),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [LineChartBarData(
        spots: spots, isCurved: true, color: color, barWidth: 3,
        dotData: FlDotData(getDotPainter: (_, __, ___, ____) =>
            FlDotCirclePainter(radius: 4, color: color, strokeWidth: 2, strokeColor: Colors.white)),
        belowBarData: BarAreaData(show: true,
            gradient: LinearGradient(colors: [color.withOpacity(0.25), color.withOpacity(0)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      )],
    ));
  }
}

class _MeasBadge extends StatelessWidget {
  final String label; final double value; final Color color;
  const _MeasBadge(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
    child: Text('$label: ${value.toStringAsFixed(1)} cm',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

// ── CALORIES TAB ─────────────────────────────────────────────────────────────

class _CaloriesTab extends StatelessWidget {
  final AppProvider provider;
  const _CaloriesTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final goal = provider.dailyCalorieGoal;
    // Build last 7 days calorie data from meals by dayOfWeek
    final today = DateTime.now();
    final last7 = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    final dayData = last7.map((date) {
      final kcal = provider.meals
          .where((m) => m.dayOfWeek == date.weekday)
          .fold(0, (s, m) => s + m.totalCalories);
      return (date: date, kcal: kcal);
    }).toList();

    final maxKcal = [
      ...dayData.map((d) => d.kcal),
      if (goal != null) goal,
    ].reduce((a, b) => a > b ? a : b).toDouble();

    const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (goal != null) ...[
          Card(
            color: AppTheme.primaryColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Text('🎯', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Objetivo diario', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  Text('$goal kcal',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryColor)),
                ]),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Proteína objetivo', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  Text('${provider.dailyProteinGoal ?? "--"} g',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 20),
        ],

        const Text('Últimos 7 días', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),

        Card(child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          child: SizedBox(
            height: 220,
            child: BarChart(BarChartData(
              maxY: maxKcal * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                    '${rod.toY.toInt()} kcal',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 24,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= last7.length) return const SizedBox.shrink();
                    final isToday = last7[i].day == today.day &&
                        last7[i].month == today.month;
                    return Text(dayLabels[last7[i].weekday - 1],
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday ? AppTheme.primaryColor : Colors.grey));
                  },
                )),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}',
                        style: const TextStyle(fontSize: 9, color: Colors.grey)))),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              extraLinesData: goal != null ? ExtraLinesData(horizontalLines: [
                HorizontalLine(y: goal.toDouble(), color: Colors.green.withOpacity(0.6),
                    strokeWidth: 1.5, dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      labelResolver: (_) => 'Objetivo',
                      style: const TextStyle(color: Colors.green, fontSize: 10),
                    )),
              ]) : null,
              barGroups: List.generate(7, (i) {
                final kcal = dayData[i].kcal;
                final isOver = goal != null && kcal > goal;
                final isToday = last7[i].day == today.day && last7[i].month == today.month;
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: kcal.toDouble(),
                    color: isOver ? Colors.red.shade400 : isToday ? AppTheme.primaryColor : Colors.blue.shade300,
                    width: 28, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ]);
              }),
            )),
          ),
        )),

        const SizedBox(height: 16),

        // Weekly summary
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Resumen semanal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            Row(children: [
              _WeekStat('Total', '${dayData.fold(0, (s, d) => s + d.kcal)} kcal', Colors.orange),
              _WeekStat('Media', '${(dayData.fold(0, (s, d) => s + d.kcal) / 7).round()} kcal/día', Colors.blue),
              if (goal != null)
                _WeekStat('Déficit', '${((goal * 7) - dayData.fold(0, (s, d) => s + d.kcal))} kcal', Colors.green),
            ]),
          ]),
        )),
      ],
    );
  }
}

class _WeekStat extends StatelessWidget {
  final String label, value; final Color color;
  const _WeekStat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
    const SizedBox(height: 4),
    Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color), textAlign: TextAlign.center),
  ]));
}

// ── WEIGHT ENTRY FORM ─────────────────────────────────────────────────────────

class _WeightEntryForm extends StatefulWidget {
  final AppProvider provider;
  const _WeightEntryForm({required this.provider});
  @override State<_WeightEntryForm> createState() => _WeightEntryFormState();
}

class _WeightEntryFormState extends State<_WeightEntryForm> {
  final _weightCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _muscleCtrl = TextEditingController();
  final _boneCtrl = TextEditingController();
  final _waterCtrl = TextEditingController();
  String? _imagePath;
  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(margin: const EdgeInsets.only(bottom: 16), width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const Text('Nuevo registro de peso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Peso *', suffixText: 'kg',
                  prefixIcon: Icon(Icons.monitor_weight_outlined))),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: _fatCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '% Grasa', suffixText: '%'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _muscleCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '% Músculo', suffixText: '%'))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: _boneCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '% Hueso', suffixText: '%'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _waterCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '% Agua', suffixText: '%'))),
          ]),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final picked = await _picker.pickImage(source: ImageSource.gallery);
              if (picked != null) setState(() => _imagePath = picked.path);
            },
            child: Container(height: 80,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300)),
              child: _imagePath != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(_imagePath!), fit: BoxFit.cover, width: double.infinity))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_a_photo_rounded, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Text('Foto opcional', style: TextStyle(color: Colors.grey.shade400)),
                    ]),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity,
            child: ElevatedButton(onPressed: _save, child: const Text('Guardar'))),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _save() {
    final w = double.tryParse(_weightCtrl.text);
    if (w == null) return;
    widget.provider.addWeightEntry(WeightEntry(
      date: DateTime.now(), weight: w,
      fatPercentage: double.tryParse(_fatCtrl.text),
      musclePercentage: double.tryParse(_muscleCtrl.text),
      bonePercentage: double.tryParse(_boneCtrl.text),
      waterPercentage: double.tryParse(_waterCtrl.text),
      imagePath: _imagePath,
    ));
    Navigator.pop(context);
  }

  @override
  void dispose() {
    for (final c in [_weightCtrl, _fatCtrl, _muscleCtrl, _boneCtrl, _waterCtrl]) {
      c.dispose();
    }
    super.dispose();
  }
}

// ── MEASUREMENT FORM ──────────────────────────────────────────────────────────

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
            Expanded(child: _Field('Cintura', _waistCtrl)),
            const SizedBox(width: 12),
            Expanded(child: _Field('Pecho', _chestCtrl)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _Field('Cadera', _hipsCtrl)),
            const SizedBox(width: 12),
            Expanded(child: _Field('Bícep', _bicepCtrl)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _Field('Muslo', _thighCtrl)),
            const SizedBox(width: 12),
            Expanded(child: _Field('Cuello', _neckCtrl)),
          ]),
          const SizedBox(height: 10),
          TextField(controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notas (opcional)')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, child: const Text('Guardar medidas'))),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _save() {
    widget.provider.addMeasurement(BodyMeasurement(
      date: DateTime.now(),
      waist: double.tryParse(_waistCtrl.text),
      chest: double.tryParse(_chestCtrl.text),
      hips: double.tryParse(_hipsCtrl.text),
      bicep: double.tryParse(_bicepCtrl.text),
      thigh: double.tryParse(_thighCtrl.text),
      neck: double.tryParse(_neckCtrl.text),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    ));
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

class _Field extends StatelessWidget {
  final String label; final TextEditingController ctrl;
  const _Field(this.label, this.ctrl);
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label, suffixText: 'cm'),
  );
}