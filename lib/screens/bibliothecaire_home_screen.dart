import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/livre_service.dart';
import '../services/emprunt_service.dart';
import '../models/livre.dart';
import '../widgets/profile_picture.dart'; // AJOUTER CET IMPORT
import 'ajouter_livre_screen.dart';
import 'modifier_livre_screen.dart';
import 'gerer_emprunts_screen.dart';
import 'login_screen.dart';

class BibliothecaireHomeScreen extends StatefulWidget {
  final AuthService authService;

  const BibliothecaireHomeScreen({super.key, required this.authService});

  @override
  State<BibliothecaireHomeScreen> createState() =>
      _BibliothecaireHomeScreenState();
}

class _BibliothecaireHomeScreenState extends State<BibliothecaireHomeScreen> {
  final LivreService _livreService = LivreService();
  final EmpruntService _empruntService = EmpruntService();

  late List<Livre> _livres;
  final _searchController = TextEditingController();
  String _searchType = 'titre';

  int _nombreEmpruntsEnCours = 0;
  int _nombreEmpruntsEnRetard = 0;
  int _nombreLivresTotal = 0;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  void _chargerDonnees() {
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _livres = _livreService.getAllLivres();
          _nombreEmpruntsEnCours = _empruntService.getNombreEmpruntsEnCours();
          _nombreEmpruntsEnRetard = _empruntService.getNombreEmpruntsEnRetard();
          _nombreLivresTotal = _livres.length;
        });
      }
    });
  }

  void _rechercherLivres(String terme) {
    setState(() {
      if (terme.isEmpty) {
        _livres = _livreService.getAllLivres();
      } else {
        if (_searchType == 'titre') {
          _livres = _livreService.rechercherParTitre(terme);
        } else if (_searchType == 'auteur') {
          _livres = _livreService.rechercherParAuteur(terme);
        } else {
          _livres = _livreService.rechercherParDomaine(terme);
        }
      }
    });
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
        title: const Text('Espace Bibliothécaire'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _deconnexion),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatCard('Livres', _nombreLivresTotal.toString(),
                    Icons.menu_book, Colors.blue),
                const SizedBox(width: 12),
                _buildStatCard(
                    'Emprunts en cours',
                    _nombreEmpruntsEnCours.toString(),
                    Icons.bookmark,
                    Colors.orange),
                const SizedBox(width: 12),
                _buildStatCard('Retards', _nombreEmpruntsEnRetard.toString(),
                    Icons.warning, Colors.red),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                              value: 'titre', label: Text('Par Titre')),
                          ButtonSegment(
                              value: 'auteur', label: Text('Par Auteur')),
                          ButtonSegment(
                              value: 'domaine', label: Text('Par Domaine')),
                        ],
                        selected: {_searchType},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _searchType = newSelection.first;
                            _rechercherLivres(_searchController.text);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Rechercher un livre...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _rechercherLivres('');
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: _rechercherLivres,
                ),
              ],
            ),
          ),
          Expanded(
            child: _livres.isEmpty
                ? const Center(child: Text('Aucun livre trouvé'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _livres.length,
                    itemBuilder: (context, index) {
                      final livre = _livres[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: livre.estDisponible
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.menu_book,
                              color: livre.estDisponible
                                  ? Colors.green
                                  : Colors.red,
                              size: 30,
                            ),
                          ),
                          title: Text(
                            livre.titre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Auteur: ${livre.auteur}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Domaine: ${livre.domaine}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Stock: ${livre.quantiteStock} exemplaires',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _modifierLivre(livre),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _supprimerLivre(livre),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () => _afficherDetailsLivre(livre),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ajouterLivre(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(
      String titre, String valeur, IconData icone, Color couleur) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icone, size: 30, color: couleur),
              const SizedBox(height: 8),
              Text(valeur,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: couleur)),
              Text(titre,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green, Colors.greenAccent],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // REMPLACÉ par ProfilePicture avec photo modifiable
                ProfilePicture(
                  user: widget.authService.utilisateurConnecte!,
                  size: 60,
                  isEditable: true,
                  onPhotoUpdated: () {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  widget.authService.utilisateurConnecte?.nom ??
                      'Bibliothécaire',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.authService.utilisateurConnecte?.email ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Accueil'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.add_box),
            title: const Text('Ajouter un livre'),
            onTap: () {
              Navigator.pop(context);
              _ajouterLivre();
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Gérer les emprunts'),
            onTap: () {
              Navigator.pop(context);
              _gererEmprunts();
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historique des emprunts'),
            onTap: () {
              Navigator.pop(context);
              _voirHistoriqueEmprunts();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title:
                const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deconnexion();
            },
          ),
        ],
      ),
    );
  }

  void _ajouterLivre() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AjouterLivreScreen()),
    );
    if (result == true && mounted) _chargerDonnees();
  }

  void _modifierLivre(Livre livre) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ModifierLivreScreen(livre: livre)),
    );
    if (result == true && mounted) _chargerDonnees();
  }

  void _supprimerLivre(Livre livre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Voulez-vous vraiment supprimer "${livre.titre}" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Non')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Oui'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final success = await _livreService.supprimerLivre(livre.idLivre);
      if (success && mounted) {
        _chargerDonnees();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Livre supprimé')));
      }
    }
  }

  void _afficherDetailsLivre(Livre livre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(livre.titre),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Auteur', livre.auteur),
            _buildDetailRow('Domaine', livre.domaine),
            _buildDetailRow('Édition', livre.edition),
            _buildDetailRow('Année', livre.anneePublication.toString()),
            _buildDetailRow('Stock', livre.quantiteStock.toString()),
            _buildDetailRow(
                'Statut', livre.estDisponible ? 'Disponible' : 'Indisponible',
                color: livre.estDisponible ? Colors.green : Colors.red),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'))
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  void _gererEmprunts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GererEmpruntsScreen(
          empruntService: _empruntService,
          livreService: _livreService,
        ),
      ),
    ).then((_) {
      if (mounted) _chargerDonnees();
    });
  }

  void _voirHistoriqueEmprunts() {
    final tousLesEmprunts = _empruntService.getAllEmprunts();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historique des emprunts'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: tousLesEmprunts.isEmpty
              ? const Center(child: Text('Aucun emprunt enregistré'))
              : ListView.builder(
                  itemCount: tousLesEmprunts.length,
                  itemBuilder: (context, index) {
                    final emprunt = tousLesEmprunts[index];
                    final livre = _livreService.getLivreById(emprunt.livreId);
                    return ListTile(
                      title: Text(livre?.titre ?? 'Livre inconnu'),
                      subtitle: Text(
                          'Emprunté le: ${_formaterDate(emprunt.dateEmprunt)}\nStatut: ${emprunt.statut}'),
                      trailing: emprunt.dateRetourReel != null
                          ? Text(
                              'Retourné le: ${_formaterDate(emprunt.dateRetourReel!)}')
                          : null,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'))
        ],
      ),
    );
  }

  String _formaterDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}
