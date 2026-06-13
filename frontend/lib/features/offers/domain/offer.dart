class OfferCompany {
  final String id;
  final String name;
  final String? logoUrl;
  final String? location;
  const OfferCompany({required this.id, required this.name, this.logoUrl, this.location});

  factory OfferCompany.fromJson(Map<String, dynamic> j) => OfferCompany(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        logoUrl: j['logoUrl'],
        location: j['location'],
      );
}

class Offer {
  final String id;
  final String title;
  final String description;
  final String type; // INTERNSHIP | JOB | ALTERNANCE | PART_TIME
  final String? location;
  final bool isRemote;
  final int? salaryMin;
  final int? salaryMax;
  final String? requiredSkills;
  final String experienceLevel;
  final String status;
  final DateTime? deadline;
  final DateTime createdAt;
  final OfferCompany? company;
  final int applicationsCount;

  const Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.location,
    required this.isRemote,
    this.salaryMin,
    this.salaryMax,
    this.requiredSkills,
    required this.experienceLevel,
    required this.status,
    this.deadline,
    required this.createdAt,
    this.company,
    this.applicationsCount = 0,
  });

  List<String> get skillList =>
      (requiredSkills ?? '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  String get typeLabel {
    switch (type) {
      case 'INTERNSHIP': return 'Stage';
      case 'JOB': return 'Emploi';
      case 'ALTERNANCE': return 'Alternance';
      case 'PART_TIME': return 'Temps partiel';
      default: return type;
    }
  }

  String get salaryLabel {
    if (salaryMin == null && salaryMax == null) return 'Non précisé';
    if (salaryMin != null && salaryMax != null) return '$salaryMin - $salaryMax MAD';
    return '${salaryMin ?? salaryMax} MAD';
  }

  factory Offer.fromJson(Map<String, dynamic> j) => Offer(
        id: j['id'],
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        type: j['type'] ?? 'INTERNSHIP',
        location: j['location'],
        isRemote: j['isRemote'] ?? false,
        salaryMin: j['salaryMin'],
        salaryMax: j['salaryMax'],
        requiredSkills: j['requiredSkills'],
        experienceLevel: j['experienceLevel'] ?? 'JUNIOR',
        status: j['status'] ?? 'OPEN',
        deadline: j['deadline'] != null ? DateTime.tryParse(j['deadline']) : null,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        company: j['company'] != null ? OfferCompany.fromJson(j['company']) : null,
        applicationsCount: j['_count']?['applications'] ?? 0,
      );
}
