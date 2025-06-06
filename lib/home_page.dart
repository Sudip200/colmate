import 'package:colmate/match.dart';
import 'package:colmate/swipe_view.dart';
import 'package:colmate/updateprofile.dart';
import 'package:flutter/material.dart';
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
   int _selectedIndex = 0;  
  
  static  List<Widget> _widgetOptions = <Widget>[  
    //demo home page with just one text widget
   SwipeView(),
    ChatListScreen(),
    UpdateDetailsScreen(),
 

  ];  
  
  void _onItemTapped(int index) {  
    setState(() {  
      _selectedIndex = index;  
    });  
  }  
  
  @override  
  Widget build(BuildContext context) {  
    return Scaffold(  
       
      body: Center(  
        child: _widgetOptions.elementAt(_selectedIndex),  
      ),  
      bottomNavigationBar: BottomNavigationBar(
        landscapeLayout: BottomNavigationBarLandscapeLayout.spread,  
        items: const <BottomNavigationBarItem>[  
          BottomNavigationBarItem(  
            icon: Icon(Icons.home,
            color: Colors.pink,),  
             label: 'Home',
            backgroundColor: Color.fromARGB(255, 244, 242, 242) ,
             
          ),  
          BottomNavigationBarItem(  
            icon: Icon(Icons.chat,
            color: Colors.pink),  
              label: 'Matches',
            backgroundColor: Color.fromARGB(255, 244, 242, 242) 
          ),  
          BottomNavigationBarItem(  
            icon: Icon(Icons.person,
            color: Colors.pink),  
             label: 'Profile',
            backgroundColor: Color.fromARGB(255, 244, 242, 242) ,  
          ),  
       
        ],  
        type: BottomNavigationBarType.fixed,  
        currentIndex: _selectedIndex,  
        selectedItemColor: Colors.white,  
        iconSize: 40,  
        onTap: _onItemTapped,  
        elevation: 10,
        
      ),  
    );  
  }  
}