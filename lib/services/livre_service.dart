import 'package:hive/hive.dart';
import '../models/livre.dart';
import 'hive_service.dart';

class LivreService {
  List<Livre> getAllLivres() {
    final box = HiveService.livresBox;
    return box.values.toList();
  }

  List<Livre> rechercherParTitre(String titre) {
    final box = HiveService.livresBox;
    return box.values
        .where(
            (livre) => livre.titre.toLowerCase().contains(titre.toLowerCase()))
        .toList();
  }

  List<Livre> rechercherParAuteur(String auteur) {
    final box = HiveService.livresBox;
    return box.values
        .where((livre) =>
            livre.auteur.toLowerCase().contains(auteur.toLowerCase()))
        .toList();
  }

  List<Livre> rechercherParDomaine(String domaine) {
    final box = HiveService.livresBox;
    return box.values
        .where((livre) =>
            livre.domaine.toLowerCase().contains(domaine.toLowerCase()))
        .toList();
  }

  Livre? getLivreById(String id) {
    final box = HiveService.livresBox;
    return box.get(id);
  }

  Future<bool> ajouterLivre(Livre livre) async {
    try {
      final box = HiveService.livresBox;
      await box.put(livre.idLivre, livre);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> mettreAJourLivre(Livre livre) async {
    try {
      final box = HiveService.livresBox;
      await box.put(livre.idLivre, livre);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> supprimerLivre(String id) async {
    try {
      final box = HiveService.livresBox;
      await box.delete(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> modifierStock(String idLivre, int nouvelleQuantite) async {
    try {
      final box = HiveService.livresBox;
      final livre = box.get(idLivre);
      if (livre != null) {
        livre.modifierStock(nouvelleQuantite);
        await box.put(idLivre, livre);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> ajouterExemplaires(String idLivre, int nombre) async {
    try {
      final box = HiveService.livresBox;
      final livre = box.get(idLivre);
      if (livre != null) {
        livre.ajouterExemplaires(nombre);
        await box.put(idLivre, livre);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> retirerExemplaire(String idLivre) async {
    try {
      final box = HiveService.livresBox;
      final livre = box.get(idLivre);
      if (livre != null && livre.retirerExemplaire()) {
        await box.put(idLivre, livre);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  bool estDisponible(String idLivre) {
    final livre = getLivreById(idLivre);
    return livre?.estDisponible ?? false;
  }

  int getQuantiteDisponible(String idLivre) {
    final livre = getLivreById(idLivre);
    return livre?.quantiteStock ?? 0;
  }

  List<Livre> getLivresParDomaine(String domaine) {
    final box = HiveService.livresBox;
    return box.values
        .where((livre) => livre.domaine.toLowerCase() == domaine.toLowerCase())
        .toList();
  }

  List<String> getAllDomaines() {
    final box = HiveService.livresBox;
    final domaines = box.values.map((livre) => livre.domaine).toSet();
    return domaines.toList();
  }

  String generateId() {
    return 'LIV_${DateTime.now().millisecondsSinceEpoch}';
  }
}
