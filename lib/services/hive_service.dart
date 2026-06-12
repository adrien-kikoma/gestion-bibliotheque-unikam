import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../models/livre.dart';
import '../models/utilisateur.dart';
import '../models/emprunt.dart';

class HiveService {
  static const String livresBoxName = 'livres';
  static const String utilisateursBoxName = 'utilisateurs';
  static const String empruntsBoxName = 'emprunts';

  static Future<void> initHive() async {
    final appDocumentDir =
        await path_provider.getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);

    Hive.registerAdapter(LivreAdapter());
    Hive.registerAdapter(UtilisateurAdapter());
    Hive.registerAdapter(EmpruntAdapter());

    await Hive.openBox<Livre>(livresBoxName);
    await Hive.openBox<Utilisateur>(utilisateursBoxName);
    await Hive.openBox<Emprunt>(empruntsBoxName);

    await initDemoData();
  }

  static Future<void> initDemoData() async {
    final userBox = Hive.box<Utilisateur>(utilisateursBoxName);

    if (userBox.isEmpty) {
      // Bibliothécaire: Fidèle Masengo
      final fideleMasengo = Utilisateur(
        id: 'user_1',
        nom: 'Fidèle Masengo',
        email: 'fidelemasengo@gmail.com',
        role: 'bibliothecaire',
        motDePasse: 'fidele123',
        matricule: 'LIB001',
      );
      await userBox.put(fideleMasengo.id, fideleMasengo);

      // Directeur
      final directeur = Utilisateur(
        id: 'user_2',
        nom: 'Marie Martin',
        email: 'mariemartin@gmail.com',
        role: 'directeur',
        motDePasse: 'dir123',
        matricule: 'DIR001',
      );
      await userBox.put(directeur.id, directeur);

      // Étudiants
      final etudiant1 = Utilisateur(
        id: 'user_3',
        nom: 'Ali Traoré',
        email: 'alitraore@gmail.com',
        role: 'etudiant',
        motDePasse: 'etu123',
        matricule: 'ETU2024001',
      );
      await userBox.put(etudiant1.id, etudiant1);

      final etudiant2 = Utilisateur(
        id: 'user_4',
        nom: 'Fatou Diallo',
        email: 'fatoudiallo@gmail.com',
        role: 'etudiant',
        motDePasse: 'etu456',
        matricule: 'ETU2024002',
      );
      await userBox.put(etudiant2.id, etudiant2);
    }

    final livreBox = Hive.box<Livre>(livresBoxName);
    if (livreBox.isEmpty) {
      final livres = [
        Livre(
          idLivre: 'liv_1',
          titre: 'Flutter pour les débutants',
          auteur: 'John Doe',
          quantiteStock: 5,
          domaine: 'Informatique',
          edition: '2ème édition',
          anneePublication: 2023,
        ),
        Livre(
          idLivre: 'liv_2',
          titre: 'Programmation Dart avancée',
          auteur: 'Jane Smith',
          quantiteStock: 3,
          domaine: 'Informatique',
          edition: '1ère édition',
          anneePublication: 2022,
        ),
        Livre(
          idLivre: 'liv_3',
          titre: 'Intelligence Artificielle',
          auteur: 'Alan Turing',
          quantiteStock: 4,
          domaine: 'Intelligence Artificielle',
          edition: '3ème édition',
          anneePublication: 2021,
        ),
        Livre(
          idLivre: 'liv_4',
          titre: 'Développement Web Moderne',
          auteur: 'Sarah Johnson',
          quantiteStock: 6,
          domaine: 'Informatique',
          edition: '2ème édition',
          anneePublication: 2023,
        ),
        Livre(
          idLivre: 'liv_5',
          titre: 'Cybersécurité Essentielle',
          auteur: 'Marc Bernard',
          quantiteStock: 3,
          domaine: 'Sécurité',
          edition: '1ère édition',
          anneePublication: 2022,
        ),
      ];

      for (var livre in livres) {
        await livreBox.put(livre.idLivre, livre);
      }
    }
  }

  static Box<Livre> get livresBox => Hive.box<Livre>(livresBoxName);
  static Box<Utilisateur> get utilisateursBox =>
      Hive.box<Utilisateur>(utilisateursBoxName);
  static Box<Emprunt> get empruntsBox => Hive.box<Emprunt>(empruntsBoxName);
}
