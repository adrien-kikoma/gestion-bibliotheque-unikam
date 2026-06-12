import 'package:hive/hive.dart';

part 'emprunt.g.dart';

@HiveType(typeId: 2)
class Emprunt {
  @HiveField(0)
  String id;

  @HiveField(1)
  String livreId;

  @HiveField(2)
  String utilisateurId;

  @HiveField(3)
  DateTime dateEmprunt;

  @HiveField(4)
  DateTime dateRetourPrevue;

  @HiveField(5)
  DateTime? dateRetourReel;

  @HiveField(6)
  String statut; // 'en_cours', 'retourne', 'en_retard'

  Emprunt({
    required this.id,
    required this.livreId,
    required this.utilisateurId,
    required this.dateEmprunt,
    required this.dateRetourPrevue,
    this.dateRetourReel,
    this.statut = 'en_cours',
  });

  // Durée d'emprunt par défaut : 14 jours
  static const dureeEmpruntJours = 14;

  // Calculer la date de retour par défaut (14 jours après emprunt)
  static DateTime calculerDateRetourPrevue(DateTime dateEmprunt) {
    return dateEmprunt.add(Duration(days: dureeEmpruntJours));
  }

  // Vérifier si l'emprunt est en retard
  bool get estEnRetard {
    if (statut == 'retourne') return false;
    return DateTime.now().isAfter(dateRetourPrevue);
  }

  // Calculer le nombre de jours de retard
  int get joursDeRetard {
    if (!estEnRetard) return 0;
    return DateTime.now().difference(dateRetourPrevue).inDays;
  }

  // Vérifier si le retour est dans les délais
  bool get estDansLesDelais {
    if (dateRetourReel == null) return true;
    return !dateRetourReel!.isAfter(dateRetourPrevue);
  }

  @override
  String toString() {
    return 'Emprunt{livreId: $livreId, dateEmprunt: $dateEmprunt, dateRetourPrevue: $dateRetourPrevue, statut: $statut}';
  }
}
