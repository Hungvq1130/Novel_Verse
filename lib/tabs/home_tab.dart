import 'package:flutter/material.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab>
    with AutomaticKeepAliveClientMixin<HomeTab> {
  @override
  bool get wantKeepAlive => true;

  int _tab = 0; // 0: Đề xuất, 1: Truyện chat

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopTabs(
                      selected: _tab,
                      onChanged: (i) => setState(() => _tab = i),
                    ),
                    const SizedBox(height: 10),
                    const _SearchBar(),
                  ],
                ),
              ),
            ),

            // ===== Không Thể Bỏ Lỡ (3 cột) =====
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Không Thể Bỏ Lỡ',
                actionText: 'Hot Nhất',
                onAction: () {},
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,          // <-- 3 cột
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.55,     // giữ tỉ lệ thẻ, đã thu nhỏ text bên dưới
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, i) => _BookCard(
                    imageUrl: 'https://picsum.photos/seed/hot$i/400/600',
                    title: 'Tựa truyện hấp dẫn #$i',
                    subtitle: (i % 2 == 0) ? 'Tình Yêu Đô Thị' : 'Xuyên Sách',
                  ),
                  childCount: 6,
                ),
              ),
            ),

            // ===== Truyện Chat (list ngang, nhỏ hơn) =====
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Truyện Chat',
                actionText: 'Thêm',
                onAction: () {},
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 240, // giảm từ ~190
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, i) => SizedBox(
                    width: 135,
                    child: _BookCard.small(
                      imageUrl: 'https://picsum.photos/seed/chat$i/400/600',
                      title: 'Chat story #$i',
                      subtitle: 'CP Idol',
                    ),
                  ),
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemCount: 6,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Truyện Hoàn Tiêu Biểu',
                actionText: 'Chuyên Khu Truyện Hoàn',
                onAction: () {},
              ),
            ),
            SliverList.separated(
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: _CompletedRow(
                  imageUrl: 'https://picsum.photos/seed/complete$i/400/600',
                  title: [
                    'Cô Vợ Yêu Nghiệt Của Đại Boss Mafia',
                    'Trái Tim Bị Đánh Cắp (Sủng) - Phi Yến',
                    'Tình Yêu Đến Từ Bao Giờ?',
                    'Một Đời Yêu Hận'
                  ][i % 4],
                  description:
                  'Gặp nhau vào bốn năm trước... câu chuyện rắc rối nhưng ngọt ngào tiếp diễn.',
                  tag: (i % 2 == 0) ? 'Tình Yêu Đô Thị' : 'Hôn Nhân',
                ),
              ),
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemCount: 3,
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------- Widgets phụ -------------------------- */

class _TopTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _TopTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, c) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        ],
      );
    });
  }
}

class _TabLabel extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;
  const _TabLabel({required this.text, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.titleMedium!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: base.copyWith(
            fontSize: 18, // nhỏ hơn 1 chút
            fontWeight: FontWeight.w700,
            color: active ? base.color : base.color?.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: TextField(
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tìm tiêu đề/tác giả',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: cs.surfaceVariant.withOpacity(0.6),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(20),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(20),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: cs.primary, width: 1.2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onSubmitted: (_) {},
          ),
        ),
        const SizedBox(width: 8),
        _RoundIconButton(icon: Icons.tune, onTap: () {}),
        const SizedBox(width: 6),
        _RoundIconButton(icon: Icons.grid_view, onTap: () {}),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Ink(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onAction;
  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 16, // nhỏ lại
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 0, 2),
      child: Row(
        children: [
          Text(title, style: style),
          const Spacer(),
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionText,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final bool compact;

  const _BookCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
  }) : compact = false;

  const _BookCard.small({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
  }) : compact = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 13,     // ↓ nhỏ lại
      height: 1.15,
    );
    final subStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 11,     // ↓ nhỏ lại
      height: 1.1,
      color: cs.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ảnh chiếm toàn bộ phần còn lại → không tràn
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        const SizedBox(height: 4), // giảm 6 -> 4
        Text(
          title,
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          // thu nhỏ nhẹ để chắc chắn không tràn
          style: titleStyle?.copyWith(fontSize: 12, height: 1.15),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: subStyle?.copyWith(fontSize: 10, height: 1.1),
        ),
      ],
    );

  }
}

/// Một dòng "Truyện Hoàn Tiêu Biểu"
class _CompletedRow extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String tag;

  const _CompletedRow({
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final coverW = w < 360 ? 68.0 : 80.0; // responsive
    final coverH = coverW * 4 / 3;

    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 16,
    );
    final descStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      height: 1.2,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final tagStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrl,
            width: coverW,
            height: coverH,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề 2 dòng, tránh overflow
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: titleStyle),
              const SizedBox(height: 4),
              // Mô tả 2 dòng
              Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: descStyle),
              const SizedBox(height: 6),
              Text(tag, maxLines: 1, overflow: TextOverflow.ellipsis, style: tagStyle),
            ],
          ),
        ),
      ],
    );
  }
}
