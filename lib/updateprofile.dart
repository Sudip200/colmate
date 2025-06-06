import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
class UpdateDetailsScreen extends StatefulWidget {
  @override
  _UpdateDetailsScreenState createState() => _UpdateDetailsScreenState();
}

class _UpdateDetailsScreenState extends State<UpdateDetailsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _secureStorage = FlutterSecureStorage();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  String? _downloadUrl;
  String? userId;
  File? _image;
  String? _prefferedGender;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    userId = await _secureStorage.read(key: 'userId');
    if (userId != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        _nameController.text = data['name'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _collegeController.text = data['college'] ?? '';
        _courseController.text = data['course'] ?? '';
        _yearController.text = data['passyear'] ?? '';
        _dobController.text = data['dob'] ?? '';
        _genderController.text = data['gender'] ?? '';
        _downloadUrl = data['profileUrl1'];
      }
    }
  }

  Future<void> _updateUserDetails() async {
   if(_genderController.text == "Male"){
      //save preferredGender to secure storage
      setState(() {
        _prefferedGender = 'Female';
      });
    }else{
      setState(() {
        _prefferedGender = 'Male';
    });
    }
    if (userId != null) {
      await _firestore.collection('users').doc(userId).set({
        'name': _nameController.text,
        'bio': _bioController.text,
        'profileUrl1': _downloadUrl,
        'college': _collegeController.text,
        'course': _courseController.text,
        'passyear': _yearController.text,
        'dob': _dobController.text,
        'gender': _genderController.text,
        'prefferedGender': _prefferedGender,

      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  Future<void> _uploadImage() async {
     final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    setState(() {
      _image = File(pickedFile.path);
    });

    // Upload image to Firebase Storage
    Reference ref = _storage.ref().child('profile_images/${DateTime.now().toString()}');
    UploadTask uploadTask = ref.putFile(_image!, SettableMetadata(contentType: 'image/jpeg'));
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
    _downloadUrl = await taskSnapshot.ref.getDownloadURL();

    // Show uploaded image on the screen
   setState(() {
      _downloadUrl = _downloadUrl;
   });
    print('Image uploaded. Download URL: $_downloadUrl');
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
        Text('Update Profile'),
        SizedBox(width: 10,),
        //logout button
        TextButton(onPressed: 
        () async {
          await _secureStorage.delete(key: 'userId');
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacementNamed(context, '/auth');
        }
        , child: Text('Logout'),)
        ],)

      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Display Profile Picture
              if (_downloadUrl != null)
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(_downloadUrl!),
                ),
              SizedBox(height: 16),

              // Update Image Button
              ElevatedButton(
                onPressed: _uploadImage,
                child: Text('Upload Profile Picture'),
              ),

              // Form Fields
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _bioController,
                decoration: InputDecoration(labelText: 'Bio'),
              ),
              TextField(
                controller: _collegeController,
                decoration: InputDecoration(labelText: 'College'),
              ),
              TextField(
                controller: _courseController,
                decoration: InputDecoration(labelText: 'Course'),
              ),
              TextField(
                controller: _yearController,
                decoration: InputDecoration(labelText: 'Year of Passing'),
              ),
              TextField(
                controller: _dobController,
                decoration: InputDecoration(labelText: 'Date of Birth'),
              ),
              TextField(
                controller: _genderController,
                decoration: InputDecoration(labelText: 'Gender'),
              ),
              SizedBox(height: 20),

              // Save Button
              ElevatedButton(
                onPressed: _updateUserDetails,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
