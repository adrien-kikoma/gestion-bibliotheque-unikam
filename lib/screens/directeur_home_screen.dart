import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/livre_service.dart';
import '../services/emprunt_service.dart';
import '../models/emprunt.dart';
import '../models/livre.dart';
import '../models/utilisateur.dart';
import '../widgets/profile_picture.dart';
import 'login_screen.dart';

class DirecteurHomeScreen extends StatefulWidget {
  final AuthService authService;

  const DirecteurHomeScreen({super.key, required this.authService});

  @override
  State<DirecteurHomeScreen> createState() => _DirecteurHomeScreenState();
}

class _DirecteurHomeScreenState extends State<DirecteurHomeScreen> {
  final LivreService _livreService = LivreService();
  final EmpruntService _empruntService = EmpruntService();

  DateTime _moisSelectionne = DateTime.now();
  String _rapportContent = '';
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _genererRapport();
  }

  Future<void> _genererRapport() async {
    setState(() {
      _isGenerating = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final rapport = await _genererRapportMensuel();

    if (mounted) {
      setState(() {
        _rapportContent = rapport;
        _isGenerating = false;
      });
    }
  }

  Future<String> _genererRapportMensuel() async {
    final empruntsMois = _empruntService.getEmpruntsDuMois(_moisSelectionne);
    final tousLesLivres = _livreService.getAllLivres();
    final tousLesUtilisateurs = widget.authService.getAllUtilisateurs();
    final etudiants =
        tousLesUtilisateurs.where((u) => u.role == 'etudiant').toList();

    final StringBuffer buffer = StringBuffer();

    buffer.writeln(
        '╔══════════════════════════════════════════════════════════════════════════════╗');
    buffer.writeln(
        '║                         BIBLIOTHÈQUE UNIVERSITAIRE UNIKAM                     ║');
    buffer.writeln(
        '║                            RAPPORT MENSUEL D\'ACTIVITÉ                         ║');
    buffer.writeln(
        '╠══════════════════════════════════════════════════════════════════════════════╣');
    buffer.writeln('║ Période        : ${_formatPeriode(_moisSelectionne)}');
    buffer.writeln(
        '║ Date génération: ${DateFormat('dd/MM/yyyy à HH:mm:ss').format(DateTime.now())}');
    buffer.writeln(
        '║ Généré par     : ${widget.authService.utilisateurConnecte?.nom ?? 'Directeur'}');
    buffer.writeln(
        '╚══════════════════════════════════════════════════════════════════════════════╝');
    buffer.writeln();

    buffer.writeln(
        '┌─────────────────────── STATISTIQUES GÉNÉRALES ───────────────────────┐');
    buffer.writeln('│');
    buffer.writeln('│ 📚 FONDS DOCUMENTAIRE');
    buffer.writeln(
        '│    ├─ Nombre total de livres  : ${_formatNumber(tousLesLivres.length)}');
    buffer.writeln(
        '│    ├─ Nombre total d\'exemplaires: ${_formatNumber(tousLesLivres.fold(0, (sum, livre) => sum + livre.quantiteStock))}');
    buffer.writeln(
        '│    └─ Exemplaires disponibles : ${_formatNumber(tousLesLivres.fold(0, (sum, livre) => sum + livre.quantiteStock))}');
    buffer.writeln('│');
    buffer.writeln('│ 👥 UTILISATEURS');
    buffer.writeln(
        '│    └─ Étudiants inscrits      : ${_formatNumber(etudiants.length)}');
    buffer.writeln('│');
    buffer.writeln('│ 📖 ACTIVITÉ GLOBALE');
    buffer.writeln(
        '│    ├─ Emprunts total          : ${_formatNumber(_empruntService.getNombreTotalEmprunts())}');
    buffer.writeln(
        '│    ├─ Emprunts en cours       : ${_formatNumber(_empruntService.getNombreEmpruntsEnCours())}');
    buffer.writeln(
        '│    └─ Emprunts en retard      : ${_formatNumber(_empruntService.getNombreEmpruntsEnRetard())}');
    buffer.writeln('│');
    buffer.writeln(
        '└───────────────────────────────────────────────────────────────────────┘');
    buffer.writeln();

    buffer.writeln(
        '┌───────────────────────── ACTIVITÉ DU MOIS ─────────────────────────┐');
    buffer.writeln('│');
    buffer.writeln('│ 📊 CHIFFRES CLÉS');
    buffer.writeln(
        '│    ├─ Emprunts réalisés      : ${_formatNumber(empruntsMois.length)}');

    final retoursMois =
        empruntsMois.where((e) => e.dateRetourReel != null).length;
    buffer.writeln(
        '│    ├─ Retours effectués      : ${_formatNumber(retoursMois)}');
    buffer.writeln(
        '│    └─ Taux de rotation       : ${_calculerTauxRotation(empruntsMois.length, tousLesLivres.length)}%');
    buffer.writeln('│');

    final empruntsParJour = <DateTime, int>{};
    for (var emprunt in empruntsMois) {
      final jour = DateTime(emprunt.dateEmprunt.year, emprunt.dateEmprunt.month,
          emprunt.dateEmprunt.day);
      empruntsParJour[jour] = (empruntsParJour[jour] ?? 0) + 1;
    }

    if (empruntsParJour.isNotEmpty) {
      final jourMax =
          empruntsParJour.entries.reduce((a, b) => a.value > b.value ? a : b);
      buffer.writeln('│ ⭐ JOUR LE PLUS ACTIF');
      buffer.writeln(
          '│    └─ ${DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(jourMax.key)} : ${jourMax.value} emprunts');
    }
    buffer.writeln('│');
    buffer.writeln(
        '└───────────────────────────────────────────────────────────────────────┘');
    buffer.writeln();

    buffer.writeln(
        '┌─────────────────── TOP 5 DES LIVRES LES PLUS EMPRUNTÉS ───────────────────┐');
    buffer.writeln('│');

    final compteurLivres = <String, int>{};
    for (var emprunt in _empruntService.getAllEmprunts()) {
      compteurLivres[emprunt.livreId] =
          (compteurLivres[emprunt.livreId] ?? 0) + 1;
    }

    final topLivres = compteurLivres.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (topLivres.isEmpty) {
      buffer.writeln('│    Aucun emprunt enregistré');
    } else {
      for (var i = 0; i < (topLivres.length < 5 ? topLivres.length : 5); i++) {
        final entry = topLivres[i];
        final livre = _livreService.getLivreById(entry.key);
        if (livre != null) {
          final pourcentage =
              (entry.value / _empruntService.getNombreTotalEmprunts() * 100)
                  .toStringAsFixed(1);
          buffer.writeln(
              '│ ${_getMedalEmoji(i + 1)} ${(i + 1).toString().padLeft(2)}. "${_truncateString(livre.titre, 35)}"');
          buffer.writeln('│        Auteur: ${livre.auteur}');
          buffer.writeln('│        Domaine: ${livre.domaine}');
          buffer.writeln(
              '│        Emprunts: ${entry.value} (${pourcentage}% des emprunts)');
          if (i < topLivres.length - 1) buffer.writeln('│');
        }
      }
    }
    buffer.writeln('│');
    buffer.writeln(
        '└─────────────────────────────────────────────────────────────────────────────┘');
    buffer.writeln();

    buffer.writeln(
        '┌─────────────────── TOP 5 DES ÉTUDIANTS LES PLUS ACTIFS ───────────────────┐');
    buffer.writeln('│');

    final compteurEtudiants = <String, int>{};
    for (var emprunt in _empruntService.getAllEmprunts()) {
      compteurEtudiants[emprunt.utilisateurId] =
          (compteurEtudiants[emprunt.utilisateurId] ?? 0) + 1;
    }

    final topEtudiants = compteurEtudiants.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (topEtudiants.isEmpty) {
      buffer.writeln('│    Aucun emprunt enregistré');
    } else {
      for (var i = 0;
          i < (topEtudiants.length < 5 ? topEtudiants.length : 5);
          i++) {
        final entry = topEtudiants[i];
        final etudiant = tousLesUtilisateurs.firstWhere(
          (u) => u.id == entry.key,
          orElse: () => Utilisateur(
            id: '',
            nom: 'Inconnu',
            email: '',
            role: '',
            motDePasse: '',
            matricule: '',
          ),
        );
        if (etudiant.id.isNotEmpty && etudiant.role == 'etudiant') {
          buffer.writeln(
              '│ ${_getMedalEmoji(i + 1)} ${(i + 1).toString().padLeft(2)}. ${_truncateString(etudiant.nom, 30)}');
          buffer.writeln('│        Matricule: ${etudiant.matricule}');
          buffer.writeln('│        Email: ${etudiant.email}');
          buffer.writeln('│        Emprunts: ${entry.value} livre(s)');
          if (i < topEtudiants.length - 1) buffer.writeln('│');
        }
      }
    }
    buffer.writeln('│');
    buffer.writeln(
        '└─────────────────────────────────────────────────────────────────────────────┘');
    buffer.writeln();

    buffer.writeln(
        '┌───────────────────────── SITUATION DES RETARDS ─────────────────────────┐');
    buffer.writeln('│');

    final empruntsEnRetard = _empruntService.getEmpruntsEnRetard();
    if (empruntsEnRetard.isNotEmpty) {
      buffer.writeln(
          '│ ⚠️  ALERTE : ${empruntsEnRetard.length} emprunt(s) en retard');
      buffer.writeln('│');
      for (var emprunt in empruntsEnRetard) {
        final livre = _livreService.getLivreById(emprunt.livreId);
        final etudiant = tousLesUtilisateurs
            .firstWhere((u) => u.id == emprunt.utilisateurId);
        final retardJours =
            DateTime.now().difference(emprunt.dateRetourPrevue).inDays;
        buffer.writeln(
            '│    📖 "${_truncateString(livre?.titre ?? 'Inconnu', 30)}"');
        buffer.writeln(
            '│       Étudiant: ${etudiant.nom} (${etudiant.matricule})');
        buffer.writeln(
            '│       Date d\'emprunt: ${_formaterDate(emprunt.dateEmprunt)}');
        buffer.writeln(
            '│       Date prévue: ${_formaterDate(emprunt.dateRetourPrevue)}');
        buffer.writeln('│       Retard: $retardJours jour(s)');
        buffer.writeln('│');
      }
    } else {
      buffer.writeln('│ ✅ FÉLICITATIONS !');
      buffer.writeln('│    Aucun emprunt en retard à signaler.');
      buffer.writeln('│    Les étudiants respectent les délais de retour.');
    }
    buffer.writeln('│');
    buffer.writeln(
        '└───────────────────────────────────────────────────────────────────────┘');
    buffer.writeln();

    buffer.writeln(
        '┌───────────────────────────── ÉTAT DU STOCK ─────────────────────────────┐');
    buffer.writeln('│');

    int livresTresDisponibles = 0;
    int livresPeuDisponibles = 0;
    int livresIndisponibles = 0;

    for (var livre in tousLesLivres) {
      if (livre.quantiteStock == 0) {
        livresIndisponibles++;
      } else if (livre.quantiteStock <= 3) {
        livresPeuDisponibles++;
      } else {
        livresTresDisponibles++;
      }
    }

    buffer.writeln('│ 📊 DISTRIBUTION DES LIVRES');
    buffer.writeln('│');
    buffer.writeln(
        '│    🟢 Très disponibles (>3 ex.) : ${_formatNumber(livresTresDisponibles)} livres');
    buffer.writeln(
        '│    🟡 Peu disponibles (1-3 ex.) : ${_formatNumber(livresPeuDisponibles)} livres');
    buffer.writeln(
        '│    🔴 Indisponibles (0 ex.)     : ${_formatNumber(livresIndisponibles)} livres');
    buffer.writeln('│');

    if (livresIndisponibles > 0) {
      buffer.writeln('│ 📋 LISTE DES LIVRES INDISPONIBLES');
      buffer.writeln('│');
      int count = 0;
      for (var livre in tousLesLivres) {
        if (livre.quantiteStock == 0 && count < 10) {
          buffer.writeln(
              '│    • "${_truncateString(livre.titre, 35)}" - ${livre.auteur}');
          buffer.writeln('│      Domaine: ${livre.domaine}');
          count++;
        }
      }
      if (livresIndisponibles > 10) {
        buffer.writeln('│    ... et ${livresIndisponibles - 10} autres livres');
      }
    }
    buffer.writeln('│');
    buffer.writeln(
        '└───────────────────────────────────────────────────────────────────────┘');
    buffer.writeln();

    buffer.writeln(
        '┌───────────────────────────── RECOMMANDATIONS ───────────────────────────┐');
    buffer.writeln('│');

    bool hasRecommendations = false;

    if (livresIndisponibles > 10) {
      buffer.writeln('│ 📚 RÉAPPROVISIONNEMENT');
      buffer.writeln('│    ➤ $livresIndisponibles livres sont indisponibles.');
      buffer.writeln(
          '│    ➤ Priorité au réapprovisionnement des ouvrages les plus demandés.');
      buffer.writeln('│');
      hasRecommendations = true;
    }

    if (_empruntService.getNombreEmpruntsEnRetard() > 5) {
      buffer.writeln('│ ⚠️ GESTION DES RETARDS');
      buffer.writeln(
          '│    ➤ ${_empruntService.getNombreEmpruntsEnRetard()} emprunts en retard.');
      buffer.writeln(
          '│    ➤ Envoyer des rappels automatiques aux étudiants concernés.');
      buffer.writeln('│');
      hasRecommendations = true;
    }

    if (empruntsMois.length < 10 && tousLesLivres.length > 20) {
      buffer.writeln('│ 📢 PROMOTION DE LA LECTURE');
      buffer.writeln('│    ➤ Taux d\'emprunt faible ce mois-ci.');
      buffer.writeln('│    ➤ Organiser une campagne de sensibilisation.');
      buffer.writeln('│    ➤ Mettre en avant les nouveaux arrivages.');
      buffer.writeln('│');
      hasRecommendations = true;
    }

    if (topLivres.isNotEmpty && topLivres.first.value > 20) {
      final livrePopulaire = _livreService.getLivreById(topLivres.first.key);
      if (livrePopulaire != null) {
        buffer.writeln('│ ⭐ LIVRE À SUCCÈS');
        buffer.writeln('│    ➤ "${livrePopulaire.titre}" est très populaire.');
        buffer.writeln('│    ➤ Commander des exemplaires supplémentaires.');
        buffer.writeln('│');
        hasRecommendations = true;
      }
    }

    if (!hasRecommendations) {
      buffer.writeln('│ ✅ TOUT EST BON !');
      buffer.writeln('│    ➤ La bibliothèque fonctionne parfaitement.');
      buffer.writeln('│    ➤ Continuez ainsi !');
      buffer.writeln('│');
    }

    buffer.writeln(
        '└───────────────────────────────────────────────────────────────────────┘');
    buffer.writeln();

    buffer.writeln(
        '╔══════════════════════════════════════════════════════════════════════════════╗');
    buffer.writeln(
        '║                            FIN DU RAPPORT                                     ║');
    buffer.writeln(
        '║                                                                              ║');
    buffer.writeln(
        '║    Document généré automatiquement par le système de gestion de bibliothèque ║');
    buffer.writeln(
        '║    Pour toute question, contacter l\'administrateur                           ║');
    buffer.writeln(
        '╚══════════════════════════════════════════════════════════════════════════════╝');

    return buffer.toString();
  }

  String _formatPeriode(DateTime date) {
    return DateFormat('MMMM yyyy', 'fr_FR').format(date).toUpperCase();
  }

  String _formatNumber(int number) {
    return NumberFormat('#,###').format(number).replaceAll(',', ' ');
  }

  String _calculerTauxRotation(int emprunts, int livres) {
    if (livres == 0) return '0';
    double taux = (emprunts / livres) * 100;
    return taux.toStringAsFixed(1);
  }

  String _getMedalEmoji(int position) {
    switch (position) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '📖';
    }
  }

  String _truncateString(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  String _formaterDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _partagerRapport() async {
    await Clipboard.setData(ClipboardData(text: _rapportContent));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Rapport copié dans le presse-papier !'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _changerMois() async {
    final DateTime? nouvelleDate = await showDatePicker(
      context: context,
      initialDate: _moisSelectionne,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (nouvelleDate != null && nouvelleDate != _moisSelectionne) {
      setState(() {
        _moisSelectionne = nouvelleDate;
      });
      await _genererRapport();
    }
  }

  void _deconnexion() {
    widget.authService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Directeur'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _deconnexion,
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec infos directeur - CORRIGÉ pour éviter overflow
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.purple.shade700, Colors.purple.shade400],
              ),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12), // Réduit le padding
            child: Row(
              children: [
                // Photo de profil plus petite
                ProfilePicture(
                  user: widget.authService.utilisateurConnecte!,
                  size: 50, // Réduit de 70 à 50
                  isEditable: true,
                  onPhotoUpdated: () {
                    setState(() {});
                  },
                ),
                const SizedBox(width: 12),
                // Informations avec Expanded pour éviter overflow
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize:
                        MainAxisSize.min, // Ajouté pour réduire la hauteur
                    children: [
                      Text(
                        widget.authService.utilisateurConnecte?.nom ??
                            'Directeur',
                        style: const TextStyle(
                          fontSize: 16, // Réduit de 20 à 16
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Matricule: ${widget.authService.utilisateurConnecte?.matricule ?? ''}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge directeur plus compact
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.purple, size: 12),
                      SizedBox(width: 4),
                      Text('Directeur',
                          style: TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                              fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contrôles du rapport (inchangé)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Période du rapport',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: Colors.purple),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                DateFormat('MMMM yyyy', 'fr_FR')
                                    .format(_moisSelectionne),
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _changerMois,
                  icon: const Icon(Icons.calendar_month, size: 16),
                  label: const Text('Changer', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _partagerRapport,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copier', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Affichage du rapport
          Expanded(
            child: _isGenerating
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.purple)),
                        const SizedBox(height: 16),
                        Text(
                          'Génération du rapport en cours...',
                          style: TextStyle(color: Colors.purple.shade700),
                        ),
                      ],
                    ),
                  )
                : Container(
                    color: Colors.grey.shade50,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(
                            _rapportContent,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              height: 1.3,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
