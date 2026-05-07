import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart'; // স্ক্রিন অন রাখার জন্য
import 'dhikr_list_screen.dart';
import 'storage_service.dart';

class DigitalTasbih extends StatefulWidget {
  final String packageName;
  final List<Dhikr> dhikrs;

  const DigitalTasbih({super.key, required this.packageName, required this.dhikrs});

  @override
  State<DigitalTasbih> createState() => _DigitalTasbihState();
}

class _DigitalTasbihState extends State<DigitalTasbih> {
  int _currentIndex = 0;
  int _counter = 0;
  bool _isLoading = true;

  bool _isVibrationOn = true;
  bool _targetVibration = true;
  bool _keepScreenOn = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  void _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIndex = prefs.getInt('${widget.packageName}_idx') ?? 0;
      _counter = prefs.getInt('${widget.packageName}_cnt') ?? 0;

      // সেটিংস থেকে ডেটা লোড
      _isVibrationOn = prefs.getBool('vibration_enabled') ?? true;
      _targetVibration = prefs.getBool('target_vibration') ?? true;
      _keepScreenOn = prefs.getBool('keep_screen_on') ?? false;

      _isLoading = false;
    });

    if (_keepScreenOn) {
      WakelockPlus.enable();
    }
  }

  void _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${widget.packageName}_idx', _currentIndex);
    await prefs.setInt('${widget.packageName}_cnt', _counter);
  }

  void _resetCurrentDhikr() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF171C22),
        title: const Text("রিসেট নিশ্চিত করুন", style: TextStyle(color: Color(0xFFD6C9B0))),
        content: const Text("আপনি কি বর্তমান জিকিরের গণনা শূন্য করতে চান?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("না", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              setState(() => _counter = 0);
              _saveProgress();
              Navigator.pop(context);
              if (_isVibrationOn) HapticFeedback.mediumImpact();
            },
            child: const Text("হ্যাঁ", style: TextStyle(color: Color(0xFFB8956A))),
          ),
        ],
      ),
    );
  }

  void _incrementCounter() {
    if (_isLoading) return;
    final currentDhikr = widget.dhikrs[_currentIndex];

    if (_counter < currentDhikr.target) {
      if (_isVibrationOn) {
        HapticFeedback.vibrate();
      }

      setState(() {
        _counter++;
      });

      _saveProgress();
      StorageService.incrementZikir();
      StorageService.incrementSpecificDhikr(currentDhikr.title);
      StorageService.updatePlanProgress(currentDhikr.title);

      if (_counter == currentDhikr.target) {
        if (_targetVibration) {
          HapticFeedback.vibrate();
          Future.delayed(const Duration(milliseconds: 200), () => HapticFeedback.vibrate());
        }
        _showTargetReachedDialog(_currentIndex);
      }
    }
  }

  void _showTargetReachedDialog(int index) {
    final TextEditingController extraController = TextEditingController();
    final currentDhikr = widget.dhikrs[index];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF171C22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("ما شاء الله (মাশাআল্লাহ!)",
            style: TextStyle(color: Color(0xFFD6C9B0), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("'${currentDhikr.title}' পড়ার লক্ষ্য সম্পন্ন হয়েছে।",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 20),
            const Text("আপনি কি আরও পড়তে চান?",
                style: TextStyle(color: Color(0xFFB8956A), fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            TextField(
              controller: extraController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "অতিরিক্ত সংখ্যা লিখুন (যেমন: ১০০)",
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF0E1014),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleNextDhikr();
            },
            child: const Text("পরের জিকিরে যান", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB8956A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              int extra = int.tryParse(extraController.text) ?? 0;
              if (extra > 0) {
                setState(() {
                  currentDhikr.target += extra;
                });
                Navigator.pop(context);
              } else {
                Navigator.pop(context);
                _handleNextDhikr();
              }
            },
            child: const Text("আরও পড়ুন", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleNextDhikr() {
    if (_currentIndex < widget.dhikrs.length - 1) {
      setState(() {
        _currentIndex++;
        _counter = 0;
      });
      _saveProgress();
    } else {
      _showFinalCompletionDialog();
    }
  }

  void _showFinalCompletionDialog() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${widget.packageName}_idx');
    await prefs.remove('${widget.packageName}_cnt');

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF171C22),
        title: const Text("আলহামদুলিল্লাহ!", style: TextStyle(color: Color(0xFFD6C9B0))),
        content: const Text("আপনার এই প্যাকেজের সব জিকির সম্পন্ন হয়েছে।", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("ঠিক আছে", style: TextStyle(color: Color(0xFFB8956A)))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final currentDhikr = widget.dhikrs[_currentIndex];
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.packageName, style: TextStyle(color: isDark ? const Color(0xFF5A5750) : Colors.black54, fontSize: 13)),
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFFB8956A)),
            onPressed: () => Navigator.pop(context)
        ),
        actions: [
          IconButton(
              icon: Icon(Icons.refresh_rounded, color: isDark ? const Color(0xFF3E424D) : Colors.grey, size: 22),
              onPressed: _resetCurrentDhikr
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF171C22) : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF2E3A4A) : Colors.grey[300]!, width: 0.5),
              ),
              child: Column(
                children: [
                  if (currentDhikr.arabic != null)
                    Text(
                      currentDhikr.arabic!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          height: 1.5
                      ),
                    ),
                  const SizedBox(height: 15),
                  Text(
                    currentDhikr.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFB8956A), fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  if (currentDhikr.meaning != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      currentDhikr.meaning!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 14, fontStyle: FontStyle.italic),
                    ),
                  ],
                  Divider(color: isDark ? const Color(0xFF2E3A4A) : Colors.grey[300], height: 30),
                  Text("লক্ষ্য: ${currentDhikr.target} বার", style: TextStyle(color: isDark ? const Color(0xFF5A5750) : Colors.black45, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 40),

            Center(
              child: GestureDetector(
                onTap: _incrementCounter,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFB8956A).withValues(alpha:0.3), width: 1),
                      color: isDark ? const Color(0xFF171C22).withValues(alpha:0.5) : Colors.grey[200],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ]
                  ),
                  child: Center(
                    child: Text(
                        "$_counter",
                        style: const TextStyle(color: Color(0xFFB8956A), fontSize: 80, fontWeight: FontWeight.w100)
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.dhikrs.length, (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == _currentIndex ? 12 : 7, height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: index == _currentIndex ? const Color(0xFFB8956A) : (isDark ? const Color(0xFF2E3A4A) : Colors.grey[350]),
                ),
              )),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
