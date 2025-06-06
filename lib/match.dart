import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  String? currentUserId;
  List<Map<String, dynamic>> matchedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadMatchedUsers();
  }
  Future<String?> _getCurrentUserId() async {
    return await _storage.read(key: 'userId');
  }

  Future<void> _loadMatchedUsers() async {
    currentUserId = await _storage.read(key: 'userId');
    if (currentUserId != null) {
      QuerySnapshot matchedSnapshot = await _firestore
          .collection('matched')
          .where('userId1', isEqualTo: currentUserId)
          .get();

      QuerySnapshot matchedSnapshot2 = await _firestore
          .collection('matched')
          .where('userId2', isEqualTo: currentUserId)
          .get();

      List<Map<String, dynamic>> users = [];

      for (var doc in matchedSnapshot.docs) {
        String otherUserId = doc['userId2'];
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(otherUserId).get();
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userData['userId'] = otherUserId;
        if (!users.any((user) => user['userId'] == otherUserId)) {
          users.add(userData);
        }
      }

      for (var doc in matchedSnapshot2.docs) {
        String otherUserId = doc['userId1'];
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(otherUserId).get();
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userData['userId'] = otherUserId;
       if (!users.any((user) => user['userId'] == otherUserId)) {
          users.add(userData);
        }
      }

      setState(() {
        matchedUsers = users;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Matches'),
      ),
      body: matchedUsers.isEmpty
          ? Center(child: Text('No matches found.'))
          : ListView.builder(
              itemCount: matchedUsers.length,
              itemBuilder: (context, index) {
                var user = matchedUsers[index];
                return ListTile(
                   contentPadding: EdgeInsets.all(8),

                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user['profileUrl1'] ?? ''),
                    radius: 30,
                  

                    
                  ),
                  title: Text(user['name'] ?? ''),
                  onTap: () async {
                     if (user['userId'] != null && user['userId'].isNotEmpty) {
    String? currentUserId = await _getCurrentUserId();
    if (currentUserId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            otherUserId: user['userId'],
            currentUserId: currentUserId,
          ),
        ),
      );
    } else {
      // Handle the case where currentUserId is null
      print("Error: currentUserId is null");
    }
  } else {
    // Handle the case where userId is null or empty
    print("Error: userId is null or empty");
  }
                  },
                );
              },
            ),
    );
  }
}



class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String currentUserId;

  ChatScreen({required this.otherUserId, required this.currentUserId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  late String _name = '';
  late String _profileUrl = '';

  @override
  void initState() {
    super.initState();
    _getUserDetails();
  }

   _getUserDetails() async {
   //document snapshot
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.otherUserId).get();
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    setState(() {
      _name = userData['name'] ?? '';
      _profileUrl = userData['profileUrl1'] ?? '';
    });
  }

  void _sendMessage() async {
    if (_messageController.text.isEmpty || widget.currentUserId == null) return;

    await _firestore.collection('chats').add({
      'conversationId': _getConversationId(),
      'senderId': widget.currentUserId,
      'receiverId': widget.otherUserId,
      'message': _messageController.text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  String _getConversationId() {
  List<String> ids = [widget.currentUserId, widget.otherUserId];
  ids.sort(); // Ensure the order is consistent
  return ids.join('_');
}

Stream<QuerySnapshot> _chatStream() {
  String conversationId = _getConversationId();
  print(conversationId);
  
  return _firestore
      .collection('chats')
      .where('conversationId', isEqualTo: conversationId)
      .orderBy('timestamp', descending: true)
      .snapshots();
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
          
            Text('$_name'),
            SizedBox(width: 8),
             CircleAvatar(
              backgroundImage: NetworkImage(_profileUrl),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatStream(),
              builder: (context, snapshot) {
               
                 if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError || !snapshot.hasData) {
        return Center(child: Text('No chats found.'));
      }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isMe = message['senderId'] == widget.currentUserId;

                    return Container(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blueAccent : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        child: Text(
                          message['message'],
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

