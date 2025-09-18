// novels_page.dart
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'novel_core_channel.dart';
import 'package:flutter/services.dart';

class NovelsPage extends StatefulWidget {
  const NovelsPage({super.key});

  @override
  State<NovelsPage> createState() => _NovelsPageState();
}

class _NovelsPageState extends State<NovelsPage> {
  late Future<List<Map>> _future;

  @override
  void initState() {
    super.initState();
    _future = NovelCore.getNovels();
  }

  Future<void> _reload() async {
    setState(() {
      _future = NovelCore.getNovels();
    });
  }

  Future<void> _importTxt() async {
    try {
      final xfile = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'Text/EPUB',
            extensions: ['txt', 'epub'],
          ),
        ],
      );
      if (xfile == null) return;

      // Lấy URI string: nếu path là content:// dùng luôn, nếu là file path thì tạo file://
      final String path = xfile.path;
      final String uriStr = path.startsWith('content://')
          ? path
          : Uri.file(path).toString();

      // Hiện tại chỉ TXT hoạt động; EPUB sẽ báo lỗi "not implemented" do repo chưa làm importEpub.
      if (path.toLowerCase().endsWith('.txt')) {
        await NovelCore.importTxt(uriStr);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nhập truyện .txt thành công')),
          );
        }
        await _reload();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('EPUB chưa hỗ trợ, vui lòng chọn .txt')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi nhập truyện: $e')),
        );
      }
    }
  }
  Future<void> _addChapterManual(BuildContext context, int novelId) async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Thêm chương (nhập tay)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề chương',
                      hintText: 'VD: Chương 11: Lối vào thung lũng',
                    ),
                    validator: (v) => (v==null || v.trim().isEmpty) ? 'Nhập tiêu đề' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contentCtrl,
                    minLines: 8,
                    maxLines: 16,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => (v==null || v.trim().isEmpty) ? 'Nhập nội dung' : null,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      await NovelCore.addChapter(
                        novelId: novelId,
                        title: titleCtrl.text.trim(),
                        content: contentCtrl.text,
                      );
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã thêm chương')),
                        );
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Lưu'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    await _reload();
  }
  Future<void> _importMoreChaptersFromTxt(BuildContext context, int novelId) async {
    final xfile = await openFile(
      acceptedTypeGroups: [ XTypeGroup(label: 'TXT', extensions: ['txt']) ],
    );
    if (xfile == null) return;
    final path = xfile.path;
    final uriStr = path.startsWith('content://') ? path : Uri.file(path).toString();

    try {
      final added = await NovelCore.importMoreFromTxt(novelId: novelId, uri: uriStr);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(added > 0 ? 'Đã thêm $added chương mới' : 'Không có chương mới để thêm')),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi thêm chương từ TXT: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tủ sách'),
      ),
      body: FutureBuilder<List<Map>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Chưa có truyện nào'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _importTxt,
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm truyện (.txt)'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = items[i];
                final id = (n['id'] as num).toInt();
                final title = (n['title'] ?? '') as String;
                final author = (n['author'] ?? '') as String;
                return ListTile(
                  leading: const Icon(Icons.menu_book),
                  title: Text(title.isEmpty ? 'No title' : title),
                  subtitle: Text(author),
                  trailing: PopupMenuButton<String>(
                    onSelected: (key) async {
                      switch (key) {
                        case 'add_manual':
                          await _addChapterManual(context, id);
                          break;
                        case 'add_from_txt':
                          await _importMoreChaptersFromTxt(context, id);
                          break;
                      }
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'add_manual',   child: ListTile(leading: Icon(Icons.edit),    title: Text('Thêm chương (nhập tay)'))),
                      PopupMenuItem(value: 'add_from_txt', child: ListTile(leading: Icon(Icons.upload),  title: Text('Thêm từ file TXT'))),
                    ],
                  ),
                  onTap: () async {
                    final chapters = await NovelCore.getChapters(id);
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _ChaptersPage(
                          novelId: id,
                          novelTitle: title,
                          chapters: chapters,
                        ),
                      ),
                    );
                  },
                );

              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _importTxt,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ChaptersPage extends StatefulWidget {
  final int novelId;
  final String novelTitle;
  final List<Map> chapters;
  const _ChaptersPage({required this.novelId, required this.novelTitle, required this.chapters});

  @override
  State<_ChaptersPage> createState() => _ChaptersPageState();
}

