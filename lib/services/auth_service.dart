import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../models/utilisateur.dart';
import 'hive_service.dart';

class AuthService {
  Utilisateur? _utilisateurConnecte;

  Utilisateur? get utilisateurConnecte => _utilisateurConnecte;

  bool get estConnecte => _utilisateurConnecte != null;

  String get roleUtilisateurConnecte => _utilisateurConnecte?.role ?? '';

  // Tentative de connexion avec email
  Future<Map<String, dynamic>> login(String email, String motDePasse) async {
    final userBox = HiveService.utilisateursBox;

    try {
      final utilisateur = userBox.values.firstWhere(
        (user) =>
            user.email.toLowerCase() == email.toLowerCase() &&
            user.motDePasse == motDePasse,
      );

      _utilisateurConnecte = utilisateur;
      return {'success': true, 'role': utilisateur.role};
    } catch (e) {
      return {'success': false, 'role': null};
    }
  }

  // Version simple pour la compatibilité
  Future<bool> loginSimple(String email, String motDePasse) async {
    final result = await login(email, motDePasse);
    return result['success'] as bool;
  }

  // Déconnexion
  void logout() {
    _utilisateurConnecte = null;
  }

  // Vérifier si l'utilisateur a un rôle spécifique
  bool hasRole(String role) {
    return _utilisateurConnecte?.role == role;
  }

  // Obtenir tous les utilisateurs
  List<Utilisateur> getAllUtilisateurs() {
    final userBox = HiveService.utilisateursBox;
    return userBox.values.toList();
  }

  // Obtenir les étudiants seulement
  List<Utilisateur> getEtudiants() {
    final userBox = HiveService.utilisateursBox;
    return userBox.values.where((user) => user.role == 'etudiant').toList();
  }

  // Obtenir les bibliothécaires
  List<Utilisateur> getBibliothecaires() {
    final userBox = HiveService.utilisateursBox;
    return userBox.values
        .where((user) => user.role == 'bibliothecaire')
        .toList();
  }

  // Obtenir un utilisateur par son ID
  Utilisateur? getUtilisateurById(String id) {
    final userBox = HiveService.utilisateursBox;
    return userBox.get(id);
  }

  // Obtenir un utilisateur par son email
  Utilisateur? getUtilisateurByEmail(String email) {
    final userBox = HiveService.utilisateursBox;
    try {
      return userBox.values.firstWhere(
        (user) => user.email.toLowerCase() == email.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Ajouter un nouvel utilisateur
  Future<bool> ajouterUtilisateur(Utilisateur utilisateur) async {
    try {
      final userBox = HiveService.utilisateursBox;
      await userBox.put(utilisateur.id, utilisateur);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Supprimer un utilisateur
  Future<bool> supprimerUtilisateur(String id) async {
    try {
      final userBox = HiveService.utilisateursBox;
      await userBox.delete(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Mettre à jour un utilisateur
  Future<bool> mettreAJourUtilisateur(Utilisateur utilisateur) async {
    try {
      final userBox = HiveService.utilisateursBox;
      await userBox.put(utilisateur.id, utilisateur);
      if (_utilisateurConnecte?.id == utilisateur.id) {
        _utilisateurConnecte = utilisateur;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Mettre à jour la photo de profil
  Future<bool> updateProfilePhoto(String userId, String? photoUrl) async {
    try {
      final userBox = HiveService.utilisateursBox;
      final user = userBox.get(userId);
      if (user != null) {
        user.photoUrl = photoUrl;
        await userBox.put(userId, user);
        if (_utilisateurConnecte?.id == userId) {
          _utilisateurConnecte = user;
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Obtenir la photo de profil
  String? getProfilePhoto(String userId) {
    final user = getUtilisateurById(userId);
    return user?.photoUrl;
  }

  // Obtenir le répertoire des documents
  Future<Directory> getApplicationDocumentsDirectory() async {
    return await path_provider.getApplicationDocumentsDirectory();
  }

  // Générer un ID unique
  String generateId() {
    return 'USER_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Vérifier si un email existe déjà
  bool emailExiste(String email) {
    final userBox = HiveService.utilisateursBox;
    try {
      userBox.values.firstWhere(
        (user) => user.email.toLowerCase() == email.toLowerCase(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Vérifier si un matricule existe déjà
  bool matriculeExiste(String matricule) {
    final userBox = HiveService.utilisateursBox;
    try {
      userBox.values.firstWhere((user) => user.matricule == matricule);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Changer le mot de passe
  Future<bool> changerMotDePasse(
      String email, String ancienMotDePasse, String nouveauMotDePasse) async {
    final utilisateur = getUtilisateurByEmail(email);
    if (utilisateur != null && utilisateur.motDePasse == ancienMotDePasse) {
      final utilisateurModifie = Utilisateur(
        id: utilisateur.id,
        nom: utilisateur.nom,
        email: utilisateur.email,
        role: utilisateur.role,
        motDePasse: nouveauMotDePasse,
        matricule: utilisateur.matricule,
        photoUrl: utilisateur.photoUrl,
      );
      return await mettreAJourUtilisateur(utilisateurModifie);
    }
    return false;
  }

  // Obtenir le nombre total d'utilisateurs par rôle
  Map<String, int> getStatistiquesUtilisateurs() {
    final users = getAllUtilisateurs();
    return {
      'etudiants': users.where((u) => u.role == 'etudiant').length,
      'bibliothecaires': users.where((u) => u.role == 'bibliothecaire').length,
      'directeurs': users.where((u) => u.role == 'directeur').length,
      'total': users.length,
    };
  }

  // Sauvegarder une image localement
  Future<String?> saveImage(File image, String userId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/profiles');

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File('${imagesDir.path}/$fileName');

      await image.copy(savedImage.path);
      return savedImage.path;
    } catch (e) {
      return null;
    }
  }

  // Supprimer une image
  Future<bool> deleteImage(String? photoUrl) async {
    if (photoUrl == null) return false;
    try {
      final file = File(photoUrl);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
