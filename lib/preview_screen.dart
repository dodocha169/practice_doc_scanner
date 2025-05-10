import 'dart:io';
import 'package:flutter/material.dart';
import '../action_button.dart';

class PreviewScreen extends StatefulWidget {
  final List<String> scannedPics;
  final VoidCallback onRetake;
  final VoidCallback onContinue;
  final Future<void> Function() onExportPdf;

  const PreviewScreen({
    super.key,
    required this.scannedPics,
    required this.onRetake,
    required this.onContinue,
    required this.onExportPdf,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_updateCurrentPage);
  }

  @override
  void dispose() {
    _pageController.removeListener(_updateCurrentPage);
    _pageController.dispose();
    super.dispose();
  }

  void _updateCurrentPage() {
    final page = _pageController.page?.round() ?? 0;
    if (_currentPage != page) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  Future<void> _handleExportPdf() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onExportPdf();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('プレビュー (${_currentPage + 1}/${widget.scannedPics.length})'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // プレビュー領域
              Expanded(
                child:
                    widget.scannedPics.isEmpty
                        ? const Center(child: Text('画像がありません'))
                        : Stack(
                          alignment: Alignment.center,
                          children: [
                            // 画像のページビュー
                            PageView.builder(
                              controller: _pageController,
                              itemCount: widget.scannedPics.length,
                              itemBuilder: (context, index) {
                                return InteractiveViewer(
                                  minScale: 0.5,
                                  maxScale: 3.0,
                                  child: Image.file(
                                    File(widget.scannedPics[index]),
                                    fit: BoxFit.contain,
                                  ),
                                );
                              },
                            ),

                            // ページインジケーター
                            if (widget.scannedPics.length > 1)
                              Positioned(
                                bottom: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      widget.scannedPics.length,
                                      (index) => Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              _currentPage == index
                                                  ? Colors.white
                                                  : Colors.white38,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
              ),

              // 操作ボタン
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // やり直す
                      ActionButton(
                        icon: Icons.refresh,
                        label: 'やり直す',
                        color: Colors.red,
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onRetake();
                        },
                      ),

                      // PDFエクスポート
                      ActionButton(
                        icon: Icons.picture_as_pdf,
                        label: 'PDFエクスポート',
                        color: Colors.green,
                        onPressed: _handleExportPdf,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

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
