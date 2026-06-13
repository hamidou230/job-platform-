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
    // Le backend retourne { totals: {...}, applicationsByStatus: [...], offersByType: [...] }
    final t = j['totals'] as Map<String, dynamic>? ?? {};

    Map<String, int> groupByToMap(dynamic list, String keyField) {
      if (list is List) {
        return { for (final e in list) e[keyField].toString(): (e['_count'] as num).toInt() };
      }
      return {};
    }

    return AdminStats(
      users: (t['users'] as num?)?.toInt() ?? 0,
      students: (t['students'] as num?)?.toInt() ?? 0,
      companies: (t['companies'] as num?)?.toInt() ?? 0,
      offers: (t['offers'] as num?)?.toInt() ?? 0,
      openOffers: (t['openOffers'] as num?)?.toInt() ?? 0,
      applications: (t['applications'] as num?)?.toInt() ?? 0,
      applicationsByStatus: groupByToMap(j['applicationsByStatus'], 'status'),
      offersByType: groupByToMap(j['offersByType'], 'type'),
    );
  }
}

class AdminApplication {
  final String id;
  final String status;
  final DateTime createdAt;
  final String studentName;
  final String offerTitle;
  final String companyName;

  const AdminApplication({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.studentName,
    required this.offerTitle,
    required this.companyName,
  });

  String get statusLabel {
    switch (status) {
      case 'PENDING': return 'En attente';
      case 'REVIEWED': return 'Examinée';
      case 'ACCEPTED': return 'Acceptée';
      case 'REJECTED': return 'Refusée';
      default: return status;
    }
  }

  factory AdminApplication.fromJson(Map<String, dynamic> j) {
    final student = j['student'] as Map<String, dynamic>? ?? {};
    final offer = j['offer'] as Map<String, dynamic>? ?? {};
    final company = offer['company'] as Map<String, dynamic>? ?? {};
    return AdminApplication(
      id: j['id'],
      status: j['status'] ?? 'PENDING',
      createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      studentName: '${student['firstName'] ?? ''} ${student['lastName'] ?? ''}'.trim(),
      offerTitle: offer['title'] ?? '',
      companyName: company['name'] ?? '',
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
