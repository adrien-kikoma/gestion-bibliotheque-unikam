import 'package:hive/hive.dart';

part 'livre.g.dart';

@HiveType(typeId: 0)
class Livre {
  @HiveField(0)
  String idLivre;

  @HiveField(1)
  String titre;

  @HiveField(2)
  String auteur;

  @HiveField(3)
  int quantiteStock;

  @HiveField(4)
  String domaine;

  @HiveField(5)
  String edition;

  @HiveField(6)
  int anneePublication;

  Livre({
    required this.idLivre,
    required this.titre,
    required this.auteur,
    required this.quantiteStock,
    required this.domaine,
    required this.edition,
    required this.anneePublication,
  });

  // Getter pour savoir si disponible
  bool get estDisponible => quantiteStock > 0;

  // Getter pour le nombre disponible (compatibilité)
  int get quantiteDisponible => quantiteStock;

  // Méthode pour modifier le stock
  void modifierStock(int nouvelleQuantite) {
    quantiteStock = nouvelleQuantite;
  }

  // Méthode pour ajouter des exemplaires
  void ajouterExemplaires(int nombre) {
    quantiteStock += nombre;
  }

  // Méthode pour retirer des exemplaires (emprunt)
  bool retirerExemplaire() {
    if (quantiteStock > 0) {
      quantiteStock--;
      return true;
    }
    return false;
  }

  // Méthode pour ajouter un exemplaire (retour)
  void ajouterExemplaire() {
    quantiteStock++;
  }

  @override
  String toString() {
    return '$titre - $auteur ($quantiteStock disponibles)';
  }
}
