import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../../utils/distance_calculator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _isInfected = false;
  bool _isAdmin = false;

  final String _smtpUsername = 'zougardriss0@gmail.com';
  final String _smtpPassword = 'kywi cnwt cqfu wxsv';

  @override
  void initState() {
    super.initState();
    _checkInfectionStatus();
    _checkAdminStatus();
    _getInitialLocation();
    _listenForInfections();
  }

  Future<void> _checkInfectionStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('infections').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _isInfected = data['isInfected'] as bool? ?? false;
        });
      }
    }
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _isAdmin = data['role'] == 'admin';
        });
      }
    }
  }

  Future<void> _getInitialLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission de localisation refusée')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission de localisation permanente refusée')),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        if (_mapController != null && _currentPosition != null) {
          _mapController.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            ),
          );
        }
      });
      if (_isInfected) {
        await _updateLocationInFirestore(position);
      }
    } catch (e) {
      print('Erreur lors de la récupération de la localisation initiale : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de localisation initiale')),
      );
    }
  }

  Future<void> _updateLocationInFirestore(Position position) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('infections').doc(user.uid).set({
        'userId': user.uid,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'isInfected': _isInfected,
        'updatedAt': FieldValue.serverTimestamp(),
        'email': user.email,
      }, SetOptions(merge: true));
      print('Infection data updated for user: ${user.uid}');
    } catch (e) {
      print('Erreur lors de la mise à jour de la localisation dans Firestore : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour des données: $e')),
      );
    }
  }

  Future<void> _declareInfected() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Localisation non disponible')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      setState(() {
        _isInfected = true;
      });
      await _updateLocationInFirestore(_currentPosition!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Déclaré comme infecté')),
      );
    } catch (e) {
      print('Erreur lors de la déclaration d\'infection : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la déclaration')),
      );
    }
  }

  Future<void> _declareNotInfected() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      setState(() {
        _isInfected = false;
      });
      await FirebaseFirestore.instance.collection('infections').doc(user.uid).update({
        'isInfected': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value == user.uid);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Déclaré comme non infecté')),
      );
    } catch (e) {
      print('Erreur lors de la déclaration comme non infecté : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la déclaration')),
      );
    }
  }

  void _listenForInfections() {
    FirebaseFirestore.instance.collection('infections').snapshots().listen((snapshot) async {
      bool hasInfected = false;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['isInfected'] == true) {
          hasInfected = true;
          break;
        }
      }

      if (!hasInfected) return;

      await _checkProximityAndSendEmail();
    });
  }

  Future<void> _checkProximityAndSendEmail() async {
    final snapshot = await FirebaseFirestore.instance.collection('infections').get();
    if (snapshot.docs.isEmpty) return;

    List<Map<String, dynamic>> users = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['latitude'] != null && data['longitude'] != null && data['email'] != null) {
        users.add({
          'userId': doc.id,
          'latitude': data['latitude'] as double,
          'longitude': data['longitude'] as double,
          'email': data['email'] as String,
          'isInfected': data['isInfected'] as bool? ?? false,
        });
      }
    }

    if (users.length < 2) return;

    List<Set<String>> proximityGroups = [];

    for (int i = 0; i < users.length; i++) {
      for (int j = i + 1; j < users.length; j++) {
        final user1 = users[i];
        final user2 = users[j];

        final distance = DistanceCalculator.calculateDistance(
          user1['latitude'],
          user1['longitude'],
          user2['latitude'],
          user2['longitude'],
        );

        if (distance < 10) {
          Set<String> group;
          int user1GroupIndex = proximityGroups.indexWhere((g) => g.contains(user1['userId']));
          int user2GroupIndex = proximityGroups.indexWhere((g) => g.contains(user2['userId']));

          if (user1GroupIndex == -1 && user2GroupIndex == -1) {
            group = {user1['userId'], user2['userId']};
            proximityGroups.add(group);
          } else if (user1GroupIndex != -1 && user2GroupIndex == -1) {
            proximityGroups[user1GroupIndex].add(user2['userId']);
          } else if (user1GroupIndex == -1 && user2GroupIndex != -1) {
            proximityGroups[user2GroupIndex].add(user1['userId']);
          } else if (user1GroupIndex != user2GroupIndex) {
            proximityGroups[user1GroupIndex].addAll(proximityGroups[user2GroupIndex]);
            proximityGroups.removeAt(user2GroupIndex);
          }
        }
      }
    }

    for (var group in proximityGroups) {
      if (group.length >= 2) {
        final groupUsers = users.where((u) => group.contains(u['userId'])).toList();
        await _sendEmailToGroup(groupUsers);
      }
    }
  }

  Future<void> _sendEmailToGroup(List<Map<String, dynamic>> groupUsers) async {
    try {
      final smtpServer = gmail(_smtpUsername, _smtpPassword);

      for (var user in groupUsers) {
        final userEmail = user['email'] as String;
        final userId = user['userId'] as String;

        final otherUsers = groupUsers.where((u) => u['userId'] != userId).map((u) => u['userId']).toList();
        final otherUsersText = otherUsers.join(', ');

        final message = Message()
          ..from = Address(_smtpUsername, 'Système d\'Alerte Proximité')
          // Removed 'replyTo' as it is not defined for the 'Message' class
          ..recipients.add(userEmail)
          ..subject = 'Notification de proximité - Risque potentiel'
          ..html = '''
            <html>
              <body>
                <h2>Notification de proximité</h2>
                <p>Bonjour,</p>
                <p>Vous avez été détecté à moins de 10 mètres des utilisateurs suivants potentiellement infectés :</p>
                <ul>
                  ${otherUsers.map((id) => '<li>Utilisateur ID: $id</li>').join('')}
                </ul>
                <p>Nous vous recommandons de rester vigilant et de suivre les mesures de sécurité appropriées.</p>
                <p>Si vous avez des questions, veuillez répondre à cet email.</p>
                <br>
                <p>Cordialement,<br>L'équipe d'alerte proximité</p>
              </body>
            </html>
          '''
          ..text = 'Notification de proximité\n\nBonjour,\n\nVous avez été détecté à moins de 10 mètres des utilisateurs suivants potentiellement infectés : $otherUsersText.\n\nNous vous recommandons de rester vigilant et de suivre les mesures de sécurité appropriées.\n\nCordialement,\nL\'équipe d\'alerte proximité';

        try {
          await send(message, smtpServer);
          print('Email envoyé à $userEmail');
        } catch (e) {
          print('Erreur lors de l\'envoi à $userEmail : $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'envoi à $userEmail: $e')),
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emails d\'alerte envoyés aux utilisateurs concernés !')),
      );
    } catch (e) {
      print('Erreur générale lors de l\'envoi des emails : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur générale lors de l\'envoi des emails: $e')),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte des infections'),
        backgroundColor: Colors.blue,
        elevation: 4,
        centerTitle: true,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/admin');
              },
              tooltip: 'Panneau d\'administration',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('infections')
                  .where('isInfected', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Erreur lors du chargement des cas infectés'));
                }

                _markers.clear();
                if (snapshot.hasData) {
                  final docs = snapshot.data!.docs;
                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final latitude = data['latitude'] as double?;
                    final longitude = data['longitude'] as double?;
                    if (latitude != null && longitude != null) {
                      _markers.add(
                        Marker(
                          markerId: MarkerId(doc.id),
                          position: LatLng(latitude, longitude),
                          infoWindow: const InfoWindow(title: 'Cas infecté'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                        ),
                      );
                    }
                  }
                }

                return GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(33.5731, -7.5898),
                    zoom: 10,
                  ),
                  onMapCreated: _onMapCreated,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _declareInfected,
                  icon: const Icon(Icons.local_hospital),
                  label: const Text('Déclarer Infecté'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _declareNotInfected,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Non Infecté'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}