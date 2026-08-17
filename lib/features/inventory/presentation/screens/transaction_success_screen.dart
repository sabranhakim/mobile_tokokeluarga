import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TransactionType { penerimaan, barangKeluar }

class TransactionSuccessScreen extends StatelessWidget {
  final TransactionType type;
  final String? noTransaksi;
  final DateTime tanggal;
  final String pihakLabel;
  final String pihakValue;
  final String? keterangan;
  final List<MapEntry<String, String>> items;
  final String totalLabel;
  final String totalValue;

  const TransactionSuccessScreen({
    super.key,
    required this.type,
    this.noTransaksi,
    required this.tanggal,
    required this.pihakLabel,
    required this.pihakValue,
    this.keterangan,
    required this.items,
    required this.totalLabel,
    required this.totalValue,
  });

  bool get _isPenerimaan => type == TransactionType.penerimaan;

  String get _title =>
      _isPenerimaan ? 'Penerimaan Berhasil' : 'Barang Keluar Berhasil';

  String get _message =>
      _isPenerimaan
          ? 'Penerimaan barang telah dicatat dan menunggu verifikasi stok.'
          : 'Barang keluar berhasil dicatat dan stok telah diperbarui.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFE7F5EC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: Color(0xFF047857),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E252D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF656F7D),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E4E8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (noTransaksi != null && noTransaksi!.isNotEmpty) ...[
                      _buildDetailRow('No. Transaksi', noTransaksi!),
                      const Divider(height: 20, color: Color(0xFFF0F1F3)),
                    ],
                    _buildDetailRow(
                      'Tanggal',
                      DateFormat('dd MMMM yyyy').format(tanggal),
                    ),
                    const Divider(height: 20, color: Color(0xFFF0F1F3)),
                    _buildDetailRow(pihakLabel, pihakValue),
                    if (keterangan != null && keterangan!.isNotEmpty) ...[
                      const Divider(height: 20, color: Color(0xFFF0F1F3)),
                      _buildDetailRow('Keterangan', keterangan!),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      'Detail Item',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7A8492),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          ...items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.key,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1E252D),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    item.value,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF444651),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFE2E4E8)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          totalLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF444651),
                          ),
                        ),
                        Text(
                          totalValue,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF00236F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B4856),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Selesai',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF7A8492),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E252D),
            ),
          ),
        ),
      ],
    );
  }
}