import '../../offers/domain/offer.dart';

/// Informations sur le candidat (visibles côté entreprise).
class Applicant {
  final String fullName;
  final String? university;
  final String? fieldOfStudy;
  final String? cvUrl;
  const Applicant({required this.fullName, this.university, this.fieldOfStudy, this.cvUrl});

  factory Applicant.fromJson(Map<String, dynamic> j) => Applicant(
        fullName: '${j['firstName'] ?? ''} ${j['lastName'] ?? ''}'.trim(),
        university: j['university'],
        fieldOfStudy: j['fieldOfStudy'],
        cvUrl: j['cvUrl'],
      );
}

class Application {
  final String id;
  final String status; // PENDING | REVIEWED | ACCEPTED | REJECTED
  final String? coverLetter;
  final String? cvUrl;
  final DateTime createdAt;
  final Offer? offer;
  final Applicant? applicant;

  const Application({
    required this.id,
    required this.status,
    this.coverLetter,
    this.cvUrl,
    required this.createdAt,
    this.offer,
    this.applicant,
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

  factory Application.fromJson(Map<String, dynamic> j) => Application(
        id: j['id'],
        status: j['status'] ?? 'PENDING',
        coverLetter: j['coverLetter'],
        cvUrl: j['cvUrl'],
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        offer: j['offer'] != null ? Offer.fromJson(j['offer']) : null,
        applicant: j['student'] != null ? Applicant.fromJson(j['student']) : null,
      );
}
