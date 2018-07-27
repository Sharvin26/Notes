import 'dart:async';

import './model/board.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = new GoogleSignIn();


void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Notes',
      debugShowCheckedModeBanner: false,
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //Page Controllers.
  PageController _pageController;
  int _page = 0;
  String _imageUrl;
  String _userName;
  String _login;
  Board board;
  List<Board> boardMessages = List();
  //Adding Database and Creating a Global Key.

  final FirebaseDatabase database = FirebaseDatabase.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  DatabaseReference databaseReference;

  @override
  void initState() {
    super.initState();
    //Page Controller
    _pageController = new PageController();
    //Database Controller
    board = new Board("","");
    databaseReference = database.reference().child("Community_board");
    databaseReference.onChildAdded.listen(_onEntryAdded);
  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Notes",
        style: new TextStyle(
          color: Colors.black
        ),),
        backgroundColor: Colors.lightBlue.shade50,
        centerTitle: true,
      ),

      body: new PageView(
        children: <Widget>[
          //Adding Note
          new Container(
            color: Colors.lightBlue.shade50,
            child: new Column(
              children: <Widget>[
                new Flexible(
                  flex: 0,
                  child: new Center(
                      child: new Form(
                          key: formKey,
                          child: new Flex(
                            direction: Axis.vertical,
                            children: <Widget>[
                              new ListTile(
                                //leading: new Icon(Icons.subject),
                                title: new TextFormField(
                                  decoration: new InputDecoration(
                                      hintText: "Title",
                                    fillColor: Colors.black
                                  ),
                                  keyboardType: TextInputType.multiline,
                                  maxLines: 2,
                                  initialValue: "",
                                  onSaved: (val) => board.subject = val,
                                  validator: (val) => val == "" ? val : null,
                                ),
                              ),
                              new ListTile(
                                //leading: new Icon(Icons.message),
                                title: new TextFormField(
                                  decoration: new InputDecoration(
                                      hintText: "Noteee..."
                                  ),
                                  keyboardType: TextInputType.multiline,
                                  maxLines: 5,
                                  initialValue: "",
                                  onSaved: (val) => board.body = val,
                                  validator: (val) => val == "" ? val: null,
                                ),
                              ),
                              new Container(
                                padding: EdgeInsets.fromLTRB(0.0, 18.0, 0.0, 0.0),
                                child: new RaisedButton(
                                    color: Colors.white,
                                    textColor: Colors.black,
                                    onPressed: (){
                                      handleSubmit();
                                    },
                                    child: new Text("Save",
                                    style: new TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0
                                    ),)
                                ),
                              ),
                            ],
                          )
                      )
                  ),
                ),
              ],
            ),
          ),

          //All Notes
          new Container(
            color: Colors.lightBlue.shade50,
            child: new Flex(
                direction: Axis.vertical,
              children: <Widget>[
                new Flexible(
                    child: FirebaseAnimatedList(
                        query: databaseReference,
                        itemBuilder: ( _ , DataSnapshot snapshot, Animation<double> animation, int index){
                          return new Card(
                            color: Colors.lightBlue.shade50,
                            child: new ListTile(
                              title: new Text(boardMessages[index].subject,
                              style: new TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600
                              ),),
                              subtitle: new Text(boardMessages[index].body,
                                style: new TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w300
                                ),),
                              onLongPress: () {
                                _onEntryChanged;
                              },
                            ),
                          );
                        }
                    )
                )
              ],
            ),
          ),

          //Authentication

          new Container(
            color: Colors.lightBlue.shade50,
            child: new Center(
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new Container(
                    width: 160.0,
                    height: 160.0,
                    decoration: new BoxDecoration(
                        shape: BoxShape.circle,
                        image: new DecorationImage(
                          fit: BoxFit.fill,
                          image: NetworkImage(_imageUrl == null || _imageUrl.isEmpty ?
                          'http://res.cloudinary.com/dkcxpbczh/image/upload/v1532601161/blank-profile-picture-973460_heq08q.png'
                              : _imageUrl,
                          ),
                        )
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: new Text(
                      _userName == null || _userName.isEmpty ? 'Hello User Please Sign In' : "Hello $_userName",
                      style: new TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: new Container(
                      width: 190.0,
                      child: FlatButton(
                        child: Text("Sign up with Google",
                        style: TextStyle(
                          fontWeight: FontWeight.w700
                        ),),
                        color: Colors.white,
                        onPressed: () => _gSignIn(),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: new Container(
                      width: 190.0,
                      child: new FlatButton(
                          onPressed: () => _logOut(),
                          child: new Text("Log Out"),
                        color: Colors.white,
                      ),
                    ),
                  )

                ],
              ),
            )
          )
        ],

          controller: _pageController,
          onPageChanged: onPageChanged
      ),

      bottomNavigationBar: new BottomNavigationBar(
          items: [
            new BottomNavigationBarItem(icon: Icon(Icons.note_add) ,title: Text("Add a Note")),
            new BottomNavigationBarItem(icon: Icon(Icons.event_note), title: Text("Notes")),
            new BottomNavigationBarItem(icon: Icon(Icons.account_circle), title: Text("Account")),
          ],
          onTap: navigationTapped,
          currentIndex: _page,
        fixedColor: Colors.lightBlue,
      ),
    );
  }

  void _onEntryAdded(Event event) {
    setState(() {
      boardMessages.add(Board.fromSnapShot(event.snapshot));
    });
  }

  void handleSubmit() {
    final FormState form = formKey.currentState;
    if(form.validate()){
      form.save();
      form.reset();
      databaseReference.push().set(board.toJson());
    }
  }

  void _onEntryChanged(Event event) {
    var oldEntry = boardMessages.singleWhere((entry){
      return entry.key == event.snapshot.key;
    });
    setState(() {
      boardMessages[boardMessages.indexOf(oldEntry)] == Board.fromSnapShot(event.snapshot);
    });
  }

  void navigationTapped(int page) {
    _pageController.animateToPage(
        _page = page,
        duration: const Duration(microseconds: 300),
        curve: Curves.ease,
    );
  }

  @override
  void dispose(){
    super.dispose();
    _pageController.dispose();
  }

  void onPageChanged(int page){
    setState((){
      this._page = page;
    });
  }

  Future<FirebaseUser> _gSignIn() async{
    GoogleSignInAccount googleSignInAccount = await _googleSignIn.signIn();
    GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;
    FirebaseUser user = await _auth.signInWithGoogle(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken
    );
    print("User is: ${user.email}");

    setState(() {
      _imageUrl = user.photoUrl;
    });

    setState(() {
     _userName = user.displayName;
    });

    return user;
  }

  _logOut() {
    setState(() {
      _googleSignIn.signOut();
      _imageUrl = null;
      _userName = null;
    });
  }
}
