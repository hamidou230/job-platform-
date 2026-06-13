enum UserRole { student, company, admin, unknown }

UserRole roleFromString(String? v) {
  switch (v) {
    case 'STUDENT': return UserRole.student;
    case 'COMPANY': return UserRole.company;
    case 'ADMIN': return UserRole.admin;
    default: return UserRole.unknown;
  }
}

class StudentProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String? university;
  final String? fieldOfStudy;
  final int? graduationYear;
  final String? phone;
  final String? bio;
  final String? skills;
  final String? cvUrl;

  const StudentProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.university,
    this.fieldOfStudy,
    this.graduationYear,
    this.phone,
    this.bio,
    this.skills,
    this.cvUrl,
  });

  String get fullName => '$firstName $lastName';
  List<String> get skillList =>
      (skills ?? '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  factory StudentProfile.fromJson(Map<String, dynamic> j) => StudentProfile(
        id: j['id'],
        firstName: j['firstName'] ?? '',
        lastName: j['lastName'] ?? '',
        university: j['university'],
        fieldOfStudy: j['fieldOfStudy'],
        graduationYear: j['graduationYear'],
        phone: j['phone'],
        bio: j['bio'],
        skills: j['skills'],
        cvUrl: j['cvUrl'],
      );
}

class CompanyProfile {
  final String id;
  final String name;
  final String? description;
  final String? industry;
  final String? location;
  final String? logoUrl;

  const CompanyProfile({
    required this.id,
    required this.name,
    this.description,
    this.industry,
    this.location,
    this.logoUrl,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> j) => CompanyProfile(
        id: j['id'],
        name: j['name'] ?? '',
        description: j['description'],
        industry: j['industry'],
        location: j['location'],
        logoUrl: j['logoUrl'],
      );
}

class AppUser {
  final String id;
  final String email;
  final UserRole role;
  final StudentProfile? student;
  final CompanyProfile? company;

  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.student,
    this.company,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'],
        email: j['email'] ?? '',
        role: roleFromString(j['role']),
        student: j['student'] != null ? StudentProfile.fromJson(j['student']) : null,
        company: j['company'] != null ? CompanyProfile.fromJson(j['company']) : null,
      );
}
