import 'package:colmate/add_details.dart';
import 'package:colmate/my_routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' ;
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthGate extends StatelessWidget {
  final storage = new FlutterSecureStorage();
  bool docExists = false;
  bool profileExists = false;
  AuthGate({super.key});
  
  @override
  Widget build(BuildContext context) {
    
    return StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges(), builder: (context,snapshot){
      if (!snapshot.hasData) {
          return SignInScreen(
            providers: [EmailAuthProvider(),GoogleProvider(clientId: '201721663741-s19morvg7es3c60vdstan8ia31n5v2ah.apps.googleusercontent.com')],
            oauthButtonVariant: OAuthButtonVariant.icon_and_text,
             headerBuilder: (context, constraints, shrinkOffset) => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Image(image: AssetImage('assets/icon/Colmate.png'),height:300,width: 200,),),
              subtitleBuilder: (context, action) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                
              );
            },
            footerBuilder:  (context, action) {
              return const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'By signing in, you agree to our terms and conditions.',
                  style: TextStyle(color: Colors.black),
                ),
              );
            },
            
            
          );
        }
       
        User user = snapshot.data!;
        String userId = user.uid;
        String email = user.email!;
        CollectionReference users = FirebaseFirestore.instance.collection('users');

     users.doc(userId).get().then((DocumentSnapshot documentSnapshot) {
          storage.write(key: 'userId', value: userId).then((value) => print('userId saved'));
          if (documentSnapshot.exists) {
                
            if(documentSnapshot.get('profileUrl1') != null){
             
             return Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyRoutes()));
            }else{
              print('profile does not exist');
             return Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AddDetails()));
            } 
          } else {
            users.doc(userId).set({
            'email': email,
            'profileUrl1': null,
            'profileUrl2': null,
            'dob': null,
            'name': null,
            'bio': null,
            'college': null,
            'course': null,
            'passyear':null,
            'gender':null
          });

          storage.write(key: 'userId', value: userId).then((value) => print('userId saved'));
          return Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AddDetails()));
          }

        });

      return Center(child: CircularProgressIndicator());
        
    }
    );
  }
}