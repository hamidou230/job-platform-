/// Représente une erreur "métier" présentable à l'utilisateur.
class Failure implements Exception {
  final String message;
  final int? statusCode;
  const Failure(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Pas de connexion internet.']) : super(message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([String message = 'Session expirée, reconnectez-vous.'])
      : super(message, statusCode: 401);
}
