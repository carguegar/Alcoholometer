class GroupSummaryModel {
  const GroupSummaryModel({
    required this.groupId,
    required this.groupName,
    required this.role,
  });

  final String groupId;
  final String groupName;
  final String role;

  factory GroupSummaryModel.fromJson(Map<String, dynamic> json) {
    return GroupSummaryModel(
      groupId: json['groupId'] as String? ?? '',
      groupName: json['groupName'] as String? ?? '',
      role: json['role'] as String? ?? 'Member',
    );
  }

  bool get isAdmin => role == 'Admin';
}

class GroupMemberModel {
  const GroupMemberModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.birthDate,
    this.heightCm = 0,
    this.weightKg = 0,
    this.biologicalSex = '',
  });

  final String userId;
  final String firstName;
  final String lastName;
  final String role;
  final DateTime? birthDate;
  final double heightCm;
  final double weightKg;
  final String biologicalSex;

  String get fullName => '$firstName $lastName';
  bool get isAdmin => role == 'Admin';

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    var a = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      a--;
    }
    return a;
  }

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      userId: json['userId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      role: json['role'] as String? ?? 'Member',
      birthDate: json['birthDate'] != null
          ? DateTime.tryParse(json['birthDate'] as String)
          : null,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      biologicalSex: json['biologicalSex'] as String? ?? '',
    );
  }
}

class GroupDetailsModel {
  const GroupDetailsModel({
    required this.groupId,
    required this.name,
    required this.invitationCode,
    required this.alertThresholdLevel,
    required this.members,
  });

  final String groupId;
  final String name;
  final String invitationCode;
  final double alertThresholdLevel;
  final List<GroupMemberModel> members;

  factory GroupDetailsModel.fromJson(Map<String, dynamic> json) {
    final membersJson = json['members'] as List<dynamic>? ?? <dynamic>[];
    return GroupDetailsModel(
      groupId: json['groupId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      invitationCode: json['invitationCode'] as String? ?? '',
      alertThresholdLevel: (json['alertThresholdLevel'] as num?)?.toDouble() ?? 0.25,
      members: membersJson
          .map((m) => GroupMemberModel.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RankingMemberModel {
  const RankingMemberModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.recordAlcoholLevel,
    required this.recordTimestamp,
    required this.recordLat,
    required this.recordLng,
  });

  final String userId;
  final String firstName;
  final String lastName;
  final double recordAlcoholLevel;
  final DateTime recordTimestamp;
  final double recordLat;
  final double recordLng;

  String get fullName => '$firstName $lastName';

  factory RankingMemberModel.fromJson(Map<String, dynamic> json) {
    return RankingMemberModel(
      userId: json['userId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      recordAlcoholLevel: (json['recordAlcoholLevel'] as num?)?.toDouble() ?? 0.0,
      recordTimestamp: json['recordTimestamp'] != null 
          ? DateTime.tryParse(json['recordTimestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      recordLat: (json['recordLat'] as num?)?.toDouble() ?? 0.0,
      recordLng: (json['recordLng'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GroupRankingModel {
  const GroupRankingModel({
    required this.groupId,
    required this.groupName,
    required this.rankings,
  });

  final String groupId;
  final String groupName;
  final List<RankingMemberModel> rankings;

  factory GroupRankingModel.fromJson(Map<String, dynamic> json) {
    final rankingsJson = json['rankings'] as List<dynamic>? ?? <dynamic>[];
    return GroupRankingModel(
      groupId: json['groupId'] as String? ?? '',
      groupName: json['groupName'] as String? ?? '',
      rankings: rankingsJson
          .map((r) => RankingMemberModel.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
