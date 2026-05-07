import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dhikr_data.dart';
import 'digital_tasbih.dart';
import 'dhikr_list_screen.dart';

class AmarPlanPage extends StatefulWidget {
  const AmarPlanPage({super.key});

  @override
  State<AmarPlanPage> createState() => _AmarPlanPageState();
}

class _AmarPlanPageState extends State<AmarPlanPage> {
  String _userName = "ইউজার";
  List<Map<String, dynamic>> _plans = [];
  final List<Map<String, dynamic>> _allAvailableDhikrObjects = [];

  @override
  void initState() {
    super.initState();
    _loadDhikrData();
    _loadData();
  }

  void _loadDhikrData() {
    _allAvailableDhikrObjects.clear();
    void addUnique(List<dynamic> dhikrs) {
      for (var dhikr in dhikrs) {
        if (!_allAvailableDhikrObjects.any((e) => e['title'] == dhikr['title'])) {
          _allAvailableDhikrObjects.add({
            'title': dhikr['title'] ?? "অজানা জিকির",
            'arabic': dhikr['arabic'] ?? "",
            'meaning': dhikr['meaning'] ?? "",
          });
        }
      }
    }
    addUnique(DhikrData.dailyDhikrPackage.expand((e) => e['dhikrs'] as List).toList());
    addUnique(DhikrData.afterPrayerDhikrPackage.expand((e) => e['dhikrs'] as List).toList());
    addUnique(DhikrData.specialDhikrPackage.expand((e) => e['dhikrs'] as List).toList());
    addUnique(DhikrData.duaPackage.expand((e) => e['dhikrs'] as List).toList());
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "ইউজার";
      final String? savedPlans = prefs.getString('user_daily_plans');
      if (savedPlans != null) {
        _plans = List<Map<String, dynamic>>.from(json.decode(savedPlans));
      }
    });
  }

  Future<void> _savePlans() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_daily_plans', json.encode(_plans));
  }

  String _toBangla(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], bangla[i]);
    }
    return input;
  }

  void _showDhikrSelectionList(bool isDark, Function(Map<String, dynamic>) onSelected) {
    List<Map<String, dynamic>> filteredList = List.from(_allAvailableDhikrObjects);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF171C22) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                TextField(
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  onChanged: (value) {
                    setModalState(() {
                      filteredList = _allAvailableDhikrObjects.where((element) => element['title'].toString().contains(value)).toList();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "খুঁজুন...",
                    hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFB8956A)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0E1014) : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(filteredList[index]['title'], style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                        trailing: const Icon(Icons.add_circle_outline, color: Color(0xFFB8956A), size: 20),
                        onTap: () {
                          onSelected(filteredList[index]);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showAddPlanSheet() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Map<String, dynamic>? selectedDhikrObj = _allAvailableDhikrObjects.isNotEmpty ? _allAvailableDhikrObjects[0] : null;
    final TextEditingController targetController = TextEditingController(text: "100");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF171C22) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 15,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 25),
                  Text("নতুন আমল", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 22, fontWeight: FontWeight.w900)),
                  Text("আপনার আজকের লক্ষ্য নির্ধারণ করুন", style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 30),
                  const Text("জিকির বা দোয়া নির্বাচন করুন", style: TextStyle(color: Color(0xFFB8956A), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showDhikrSelectionList(isDark, (selected) {
                      setModalState(() => selectedDhikrObj = selected);
                    }),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0E1014) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(selectedDhikrObj?['title'] ?? "সিলেক্ট করুন",
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.search_rounded, color: Color(0xFFB8956A), size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text("কতবার পড়তে চান?", style: TextStyle(color: Color(0xFFB8956A), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "উদা: ১০০",
                      hintStyle: TextStyle(color: isDark ? Colors.white10 : Colors.grey[300]),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0E1014) : Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFB8956A), width: 1.5)),
                      suffixText: "বার",
                      suffixStyle: const TextStyle(color: Color(0xFFB8956A), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 35),
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(colors: [Color(0xFFB8956A), Color(0xFFD6C9B0)]),
                      boxShadow: [BoxShadow(color: const Color(0xFFB8956A).withValues(alpha:0.3), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                      onPressed: () {
                        if (selectedDhikrObj != null && targetController.text.isNotEmpty) {
                          setState(() {
                            _plans.add({
                              'task': selectedDhikrObj!['title'],
                              'arabic': selectedDhikrObj!['arabic'] ?? "",
                              'meaning': selectedDhikrObj!['meaning'] ?? "",
                              'target': targetController.text,
                              'currentCount': 0,
                              'isDone': false,
                            });
                          });
                          _savePlans();
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("পরিকল্পনা নিশ্চিত করুন", style: TextStyle(color: Color(0xFF0E1014), fontWeight: FontWeight.w900, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _resetAllPlans() async {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF171C22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("সব রিসেট করবেন?"),
        content: const Text("এটি আপনার আজকের সব প্রগ্রেস জিরো করে দিবে।"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("না", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              setState(() {
                for (var plan in _plans) {
                  plan['currentCount'] = 0;
                  plan['isDone'] = false;
                }
              });
              _savePlans();
              Navigator.pop(context);
            },
            child: const Text("হ্যাঁ, রিসেট করুন", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // আজ রবিবার, ৫ এপ্রিল ২০২৬
    final String formattedDate = _toBangla(DateFormat('EEEE, d MMMM yyyy', 'bn').format(now));
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_plans.isNotEmpty)
            IconButton(icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white60 : Colors.grey), onPressed: _resetAllPlans),
          IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFFB8956A)), onPressed: _showAddPlanSheet),
        ],
      ),
      body: Column(
        children: [
          // সুন্দর এবং মিনিমাল হেডার
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "আজ $formattedDate",
                  style: const TextStyle(
                    color: Color(0xFFB8956A),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 30,
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w300,
                    ),
                    children: [
                      const TextSpan(text: "প্রিয় "),
                      TextSpan(
                          text: _userName,
                          style: const TextStyle(color: Color(0xFFB8956A), fontWeight: FontWeight.bold)
                      ),
                      const TextSpan(text: ","),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  style: TextStyle(color: isDark ? Colors.white30 : Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _plans.isEmpty
                ? Center(child: Text("কোনো আমল যোগ করা হয়নি", style: TextStyle(color: isDark ? Colors.white24 : Colors.grey[400])))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                return _buildPlanCard(index, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(int index, bool isDark) {
    final plan = _plans[index];
    bool isDone = plan['isDone'] ?? false;
    int current = plan['currentCount'] ?? 0;
    int target = int.tryParse(plan['target'].toString()) ?? 1;
    double progress = (current / target).clamp(0.0, 1.0);

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() => _plans.removeAt(index));
        _savePlans();
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(18)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Opacity(
        opacity: isDone ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171C22) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDone ? const Color(0xFFB8956A).withValues(alpha:0.3) : (isDark ? Colors.white10 : Colors.grey[200]!)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isDone,
                    activeColor: const Color(0xFFB8956A),
                    onChanged: (val) {
                      setState(() => _plans[index]['isDone'] = val);
                      _savePlans();
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan['task'] ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text("লক্ষ্য: ${_toBangla(target.toString())} বার (পড়া: ${_toBangla(current.toString())})", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.play_circle_fill, color: isDone ? Colors.grey : const Color(0xFFB8956A), size: 30),
                    onPressed: isDone ? null : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DigitalTasbih(
                            packageName: plan['task'],
                            dhikrs: [Dhikr(plan['task'], target, arabic: plan['arabic'], meaning: plan['meaning'])],
                          ),
                        ),
                      ).then((_) => _loadData());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: progress, backgroundColor: isDark ? Colors.white10 : Colors.grey[100], color: const Color(0xFFB8956A), minHeight: 4),
            ],
          ),
        ),
      ),
    );
  }
}
