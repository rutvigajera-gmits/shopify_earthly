import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

const _kSizeRows = [
  (6, '14.6', '45.9'), (7, '15.0', '47.1'), (8, '15.3', '48.1'),
  (9, '15.6', '49.0'), (10, '15.9', '50.0'), (11, '16.2', '50.9'),
  (12, '16.5', '51.8'), (13, '16.8', '52.8'), (14, '17.2', '54.0'),
  (15, '17.5', '55.0'), (16, '17.8', '55.9'), (17, '18.1', '56.9'),
  (18, '18.4', '57.8'), (19, '18.7', '59.1'), (20, '19.1', '60.0'),
  (21, '19.4', '60.9'), (22, '19.7', '61.9'), (23, '20.0', '62.8'),
  (24, '20.3', '63.8'), (25, '20.6', '64.7'), (26, '21.0', '66.0'),
  (27, '21.3', '66.9'), (28, '21.6', '67.9'), (29, '22.0', '69.1'),
  (30, '22.3', '70.1'),
];

class SizeChartLink extends StatelessWidget {
  const SizeChartLink({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const SizeChartSheet(),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.straighten_outlined, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text('Size chart',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              decoration: TextDecoration.underline,
            )),
      ]),
    );
  }
}

class SizeChartSheet extends StatelessWidget {
  const SizeChartSheet({super.key});

  @override
  Widget build(BuildContext context) {
    const mid = 13;
    final left = _kSizeRows.sublist(0, mid);
    final right = _kSizeRows.sublist(mid);
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, ctrl) => Container(
        color: Colors.white,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
            child: Row(children: [
              Text('Ring Size Chart',
                  style: AppTextStyles.headlineLarge.copyWith(fontSize: 22)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.close, size: 16, color: AppColors.textPrimary),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _SizeTable(rows: left)),
                  const SizedBox(width: 8),
                  Expanded(child: _SizeTable(rows: right)),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(),
                    elevation: 0,
                  ),
                  child: Text('How to Measure?',
                      style: AppTextStyles.button.copyWith(color: Colors.white)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SizeTable extends StatelessWidget {
  final List<(int, String, String)> rows;
  const _SizeTable({required this.rows});

  static const _h = TextStyle(
      fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF444444), height: 1.4);
  static const _c = TextStyle(fontSize: 11, color: Color(0xFF333333));

  Widget _cell(String t, {bool h = false}) => Padding(
      padding: const EdgeInsets.all(6),
      child: Text(t, style: h ? _h : _c, textAlign: TextAlign.center, maxLines: 2));

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: AppColors.border, width: 0.5),
      columnWidths: const {
        0: FlexColumnWidth(0.8),
        1: FlexColumnWidth(1.1),
        2: FlexColumnWidth(1.3),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AppColors.surfaceWarm),
          children: [
            _cell('Ring\nSize', h: true),
            _cell('Diameter\n(mm)', h: true),
            _cell('Circum.\n(mm)', h: true),
          ],
        ),
        ...rows.map((r) => TableRow(children: [
              _cell('${r.$1}'),
              _cell(r.$2),
              _cell(r.$3),
            ])),
      ],
    );
  }
}
