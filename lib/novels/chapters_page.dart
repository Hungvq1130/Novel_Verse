import 'package:flutter/material.dart';
import 'package:novelverse/novel_core_channel.dart';
import 'package:novelverse/novels/raeder_page.dart';

class ChaptersPage extends StatefulWidget {
  final int novelId;
  final String novelTitle;
  final List<Map> chapters;

  const ChaptersPage({
    super.key,
    required this.novelId,
    required this.novelTitle,
    required this.chapters,
  });

  @override
  State<ChaptersPage> createState() => _ChaptersPageState();
}

class _ChaptersPageState extends State<ChaptersPage> {
  ReadingTheme _readingTheme = ReadingTheme.dark;
  late Future<List<Map>> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.value(widget.chapters);
  }

  Future<void> _reload() async {
    setState(() {
      _future = NovelCore.getChapters(widget.novelId);
    });
  }

  Future<void> _openReaderAt(List<Map> chapters, int idx) async {
    // ✅ đánh dấu đúng chương được chọn là đã đọc
    chapters[idx]['read'] = true;

    final ch = chapters[idx];
    final cid = (ch['id'] as num).toInt();
    final title = (ch['title'] ?? 'Chương ${ch['indexInBook']}') as String;
    final content = await NovelCore.getChapterContent(cid);
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderPage(
          title: title,
          content: content,
          chapters: chapters,
          currentIndex: idx,
          onGotoChapter: (newIdx) => _replaceReaderAt(chapters, newIdx),
          onPrevChapter: idx > 0 ? () => _replaceReaderAt(chapters, idx - 1) : null,
          onNextChapter: idx < chapters.length - 1 ? () => _replaceReaderAt(chapters, idx + 1) : null,
          initialTheme: _readingTheme,                    // 👈 truyền vào
          onThemeChanged: (m) => setState(() {            // 👈 lưu lại khi user đổi
            _readingTheme = m;
          }),
        ),
      ),
    );

  }

  Future<void> _replaceReaderAt(List<Map> chapters, int idx) async {
    // ✅ cũng đánh dấu khi đi bằng prev/next
    chapters[idx]['read'] = true;

    final ch = chapters[idx];
    final cid = (ch['id'] as num).toInt();
    final title = (ch['title'] ?? 'Chương ${ch['indexInBook']}') as String;
    final content = await NovelCore.getChapterContent(cid);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReaderPage(
          title: title,
          content: content,
          chapters: chapters,
          currentIndex: idx,
          onGotoChapter: (newIdx) => _replaceReaderAt(chapters, newIdx),
          onPrevChapter: idx > 0 ? () => _replaceReaderAt(chapters, idx - 1) : null,
          onNextChapter: idx < chapters.length - 1 ? () => _replaceReaderAt(chapters, idx + 1) : null,
          initialTheme: _readingTheme,                    // 👈 truyền vào
          onThemeChanged: (m) => setState(() {            // 👈 lưu lại
            _readingTheme = m;
          }),
        ),
      ),
    );

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.novelTitle)),
      body: FutureBuilder<List<Map>>(
        future: _future,
        builder: (c, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final chapters = s.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (context, i) {
                final ch = chapters[i];
                final title = (ch['title'] ?? 'Chương ${ch['indexInBook']}') as String;
                return ListTile(
                  title: Text(title),
                  onTap: () => _openReaderAt(chapters, i),
                );
              },
            ),
          );
        },
      ),
    );
  }
}