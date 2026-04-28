class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.biologicalSex,
    required this.isNoviceDriver,
    required this.hasLicense,
  });

  final String id;
  final String fullName;
  final String email;
  final int age;
  final double weightKg;
  final double heightCm;
  final String biologicalSex;
  final bool isNoviceDriver;
  final bool hasLicense;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? 'Desconocido',
      email: json['email'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0.0,
      biologicalSex: json['biologicalSex'] as String? ?? 'Male',
      isNoviceDriver: json['isNoviceDriver'] as bool? ?? false,
      hasLicense: json['hasLicense'] as bool? ?? true,
    );
  }
}
