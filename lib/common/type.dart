enum Role { admin, editor, perawat }

class User {
  User({
    required this.id,
    required this.username,
    required this.role,
    required this.email,
    required this.token,
  });

  /// Buat User dari JSON. Jika token tersedia (mis. dari response login), bisa diteruskan lewat parameter token.
  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    String _s(Object? v) => v?.toString() ?? '';

    final idStr = json['id'] ?? json['user_id'] ?? json['userId'];
    final id = _s(idStr);

    final username = _s(json['username'] ?? json['user'] ?? json['name']);
    final email = _s(json['email'] ?? json['user_email']);

    String rawRole = _s(json['role']).toLowerCase();
    rawRole = rawRole.replaceAll(RegExp(r'[^a-z0-9]'), '');

    const roleMap = <String, Role>{
      'admin': Role.admin,
      'editor': Role.editor,
      'ketim': Role.editor,
      'user': Role.perawat,
      'perawat': Role.perawat,
    };

    final role = roleMap[rawRole] ?? Role.perawat;

    final tokFromJson = _s(
      json['token'] ?? json['access_token'] ?? json['accessToken'],
    );
    final finalToken = (token != null && token.isNotEmpty)
        ? token
        : (tokFromJson.isNotEmpty ? tokFromJson : '');

    return User(
      id: id,
      username: username,
      role: role,
      email: email,
      token: finalToken,
    );
  }

  final String id;
  final String username;
  final Role role;
  final String email;
  final String token;

  Map<String, dynamic> toJson() {
    String roleOut;
    switch (role) {
      case Role.admin:
        roleOut = 'Admin';
        break;
      case Role.editor:
        roleOut = 'Ketua Tim';
        break;
      case Role.perawat:
        roleOut = 'Perawat';
        break;
    }

    return {
      'id': id,
      'username': username,
      'role': roleOut,
      'email': email,
      'token': token,
    };
  }
}

class Patient {
  Patient({
    required this.id,
    required this.noRekamMedis,
    required this.assesmentId,
    required this.nama,
    required this.tglLahir,
    required this.jenisKelamin,
    required this.alamat,
    required this.agama,
    required this.pekerjaan,
    required this.statusPerkawinan,
    required this.penanggungJawab,
    required this.hubunganPenanggungJawab,
    required this.kontakPenanggungJawab,
    required this.statusRawat,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    String _s(Object? v) => v?.toString() ?? '';

    DateTime? parseDate(Object? v) {
      final s = v?.toString();
      if (s == null || s.isEmpty) return null;
      try {
        return DateTime.tryParse(s);
      } catch (_) {
        return null;
      }
    }

    return Patient(
      id: _s(json['id']),
      noRekamMedis: _s(json['no_rekam_medis'] ?? json['noRekamMedis']),
      assesmentId: _s(
        json['id_assesment'] ?? json['assesment_id'] ?? json['assesmentId'],
      ),
      nama: _s(json['nama']),
      tglLahir: parseDate(json['tgl_lahir'] ?? json['tglLahir']),
      jenisKelamin: _s(json['jenis_kelamin'] ?? json['jenisKelamin']),
      alamat: _s(json['alamat']),
      agama: _s(json['agama']),
      pekerjaan: _s(json['pekerjaan']),
      statusPerkawinan: _s(
        json['status_perkawinan'] ?? json['statusPerkawinan'],
      ),
      penanggungJawab: _s(json['penanggung_jawab'] ?? json['penanggungJawab']),
      hubunganPenanggungJawab: _s(
        json['hubungan_penanggung_jawab'] ?? json['hubunganPenanggungJawab'],
      ),
      kontakPenanggungJawab: _s(
        json['kontak_penanggung_jawab'] ?? json['kontakPenanggungJawab'],
      ),
      statusRawat: _s(json['status_rawat'] ?? json['statusRawat']),
    );
  }

  final String id;
  final String noRekamMedis;
  final String assesmentId;
  final String nama;
  final DateTime? tglLahir;
  final String jenisKelamin;
  final String alamat;
  final String agama;
  final String pekerjaan;
  final String statusPerkawinan;
  final String penanggungJawab;
  final String hubunganPenanggungJawab;
  final String kontakPenanggungJawab;
  final String statusRawat;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'no_rekam_medis': noRekamMedis,
      'id_assesment': assesmentId,
      'nama': nama,
      'tgl_lahir': tglLahir?.toIso8601String(),
      'jenis_kelamin': jenisKelamin,
      'alamat': alamat,
      'agama': agama,
      'pekerjaan': pekerjaan,
      'status_perkawinan': statusPerkawinan,
      'penanggung_jawab': penanggungJawab,
      'hubungan_penanggung_jawab': hubunganPenanggungJawab,
      'kontak_penanggung_jawab': kontakPenanggungJawab,
      'status_rawat': statusRawat,
    };
  }
}