class _ChaptersPageState extends State<_ChaptersPage> {
  late Future<List<Map>> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.value(widget.chapters);
  }

  Future<void> _reload() async {
    setState(() { _future = NovelCore.getChapters(widget.novelId); });
  }

  Future<void> _openReaderAt(List<Map> chapters, int idx) async {
    final ch = chapters[idx];
    final cid = (ch['id'] as num).toInt();
    final title = (ch['title'] ?? 'Chương ${ch['indexInBook']}') as String;
    final content = await NovelCore.getChapterContent(cid);
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ReaderPage(
          title: title,
          content: content,
          chapters: chapters,          // truyền full list
          currentIndex: idx,           // vị trí hiện tại
          onGotoChapter: (newIdx) => _replaceReaderAt(chapters, newIdx),
          onPrevChapter: idx > 0
              ? () => _replaceReaderAt(chapters, idx - 1)
              : null,
          onNextChapter: idx < chapters.length - 1
              ? () => _replaceReaderAt(chapters, idx + 1)
              : null,
        ),
      ),
    );
  }

  Future<void> _replaceReaderAt(List<Map> chapters, int idx) async {
    final ch = chapters[idx];
    final cid = (ch['id'] as num).toInt();
    final title = (ch['title'] ?? 'Chương ${ch['indexInBook']}') as String;
    final content = await NovelCore.getChapterContent(cid);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _ReaderPage(
          title: title,
          content: content,
          chapters: chapters,
          currentIndex: idx,
          onGotoChapter: (newIdx) => _replaceReaderAt(chapters, newIdx),
          onPrevChapter: idx > 0
              ? () => _replaceReaderAt(chapters, idx - 1)
              : null,
          onNextChapter: idx < chapters.length - 1
              ? () => _replaceReaderAt(chapters, idx + 1)
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.novelTitle),
      ),
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
                final cid = (ch['id'] as num).toInt();
                final title = (ch['title'] ?? 'Chương ${ch['indexInBook']}') as String;
                return ListTile(
                  title: Text(title),
                  onTap: () async {
                    await _openReaderAt(chapters, i);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}


class _ReaderPage extends StatefulWidget {
  final String title;
  final String content;
  final List<Map>? chapters;
  final int? currentIndex;
  final ValueChanged<int>? onGotoChapter;

  final VoidCallback? onPrevChapter;
  final VoidCallback? onNextChapter;

  const _ReaderPage({
    required this.title,
    required this.content,
    this.chapters,
    this.currentIndex,
    this.onGotoChapter,
    this.onPrevChapter,
    this.onNextChapter,
  });

  @override
  State<_ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<_ReaderPage> {
  bool _uiVisible = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleUI() {
    setState(() => _uiVisible = !_uiVisible);
    if (_uiVisible) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  Future<void> _showChapterSheet() async {
    final chapters = widget.chapters ?? const <Map>[];
    final cur = widget.currentIndex ?? 0;
    if (chapters.isEmpty) return;

    bool newestFirst = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final total = chapters.length;
            List<int> order = List<int>.generate(total, (i) => i);
            if (newestFirst) {
              order = order.reversed.toList(); // ✅
            }

            return SafeArea(
              top: false,
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.6,
                minChildSize: 0.35,
                maxChildSize: 0.95,
                builder: (_, controller) => Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Text('$total Chương', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          // Cũ nhất | Mới nhất
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => setSheet(() => newestFirst = false),
                                child: Text(
                                  'Cũ nhất',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: newestFirst
                                        ? Theme.of(context).textTheme.bodyMedium!.color
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(width: 1, height: 14, color: Colors.white24),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => setSheet(() => newestFirst = true),
                                child: Text(
                                  'Mới nhất',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: newestFirst
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).textTheme.bodyMedium!.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: ListView.separated(
                        controller: controller,
                        itemCount: order.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
                        itemBuilder: (_, i) {
                          final idx = order[i];
                          final ch = chapters[idx];
                          final title = (ch['title'] ?? 'Chương ${ch['indexInBook']}') as String;

                          final isCurrent = idx == cur;
                          final isRead = idx < cur; // “đã đọc” = trước chương hiện tại
                          final primary = Theme.of(context).colorScheme.primary;

                          return ListTile(
                            dense: true,
                            leading: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                color: isCurrent ? primary : null,
                              ),
                            ),
                            title: Opacity(
                              opacity: isCurrent ? 1 : (isRead ? 0.45 : 1),
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isCurrent ? primary : null,
                                  fontWeight: isCurrent ? FontWeight.w700 : null,
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              widget.onGotoChapter?.call(idx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final bottomPad = mq.padding.bottom;
    final topBarH = kToolbarHeight + topPad;
    final bottomBarH = 90.0 + bottomPad;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Nội dung full màn hình; bar sẽ ĐÈ lên chữ
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleUI,
              child: SingleChildScrollView(
                // Khi bar hiện -> khóa scroll; khi bar ẩn -> cho scroll bình thường
                physics: _uiVisible
                    ? const NeverScrollableScrollPhysics()
                    : const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Text(
                  widget.content,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontSize: 16, height: 1.6),
                ),
              )
            ),
          ),

          if (_uiVisible)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleUI,              // chạm để ẩn bar
                // bắt hết các gesture vuốt để không lọt xuống ScrollView
                onVerticalDragStart: (_) {},
                onVerticalDragUpdate: (_) {},
                onVerticalDragEnd: (_) {},
                onHorizontalDragStart: (_) {},
                onHorizontalDragUpdate: (_) {},
                onHorizontalDragEnd: (_) {},
              ),
            ),

          // Scrim mờ dưới bar để dễ đọc (không bắt buộc)
          IgnorePointer(
            ignoring: true,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _uiVisible ? 1 : 0,
              child: Column(
                children: [
                  Container(
                    height: topBarH,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.35), Colors.transparent],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: bottomBarH,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter, end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.35), Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // TOP BAR (overlay)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            top: _uiVisible ? 0 : -topBarH,
            left: 0, right: 0,
            child: Container(
              height: topBarH,
              padding: EdgeInsets.only(top: topPad),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
              ),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop()),
                  Expanded(
                    child: Text(widget.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: FilledButton(onPressed: () {}, child: const Text('Chi tiết')),
                  ),
                  IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
                ],
              ),
            ),
          ),

          // BOTTOM BAR (overlay)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            left: 0, right: 0,
            bottom: _uiVisible ? 0 : -bottomBarH,
            child: Container(
              padding: EdgeInsets.only(bottom: bottomPad),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hàng điều hướng chương trong _ReaderPage (thay thế block cũ)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        // Chương trước: < Chương trước (disable khi onPrevChapter == null)
                        TextButton(
                          onPressed: widget.onPrevChapter,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.chevron_left),
                              SizedBox(width: 4),
                              Text('Chương trước'),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Chương sau: Chương sau >
                        TextButton(
                          onPressed: widget.onNextChapter,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('Chương sau'),
                              SizedBox(width: 4),
                              Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        InkWell(
                          onTap: _showChapterSheet,
                          child: const _BarIcon(text: 'Chương', icon: Icons.list),
                        ),
                        const _BarIcon(text: 'Thích', icon: Icons.thumb_up_alt_outlined),
                        const _BarIcon(text: 'Bình luận', icon: Icons.chat_bubble_outline),
                        const _BarIcon(text: 'Cài đặt', icon: Icons.settings_outlined),
                        const _BarIcon(text: 'Ban đêm', icon: Icons.brightness_2_outlined),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarIcon extends StatelessWidget {
  final String text;
  final IconData icon;
  const _BarIcon({required this.text, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}


