import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PhotoService {
  final ImagePicker _picker = ImagePicker();

  // Choisir une photo depuis la galerie
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 500,
        maxHeight: 500,
      );
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Prendre une photo avec l'appareil photo
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 500,
        maxHeight: 500,
      );
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Sauvegarder la photo localement
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

  // Supprimer une photo
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

  // Afficher la photo (widget)
  Widget buildProfileImage(String? photoUrl, String nom, double size) {
    if (photoUrl != null && File(photoUrl).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.file(
          File(photoUrl),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar(nom, size);
          },
        ),
      );
    }
    return _buildDefaultAvatar(nom, size);
  }

  Widget _buildDefaultAvatar(String nom, double size) {
    final String initial = nom.isNotEmpty ? nom[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
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
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Afficher le dialogue de sélection
  Future<File?> showImagePickerDialog(BuildContext context) async {
    return showDialog<File>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Choisir dans la galerie'),
              onTap: () async {
                final image = await pickImageFromGallery();
                if (context.mounted) Navigator.pop(context, image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Prendre une photo'),
              onTap: () async {
                final image = await pickImageFromCamera();
                if (context.mounted) Navigator.pop(context, image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Supprimer la photo'),
              onTap: () {
                Navigator.pop(context, null);
              },
            ),
          ],
        ),
      ),
    );
  }
}
