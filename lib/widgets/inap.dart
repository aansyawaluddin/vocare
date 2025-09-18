import 'package:flutter/material.dart';
import 'package:vocare/common/type.dart';
import 'package:vocare/page/perawat/inap/daftar_riwayat.dart' as perawat_page;
import 'package:vocare/page/ketua_tim/daftar_riwayat.dart' as ketua_page;

class PasienInapWidget extends StatefulWidget {
  const PasienInapWidget({
    super.key,
    required this.rooms,
    required this.inpatients,
    required this.navy,
    required this.cardBlue,
    required this.role, 
    this.isCompact = false,
  });

  final List<String> rooms;
  final List<Map<String, String>> inpatients;
  final Color navy;
  final Color cardBlue;
  final bool isCompact;
  final String role;

  @override
  State<PasienInapWidget> createState() => _PasienInapWidgetState();
}

class _PasienInapWidgetState extends State<PasienInapWidget> {
  String? _selectedRoom;

  @override
  void initState() {
    super.initState();
    _selectedRoom = widget.rooms.isNotEmpty ? widget.rooms.first : null;
  }

  bool get _isKetua {
    final r = widget.role.toLowerCase();
    return r.contains('ketua');
  }

  @override
  Widget build(BuildContext context) {
    final navy = widget.navy;
    final cardBlue = widget.cardBlue;
    final isCompact = widget.isCompact;

    final visible = (_selectedRoom == null || _selectedRoom == 'Semua Ruangan')
        ? widget.inpatients
        : widget.inpatients.where((p) => p['room'] == _selectedRoom).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Ruangan:',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.w700,
            fontSize: isCompact ? 14 : 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRoom,
              items: widget.rooms
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRoom = v),
              isExpanded: true,
              icon: const Icon(Icons.expand_more),
              dropdownColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Pasien Rawat Inap :',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.w700,
            fontSize: isCompact ? 14 : 16,
          ),
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                'Tidak ada pasien di ruangan ini',
                style: TextStyle(color: navy.withOpacity(0.8)),
              ),
            ),
          )
        else
          Column(
            children: visible
                .map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InpatientCard(
                      navy: navy,
                      cardBlue: cardBlue,
                      name: p['name'] ?? '-',
                      room: p['room'] ?? '-',
                      condition: p['condition'] ?? '-',
                      lastAction: p['lastAction'] ?? '-',
                      isCompact: isCompact,
                      onTap: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (_) {
                        //       if (_isKetua) {
                        //         return ketua_page.DaftarRiwayatPage(
                        //           reportText: p['reportText'] ?? '-',
                        //         );
                        //       } else {
                        //         return perawat_page.DaftarRiwayatPage(user:,
                        //           reportText: p['reportText'] ?? '-',
                        //         );
                        //       }
                        //     },
                        //   ),
                        // );
                      },
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class InpatientCard extends StatelessWidget {
  const InpatientCard({
    super.key,
    required this.navy,
    required this.cardBlue,
    required this.name,
    required this.room,
    required this.condition,
    required this.lastAction,
    this.isCompact = false,
    this.onTap,
  });

  final Color navy;
  final Color cardBlue;
  final String name;
  final String room;
  final String condition;
  final String lastAction;
  final bool isCompact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardHeight = isCompact ? 120.0 : 100.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: cardHeight,
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              Icons.article_outlined,
              color: Colors.white,
              size: isCompact ? 26 : 28,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipPath(
            clipper: RightArrowClipper(),
            child: Material(
              color: cardBlue,
              child: InkWell(
                onTap: onTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  height: cardHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nama : $name',
                        style: TextStyle(
                          color: navy,
                          fontWeight: FontWeight.w700,
                          fontSize: isCompact ? 12 : 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kamar : $room',
                        style: TextStyle(
                          color: navy.withOpacity(0.95),
                          fontSize: isCompact ? 11 : 12,
                        ),
                      ),
                      Text(
                        'Kondisi : $condition',
                        style: TextStyle(
                          color: navy.withOpacity(0.95),
                          fontSize: isCompact ? 11 : 12,
                        ),
                      ),
                      Text(
                        'Tindakan Sebelumnya : $lastAction',
                        style: TextStyle(
                          color: navy.withOpacity(0.9),
                          fontSize: isCompact ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RightArrowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - 18, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width - 18, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
