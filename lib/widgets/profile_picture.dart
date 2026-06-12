import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';
import '../models/utilisateur.dart';

class ProfilePicture extends StatefulWidget {
  final Utilisateur user;
  final double size;
  final bool isEditable;
  final VoidCallback? onPhotoUpdated;

  const ProfilePicture({
    super.key,
    required this.user,
    this.size = 80,
    this.isEditable = false,
    this.onPhotoUpdated,
  });

  @override
  State<ProfilePicture> createState() => _ProfilePictureState();
}

class _ProfilePictureState extends State<ProfilePicture> {
  final ImagePicker _picker = ImagePicker();
  final AuthService _authService = AuthService();
  String? _currentPhotoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentPhotoUrl = widget.user.photoUrl;
  }

  Future<void> _checkAndRequestPermissions() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      final status = await Permission.storage.status;
      final cameraStatus = await Permission.camera.status;
      if (!status.isGranted || !cameraStatus.isGranted) {
        await [Permission.storage, Permission.camera].request();
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    await _checkAndRequestPermissions();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Changer la photo de profil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library, color: Colors.blue),
              ),
              title: const Text('Choisir dans la galerie'),
              subtitle: const Text('Sélectionnez une photo existante'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.green),
              ),
              title: const Text('Prendre une photo'),
              subtitle: const Text('Utilisez l\'appareil photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_currentPhotoUrl != null) ...[
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                title: const Text('Supprimer la photo'),
                subtitle: const Text('Revenir à l\'avatar par défaut'),
                onTap: () {
                  Navigator.pop(context);
                  _deletePhoto();
                },
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 500,
        maxHeight: 500,
      );
      if (image != null) {
        await _saveImage(File(image.path));
      }
    } catch (e) {
      debugPrint('Erreur selection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erreur lors de la sélection'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveImage(File image) async {
    setState(() => _isLoading = true);
    try {
      final savedPath = await _authService.saveImage(image, widget.user.id);
      if (savedPath != null) {
        final success =
            await _authService.updateProfilePhoto(widget.user.id, savedPath);
        if (success && mounted) {
          setState(() {
            _currentPhotoUrl = savedPath;
            _isLoading = false;
          });
          widget.onPhotoUpdated?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Photo mise à jour !'),
                backgroundColor: Colors.green),
          );
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Erreur sauvegarde: $e');
    }
  }

  Future<void> _deletePhoto() async {
    setState(() => _isLoading = true);
    try {
      if (_currentPhotoUrl != null) {
        await _authService.deleteImage(_currentPhotoUrl);
      }
      final success =
          await _authService.updateProfilePhoto(widget.user.id, null);
      if (success && mounted) {
        setState(() {
          _currentPhotoUrl = null;
          _isLoading = false;
        });
        widget.onPhotoUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Photo supprimée'), backgroundColor: Colors.orange),
        );
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isEditable ? _showImageSourceDialog : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: _isLoading
                ? Container(
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.grey),
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : _buildImage(),
          ),
          if (widget.isEditable && !_isLoading)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(widget.size * 0.08),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(Icons.camera_alt,
                    color: Colors.white, size: widget.size * 0.25),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (_currentPhotoUrl != null && File(_currentPhotoUrl!).existsSync()) {
      return ClipOval(
        child: Image.file(
          File(_currentPhotoUrl!),
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
        ),
      );
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    final String initial =
        widget.user.nom.isNotEmpty ? widget.user.nom[0].toUpperCase() : '?';
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade400, Colors.blue.shade700],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
              fontSize: widget.size * 0.4,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
      ),
    );
  }
}
