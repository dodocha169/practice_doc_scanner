import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../preview_screen.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import '../pdf_service.dart';
import '../scan_button.dart';

class App extends StatelessWidget {
  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doc Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _scannedPics = [];
  final PdfService _pdfService = PdfService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.storage.request();
  }

  // ① カメラ起動処理
  Future<void> _startScanning() async {
    List<String> scannedPics = [];
    setState(() {
      _isLoading = true;
    });

    try {
      scannedPics = await CunningDocumentScanner.getPictures() ?? [];
      if (!mounted) return;
      setState(() {
        _scannedPics = scannedPics;
      });
      // プレビュー画面へ遷移
      _navigateToPreview();
    } catch (e) {
      _showErrorSnackBar('スキャン中にエラーが発生しました: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // プレビュー画面へ遷移
  void _navigateToPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PreviewScreen(
              scannedPics: _scannedPics,
              onRetake: _retake,
              onContinue: _continueScanning,
              onExportPdf: _exportPdf,
            ),
      ),
    );
  }

  // やり直す: データ破棄 → ①へ
  void _retake() {
    if (_scannedPics.isNotEmpty) {
      setState(() {
        _scannedPics.removeLast(); // 最後に撮影した画像を削除
      });
    }
    _startScanning();
  }

  // 続けて撮影: データ保持 → ①へ
  void _continueScanning() {
    _startScanning();
  }

  // PDFエクスポート: PDF出力 → 保存 or 共有
  Future<void> _exportPdf() async {
    if (_scannedPics.isEmpty) {
      _showErrorSnackBar('スキャンされた画像がありません');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _pdfService.createAndSharePdf(
        _scannedPics.map((path) => File(path)).toList(),
      );
    } catch (e) {
      _showErrorSnackBar('PDFの作成中にエラーが発生しました: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ドキュメントスキャナー'), elevation: 0),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // アプリロゴやアイコン
                Icon(
                  Icons.document_scanner,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),

                // タイトル
                Text(
                  'ドキュメントスキャナー',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),

                const SizedBox(height: 16),

                // 説明テキスト
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'カメラを使ってドキュメントをスキャンし、PDFとして保存できます',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),

                const SizedBox(height: 48),

                // スキャン開始ボタン
                ScanButton(label: 'スキャン開始', onPressed: _startScanning),

                const SizedBox(height: 24),

                // 撮影済み画像がある場合
                if (_scannedPics.isNotEmpty) ...[
                  Text(
                    '${_scannedPics.length}枚のドキュメントをスキャンしました',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.preview),
                    label: const Text('プレビュー表示'),
                    onPressed: _navigateToPreview,
                  ),
                ],
              ],
            ),
          ),

          // ローディングインジケーター
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
