class FormModel {
  final int id;
 // gunakan int?, bukan String?
  final String? namaPengirim;
  final String lokasiPengirim;
  final DateTime waktuPengiriman;
  final String phonePengirim;
  final double berat;
  final String deskripsi;
  final String? namaPenerima;
  final String lokasiPenerima;
  final String phonePenerima;
  final String? buktiPengiriman;

  FormModel({
    required this.id, // pastikan ini ada
    this.namaPengirim,
    required this.lokasiPengirim,
    required this.waktuPengiriman,
    required this.phonePengirim,
    required this.berat,
    required this.deskripsi,
    this.namaPenerima,
    required this.lokasiPenerima,
    required this.phonePenerima,
    this.buktiPengiriman,
  });

  factory FormModel.fromJson(Map<String, dynamic> json) {
    return FormModel(
      id: json['id'] is int
      ? json['id']
      : int.tryParse(json['id'].toString()) ?? 0,
      namaPengirim: json['namaPengirim'],
      lokasiPengirim: json['lokasiPengirim'],
      waktuPengiriman: DateTime.parse(json['waktuPengiriman']),
      phonePengirim: json['phonenumberPengirim'],
      berat: double.tryParse(json['berat'].toString()) ?? 0.0,
      deskripsi: json['deskripsi'],
      namaPenerima: json['namaPenerima'],
      lokasiPenerima: json['lokasiPenerima'],
      phonePenerima: json['phonenumberPenerima'],
      buktiPengiriman: json['bukti_pengiriman'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'namaPengirim': namaPengirim,
      'lokasiPengirim': lokasiPengirim,
      'waktuPengiriman': waktuPengiriman.toIso8601String(),
      'phonenumberPengirim': phonePengirim,
      'berat': berat,
      'deskripsi': deskripsi,
      'namaPenerima': namaPenerima,
      'lokasiPenerima': lokasiPenerima,
      'phonenumberPenerima': phonePenerima,
    };
  }
}
