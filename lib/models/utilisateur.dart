import 'package:hive/hive.dart';

part 'utilisateur.g.dart';

@HiveType(typeId: 1)
class Utilisateur {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nom;

  @HiveField(2)
  String email;

  @HiveField(3)
  String role;

  @HiveField(4)
  String motDePasse;

  @HiveField(5)
  String matricule;

  @HiveField(6)
  String? photoUrl; // NOUVEAU : chemin de la photo

  Utilisateur({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    required this.motDePasse,
    required this.matricule,
    this.photoUrl,
  });
}
