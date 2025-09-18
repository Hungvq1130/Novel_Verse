import 'package:flutter/material.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab>
    with AutomaticKeepAliveClientMixin<LibraryTab> {
  @override
  bool get wantKeepAlive => true;

  final _books = <String>[]; // giả lập tủ sách trống

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tủ sách')),
      body: _books.isEmpty
          ? Center(
        child: Text(
          'Chưa có truyện nào.\nHãy thêm từ Trang chủ hoặc Thể loại.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.bookmark),
          title: Text(_books[i]),
        ),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: _books.length,
      ),
    );
  }
}
