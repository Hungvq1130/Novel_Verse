import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_brightness/screen_brightness.dart';

enum ReadingTheme { light, sepia, gray, dark }

class ReaderPage extends StatefulWidget {
  final ReadingTheme? initialTheme; // 👈 thêm
  final ValueChanged<ReadingTheme>? onThemeChanged;
  final String title;
  final String content;
  final List<Map>? chapters;
  final int? currentIndex;
  final ValueChanged<int>? onGotoChapter;
  final VoidCallback? onPrevChapter;
  final VoidCallback? onNextChapter;

  const ReaderPage({
    super.key,
    required this.title,
    required this.content,
    this.chapters,
    this.currentIndex,
    this.onGotoChapter,
    this.onPrevChapter,
    this.onNextChapter,
    this.initialTheme, // 👈 thêm
    this.onThemeChanged,
  });

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> with TickerProviderStateMixin {
  // Overlays/panels
  bool _uiVisible = false;
  bool _chaptersOpen = false;
  bool _settingsOpen = false;

  // Settings
  static const Color _accent = Colors.blue; // màu nhấn xanh dương
  double _fontScale = 1.0; // 0.85..1.6
  double _lineHeight = 1.6; // 1.0..2.0
  String _fontKey = 'Roboto'; // Roboto | Merriweather | Open Sans
  bool _verticalReading = true;
  bool _showCommentsPerPara = true;
  ReadingTheme _theme = ReadingTheme.dark;

  // Brightness (màn hình máy)
  double _sysBrightness = 1.0;
  double? _prevBrightness;

  late final AnimationController _uiCtrl; // bật/tắt Top/Icons/Nav + scrim
  late final Animation<double> _uiOpacity; // opacity cho scrim
  late final Animation<Offset> _topSlide; // trượt top bar từ trên xuống
  late final Animation<Offset> _bottomBarsSlide; // trượt nav bar từ dưới lên

  late final AnimationController _chaptersCtrl; // panel Chương
  late final AnimationController _settingsCtrl; // panel Cài đặt
  late final Animation<Offset> _chaptersSlide; // trượt panel chương từ dưới lên
  late final Animation<Offset>
  _settingsSlide; // trượt panel cài đặt từ dưới lên

  Widget _swipeDismissWrapper({
    required Widget child,
    bool closeOnlyPanels = false,
  }) {
    const double kDismissSlop = 16; // ngưỡng nhỏ để nhận vuốt
    bool dismissed = false;
    void dismiss() {
      if (dismissed) return;
      dismissed = true;
      if (closeOnlyPanels) {
        _closePanels();
      } else {
        _hideAllUI();
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (d) {
        if (d.primaryDelta != null && d.primaryDelta!.abs() > kDismissSlop)
          dismiss();
      },
      onHorizontalDragUpdate: (d) {
        if (d.primaryDelta != null && d.primaryDelta!.abs() > kDismissSlop)
          dismiss();
      },
      onVerticalDragEnd: (_) => dismiss(),
      onHorizontalDragEnd: (_) => dismiss(),
      child: child,
    );
  }

  @override
  void initState() {
    super.initState();
    _uiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );

    final curve = CurvedAnimation(
      parent: _uiCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    );
    _uiOpacity = CurvedAnimation(parent: _uiCtrl, curve: Curves.easeInOut);

    _topSlide = Tween(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(curve);
    _bottomBarsSlide = Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curve);

    // panel controllers
    _chaptersCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _settingsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
    );

    final pCurve1 = CurvedAnimation(
      parent: _chaptersCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    );
    final pCurve2 = CurvedAnimation(
      parent: _settingsCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    );

    _chaptersSlide = Tween(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(pCurve1);
    _settingsSlide = Tween(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(pCurve2);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initBrightness();
    if (widget.initialTheme != null) {
      _theme = widget.initialTheme!; // 👈 dùng theme truyền vào
    }
  }

  Future<void> _initBrightness() async {
    try {
      final cur = await ScreenBrightness().current;
      _prevBrightness = cur;
      if (mounted) setState(() => _sysBrightness = cur);
    } catch (_) {
      /* ignore */
    }
  }

  Future<void> _setBrightness(double v) async {
    setState(() => _sysBrightness = v);
    try {
      await ScreenBrightness().setScreenBrightness(v);
    } catch (_) {
      /* ignore */
    }
  }

  @override
  void dispose() {
    _uiCtrl.dispose();
    _chaptersCtrl.dispose();
    _settingsCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (_prevBrightness != null) {
      ScreenBrightness().setScreenBrightness(_prevBrightness!);
    }
    super.dispose();
  }


  void _toggleUI() {
    if (_uiCtrl.status == AnimationStatus.dismissed) {
      setState(() => _uiVisible = true);
      _uiCtrl.forward();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      _uiCtrl.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _uiVisible = false;
          _chaptersOpen = false;
          _settingsOpen = false;
        });
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      });
    }
  }

  void _hideAllUI() {
    if (_uiCtrl.status == AnimationStatus.dismissed) return;
    _uiCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _uiVisible = false;
        _chaptersOpen = false;
        _settingsOpen = false;
      });
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
  }

  void _toggleChapters() {
    if (_chaptersOpen) {
      _chaptersCtrl.reverse().then((_) {
        if (!mounted) return;
        setState(() => _chaptersOpen = false);
      });
    } else {
      _settingsCtrl.reverse();
      setState(() => _settingsOpen = false);
      setState(() => _chaptersOpen = true);
      _chaptersCtrl.forward();
    }
  }

  void _toggleSettings() {
    if (_settingsOpen) {
      _settingsCtrl.reverse().then((_) {
        if (!mounted) return;
        setState(() => _settingsOpen = false);
      });
    } else {
      _chaptersCtrl.reverse();
      setState(() => _chaptersOpen = false);
      setState(() => _settingsOpen = true);
      _settingsCtrl.forward();
    }
  }

  void _closePanels() {
    _chaptersCtrl.reverse();
    _settingsCtrl.reverse();
    setState(() {
      _chaptersOpen = false;
      _settingsOpen = false;
    });
  }

  ThemeData _themeFor(ReadingTheme m) {
    const seed = Colors.blue;

    ThemeData make({
      required Brightness brightness,
      required Color bg,
      required Color surfaceVariant,
      required Color outlineVariant,
    }) {
      final scheme =
          ColorScheme.fromSeed(
            seedColor: seed,
            brightness: brightness,
          ).copyWith(
            surface: bg, // 🔵 bar/panel sẽ đúng cùng màu nền
            surfaceVariant: surfaceVariant,
            outlineVariant: outlineVariant,
          );
      return ThemeData(
        brightness: brightness,
        colorScheme: scheme,
        scaffoldBackgroundColor: bg,
      );
    }

    switch (m) {
      case ReadingTheme.light:
        return make(
          brightness: Brightness.light,
          bg: Colors.white,
          surfaceVariant: const Color(0xFFE7E7E7),
          outlineVariant: const Color(0xFFDDDDDD),
        );
      case ReadingTheme.sepia:
        return make(
          brightness: Brightness.light,
          bg: const Color(0xFFF1E9E1),
          surfaceVariant: const Color(0xFFE4DACE),
          outlineVariant: const Color(0xFFD8CFC3),
        );
      case ReadingTheme.gray:
        return make(
          brightness: Brightness.dark,
          bg: const Color(0xFF2E3138),
          surfaceVariant: const Color(0xFF3A3E46),
          outlineVariant: const Color(0xFF4A4F59),
        );
      case ReadingTheme.dark:
      default:
        return make(
          brightness: Brightness.dark,
          bg: const Color(0xFF121212),
          surfaceVariant: const Color(0xFF1E1E1E),
          outlineVariant: const Color(0xFF2A2A2A),
        );
    }
  }

  TextStyle _contentTextStyle(BuildContext context, double baseSize) {
    final family = _fontKey == 'Roboto'
        ? null
        : (_fontKey == 'Merriweather' ? 'serif' : 'sans-serif');
    return TextStyle(
      fontSize: baseSize * _fontScale,
      height: _lineHeight,
      fontFamily: family,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themeFor(_theme);

    return Theme(
      data: theme, // toàn bộ trang reader theo theme đã chọn
      child: Builder(
        builder: (context) {
          final mq = MediaQuery.of(context);
          final cs = Theme.of(context).colorScheme;

          const double _chapterHF = 0.75; // height factor panel Chương
          const double _settingsHF =
              0.51; // height factor panel Cài đặt (thấp hơn)

          // responsive
          final shortest = mq.size.shortestSide;
          final baseScale = (shortest / 392.0).clamp(0.85, 1.25);
          double rem(double v) => v * baseScale;

          final topPad = mq.padding.top;
          final safeBottom = mq.padding.bottom.ceilToDouble();

          // thanh dưới: tách nav + icons
          final navBarH = rem(48);
          final iconsBarBodyH = rem(56);
          final iconsBarTotalH = iconsBarBodyH + safeBottom;
          final bottomBarsH = navBarH + iconsBarBodyH + safeBottom;

          final topBarH = kToolbarHeight + topPad;

          final chapters = widget.chapters ?? const <Map>[];
          final currentIndex = (widget.currentIndex ?? 0).clamp(
            0,
            (chapters.length - 1).clamp(0, chapters.length),
          );

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: [
                // ===== Nội dung
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleUI,
                    child: SingleChildScrollView(
                      physics: _uiVisible
                          ? const NeverScrollableScrollPhysics()
                          : const ClampingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        rem(20),
                        rem(20),
                        rem(20),
                        rem(24),
                      ),
                      child: Text(
                        widget.content,
                        textAlign: TextAlign.justify,
                        style: _contentTextStyle(context, 16),
                      ),
                    ),
                  ),
                ),

                // ===== Chặn gesture khi UI mở
                if (_uiVisible)
                  Positioned.fill(
                    child: _swipeDismissWrapper(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleUI, // vẫn cho phép chạm để tắt
                        child: const SizedBox.expand(), // vùng bắt vuốt
                      ),
                    ),
                  ),

                // ===== Scrim mờ (top + vùng dưới)
                IgnorePointer(
                  ignoring: true,
                  child: IgnorePointer(
                    ignoring: _uiCtrl.status == AnimationStatus.dismissed && _uiCtrl.value == 0,
                    child: FadeTransition(
                      opacity: _uiOpacity,
                      child: Column(
                        children: [
                          Container(height: topBarH, decoration: BoxDecoration(/* gradient như cũ */)),
                          const Spacer(),
                          Container(
                            height: bottomBarsH,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black.withOpacity(0.35), Colors.transparent],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ===== Scrim đóng panel
                if (_chaptersOpen || _settingsOpen)
                  Positioned.fill(
                    child: _swipeDismissWrapper(
                      closeOnlyPanels: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _closePanels,
                        child: Container(color: Colors.black.withOpacity(0.35)),
                      ),
                    ),
                  ),

                // ==== BOTTOM BARS (Nav + Icons) — animate cùng nhau
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: SlideTransition(
                    position: _bottomBarsSlide,
                    child: _swipeDismissWrapper( // vẫn cho vuốt để đóng
                      child: Container(
                        height: bottomBarsH,
                        decoration: const BoxDecoration(), // để trống - style bên trong từng bar
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // --- NAV BAR (Chương trước / sau)
                            Container(
                              height: navBarH,
                              decoration: BoxDecoration(
                                color: cs.surface,
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: rem(4))],
                                border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.7)),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: rem(8)),
                                child: Row(
                                  children: [
                                    TextButton(
                                      onPressed: widget.onPrevChapter,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.chevron_left, size: rem(20)),
                                          SizedBox(width: rem(4)),
                                          Text('Chương trước', style: TextStyle(fontSize: rem(14))),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: widget.onNextChapter,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Chương sau', style: TextStyle(fontSize: rem(14))),
                                          SizedBox(width: rem(4)),
                                          Icon(Icons.chevron_right, size: rem(20)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // --- ICONS BAR (Chương / Cài đặt...)
                            Container(
                              height: iconsBarBodyH + safeBottom, // tự cộng safeBottom, không dùng SafeArea nữa
                              decoration: BoxDecoration(
                                color: cs.surface,
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: rem(6))],
                              ),
                              padding: EdgeInsets.fromLTRB(rem(12), rem(6), rem(12), rem(6) + safeBottom),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  InkWell(
                                    onTap: chapters.isEmpty ? null : _toggleChapters,
                                    child: _BarIcon(
                                      text: 'Chương',
                                      icon: Icons.format_list_bulleted_outlined,
                                      active: _chaptersOpen,
                                      disabled: chapters.isEmpty,
                                      activeColor: _accent,
                                      iconSize: rem(22), fontSize: rem(12),
                                    ),
                                  ),
                                  const _BarIcon(text: 'Thích', icon: Icons.thumb_up_alt_outlined),
                                  const _BarIcon(text: 'Bình luận', icon: Icons.comment_outlined),
                                  InkWell(
                                    onTap: _toggleSettings,
                                    child: _BarIcon(
                                      text: 'Cài đặt',
                                      icon: Icons.settings_outlined,
                                      active: _settingsOpen,
                                      activeColor: _accent,
                                      iconSize: rem(22), fontSize: rem(12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),


                // ===== PANEL CHAPTERS (trên NavBar, dưới IconsBar)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  left: 0,
                  right: 0,
                  bottom: _chaptersOpen
                      ? iconsBarTotalH
                      : -(mq.size.height * _chapterHF),
                  child: IgnorePointer(
                    ignoring: !_chaptersOpen,
                    child: _ChapterPanel(
                      topPad: topPad,
                      radius: 20,
                      bottomPadding: rem(16),
                      heightFactor: _chapterHF,
                      chapters: chapters,
                      currentIndex: currentIndex,
                      fontScale: baseScale,
                      accentBlue: _accent,
                      onTapItem: (i) {
                        if (widget.chapters != null &&
                            i >= 0 &&
                            i < widget.chapters!.length) {
                          widget.chapters![i]['read'] =
                              true; // chỉ chương đã chọn mới mờ
                        }
                        _closePanels();
                        widget.onGotoChapter?.call(i);
                      },
                    ),
                  ),
                ),

                // ===== PANEL SETTINGS (trên NavBar, dưới IconsBar)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  left: 0,
                  right: 0,
                  bottom: _settingsOpen
                      ? iconsBarTotalH
                      : -(mq.size.height * _settingsHF),
                  child: IgnorePointer(
                    ignoring: !_settingsOpen,
                    child: _SettingsPanel(
                      topPad: topPad,
                      radius: 20,
                      bottomPadding: rem(16),
                      fontScale: baseScale,
                      accentBlue: _accent,
                      heightFactor: _settingsHF,
                      // values
                      systemBrightness: _sysBrightness,
                      theme: _theme,
                      fontScaleValue: _fontScale,
                      lineHeight: _lineHeight,
                      verticalReading: _verticalReading,
                      fontKey: _fontKey,
                      showCommentsPerPara: _showCommentsPerPara,
                      // callbacks
                      onBrightnessChanged: _setBrightness,
                      onThemeChanged: (m) {
                        setState(() => _theme = m); // cập nhật UI hiện tại
                        widget.onThemeChanged?.call(
                          m,
                        ); // báo về ChaptersPage để lưu
                      },
                      onFontScaleMinus: () => setState(
                        () => _fontScale = (_fontScale - 0.05).clamp(0.85, 1.6),
                      ),
                      onFontScalePlus: () => setState(
                        () => _fontScale = (_fontScale + 0.05).clamp(0.85, 1.6),
                      ),
                      onLineHeightMinus: () => setState(
                        () => _lineHeight = (_lineHeight - 0.1).clamp(1.0, 2.0),
                      ),
                      onLineHeightPlus: () => setState(
                        () => _lineHeight = (_lineHeight + 0.1).clamp(1.0, 2.0),
                      ),
                      onDirectionChanged: (v) =>
                          setState(() => _verticalReading = v),
                      onFontChanged: (k) => setState(() => _fontKey = k),
                      onShowCommentsChanged: (v) =>
                          setState(() => _showCommentsPerPara = v),
                    ),
                  ),
                ),

                // ===== TOP BAR
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  top: _uiVisible ? 0 : -topBarH,
                  left: 0,
                  right: 0,
                  child: SlideTransition(
                    position: _topSlide,
                    child: Container(
                      height: topBarH,
                      padding: EdgeInsets.only(top: topPad),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: rem(6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, size: rem(22)),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: rem(16),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: rem(8)),
                            child: FilledButton(
                              onPressed: () {},
                              child: Text(
                                'Chi tiết',
                                style: TextStyle(fontSize: rem(13)),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.more_vert, size: rem(22)),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ===== ICONS BAR (THANH CHỌN)
              ],
            ),
          );
        },
      ),
    );
  }
}

// ====== Small widgets ======

class _BarIcon extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool active;
  final bool disabled;
  final double iconSize;
  final double fontSize;
  final Color? activeColor;

  const _BarIcon({
    required this.text,
    required this.icon,
    this.active = false,
    this.disabled = false,
    this.iconSize = 22,
    this.fontSize = 12,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color base = disabled
        ? cs.outline
        : (active ? (activeColor ?? Colors.blue) : cs.onSurfaceVariant);
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: base),
          const SizedBox(height: 2),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              height: 1.0,
              color: base,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ====== Chapter panel (không số thứ tự, không tick, xanh dương) ======

class _ChapterPanel extends StatefulWidget {
  final double topPad;
  final double bottomPadding;
  final double radius;
  final List<Map> chapters;
  final int currentIndex;
  final void Function(int) onTapItem;
  final double fontScale;
  final Color accentBlue;
  final double heightFactor;

  const _ChapterPanel({
    super.key,
    required this.topPad,
    required this.bottomPadding,
    required this.radius,
    required this.chapters,
    required this.currentIndex,
    required this.onTapItem,
    this.fontScale = 1.0,
    this.accentBlue = Colors.blue,
    required this.heightFactor,
  });

  @override
  State<_ChapterPanel> createState() => _ChapterPanelState();
}

class _ChapterPanelState extends State<_ChapterPanel> {
  bool newestFirst = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final h = size.height * widget.heightFactor;
    double rem(double v) => v * widget.fontScale;

    final total = widget.chapters.length;
    List<int> order = List<int>.generate(total, (i) => i);
    if (newestFirst) order = order.reversed.toList();

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(widget.radius),
        ),
        child: Material(
          color: cs.surface,
          elevation: 12,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(widget.radius),
            ),
          ),
          child: SizedBox(
            height: h,
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.only(
                    top: widget.topPad + rem(8),
                    left: rem(16),
                    right: rem(12),
                    bottom: rem(8),
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border(
                      bottom: BorderSide(color: cs.outlineVariant, width: 0.7),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$total Chương',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: rem(14),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => newestFirst = false),
                            child: Text(
                              'Cũ nhất',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: rem(13),
                                color: newestFirst ? null : widget.accentBlue,
                              ),
                            ),
                          ),
                          SizedBox(width: rem(12)),
                          Container(
                            width: 1,
                            height: rem(14),
                            color: cs.outlineVariant,
                          ),
                          SizedBox(width: rem(12)),
                          GestureDetector(
                            onTap: () => setState(() => newestFirst = true),
                            child: Text(
                              'Mới nhất',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: rem(13),
                                color: newestFirst ? widget.accentBlue : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Danh sách chương
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      rem(14),
                      rem(10),
                      rem(14),
                      widget.bottomPadding,
                    ),
                    itemCount: order.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: cs.outlineVariant),
                    itemBuilder: (_, i) {
                      final idx = order[i];
                      final ch = widget.chapters[idx];
                      final title =
                          (ch['title'] ?? 'Chương ${ch['indexInBook']}')
                              as String;

                      final isCurrent = idx == widget.currentIndex;
                      final isRead =
                          (ch['read'] ==
                          true); // chỉ mờ nếu chính chương đó đã chọn

                      final color = isCurrent
                          ? widget.accentBlue
                          : cs.onSurface;
                      final weight = isCurrent
                          ? FontWeight.w700
                          : FontWeight.w500;

                      return InkWell(
                        onTap: () => widget.onTapItem(idx),
                        borderRadius: BorderRadius.circular(rem(14)),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: rem(10),
                            horizontal: rem(8),
                          ),
                          child: Opacity(
                            opacity: isCurrent ? 1 : (isRead ? 0.55 : 1),
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: color,
                                fontWeight: weight,
                                fontSize: rem(15),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ====== Settings panel (độ sáng màn hình + theme) ======

class _SettingsPanel extends StatelessWidget {
  final double topPad;
  final double bottomPadding;
  final double radius;
  final double fontScale;
  final Color accentBlue;
  final double heightFactor;

  // values
  final double systemBrightness;
  final ReadingTheme theme;
  final double fontScaleValue;
  final double lineHeight;
  final bool verticalReading;
  final String fontKey;
  final bool showCommentsPerPara;

  // callbacks
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<ReadingTheme> onThemeChanged;
  final VoidCallback onFontScaleMinus;
  final VoidCallback onFontScalePlus;
  final VoidCallback onLineHeightMinus;
  final VoidCallback onLineHeightPlus;
  final ValueChanged<bool> onDirectionChanged;
  final ValueChanged<String> onFontChanged;
  final ValueChanged<bool> onShowCommentsChanged;

  const _SettingsPanel({
    super.key,
    required this.topPad,
    required this.bottomPadding,
    required this.radius,
    required this.fontScale,
    required this.accentBlue,
    required this.systemBrightness,
    required this.theme,
    required this.fontScaleValue,
    required this.lineHeight,
    required this.verticalReading,
    required this.fontKey,
    required this.showCommentsPerPara,
    required this.onBrightnessChanged,
    required this.onThemeChanged,
    required this.onFontScaleMinus,
    required this.onFontScalePlus,
    required this.onLineHeightMinus,
    required this.onLineHeightPlus,
    required this.onDirectionChanged,
    required this.onFontChanged,
    required this.onShowCommentsChanged,
    required this.heightFactor,
  });

  @override
  Widget build(BuildContext context) {
    Color _bgOf(ReadingTheme m) {
      switch (m) {
        case ReadingTheme.light:
          return Colors.white;
        case ReadingTheme.sepia:
          return const Color(0xFFF1E9E1);
        case ReadingTheme.gray:
          return const Color(0xFF2E3138);
        case ReadingTheme.dark:
          return const Color(0xFF121212);
      }
    }

    final cs = Theme.of(context).colorScheme;
    double rem(double v) => v * fontScale;
    final h = MediaQuery.of(context).size.height * heightFactor;

    Widget chip(String text, bool active, VoidCallback onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(rem(999)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: rem(14), vertical: rem(8)),
        decoration: BoxDecoration(
          color: active ? accentBlue.withOpacity(0.12) : cs.surface,
          border: Border.all(
            color: active ? accentBlue : cs.outlineVariant,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(rem(999)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: rem(13),
            color: active ? accentBlue : cs.onSurface,
          ),
        ),
      ),
    );
    Widget _swatch(ReadingTheme m) {
      final active = theme == m; // 'theme' là field của _SettingsPanel
      final c = _bgOf(m);
      return InkWell(
        onTap: () => onThemeChanged(m),
        borderRadius: BorderRadius.circular(rem(14)),
        child: Container(
          width: rem(44),
          height: rem(28),
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(rem(14)),
            border: Border.all(
              color: active ? accentBlue : cs.outlineVariant,
              width: active ? 2 : 1.5,
            ),
            // để swatch nổi nhẹ trên bg tương tự
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: rem(3),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
        child: Material(
          color: cs.surface,
          elevation: 12,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
          ),
          child: SizedBox(
            height: h,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                rem(16),
                topPad + rem(12),
                rem(16),
                bottomPadding,
              ),
              children: [
                // Brightness (màn hình máy)
                _SectionTitle('Độ sáng'),
                Row(
                  children: [
                    Icon(
                      Icons.brightness_low,
                      size: rem(18),
                      color: cs.onSurfaceVariant,
                    ),
                    Expanded(
                      child: Slider(
                        value: systemBrightness,
                        onChanged: onBrightnessChanged,
                        min: 0,
                        max: 1,
                        activeColor: accentBlue,
                      ),
                    ),
                    Icon(
                      Icons.brightness_high,
                      size: rem(18),
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
                SizedBox(height: rem(8)),

                // Theme mode
                _SectionTitle('Màu nền'),
                Wrap(
                  spacing: rem(12),
                  runSpacing: rem(10),
                  children: [
                    _swatch(ReadingTheme.light),
                    _swatch(ReadingTheme.sepia),
                    _swatch(ReadingTheme.gray),
                    _swatch(ReadingTheme.dark),
                  ],
                ),
                SizedBox(height: rem(14)),

                // Size + line height
                _SectionTitle('Size'),
                Row(
                  children: [
                    _RoundBtn(
                      icon: Icons.text_decrease,
                      onTap: onFontScaleMinus,
                      size: rem(36),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: rem(12)),
                      child: Text(
                        (fontScaleValue * 16).toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: rem(15),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _RoundBtn(
                      icon: Icons.text_increase,
                      onTap: onFontScalePlus,
                      size: rem(36),
                    ),
                    const Spacer(),
                    _RoundBtn(
                      icon: Icons.format_line_spacing,
                      onTap: onLineHeightMinus,
                      size: rem(36),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: rem(8)),
                      child: Text(
                        lineHeight.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: rem(15),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _RoundBtn(
                      icon: Icons.format_line_spacing,
                      onTap: onLineHeightPlus,
                      size: rem(36),
                      rotated: true,
                    ),
                  ],
                ),
                SizedBox(height: rem(14)),

                // Direction
                _SectionTitle('Chế độ lật trang'),
                Row(
                  children: [
                    chip(
                      'Theo chiều dọc',
                      verticalReading,
                      () => onDirectionChanged(true),
                    ),
                    SizedBox(width: rem(12)),
                    chip(
                      'Lật ngang',
                      !verticalReading,
                      () => onDirectionChanged(false),
                    ),
                  ],
                ),
                SizedBox(height: rem(14)),

                // Fonts
                _SectionTitle('Font'),
                Wrap(
                  spacing: rem(12),
                  runSpacing: rem(10),
                  children: [
                    chip(
                      'Roboto',
                      fontKey == 'Roboto',
                      () => onFontChanged('Roboto'),
                    ),
                    chip(
                      'Merriweather',
                      fontKey == 'Merriweather',
                      () => onFontChanged('Merriweather'),
                    ),
                    chip(
                      'Open Sans',
                      fontKey == 'Open Sans',
                      () => onFontChanged('Open Sans'),
                    ),
                  ],
                ),
                SizedBox(height: rem(14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool rotated;

  const _RoundBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 36,
    this.rotated = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Center(
          child: Transform.rotate(
            angle: rotated ? 3.1415 : 0,
            child: Icon(icon, size: size * 0.55, color: cs.onSurface),
          ),
        ),
      ),
    );
  }
}
