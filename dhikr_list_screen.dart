class Dhikr {
  final String title;
  int target;
  final String? arabic;
  final String? meaning;

  Dhikr(this.title, this.target, {this.arabic, this.meaning});
}

class DhikrPackage {
  final String packageName;
  final List<Dhikr> dhikrs;
  const DhikrPackage(this.packageName, this.dhikrs);
}
