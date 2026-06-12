import 'package:flutter/material.dart';
import '../services/emprunt_service.dart';
import '../services/livre_service.dart';
import '../models/emprunt.dart';
import '../models/livre.dart';
import '../models/utilisateur.dart';
import '../services/auth_service.dart';

class GererEmpruntsScreen extends StatefulWidget {
  final EmpruntService empruntService;
  final LivreService livreService;

  const GererEmpruntsScreen({
    super.key,
    required this.empruntService,
    required this.livreService,
  });

  @override
  State<GererEmpruntsScreen> createState() => _GererEmpruntsScreenState();
}

class _GererEmpruntsScreenState extends State<GererEmpruntsScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  List<Emprunt> _empruntsEnCours = [];
  List<Emprunt> _empruntsEnRetard = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerEmprunts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _chargerEmprunts() {
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _empruntsEnCours = widget.empruntService.getEmpruntsEnCours();
          _empruntsEnRetard = widget.empruntService.getEmpruntsEnRetard();
        });
      }
    });
  }

  Future<void> _enregistrerRetour(Emprunt emprunt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation du retour',
            style: TextStyle(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirmez-vous le retour de ce livre ?',
                style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: emprunt.estEnRetard
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (emprunt.estEnRetard) ...[
                    const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 16),
                        SizedBox(width: 6),
                        Text(
                          '⚠️ LIVRE EN RETARD',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Retard de ${emprunt.joursDeRetard} jour(s)',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ] else ...[
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 6),
                        Text('Retour dans les délais',
                            style:
                                TextStyle(color: Colors.green, fontSize: 12)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(fontSize: 13)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: emprunt.estEnRetard ? Colors.red : Colors.green,
            ),
            child: const Text('Confirmer le retour',
                style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await widget.empruntService.enregistrerRetour(emprunt.id);
      if (success && mounted) {
        _chargerEmprunts();
        // SNACKBAR CORRIGÉ - plus compact
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(emprunt.estEnRetard ? Icons.warning : Icons.check_circle,
                    size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    emprunt.estEnRetard
                        ? 'Retour +${emprunt.joursDeRetard}J de retard'
                        : 'Retour dans les délais',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: emprunt.estEnRetard ? Colors.orange : Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur', style: TextStyle(fontSize: 12)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _nouvelEmprunt() async {
    final livre = await _selectionnerLivre();
    if (livre == null) return;

    final etudiant = await _selectionnerEtudiant();
    if (etudiant == null) return;

    final dateEmprunt = await _selectionnerDateEmprunt();
    if (dateEmprunt == null) return;

    final dateRetourPrevue = await _selectionnerDateRetourPrevue(dateEmprunt);
    if (dateRetourPrevue == null) return;

    final nouvelEmprunt = Emprunt(
      id: widget.empruntService.generateId(),
      livreId: livre.idLivre,
      utilisateurId: etudiant.id,
      dateEmprunt: dateEmprunt,
      dateRetourPrevue: dateRetourPrevue,
      statut: 'en_cours',
    );

    final success =
        await widget.empruntService.enregistrerEmprunt(nouvelEmprunt);

    if (success && mounted) {
      _chargerEmprunts();
      // SNACKBAR CORRIGÉ - plus compact
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Emprunt: ${etudiant.nom}',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('Retour: ${_formaterDate(dateRetourPrevue)}',
                        style: const TextStyle(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Livre indisponible', style: TextStyle(fontSize: 12)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<DateTime?> _selectionnerDateEmprunt() async {
    return await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      helpText: 'Sélectionner la date d\'emprunt',
      confirmText: 'Confirmer',
      cancelText: 'Annuler',
    );
  }

  Future<DateTime?> _selectionnerDateRetourPrevue(DateTime dateEmprunt) async {
    final dateParDefaut = Emprunt.calculerDateRetourPrevue(dateEmprunt);

    return await showDialog<DateTime>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            const Text('Date de retour prévue', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Durée standard : 14 jours',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, dateParDefaut),
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text('Retour: ${_formaterDate(dateParDefaut)}',
                  style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final datePerso = await showDatePicker(
                  context: context,
                  initialDate: dateParDefaut,
                  firstDate: dateEmprunt,
                  lastDate: dateEmprunt.add(const Duration(days: 60)),
                  helpText: 'Choisir une date',
                  confirmText: 'OK',
                  cancelText: 'Annuler',
                );
                if (datePerso != null && context.mounted) {
                  Navigator.pop(context, datePerso);
                }
              },
              icon: const Icon(Icons.edit_calendar, size: 16),
              label: const Text('Autre date', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<Livre?> _selectionnerLivre() async {
    final livres = widget.livreService.getAllLivres();
    final livresDisponibles = livres.where((l) => l.estDisponible).toList();

    if (livresDisponibles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Aucun livre disponible', style: TextStyle(fontSize: 12)),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return null;
    }

    return await showDialog<Livre>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            const Text('Sélectionner un livre', style: TextStyle(fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: ListView.builder(
            itemCount: livresDisponibles.length,
            itemBuilder: (context, index) {
              final livre = livresDisponibles[index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.menu_book, size: 20),
                title: Text(livre.titre,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                subtitle: Text('${livre.auteur} - ${livre.quantiteStock} dispo',
                    style: const TextStyle(fontSize: 11)),
                onTap: () => Navigator.pop(context, livre),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<Utilisateur?> _selectionnerEtudiant() async {
    final etudiants = _authService.getEtudiants();

    return await showDialog<Utilisateur>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner un étudiant',
            style: TextStyle(fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: ListView.builder(
            itemCount: etudiants.length,
            itemBuilder: (context, index) {
              final etudiant = etudiants[index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.person, size: 20),
                title: Text(etudiant.nom,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                subtitle: Text('Mat: ${etudiant.matricule}',
                    style: const TextStyle(fontSize: 11)),
                onTap: () => Navigator.pop(context, etudiant),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Gestion des emprunts', style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'En cours'),
            Tab(text: 'En retard'),
          ],
          labelStyle: const TextStyle(fontSize: 13),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEmpruntsList(_empruntsEnCours, 'Aucun emprunt en cours'),
          _buildEmpruntsList(_empruntsEnRetard, 'Aucun emprunt en retard'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _nouvelEmprunt,
        child: const Icon(Icons.add),
        tooltip: 'Nouvel emprunt',
      ),
    );
  }

  Widget _buildEmpruntsList(List<Emprunt> emprunts, String messageVide) {
    if (emprunts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 50, color: Colors.grey),
            const SizedBox(height: 12),
            Text(messageVide,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: emprunts.length,
      itemBuilder: (context, index) {
        final emprunt = emprunts[index];
        final livre = widget.livreService.getLivreById(emprunt.livreId);
        final utilisateur = _authService
            .getAllUtilisateurs()
            .firstWhere((u) => u.id == emprunt.utilisateurId);

        final bool estEnRetard = emprunt.estEnRetard;
        final int joursRetard = emprunt.joursDeRetard;

        // CARTE CORRIGÉE - taille réduite pour éviter overflow
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color:
                    estEnRetard ? Colors.red.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.book,
                color: estEnRetard ? Colors.red : Colors.orange,
                size: 24,
              ),
            ),
            title: Text(
              livre?.titre ?? 'Livre inconnu',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${utilisateur.nom} (${utilisateur.matricule})',
                  style: const TextStyle(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 10, color: Colors.grey),
                    const SizedBox(width: 2),
                    Text('Emprunt: ${_formaterDate(emprunt.dateEmprunt)}',
                        style: const TextStyle(fontSize: 10)),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 10,
                      color: estEnRetard ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Retour: ${_formaterDate(emprunt.dateRetourPrevue)}',
                      style: TextStyle(
                        color: estEnRetard ? Colors.red : Colors.grey,
                        fontWeight:
                            estEnRetard ? FontWeight.bold : FontWeight.normal,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                if (estEnRetard) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'RETARD $joursRetard J',
                      style: const TextStyle(
                          color: Colors.red,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            trailing: SizedBox(
              height: 30,
              width: 65,
              child: ElevatedButton(
                onPressed: () => _enregistrerRetour(emprunt),
                style: ElevatedButton.styleFrom(
                  backgroundColor: estEnRetard ? Colors.orange : Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(60, 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Retour', style: TextStyle(fontSize: 11)),
              ),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  String _formaterDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
