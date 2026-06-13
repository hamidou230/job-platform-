class AdminStats {
  final int users;
  final int students;
  final int companies;
  final int offers;
  final int openOffers;
  final int applications;
  final Map<String, int> applicationsByStatus;
  final Map<String, int> offersByType;

  const AdminStats({
    required this.users,
    required this.students,
    required this.companies,
    required this.offers,
    required this.openOffers,
    required this.applications,
    required this.applicationsByStatus,
    required this.offersByType,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) {
    Map<String, int> toMap(dynamic v) {
      if (v is Map) {
        return v.map((k, val) => MapEntry(k.toString(), (val as num).toInt()));
      }
      return {};
    }

    return AdminStats(
      users: j['users'] ?? 0,
      students: j['students'] ?? 0,
      companies: j['companies'] ?? 0,
      offers: j['offers'] ?? 0,
      openOffers: j['openOffers'] ?? 0,
      applications: j['applications'] ?? 0,
      applicationsByStatus: toMap(j['applicationsByStatus']),
      offersByType: toMap(j['offersByType']),
    );
  }
}

class AdminUser {
  final String id;
  final String email;
  final String role;
  final bool isActive;
  final String? name; // nom étudiant ou entreprise si dispo

  const AdminUser({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
    this.name,
  });

  factory AdminUser.fromJson(Map<String, dynamic> j) {
    String? name;
    if (j['student'] != null) {
      name = '${j['student']['firstName'] ?? ''} ${j['student']['lastName'] ?? ''}'.trim();
    } else if (j['company'] != null) {
      name = j['company']['name'];
    }
    return AdminUser(
      id: j['id'],
      email: j['email'] ?? '',
      role: j['role'] ?? 'STUDENT',
      isActive: j['isActive'] ?? true,
      name: (name == null || name.isEmpty) ? null : name,
    );
  }
}
