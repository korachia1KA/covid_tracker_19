import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide AdminScreen;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../data/services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEmailVerified = false;
  bool _isUploading = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  String? _currentImageUrl;
  static const String IMGBB_API_KEY = '94b9a844826404f4f9d3a347673ce463';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _isEmailVerified = user.emailVerified;
        _currentImageUrl = userDoc.data()?['imageUrl'] ?? '';
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await AuthService.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  Future<void> _resendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent! Check your inbox.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending verification email: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
          _isUploading = true;
        });
        await _updateProfilePhoto();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<String?> _uploadImageToImgBB(File image) async {
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$IMGBB_API_KEY');

    try {
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', image.path));
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseData.body);
        return jsonResponse['data']['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateProfilePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _profileImage == null) return;

    final newImageUrl = await _uploadImageToImgBB(_profileImage!);
    if (newImageUrl != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'imageUrl': newImageUrl});
      setState(() {
        _currentImageUrl = newImageUrl;
        _profileImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo de profil mise à jour avec succès.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise à jour de la photo.')),
      );
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Non disponible';
    final date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Text(
                'COVID-19 Tracker',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your Profile',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              if (user == null) ...[
                Card(
                  color: Colors.grey[800],
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Not signed in',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Sign In', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ] else ...[
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                          ? NetworkImage(_currentImageUrl!)
                          : null,
                      child: _currentImageUrl == null || _currentImageUrl!.isEmpty
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                    if (!_isUploading)
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.blue,
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: _pickImage,
                      ),
                    if (_isUploading)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Text('Error loading user data');
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return Column(
                        children: [
                          Card(
                            color: Colors.grey[800],
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Text(
                                    'User data not found. Please try logging out and logging in again.',
                                    style: TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _signOut,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(vertical: 15),
                                    ),
                                    child: const Text('Log Out', style: TextStyle(fontSize: 18)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    final userData = snapshot.data!.data() as Map<String, dynamic>;
                    final userRole = userData['role'] as String? ?? 'Unknown';
                    final createdAt = userData['createdAt'] as Timestamp?;
                    final formattedCreatedAt = _formatTimestamp(createdAt);

                    return Column(
                      children: [
                        Card(
                          color: Colors.grey[800],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Profile Details',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.email, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Email: ${user.email}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.person, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Role: ${userRole == 'admin' ? 'Administrator' : 'User'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: userRole == 'admin' ? Colors.green : Colors.white,
                                        fontWeight: userRole == 'admin' ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.verified, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Email Verified: ${_isEmailVerified ? 'Yes' : 'No'}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                if (!_isEmailVerified) ...[
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _resendVerificationEmail,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                      ),
                                      child: const Text('Resend Verification Email', style: TextStyle(fontSize: 16)),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Account Created: $formattedCreatedAt',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}