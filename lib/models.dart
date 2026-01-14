enum UserRole { parent, child }

class FamilyMember {
  final String id;
  final String name;
  final UserRole role;
  final int screenTimeMinutes;
  final List<AppUsage>? usageBreakdown;

  FamilyMember({
    required this.id,
    required this.name,
    required this.role,
    this.screenTimeMinutes = 0,
    this.usageBreakdown,
  });
}

class AppUsage {
  final String appName;
  final int minutes;

  AppUsage({required this.appName, required this.minutes});
}

class Family {
  final String id;
  final String name;
  final String joinCode;
  final List<FamilyMember> members;

  Family({
    required this.id,
    required this.name,
    required this.joinCode,
    required this.members,
  });
}
