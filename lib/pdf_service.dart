import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class PdfService {
  /// スキャンした画像からPDFを作成し、共有する
  Future<void> createAndSharePdf(List<File> images) async {
    if (images.isEmpty) {
      throw Exception('画像が選択されていません');
    }

    try {
      // PDFドキュメントを作成
      final pdf = pw.Document();

      // 各画像をPDFページとして追加
      for (var image in images) {
        final imageBytes = await image.readAsBytes();
        final pdfImage = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.FittedBox(
                  fit: pw.BoxFit.contain,
                  child: pw.Image(pdfImage),
                ),
              );
            },
          ),
        );
      }

      // 一時ディレクトリを取得
      final output = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${output.path}/scanned_document_$timestamp.pdf';
      final file = File(filePath);

      // PDFをファイルとして保存
      await file.writeAsBytes(await pdf.save());

      // 保存したPDFを共有
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'スキャンしたドキュメント',
        text: 'ドキュメントスキャナーで作成したPDFです',
      );
    } catch (e) {
      rethrow;
    }
  }
}
