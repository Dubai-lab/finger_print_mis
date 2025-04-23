import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';

class ProfilePictureManager extends StatefulWidget {
  const ProfilePictureManager({Key? key}) : super(key: key);

  @override
  State<ProfilePictureManager> createState() => _ProfilePictureManagerState();
}

class _ProfilePictureManagerState extends State<ProfilePictureManager> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? _profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  Future<void> _loadProfilePicture() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('instructor_profile_pictures')
        .doc(user.id)
        .get();

    if (doc.exists) {
      setState(() {
        _profilePictureUrl = doc.data()?['profilePictureUrl'] as String?;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    if (user == null) return;

    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      File file = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('instructor_profile_pictures')
          .child('${user.id}.jpg');

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('instructor_profile_pictures')
          .doc(user.id)
          .set({'profilePictureUrl': downloadUrl});

      setState(() {
        _profilePictureUrl = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: \$e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUploadImage,
      child: CircleAvatar(
        radius: 40,
        backgroundImage: _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
            ? NetworkImage(_profilePictureUrl!)
            : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
        backgroundColor: Colors.grey[200],
        child: _isUploading ? const CircularProgressIndicator() : null,
      ),
    );
  }
}
