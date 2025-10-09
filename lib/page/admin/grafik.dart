import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AssessmentsPieChart extends StatefulWidget {
  final double? width;
  const AssessmentsPieChart({Key? key, this.width}) : super(key: key);

  @override
  State<AssessmentsPieChart> createState() => _AssessmentsPieChartState();
}

class _AssessmentsPieChartState extends State<AssessmentsPieChart> {
  bool _loading = true;
  String? _error;
  List<double> _values = [1, 1, 1];

  final List<String> _mainFields = [
    'informasi_umum',
    'data_kunjungan',
    'keluhan_utama',
    'pemeriksaan_fisik',
    'tanda_vital',
    'pemeriksaan_sistem',
    'alergi',
    'asesmen_nyeri',
    'skrining_gizi',
    'skrining_risiko_jatuh',
    'status_psikososial',
    'rencana_perawatan',
    'masalah_keperawatan',
    'edukasi',
    'rencana_asuhan_keperawatan',
  ];

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final baseApi = dotenv.env['API_URL'];

      if (baseApi == null || baseApi.isEmpty) {
        throw Exception('Tidak menemukan API_URL di .env');
      }

      // Gunakan endpoint /assesments/ sesuai catatan Anda
      final url = baseApi.endsWith('/')
          ? '${baseApi}assesments/'
          : '$baseApi/assesments/';

      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        // Keluarkan body untuk membantu debugging ketika bukan 200
        final body = resp.body;
        throw Exception(
          'HTTP ${resp.statusCode}: ${resp.reasonPhrase ?? 'Unknown'}. Body: $body',
        );
      }

      final jsonBody = jsonDecode(resp.body);
      final List<dynamic> rawRecords = _extractRecordsList(jsonBody);

      int red = 0, yellow = 0, green = 0;
      for (final item in rawRecords) {
        final parsed = _parseRecordData(item);
        final asesmen = parsed?['asesmen_awal_keperawatan'] ?? parsed;
        if (asesmen == null || asesmen is! Map<String, dynamic>) continue;

        final int filled = _countFilledMainFields(asesmen, _mainFields);
        if (filled <= 5)
          red++;
        else if (filled <= 10)
          yellow++;
        else
          green++;
      }

      final total = red + yellow + green;
      setState(() {
        _values = total == 0
            ? [0, 0, 0]
            : [red.toDouble(), yellow.toDouble(), green.toDouble()];
        _loading = false;
      });
    } on TimeoutException {
      setState(() {
        _loading = false;
        _error = 'Request timeout. Coba periksa koneksi atau endpoint.';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<dynamic> _extractRecordsList(dynamic jsonBody) {
    if (jsonBody is Map && jsonBody['data'] is List) {
      return List<dynamic>.from(jsonBody['data']);
    }

    if (jsonBody is Map && jsonBody['data'] is Map) {
      final inner = jsonBody['data'];
      if (inner['data'] is List) return List<dynamic>.from(inner['data']);
      return [inner];
    }

    if (jsonBody is List) return jsonBody;

    return <dynamic>[];
  }

  Map<String, dynamic>? _parseRecordData(dynamic record) {
    if (record == null) return null;
    if (record is Map && record.containsKey('data')) {
      final inner = record['data'];
      if (inner == null) return null;
      if (inner is Map) return Map<String, dynamic>.from(inner);
      if (inner is String) {
        final cleaned = _stripCodeFence(inner);
        try {
          final decoded = jsonDecode(cleaned);
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {
          return null;
        }
      }
    }

    if (record is Map) return Map<String, dynamic>.from(record);

    return null;
  }

  // Hilangkan ```json\n ... ``` jika ada
  String _stripCodeFence(String s) {
    var out = s.trim();
    if (out.startsWith('```')) {
      final idx = out.indexOf('\n');
      if (idx != -1) out = out.substring(idx + 1);
      out = out.replaceAll('```', '');
    }
    return out.trim();
  }

  int _countFilledMainFields(
    Map<String, dynamic> asesmen,
    List<String> fields,
  ) {
    int cnt = 0;
    for (final f in fields) {
      if (!asesmen.containsKey(f)) continue;
      final val = asesmen[f];
      if (_isFilled(val)) cnt++;
    }
    return cnt;
  }

  // Rekursif cek apakah value terisi
  bool _isFilled(dynamic v) {
    if (v == null) return false;
    if (v is String) {
      final s = v.replaceAll(RegExp(r'[`"\n\r\t]'), '').trim();
      return s.isNotEmpty;
    }
    if (v is num || v is bool) return true;
    if (v is List) return v.isNotEmpty;
    if (v is Map) {
      for (final val in v.values) {
        if (_isFilled(val)) return true;
      }
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEAEA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monitoring Kelengkapan Assessments Perawat',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text('Terjadi kesalahan: $_error'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loadAssessments,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    return PieChartDashboard(
      width: widget.width,
      values: _values,
      colors: const [Colors.red, Colors.yellow, Colors.green],
    );
  }
}

class PieChartDashboard extends StatelessWidget {
  final double? width;
  final List<double> values;
  final List<Color> colors;

  const PieChartDashboard({
    Key? key,
    this.width,
    this.values = const [30, 35, 35],
    this.colors = const [Colors.red, Colors.yellow, Colors.green],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final w = width ?? MediaQuery.of(context).size.width;
    final isCompact = w < 380;
    final total = values.fold<double>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDCE9FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Monitoring Kelengkapan Assessments Perawat',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          // Wrap chart + legend responsively
          Flex(
            direction: isCompact ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Chart
              Expanded(
                flex: isCompact ? 0 : 1,
                child: Center(
                  child: Container(
                    width: isCompact ? 200 : 230,
                    height: isCompact ? 200 : 230,
                    // subtle card shadow around the donut
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, child) {
                        return CustomPaint(
                          painter: _PieChartPainter(
                            values: values,
                            colors: colors,
                            animationPercent: t,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  total.round().toString(),
                                  style: TextStyle(
                                    fontSize: isCompact ? 18 : 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: isCompact ? 11 : 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Spacing for horizontal layout
              SizedBox(width: isCompact ? 0 : 18, height: isCompact ? 12 : 0),

              // Legend (compact)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isCompact ? double.infinity : 220,
                ),
                child: _Legend(values: values, colors: colors),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  const _Legend({required this.values, required this.colors});

  @override
  Widget build(BuildContext context) {
    final total = values.fold<double>(0, (a, b) => a + b);
    final labels = [
      'Kelengkapan \u2264 5',
      'Kelengkapan 6 - 10',
      'Kelengkapan > 10',
    ];

    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(labels.length, (i) {
        final cnt = values[i].round();
        final percent = total > 0 ? values[i] / total * 100 : 0.0;
        final percentStr = (percent % 1 == 0)
            ? percent.toStringAsFixed(0)
            : percent.toStringAsFixed(1);
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[i],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$cnt  •  $percentStr%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double animationPercent;

  _PieChartPainter({
    required this.values,
    required this.colors,
    this.animationPercent = 1.0,
  }) : assert(
         values.length == colors.length,
         'values and colors length must match',
       );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide * 0.5);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final total = values.fold<double>(0, (a, b) => a + b);

    // simpan rect label untuk deteksi overlap
    final List<Rect> occupied = [];

    if (total <= 0) {
      paint.color = const Color(0xFFEFEFEF);
      canvas.drawCircle(center, radius, paint);
      _drawCenterHole(canvas, center, size.width * 0.28);
      return;
    }

    double start = -math.pi / 2;

    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * math.pi * animationPercent;
      paint.color = colors[i];
      canvas.drawArc(rect, start, sweep, true, paint);

      final mid = start + sweep / 2;
      final sliceAngle = sweep;

      // prioritas: coba tempatkan di dalam
      bool placed = false;

      // buat teks label
      final int count = values[i].round();
      final double percent = total > 0 ? (values[i] / total * 100) : 0.0;
      final percentStr = (percent % 1 == 0)
          ? percent.toStringAsFixed(0)
          : percent.toStringAsFixed(1);
      final String labelText = '$count\n$percentStr%';

      // ukuran font dinamis
      double baseFont = (radius * 0.12).clamp(10.0, 14.0);
      if (sliceAngle < 0.25) {
        baseFont = (radius * 0.10).clamp(
          9.0,
          12.0,
        ); // kecilkan font untuk slice sempit
      }

      final textColorInside = colors[i].computeLuminance() > 0.55
          ? Colors.black
          : Colors.white;

      // fungsi bantu untuk membuat TextPainter berdasarkan style
      TextPainter _makeTP({required Color color, required double fontSize}) {
        return TextPainter(
          text: TextSpan(
            text: labelText,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
      }

      // 1) Coba di dalam slice, mulai dari radius relatif kecil, dorong keluar jika overlap
      double tryRadius = radius * 0.58;
      final double maxInsideRadius = radius * 0.85;
      int attempts = 0;
      final int maxAttempts = 6;

      while (!placed &&
          attempts < maxAttempts &&
          tryRadius <= maxInsideRadius) {
        final tp = _makeTP(color: textColorInside, fontSize: baseFont);
        tp.layout(minWidth: 0, maxWidth: radius * 0.7);

        final dx = center.dx + math.cos(mid) * tryRadius;
        final dy = center.dy + math.sin(mid) * tryRadius;
        final labelRect = Rect.fromLTWH(
          dx - tp.width / 2,
          dy - tp.height / 2,
          tp.width,
          tp.height,
        );

        bool intersects = false;
        for (final occ in occupied) {
          if (occ.overlaps(labelRect.inflate(2.0))) {
            intersects = true;
            break;
          }
        }

        if (!intersects) {
          // ok tempatkan di sini
          tp.paint(canvas, Offset(labelRect.left, labelRect.top));
          occupied.add(labelRect);
          placed = true;
          break;
        }

        // kalau overlap, dorong keluar sedikit (naikkan radius)
        tryRadius += (radius * 0.08);
        attempts++;
      }

      // 2) Jika tidak bisa ditempatkan di dalam (atau slice sangat sempit), letakkan di luar dengan leader line
      if (!placed) {
        // hitung titik start line (di pinggir slice)
        final outerPoint = Offset(
          center.dx + math.cos(mid) * (radius * 0.90),
          center.dy + math.sin(mid) * (radius * 0.90),
        );
        // titik label lebih jauh
        double outsideLabelRadius = radius * 1.12;
        int outAttempts = 0;
        final int maxOutAttempts = 6;

        while (outAttempts < maxOutAttempts && !placed) {
          final labelPoint = Offset(
            center.dx + math.cos(mid) * outsideLabelRadius,
            center.dy + math.sin(mid) * outsideLabelRadius,
          );

          // buat label dengan warna gelap (agar terbaca di luar)
          final tp = _makeTP(color: Colors.black87, fontSize: baseFont - 1);
          tp.layout(minWidth: 0, maxWidth: radius * 0.6);

          final labelRect = Rect.fromLTWH(
            labelPoint.dx - tp.width / 2,
            labelPoint.dy - tp.height / 2,
            tp.width,
            tp.height,
          );

          bool intersects = false;
          for (final occ in occupied) {
            if (occ.overlaps(labelRect.inflate(2.0))) {
              intersects = true;
              break;
            }
          }

          if (!intersects) {
            // gambar garis penunjuk
            final midPoint = Offset(
              center.dx + math.cos(mid) * (radius * 0.78),
              center.dy + math.sin(mid) * (radius * 0.78),
            );
            final linePaint = Paint()
              ..color = Colors.black.withOpacity(0.5)
              ..strokeWidth = 1.0
              ..style = PaintingStyle.stroke;
            canvas.drawLine(midPoint, outerPoint, linePaint);
            canvas.drawLine(outerPoint, labelPoint, linePaint);

            tp.paint(canvas, Offset(labelRect.left, labelRect.top));
            occupied.add(labelRect);
            placed = true;
            break;
          }
          outsideLabelRadius += radius * 0.08;
          outAttempts++;
        }
        if (!placed) {
        }
      }

      start += sweep;
    }

    _drawCenterHole(canvas, center, size.width * 0.15);
  }

  void _drawCenterHole(Canvas canvas, Offset center, double holeRadius) {
    // subtle shadow behind hole
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.06);
    canvas.drawCircle(center.translate(0, 2), holeRadius + 2, shadowPaint);

    final holePaint = Paint()
      ..color = Colors.white
      ..isAntiAlias = true;
    canvas.drawCircle(center, holeRadius, holePaint);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.colors != colors ||
        oldDelegate.animationPercent != animationPercent;
  }
}
