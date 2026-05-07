import 'package:flutter/material.dart';
import 'digital_tasbih.dart';
import 'dhikr_list_screen.dart';
import 'dhikr_data.dart';

class AfterPrayerDhikrScreen extends StatelessWidget {
  const AfterPrayerDhikrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const packages = DhikrData.afterPrayerDhikrPackage;
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          style: TextStyle(
            color: isDark ? const Color(0xFFD6C9B0) : const Color(0xFFB8956A),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? const Color(0xFFD6C9B0) : const Color(0xFFB8956A),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: packages.length,
        itemBuilder: (context, index) {
          return _buildPackageCard(context, packages[index], isDark);
        },
      ),
    );
  }

  Widget _buildPackageCard(BuildContext context, Map<String, dynamic> package, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171C22) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3A4A) : Colors.grey[300]!,
          width: 0.5,
        ),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: isDark ? const Color(0xFF1A2129) : Colors.grey[100],
          child: const Icon(Icons.auto_awesome, color: Color(0xFFB8956A), size: 20),
        ),
        title: Text(
          package['packageName'],
          style: TextStyle(
            color: isDark ? const Color(0xFFD6C9B0) : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          package['description'],
          style: TextStyle(
            color: isDark ? const Color(0xFF5A5750) : Colors.black45,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF3E4450), size: 14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DhikrListDetailScreen(
                packageName: package['packageName'],
                dhikrs: package['dhikrs'],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DhikrListDetailScreen extends StatelessWidget {
  final String packageName;
  final List<dynamic> dhikrs;

  const DhikrListDetailScreen({super.key, required this.packageName, required this.dhikrs});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          packageName,
          style: TextStyle(
            color: isDark ? const Color(0xFFD6C9B0) : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? const Color(0xFFD6C9B0) : Colors.black87,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_fill, color: Color(0xFFB8956A), size: 28),
            onPressed: () => _startFullSequence(context),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dhikrs.length,
        itemBuilder: (context, index) => _buildDhikrItem(context, dhikrs[index], isDark),
      ),
    );
  }

  Widget _buildDhikrItem(BuildContext context, Map<String, dynamic> dhikr, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171C22) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3A4A) : Colors.grey[200]!,
          width: 0.5,
        ),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dhikr['title'],
            style: const TextStyle(
              color: Color(0xFFB8956A),
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              dhikr['arabic'] ?? '',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 22,
                fontFamily: 'Amiri', // আরবিক ফন্ট থাকলে দিতে পারেন
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            dhikr['Fazilat'] ?? '',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
            ),
          ),
          Divider(
            color: isDark ? Colors.white10 : Colors.black12,
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  dhikr['ref'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8956A),
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  elevation: 0,
                  minimumSize: const Size(60, 30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DigitalTasbih(
                        packageName: dhikr['title'],
                        dhikrs: [
                          Dhikr(
                            dhikr['title'],
                            int.parse(dhikr['target'] ?? '0'),
                            arabic: dhikr['arabic'],
                            meaning: dhikr['meaning'],
                          )
                        ],
                      ),
                    ),
                  );
                },
                child: const Text("শুরু", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    );
  }

  void _startFullSequence(BuildContext context) {
    List<Dhikr> list = dhikrs
        .map((d) => Dhikr(
      d['title'],
      int.parse(d['target']),
      arabic: d['arabic'],
      meaning: d['meaning'],
    ))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DigitalTasbih(packageName: packageName, dhikrs: list),
      ),
    );
  }
}
