import 'package:flutter/material.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SwipeView extends StatefulWidget {
  @override
  _SwipeViewState createState() => _SwipeViewState();
}

class _SwipeViewState extends State<SwipeView> {
  List<SwipeItem> _swipeItems = [];
  MatchEngine? _matchEngine;
  final _firestore = FirebaseFirestore.instance;
  final _secureStorage = FlutterSecureStorage();
  String? userId;
  String? preferredGender;

  @override
  void initState() {
    super.initState();
    _getUserIdAndLoadProfiles();
    
  }

 Future<void> _getUserIdAndLoadProfiles() async {
  userId = await _secureStorage.read(key: 'userId');
 
  
  // Retrieve liked and disliked profile IDs
   DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
  DocumentSnapshot likesSnapshot = await _firestore.collection('likes').doc(userId).get();
  DocumentSnapshot dislikesSnapshot = await _firestore.collection('dislike').doc(userId).get();

  List<String> likedIds = [];
  List<String> dislikedIds = [];

  // Check if likedId is a list or a single string and handle accordingly
  if (likesSnapshot.exists) {
    var likedData = likesSnapshot['likedId'];
    if (likedData is List) {
      likedIds = List<String>.from(likedData);
    } else if (likedData is String) {
      likedIds.add(likedData);
    }
  }

  // Check if dislikedId is a list or a single string and handle accordingly
  if (dislikesSnapshot.exists) {
    var dislikedData = dislikesSnapshot['dislikedId'];
    if (dislikedData is List) {
      dislikedIds = List<String>.from(dislikedData);
    } else if (dislikedData is String) {
      dislikedIds.add(dislikedData);
    }
  }

  if(userDoc.exists){
    preferredGender = userDoc['prefferedGender'];
  }
 
  // Combine liked and disliked profile IDs
  Set<String> excludedIds = {...likedIds, ...dislikedIds};

  // Fetch profiles that match the gender preference and exclude liked/disliked profiles
  QuerySnapshot snapshot = await _firestore
      .collection('users')
      .where('gender', isEqualTo: preferredGender)
      .where('profileUrl1', isNotEqualTo: null)
      .get();

  for (var doc in snapshot.docs) {
    String profileId = doc.id;
    print(profileId);

    // Skip profiles that are already liked or disliked
    if (excludedIds.contains(profileId)) {
      continue;
    }

    var data = doc.data() as Map<String, dynamic>;
        print(data);
    _swipeItems.add(
      SwipeItem(
        content: data,
        likeAction: () {
          _handleLikeAction(profileId);
        },
        nopeAction: () {
          _handleNopeAction(profileId);
        },
      ),
    );
  }

  _matchEngine = MatchEngine(swipeItems: _swipeItems);
  setState(() {});
}


  Future<void> _handleLikeAction(String profileId) async {
    String? likedId = userId;
    // Save like to Firestore
    await _firestore.collection('likes').doc(userId).set({
      'likedId': profileId,
    });

    // Check if a match exists
    DocumentSnapshot likedProfile = await _firestore
        .collection('likes')
        .doc(profileId)
        .get();

    if (likedProfile.exists && likedProfile['likedId'] == userId) {
      await _firestore.collection('matched').add({
        'userId1': userId,
        'userId2': profileId,
      });
    }
  }

  Future<void> _handleNopeAction(String profileId) async {
    // Save to dislike collection
    await _firestore.collection('dislike').doc(userId).set({
      'dislikedId': profileId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find your person'),
      ),
      body: _matchEngine == null
          ? Center(child: Text('Loading profiles...'))
          : Column(
              children: [
                Container(
                  height: 550,
                  child: SwipeCards(
                    matchEngine: _matchEngine!,
                    itemBuilder: (BuildContext context, int index) {
                      var profile = _swipeItems[index].content as Map<String, dynamic>;
                      return Card(
  elevation: 5,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(15),
  ),
  child: Stack(
    children: [
      // Image with overlaid text
      Container(
        height: 800,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(
            //if profileUrl1 is null, use a placeholder image
            image: NetworkImage(profile['profileUrl1']) ,
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          alignment: Alignment.bottomLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.account_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    profile['name'],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.school, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    profile['college'],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.book, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    profile['course'],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.cake, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Age: ${profile['dob']}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Row(children: [
              Icon(Icons.favorite, color: Colors.white, size: 20,),
              const SizedBox(width: 8),
                Text(
                    '${profile['bio']}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
              ],)
            ],
          ),
        ),
      ),
      // Bio below the image
    
      
    ],
  ),
);

                    },
                    onStackFinished: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("No more profiles"),
                        duration: Duration(milliseconds: 500),
                      ));
                    },
                    upSwipeAllowed: true,
                    fillSpace: true,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () {
                        _matchEngine?.currentItem?.nope();
                      },
                      icon: Icon(Icons.close),
                      color: Colors.red,
                      iconSize: 50,
                    ),
                   
                    IconButton(
                      onPressed: () {
                        _matchEngine?.currentItem?.like();
                      },
                      icon: Icon(Icons.favorite),
                      color: Colors.green,
                      iconSize: 50,
                    ),
                  ],
                ),
               
              ],
            ),
    );
  }
}