class Assesment {
  Assesment({
    required this.id,
    required this.patientId,
    required this.tanggal,
    required this.perawat,
    required this.data,
  });

  factory Assesment.fromJson(Map<String, dynamic> json) {
    String _s(Object? v) => v?.toString() ?? '';
    DateTime? parseDate(Object? v) {
      final s = v?.toString();
      if (s == null || s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    final dynamic dataField = json['data'];

    return Assesment(
      id: _s(json['id']),
      patientId: _s(json['patient_id'] ?? json['patientId']),
      tanggal: parseDate(json['tanggal']),
      perawat: _s(json['perawat']),
      data: dataField,
    );
  }

  final String id;
  final String patientId;
  final DateTime? tanggal;
  final String perawat;
  final dynamic data;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'tanggal': tanggal?.toIso8601String(),
      'perawat': perawat,
      'data': data,
    };
  }
}

class CPPT {
  CPPT({
    required this.id,
    required this.patientId,
    required this.tanggal,
    required this.userId,
    required this.subjective,
    required this.objective,
    required this.assessment,
    required this.plan,
    required this.keterangan,
    required this.dokter,
    required this.signature,
  });

  factory CPPT.fromJson(Map<String, dynamic> json) {
    String _s(Object? v) => v?.toString() ?? '';
    DateTime? parseDate(Object? v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return CPPT(
      id: _s(json['id']),
      patientId: _s(json['patient_id'] ?? json['patientId']),
      tanggal: parseDate(json['tanggal']),
      userId: _s(json['user_id'] ?? json['userId']),
      subjective: _s(json['subjective']),
      objective: _s(json['objective']),
      assessment: _s(json['assessment']),
      plan: _s(json['plan']),
      keterangan: _s(json['keterangan']),
      dokter: _s(json['dokter']),
      signature: _s(json['signature']),
    );
  }

  final String id;
  final String patientId;
  final DateTime? tanggal;
  final String userId;
  final String subjective;
  final String objective;
  final String assessment;
  final String plan;
  final String keterangan;
  final String dokter;
  final String signature;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'tanggal': tanggal?.toIso8601String(),
      'user_id': userId,
      'subjective': subjective,
      'objective': objective,
      'assessment': assessment,
      'plan': plan,
      'keterangan': keterangan,
      'dokter': dokter,
      'signature': signature,
    };
  }
}

class Laporan {
  Laporan({
    required this.id,
    required this.patientId,
    required this.cpptId,
    required this.tanggal,
    required this.userId,
    required this.subjective,
    required this.objective,
    required this.assessment,
    required this.plan,
    required this.keterangan,
    required this.dokter,
    required this.signature,
    required this.tindakanLanjutan,
    required this.slki,
    required this.siki,
    required this.sdki
  });

  factory Laporan.fromJson(Map<String, dynamic> json) {
    String _s(Object? v) => v?.toString() ?? '';
    DateTime? parseDate(Object? v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return Laporan(
      id: _s(json['id']),
      patientId: _s(json['patient_id'] ?? json['patientId']),
      cpptId: _s(json['cppt_id'] ?? json['cpptId']),
      tanggal: parseDate(json['tanggal']),
      userId: _s(json['user_id'] ?? json['userId']),
      subjective: _s(json['subjective']),
      objective: _s(json['objective']),
      assessment: _s(json['assessment']),
      plan: _s(json['plan']),
      keterangan: _s(json['keterangan']),
      dokter: _s(json['dokter']),
      signature: _s(json['signature']),
      tindakanLanjutan: _s(
        json['tindakan_lanjutan'] ?? json['tindakanLanjutan'],
      ),
      slki: _s(json['SLKI'] ?? json['slki']),
      siki: _s(json['SIKI'] ?? json['siki']),
      sdki: _s(json['SDKI'] ?? json['sdki']),
    );
  }

  final String id;
  final String patientId;
  final String cpptId;
  final DateTime? tanggal;
  final String userId;
  final String subjective;
  final String objective;
  final String assessment;
  final String plan;
  final String keterangan;
  final String dokter;
  final String signature;
  final String tindakanLanjutan;
  final String slki;
  final String siki;
  final String sdki;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'cppt_id': cpptId,
      'tanggal': tanggal?.toIso8601String(),
      'user_id': userId,
      'subjective': subjective,
      'objective': objective,
      'assessment': assessment,
      'plan': plan,
      'keterangan': keterangan,
      'dokter': dokter,
      'signature': signature,
      'tindakan_lanjutan': tindakanLanjutan,
      'SLKI': slki,
      'SIKI': siki,
      'SDKI': sdki,
    };
  }
}
