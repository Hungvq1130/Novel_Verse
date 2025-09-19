// novels_page.dart
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:novelverse/novels/chapters_page.dart';
import '../novel_core_channel.dart';
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
                        builder: (_) => ChaptersPage(   // 👈 đổi từ _ChaptersPage
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




