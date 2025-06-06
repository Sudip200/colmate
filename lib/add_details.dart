import 'dart:io';
import 'package:colmate/my_routes.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

class AddDetails extends StatefulWidget {
  @override
  _AddDetailsState createState() => _AddDetailsState();
}

class _AddDetailsState extends State<AddDetails> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _collegecontroller= TextEditingController();
  final TextEditingController _coursecontroller= TextEditingController();
  final TextEditingController _yearcontroller= TextEditingController();
  final TextEditingController _agecontroller= TextEditingController();
  

String ? _course;
String ? _gender;
String ? _prefferedGender;

  File? _image;
  String? _downloadUrl;

  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;
  final _secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  _getUserId() async {
    // Fetch the user ID from secure storage
    String? userId = await _secureStorage.read(key: 'userId');
    print('User ID: $userId');
  }

  _uploadImage() async {
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
  
    print('Image uploaded. Download URL: $_downloadUrl');
  }
}

  _saveDetailsToFirestore() async {
    String? userId = await _secureStorage.read(key: 'userId');
    if(_gender == "Male"){
      //save preferredGender to secure storage
      setState(() {
        _prefferedGender = 'Female';
      });
    }else{
      setState(() {
        _prefferedGender = 'Male';
    });
    }
    //if all fields are filled
    if (userId != null &&
        _nameController.text.isNotEmpty &&
        _bioController.text.isNotEmpty &&
        _collegecontroller.text.isNotEmpty &&
        _course != null &&
        _yearcontroller.text.isNotEmpty &&
        _agecontroller.text.isNotEmpty &&
        _downloadUrl != null  ) {
      // Save details to Firestore
      await _firestore.collection('users').doc(userId).set({
        'name': _nameController.text,
        'bio': _bioController.text,
        'profileUrl1': _downloadUrl,
        'college': _collegecontroller.text,
        'course': _course,
        'passyear': _yearcontroller.text,
        'dob': _agecontroller.text,
        'gender':_gender,
        'prefferedGender':_prefferedGender,    
      });

      print('Details saved to Firestore');
      return Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyRoutes()),
      );
    }else{
      //show alert dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Please fill all the fields'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Column(
          children: [
            _image != null
                ? CircleAvatar(
                    radius: 50,
                    backgroundImage: FileImage(_image!),
                    backgroundColor: Colors.pink,

                    )
                : Icon(Icons.person, size: 100),
            ElevatedButton(
              onPressed: _uploadImage,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.pink,
              ),
              child: Text('Upload Profile Picture'),
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _bioController,
              decoration: InputDecoration(labelText: 'Bio'),
            ),
          
          DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Gender'),
                value: _gender,
                items: <String>['Male', 'Female', 'Others']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _gender = newValue;
                  });
                },
              ),

            TextField(
              controller: _collegecontroller,
              decoration: InputDecoration(labelText: 'College'),

            ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Course'),
                value: _course,
                items: <String>['B.Tech', 'M.Tech', 'MBA','MBBS', 'B.Sc', 'M.Sc ', 
                'B.Com', 'M.Com', 'B.A', 'M.A', 'BBA', 'BCA', 'MCA', 
                'BDS', 'B.Pharm', 'M.Pharm', 'B.Arch', 
                'M.Arch', 'BBA LLB', 'LLB', 'LLM', 'BHM', 
                'MHM', 'B.Ed', 'M.Ed', 'B.P.Ed', 'M.P.Ed', 
                'BFA', 'MFA', 'B.Des', 'M.Des', 'B.Voc',
                 'M.Voc', 'BBA', 'MBA', 'BMS', 'MMS',
                  'BMM','Other']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _course = newValue;
                  });
                },
              ),
            TextField(
              controller: _yearcontroller,
              decoration: InputDecoration(labelText: 'Passing Year'),

            ),
            TextField(
              controller: _agecontroller,
              //required



              decoration: InputDecoration(labelText: 'Age'),

            ),

            SizedBox(height: 5),
            ElevatedButton(
              onPressed: () {
                _saveDetailsToFirestore();
              },
             //full width button
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                minimumSize: Size(double.infinity, 50),
                textStyle: TextStyle(color: Colors.white),
              ),
              child: Text('Save Details'),
            ),
          ],
        ),
      ),
    );
  }
}