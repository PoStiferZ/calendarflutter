import 'package:flutter/material.dart';
import 'package:fluttercalendar/calendaruser.dart';
import 'package:fluttercalendar/inscription.dart';

import 'package:mysql1/mysql1.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final conn = await MySqlConnection.connect(ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: 'root',
    db: 'my_store',
  ));

  runApp(HomePage(conn: conn));
}

class HomePage extends StatefulWidget {
  final MySqlConnection conn;

  const HomePage({Key? key, required this.conn}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Widget> _pages = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(conn: widget.conn),
      CalendarUser(conn: widget.conn),
      EventList(conn: widget.conn),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: _pages[_selectedIndex],
        ),
        appBar: AppBar(
          title: const Text('Accueil'),
          actions: [
            Material(
              color: Colors.green,
              child: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
            ),
            Material(
              color: Colors.red,
              child: IconButton(
                icon: const Icon(Icons.list),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final MySqlConnection conn;

  const HomeScreen({Key? key, required this.conn}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String idPersonne = '';
  String mail = '';
  String nom = '';
  String prenom = '';
  String telephone = '';

  @override
  void initState() {
    super.initState();
    _loadUserDataFromSharedPreferences();
  }

  Future<void> _loadUserDataFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      idPersonne = prefs.getString('idPersonne') ?? '';
      mail = prefs.getString('mail') ?? '';
      nom = prefs.getString('nom') ?? '';
      prenom = prefs.getString('prenom') ?? '';
      telephone = prefs.getString('telephone') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('$nom $prenom',
                style: const TextStyle(
                  fontSize: 24.0,
                )),
            Text(mail,
                style: const TextStyle(
                  fontSize: 24.0,
                )),
            Text(telephone,
                style: const TextStyle(
                  fontSize: 24.0,
                )),
          ],
        ),
      ),
    );
  }
}
