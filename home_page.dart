import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'stats_page.dart';
import 'amar_plan_page.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PrayerTimes? _prayerTimes;
  Timer? _timer;
  String _locationName = "লোকেশন খোঁজা হচ্ছে...";
  String _hijriDate = "লোড হচ্ছে...";
  bool _showCountdown = false;

  @override
  void initState() {
    super.initState();
    _initData();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initData() async {
    await _getPrayerTimes();
  }

  Future<void> _calculateLocalHijri() async {
    final dateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final url = Uri.parse('https://api.aladhan.com/v1/gToH?date=$dateStr');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final hijri = data['data']['hijri'];

        // মাসগুলোর বাংলা নাম
        Map<String, String> monthsBn = {
          "Al-Muḥarram": "মুহররম", "Ṣafar": "সফর", "Rabīʿ al-awwal": "রবিউল আউয়াল",
          "Rabīʿ al-thānī": "রবিউস সানি", "Jumādā al-ūlā": "জমাদিউল আউয়াল",
          "Jumādā al-ākhirah": "জমাদিউস সানি", "Rajab": "রজব", "Shaʿbān": "শাবান",
          "Ramaḍān": "রমজান", "Shawwāl": "শাওয়াল", "Dhū al-Qaʿdah": "জিলকদ", "Dhū al-Ḥijjah": "জিলহজ"
        };

        String monthEn = hijri['month']['en'];
        String monthBn = monthsBn[monthEn] ?? monthEn;

        if (mounted) {
          setState(() {
            _hijriDate = "${_toBangla(hijri['day'])} $monthBn, ${_toBangla(hijri['year'])} হিজরি";
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching Hijri: $e");
    }
  }

  Future<void> _getPrayerTimes() async {
    try {
      Position position = await _determinePosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      String city = "আপনার অবস্থান";
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        city = (place.subLocality?.isNotEmpty == true) ? place.subLocality! : (place.locality ?? "আপনার এলাকা");
      }

      final coordinates = Coordinates(position.latitude, position.longitude);
      final params = CalculationMethod.karachi.getParameters();
      params.madhab = Madhab.hanafi;

      if (mounted) {
        setState(() {
          _prayerTimes = PrayerTimes.today(coordinates, params);
          _locationName = city;
        });
        // ফাংশন কল এখন সঠিক নামের সাথে মিলবে
        _calculateLocalHijri();
      }
    } catch (e) {
      final coordinates = Coordinates(23.8103, 90.4125);
      final params = CalculationMethod.karachi.getParameters();
      params.madhab = Madhab.hanafi;
      if (mounted) {
        setState(() {
          _prayerTimes = PrayerTimes.today(coordinates, params);
          _locationName = "ঢাকা (ডিফল্ট)";
        });
        _calculateLocalHijri();
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Permission denied');
    }
    return await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.low));
  }

  String _toBangla(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], bangla[i]);
    }
    return input;
  }

  String _getBengaliCalendarDate(DateTime date) {
    int day = date.day;
    int month = date.month;
    int year = date.year;
    int bDay; String bMonth; int bYear = year - 593;

    if (month == 4) {
      if (day <= 13) { bMonth = "চৈত্র"; bDay = day + 17; bYear--; }
      else { bMonth = "বৈশাখ"; bDay = day - 13; }
    } else if (month == 5) {
      if (day <= 14) { bMonth = "বৈশাখ"; bDay = day + 17; }
      else { bMonth = "জ্যৈষ্ঠ"; bDay = day - 14; }
    } else if (month == 6) {
      if (day <= 14) { bMonth = "জ্যৈষ্ঠ"; bDay = day + 17; }
      else { bMonth = "আষাঢ়"; bDay = day - 14; }
    } else if (month == 7) {
      if (day <= 15) { bMonth = "আষাঢ়"; bDay = day + 16; }
      else { bMonth = "শ্রাবণ"; bDay = day - 15; }
    } else if (month == 8) {
      if (day <= 15) { bMonth = "শ্রাবণ"; bDay = day + 16; }
      else { bMonth = "ভাদ্র"; bDay = day - 15; }
    } else if (month == 9) {
      if (day <= 15) { bMonth = "ভাদ্র"; bDay = day + 16; }
      else { bMonth = "আশ্বিন"; bDay = day - 15; }
    } else if (month == 10) {
      if (day <= 15) { bMonth = "আশ্বিন"; bDay = day + 15; }
      else { bMonth = "কার্তিক"; bDay = day - 15; }
    } else if (month == 11) {
      if (day <= 14) { bMonth = "কার্তিক"; bDay = day + 16; }
      else { bMonth = "অগ্রহায়ণ"; bDay = day - 14; }
    } else if (month == 12) {
      if (day <= 14) { bMonth = "অগ্রহায়ণ"; bDay = day + 16; }
      else { bMonth = "পৌষ"; bDay = day - 14; }
    } else if (month == 1) {
      if (day <= 13) { bMonth = "পৌষ"; bDay = day + 17; bYear--; }
      else { bMonth = "মাঘ"; bDay = day - 13; }
    } else if (month == 2) {
      if (day <= 12) { bMonth = "মাঘ"; bDay = day + 18; bYear--; }
      else { bMonth = "ফাল্গুন"; bDay = day - 12; }
    } else if (month == 3) {
      if (day <= 14) { bMonth = "ফাল্গুন"; bDay = day + 16; bYear--; }
      else { bMonth = "চৈত্র"; bDay = day - 14; bYear--; }
    } else { bMonth = "বৈশাখ"; bDay = 1; }

    return "${_toBangla(bDay.toString())} $bMonth, ${_toBangla(bYear.toString())}";
  }

  Future<Map<String, dynamic>> _getPlanProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('user_daily_plans');
    if (savedData == null || savedData == '[]') return {"done": 0, "total": 0, "percent": 0.0};
    final List<dynamic> plans = json.decode(savedData);
    int total = plans.length;
    int done = plans.where((p) => p['isDone'] == true).length;
    return {"done": done, "total": total, "percent": total > 0 ? done / total : 0.0};
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final String dayName = DateFormat('EEEE', 'bn').format(now);
    final String formattedDate = _toBangla(DateFormat('dd MMMM yyyy', 'bn').format(now));
    final String bengaliDate = _getBengaliCalendarDate(now);

    String activeStatusName = "পরবর্তী";
    String activeTimeRange = "--:--";
    int highlightIndex = -1;
    bool isCurrentWakt = false;

    if (_prayerTimes != null) {
      final List<_Prayer> mainPrayers = [
        _Prayer("ফজর", _prayerTimes!.fajr, _prayerTimes!.sunrise, Icons.wb_twilight_rounded),
        _Prayer("যোহর", _prayerTimes!.dhuhr, _prayerTimes!.asr, Icons.wb_sunny_outlined),
        _Prayer("আসর", _prayerTimes!.asr, _prayerTimes!.maghrib, Icons.cloud_outlined),
        _Prayer("মাগরিব", _prayerTimes!.maghrib, _prayerTimes!.isha, Icons.wb_twilight_outlined),
        _Prayer("এশা", _prayerTimes!.isha, _prayerTimes!.fajr.add(const Duration(hours: 24)), Icons.nightlight_round_outlined),
      ];

      final sunrise = _prayerTimes!.sunrise;
      final forbiddenSunriseEnd = sunrise.add(const Duration(minutes: 15));
      final ishraqStart = forbiddenSunriseEnd;
      final ishraqEnd = ishraqStart.add(const Duration(minutes: 45));
      final chashtEnd = _prayerTimes!.dhuhr.subtract(const Duration(minutes: 30));
      final forbiddenNoonStart = _prayerTimes!.dhuhr.subtract(const Duration(minutes: 10));
      final forbiddenSunsetStart = _prayerTimes!.maghrib.subtract(const Duration(minutes: 15));
      final tahajjudStart = _prayerTimes!.isha.add(const Duration(hours: 2));

      if (now.isAfter(sunrise) && now.isBefore(forbiddenSunriseEnd)) {
        activeStatusName = "নিষিদ্ধ সময় (সূর্যোদয়)";
        activeTimeRange = "${_toBangla(DateFormat.jm('bn').format(sunrise))} - ${_toBangla(DateFormat.jm('bn').format(forbiddenSunriseEnd))}";
      } else if (now.isAfter(forbiddenNoonStart) && now.isBefore(_prayerTimes!.dhuhr)) {
        activeStatusName = "নিষিদ্ধ সময় (জাওয়াল)";
        activeTimeRange = "${_toBangla(DateFormat.jm('bn').format(forbiddenNoonStart))} - ${_toBangla(DateFormat.jm('bn').format(_prayerTimes!.dhuhr))}";
      } else if (now.isAfter(forbiddenSunsetStart) && now.isBefore(_prayerTimes!.maghrib)) {
        activeStatusName = "নিষিদ্ধ সময় (সূর্যাস্ত)";
        activeTimeRange = "${_toBangla(DateFormat.jm('bn').format(forbiddenSunsetStart))} - ${_toBangla(DateFormat.jm('bn').format(_prayerTimes!.maghrib))}";
      } else if (now.isAfter(ishraqStart) && now.isBefore(ishraqEnd)) {
        activeStatusName = "ইশরাক ওয়াক্ত";
        activeTimeRange = "${_toBangla(DateFormat.jm('bn').format(ishraqStart))} - ${_toBangla(DateFormat.jm('bn').format(ishraqEnd))}";
      } else if (now.isAfter(ishraqEnd) && now.isBefore(chashtEnd)) {
        activeStatusName = "চাশত ওয়াক্ত";
        activeTimeRange = "${_toBangla(DateFormat.jm('bn').format(ishraqEnd))} - ${_toBangla(DateFormat.jm('bn').format(chashtEnd))}";
      } else if (now.isAfter(tahajjudStart) || now.isBefore(_prayerTimes!.fajr.subtract(const Duration(minutes: 1)))) {
        activeStatusName = "তাহাজ্জুদ ওয়াক্ত";
        activeTimeRange = "শেষরাত - ${_toBangla(DateFormat.jm('bn').format(_prayerTimes!.fajr))}";
      } else {
        int currentIdx = mainPrayers.indexWhere((p) => now.isAfter(p.start) && now.isBefore(p.end));
        if (currentIdx != -1) {
          highlightIndex = currentIdx;
          isCurrentWakt = true;
          activeStatusName = mainPrayers[currentIdx].name;
          activeTimeRange = "${_toBangla(DateFormat.jm('bn').format(mainPrayers[currentIdx].start))} - ${_toBangla(DateFormat.jm('bn').format(mainPrayers[currentIdx].end))}";
        } else {
          int nextIdx = mainPrayers.indexWhere((p) => p.start.isAfter(now));
          if (nextIdx == -1) nextIdx = 0;
          highlightIndex = nextIdx;
          activeStatusName = "পরবর্তী: ${mainPrayers[highlightIndex].name}";
          activeTimeRange = _toBangla(DateFormat.jm('bn').format(mainPrayers[highlightIndex].start));
        }
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _HeroHeader(
              dayName: dayName,
              dateStr: formattedDate,
              hijriDate: _hijriDate,
              bengaliDate: bengaliDate,
              prayerTimes: _prayerTimes,
              location: _locationName,
              activeName: activeStatusName,
              activeTime: activeTimeRange,
              toBangla: _toBangla,
              showCountdown: _showCountdown,
              onToggle: () => setState(() => _showCountdown = !_showCountdown),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _getPlanProgress(),
              builder: (context, snapshot) {
                final data = snapshot.data ?? {"done": 0, "total": 0, "percent": 0.0};
                return _ProgressCard(
                  done: data['done'],
                  total: data['total'],
                  percent: data['percent'],
                  toBangla: _toBangla,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AmarPlanPage())).then((_) => setState(() {})),
                );
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, i) {
                  final List<_Prayer> mainPrayers = _prayerTimes == null ? [] : [
                    _Prayer("ফজর", _prayerTimes!.fajr, _prayerTimes!.sunrise, Icons.wb_twilight_rounded),
                    _Prayer("যোহর", _prayerTimes!.dhuhr, _prayerTimes!.asr, Icons.wb_sunny_outlined),
                    _Prayer("আসর", _prayerTimes!.asr, _prayerTimes!.maghrib, Icons.cloud_outlined),
                    _Prayer("মাগরিব", _prayerTimes!.maghrib, _prayerTimes!.isha, Icons.wb_twilight_outlined),
                    _Prayer("এশা", _prayerTimes!.isha, _prayerTimes!.fajr.add(const Duration(hours: 24)), Icons.nightlight_round_outlined),
                  ];
                  return _PrayerRow(
                      prayer: mainPrayers[i],
                      isHighlighted: i == highlightIndex,
                      isCurrent: isCurrentWakt,
                      toBangla: _toBangla
                  );
                },
                childCount: _prayerTimes == null ? 0 : 5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String dayName, dateStr, hijriDate, bengaliDate, location, activeName, activeTime;
  final PrayerTimes? prayerTimes;
  final Function(String) toBangla;
  final bool showCountdown;
  final VoidCallback onToggle;

  const _HeroHeader({
    required this.dayName,
    required this.dateStr,
    required this.hijriDate,
    required this.bengaliDate,
    this.prayerTimes,
    required this.location,
    required this.activeName,
    required this.activeTime,
    required this.toBangla,
    required this.showCountdown,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (prayerTimes == null) return const SizedBox(height: 300);

    final now = DateTime.now();
    final sehriEnd = prayerTimes!.fajr;
    final iftarTime = prayerTimes!.maghrib;
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    String countdownLabel = "";
    Duration remaining = Duration.zero;
    double progress = 0.0;
    bool isSiamActive = false;

    if (now.isAfter(sehriEnd) && now.isBefore(iftarTime)) {
      isSiamActive = true;
      countdownLabel = "ইফতারের বাকি";
      remaining = iftarTime.difference(now);
      final totalSiam = iftarTime.difference(sehriEnd).inSeconds;
      final elapsed = now.difference(sehriEnd).inSeconds;
      progress = (elapsed / totalSiam).clamp(0.0, 1.0);
    } else {
      isSiamActive = false;
      countdownLabel = "সেহরির বাকি";
      DateTime nextSehri = now.isAfter(iftarTime)
          ? sehriEnd.add(const Duration(days: 1))
          : sehriEnd;
      remaining = nextSehri.difference(now);
      final totalWait = nextSehri.difference(now.isAfter(iftarTime) ? iftarTime : sehriEnd.subtract(const Duration(days: 1))).inSeconds;
      final elapsed = now.difference(now.isAfter(iftarTime) ? iftarTime : sehriEnd.subtract(const Duration(days: 1))).inSeconds;
      progress = (elapsed / totalWait).clamp(0.0, 1.0);
    }

    String timerText = "${remaining.inHours.toString().padLeft(2, '0')}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}";

    final bool isForbidden = activeName.contains("নিষিদ্ধ");
    final Color activeSectionColor = isForbidden ? Colors.red : const Color(0xFFB8956A);
    final Color timeColor = isForbidden ? Colors.red : (isDark ? Colors.white : Colors.black87);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF141820), const Color(0xFF0E1014)]
                : [Colors.grey[100]!, Colors.white]
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$dayName, $dateStr | $bengaliDate", style: TextStyle(color: isDark ? Colors.white : const Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w500)),
              IconButton(icon: const Icon(Icons.bar_chart_rounded, color: Color(0xFFB8956A)), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StatsPage()))),
            ],
          ),
          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: !showCountdown
                        ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        key: const ValueKey('main_text'),
                        "জিকিরে গড়ুন\nআপনার ঈমান",
                        textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 32, color: isDark ? const Color(0xFFD6C9B0) : const Color(0xFFB8956A), fontWeight: FontWeight.w300, height: 1.2),
                      ),
                    )
                        : Align(
                      alignment: Alignment.centerLeft,
                      key: const ValueKey('countdown'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(countdownLabel, style: const TextStyle(color: Color(0xFFB8956A), fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(toBangla(timerText), style: TextStyle(fontSize: 36, color: isDark ? const Color(0xFFD6C9B0) : Colors.black87, fontWeight: FontWeight.w200, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(hijriDate, style: const TextStyle(color: Color(0xFFB8956A), fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                      activeName.contains("পরবর্তী") || isForbidden ? activeName : "$activeName-এর ওয়াক্ত",
                      style: TextStyle(color: activeSectionColor, fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 2),
                  Text(
                      activeTime,
                      style: TextStyle(color: timeColor, fontSize: 15, fontWeight: FontWeight.w300)
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 25),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(10)),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 4,
                        width: constraints.maxWidth * progress,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF2E3A4A), Color(0xFFB8956A)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Positioned(
                        left: (constraints.maxWidth * progress) - 8,
                        top: -6,
                        child: Icon(
                          isSiamActive ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                          size: 16,
                          color: const Color(0xFFB8956A),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TimeChip(label: "সেহরির শেষ সময়", time: toBangla(DateFormat.jm('bn').format(sehriEnd)), icon: Icons.wb_twilight_rounded),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFB8956A), size: 12),
                  const SizedBox(width: 4),
                  Text(location, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[600], fontSize: 11)),
                ],
              ),
              _TimeChip(label: "ইফতারের সময়", time: toBangla(DateFormat.jm('bn').format(iftarTime)), icon: Icons.wb_twilight_outlined, accent: true),
            ],
          )
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int done, total;
  final double percent;
  final Function(String) toBangla;
  final VoidCallback onTap;
  const _ProgressCard({required this.done, required this.total, required this.percent, required this.toBangla, required this.onTap});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? const Color(0xFF2E3A4A) : Colors.grey[200]!, width: 0.8)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("আমার আমলের লক্ষ্য", style: TextStyle(color: isDark ? const Color(0xFFD6C9B0) : const Color(0xFFB8956A), fontWeight: FontWeight.bold)),
                Text(toBangla("${(percent * 100).toInt()}%"), style: const TextStyle(color: Color(0xFFB8956A), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 15),
            LinearProgressIndicator(value: percent, backgroundColor: isDark ? const Color(0xFF0E1014) : Colors.grey[200], color: const Color(0xFFB8956A), minHeight: 7, borderRadius: BorderRadius.circular(10)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(total == 0 ? "কোনো প্ল্যান যোগ করা হয়নি" : toBangla("$totalটির মধ্যে $doneটি সম্পন্ন হয়েছে"), style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[600], fontSize: 12)),
                Icon(Icons.arrow_forward_ios, color: isDark ? Colors.white10 : Colors.grey[300], size: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final _Prayer prayer;
  final bool isHighlighted;
  final bool isCurrent;
  final Function(String) toBangla;
  const _PrayerRow({required this.prayer, required this.isHighlighted, required this.isCurrent, required this.toBangla});

  @override
  Widget build(BuildContext context) {
    String timeStr = toBangla(DateFormat.jm('bn').format(prayer.start));
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? (isDark ? const Color(0xFF1A2129) : Colors.brown[50])
            : (isDark ? const Color(0xFF111418) : Colors.grey[50]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isHighlighted ? const Color(0xFFB8956A).withValues(alpha:0.4) : Colors.transparent, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(prayer.icon, color: isHighlighted ? const Color(0xFFB8956A) : (isDark ? Colors.white24 : Colors.grey[400]), size: 20),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(prayer.name, style: TextStyle(color: isHighlighted ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white60 : Colors.black54), fontSize: 16, fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal)),
              if (isHighlighted)
                Text(isCurrent ? "চলমান ওয়াক্ত" : "পরবর্তী ওয়াক্ত", style: const TextStyle(color: Color(0xFFB8956A), fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Text(timeStr, style: TextStyle(color: isHighlighted ? const Color(0xFFB8956A) : (isDark ? Colors.white38 : Colors.grey[500]), fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label, time;
  final IconData icon;
  final bool accent;
  const _TimeChip({required this.label, required this.time, required this.icon, this.accent = false});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 18, color: accent ? const Color(0xFFB8956A) : (isDark ? Colors.white38 : Colors.grey[400])),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey[600], fontWeight: FontWeight.w500)),
            Text(time, style: TextStyle(fontSize: 14, color: accent ? const Color(0xFFB8956A) : (isDark ? Colors.white : Colors.black87), fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }
}

class _Prayer {
  final String name;
  final DateTime start;
  final DateTime end;
  final IconData icon;
  const _Prayer(this.name, this.start, this.end, this.icon);
}
