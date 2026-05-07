import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'developer_page.dart';
import 'splash_screen.dart';
import 'home_page.dart';
import 'daily_dhikr_screen.dart';
import 'dua_screen.dart';
import 'special_dhikr_screen.dart';
import 'after_prayer_dhikr_screen.dart';
import 'amar_plan_page.dart';
import 'settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('bn', null);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  runApp(const DailyZikirApp());
}

class DailyZikirApp extends StatefulWidget {
  const DailyZikirApp({super.key});

  @override
  State<DailyZikirApp> createState() => _DailyZikirAppState();
}

class _DailyZikirAppState extends State<DailyZikirApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  String _currentFont = 'Hind Siliguri';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      String? savedTheme = prefs.getString('theme_mode');
      if (savedTheme == 'Light') {
        _themeMode = ThemeMode.light;
      } else if (savedTheme == 'System') {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.dark;
      }

      _currentFont = prefs.getString('app_font') ?? 'Hind Siliguri';
    });
  }

  void _updateTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void _updateFont(String fontName) {
    setState(() {
      _currentFont = fontName;
    });
  }

  TextTheme _getTextTheme(Brightness brightness) {
    TextTheme baseTheme = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    try {
      return GoogleFonts.getTextTheme(_currentFont, baseTheme);
    } catch (e) {
      return GoogleFonts.hindSiliguriTextTheme(baseTheme);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daily Zikir',
      themeMode: _themeMode,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[200],
        cardColor: Colors.white,
        primaryColor: const Color(0xFFB8956A),
        textTheme: _getTextTheme(Brightness.light).apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black87),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB8956A),
          brightness: Brightness.light,
          surface: Colors.white,
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E1014),
        primaryColor: const Color(0xFFD6C9B0),
        textTheme: _getTextTheme(Brightness.dark),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
      ),

      home: const SplashScreen(),

      onGenerateRoute: (settings) {
        if (settings.name == '/main') {
          return MaterialPageRoute(
            builder: (context) => MainNavigation(
              onThemeChanged: _updateTheme,
              onFontChanged: _updateFont,
            ),
          );
        }
        return null;
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;
  final Function(String)? onFontChanged;

  const MainNavigation({super.key, this.onThemeChanged, this.onFontChanged});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const DailyDhikrScreen(),
    const SpecialDhikrScreen(),
    const AfterPrayerDhikrScreen(),
    const DuaScreen(),
    const AmarPlanPage(),
  ];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFab(
              heroTag: "settings_btn",
              icon: Icons.settings_rounded,
              isDark: isDark,
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(
                      onThemeChanged: widget.onThemeChanged!,
                      onFontChanged: widget.onFontChanged!,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildFab(
              heroTag: "dev_btn",
              icon: Icons.code_rounded,
              isDark: isDark,
              onPressed: () {
                HapticFeedback.mediumImpact();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF171C22) : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const Expanded(child: DeveloperPage()),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      bottomNavigationBar: _ClassyBottomNav(
        currentIndex: _selectedIndex,
        onTap: (i) {
          setState(() => _selectedIndex = i);
        },
      ),
    );
  }

  Widget _buildFab({required String heroTag, required IconData icon, required bool isDark, required VoidCallback onPressed}) {
    return SizedBox(
      width: 35,
      height: 35,
      child: FloatingActionButton(
        heroTag: heroTag,
        elevation: 4,
        backgroundColor: isDark ? const Color(0xFF1C1E24) : Colors.white,
        shape: CircleBorder(
          side: BorderSide(
              color: isDark ? const Color(0xFF2E3A4A) : Colors.grey[300]!,
              width: 0.5
          ),
        ),
        onPressed: onPressed,
        child: Icon(icon, size: 18, color: const Color(0xFFB8956A)),
      ),
    );
  }
}

class _ClassyBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ClassyBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'হোম'),
    _NavItem(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book_rounded, label: 'দৈনন্দিন'),
    _NavItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, label: 'বিশেষ'),
    _NavItem(icon: Icons.nights_stay_outlined, activeIcon: Icons.nights_stay_rounded, label: 'নামাজ'),
    _NavItem(icon: Icons.import_contacts_outlined, activeIcon: Icons.import_contacts_rounded, label: 'দোয়া'),
  ];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0F12) : Colors.white,
        border: Border(
          top: BorderSide(
              color: isDark ? const Color(0xFF1C1E24) : Colors.grey[300]!,
              width: 0.8
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 65,
          child: Row(
            children: List.generate(
              _items.length,
                  (i) => Expanded(
                child: _NavTile(
                  item: _items[i],
                  isActive: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? const Color(0xFFD6C9B0) : const Color(0xFFB8956A);
    final inactiveColor = isDark ? const Color(0xFF3E424D) : Colors.grey[400];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _ctrl.forward();
      },
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isActive ? widget.item.activeIcon : widget.item.icon,
                size: widget.isActive ? 24 : 22,
                color: widget.isActive ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.label,
                style: TextStyle(
                  fontSize: 10.5,
                  color: widget.isActive ? activeColor : inactiveColor,
                  fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
