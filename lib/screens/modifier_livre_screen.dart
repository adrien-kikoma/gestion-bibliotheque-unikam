import 'package:flutter/material.dart';
import '../services/livre_service.dart';
import '../models/livre.dart';

class ModifierLivreScreen extends StatefulWidget {
  final Livre livre;

  const ModifierLivreScreen({super.key, required this.livre});

  @override
  State<ModifierLivreScreen> createState() => _ModifierLivreScreenState();
}

class _ModifierLivreScreenState extends State<ModifierLivreScreen> {
  final LivreService _livreService = LivreService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titreController;
  late TextEditingController _auteurController;
  late TextEditingController _domaineController;
  late TextEditingController _editionController;
  late TextEditingController _anneeController;
  late TextEditingController _quantiteStockController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController(text: widget.livre.titre);
    _auteurController = TextEditingController(text: widget.livre.auteur);
    _domaineController = TextEditingController(text: widget.livre.domaine);
    _editionController = TextEditingController(text: widget.livre.edition);
    _anneeController =
        TextEditingController(text: widget.livre.anneePublication.toString());
    _quantiteStockController =
        TextEditingController(text: widget.livre.quantiteStock.toString());
  }

  @override
  void dispose() {
    _titreController.dispose();
    _auteurController.dispose();
    _domaineController.dispose();
    _editionController.dispose();
    _anneeController.dispose();
    _quantiteStockController.dispose();
    super.dispose();
  }

  Future<void> _modifierLivre() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final livreModifie = Livre(
      idLivre: widget.livre.idLivre,
      titre: _titreController.text.trim(),
      auteur: _auteurController.text.trim(),
      quantiteStock: int.parse(_quantiteStockController.text.trim()),
      domaine: _domaineController.text.trim(),
      edition: _editionController.text.trim(),
      anneePublication: int.parse(_anneeController.text.trim()),
    );

    final success = await _livreService.mettreAJourLivre(livreModifie);

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livre modifié avec succès!')),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la modification')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le livre'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                controller: _titreController,
                label: 'Titre',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Veuillez entrer le titre';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _auteurController,
                label: 'Auteur',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Veuillez entrer l\'auteur';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _domaineController,
                label: 'Domaine',
                icon: Icons.category,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Veuillez entrer le domaine';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _editionController,
                label: 'Édition',
                icon: Icons.edit_note,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Veuillez entrer l\'édition';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _anneeController,
                label: 'Année de publication',
                icon: Icons.date_range,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Veuillez entrer l\'année';
                  final annee = int.tryParse(value);
                  if (annee == null ||
                      annee < 1000 ||
                      annee > DateTime.now().year) {
                    return 'Année invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _quantiteStockController,
                label: 'Quantité en stock',
                icon: Icons.copy,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Veuillez entrer la quantité';
                  final quantite = int.tryParse(value);
                  if (quantite == null || quantite < 0)
                    return 'Quantité invalide';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _modifierLivre,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Modifier', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
