import 'package:hive/hive.dart';
import '../models/emprunt.dart';
import '../models/livre.dart';
import 'hive_service.dart';

class EmpruntService {
  // Enregistrer un nouvel emprunt
  Future<bool> enregistrerEmprunt(Emprunt emprunt) async {
    try {
      final empruntBox = HiveService.empruntsBox;
      final livreBox = HiveService.livresBox;

      // Vérifier si le livre est disponible
      final livre = livreBox.get(emprunt.livreId);
      if (livre == null || livre.quantiteStock <= 0) {
        return false;
      }

      // Réduire la quantité disponible
      livre.retirerExemplaire();
      await livreBox.put(livre.idLivre, livre);

      // Vérifier si l'emprunt est déjà en retard à la création
      String statut = 'en_cours';
      if (emprunt.estEnRetard) {
        statut = 'en_retard';
      }

      final nouvelEmprunt = Emprunt(
        id: emprunt.id,
        livreId: emprunt.livreId,
        utilisateurId: emprunt.utilisateurId,
        dateEmprunt: emprunt.dateEmprunt,
        dateRetourPrevue: emprunt.dateRetourPrevue,
        statut: statut,
      );

      // Enregistrer l'emprunt
      await empruntBox.put(nouvelEmprunt.id, nouvelEmprunt);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Enregistrer un retour de livre
  Future<bool> enregistrerRetour(String empruntId) async {
    try {
      final empruntBox = HiveService.empruntsBox;
      final livreBox = HiveService.livresBox;

      final emprunt = empruntBox.get(empruntId);
      if (emprunt == null || emprunt.statut == 'retourne') {
        return false;
      }

      // Mettre à jour l'emprunt
      emprunt.dateRetourReel = DateTime.now();
      emprunt.statut = 'retourne';
      await empruntBox.put(empruntId, emprunt);

      // Augmenter la quantité disponible du livre
      final livre = livreBox.get(emprunt.livreId);
      if (livre != null) {
        livre.ajouterExemplaire();
        await livreBox.put(livre.idLivre, livre);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Obtenir tous les emprunts
  List<Emprunt> getAllEmprunts() {
    final box = HiveService.empruntsBox;
    return box.values.toList();
  }

  // Obtenir les emprunts en cours
  List<Emprunt> getEmpruntsEnCours() {
    final box = HiveService.empruntsBox;
    return box.values
        .where(
            (emprunt) => emprunt.statut == 'en_cours' && !emprunt.estEnRetard)
        .toList();
  }

  // Obtenir les emprunts en retard
  List<Emprunt> getEmpruntsEnRetard() {
    final box = HiveService.empruntsBox;
    return box.values
        .where((emprunt) => emprunt.statut == 'en_cours' && emprunt.estEnRetard)
        .toList();
  }

  // Obtenir les emprunts d'un utilisateur spécifique
  List<Emprunt> getEmpruntsParUtilisateur(String utilisateurId) {
    final box = HiveService.empruntsBox;
    return box.values
        .where((emprunt) => emprunt.utilisateurId == utilisateurId)
        .toList();
  }

  // Obtenir les emprunts d'un livre spécifique
  List<Emprunt> getEmpruntsParLivre(String livreId) {
    final box = HiveService.empruntsBox;
    return box.values.where((emprunt) => emprunt.livreId == livreId).toList();
  }

  // Obtenir les emprunts du mois (pour rapports)
  List<Emprunt> getEmpruntsDuMois(DateTime mois) {
    final box = HiveService.empruntsBox;
    return box.values
        .where((emprunt) =>
            emprunt.dateEmprunt.year == mois.year &&
            emprunt.dateEmprunt.month == mois.month)
        .toList();
  }

  // Vérifier si un utilisateur a des emprunts en retard
  bool aDesEmpruntsEnRetard(String utilisateurId) {
    final emprunts = getEmpruntsParUtilisateur(utilisateurId);
    return emprunts
        .any((emprunt) => emprunt.statut == 'en_cours' && emprunt.estEnRetard);
  }

  // Générer un ID unique pour un emprunt
  String generateId() {
    return 'EMP_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Obtenir le nombre total d'emprunts
  int getNombreTotalEmprunts() {
    final box = HiveService.empruntsBox;
    return box.length;
  }

  // Obtenir le nombre d'emprunts en cours
  int getNombreEmpruntsEnCours() {
    return getEmpruntsEnCours().length;
  }

  // Obtenir le nombre d'emprunts en retard
  int getNombreEmpruntsEnRetard() {
    return getEmpruntsEnRetard().length;
  }

  // Mettre à jour les statuts des emprunts
  Future<void> mettreAJourStatuts() async {
    final box = HiveService.empruntsBox;
    for (var emprunt in box.values) {
      if (emprunt.statut == 'en_cours' && emprunt.estEnRetard) {
        emprunt.statut = 'en_retard';
        await box.put(emprunt.id, emprunt);
      }
    }
  }
}
