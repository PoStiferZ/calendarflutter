import 'package:flutter/material.dart';
import 'package:fluttercalendar/homescreen.dart';
import 'package:mysql1/mysql1.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final conn = await MySqlConnection.connect(ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: 'root',
    db: 'equestreproject',
  ));
  runApp(MyApp(conn: conn));
}

class MyApp extends StatelessWidget {
  final MySqlConnection conn;

  const MyApp({super.key, required this.conn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion des cours',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(conn: conn),
        '/home': (context) => HomePage(conn: conn),
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  final MySqlConnection conn;

  const LoginPage({super.key, required this.conn});

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late String _username;
  late String _password;
  String _errorMessage = '';

  Future<void> _validateInputs() async {
    final results = await widget.conn.query(
      'SELECT idPersonne, nom, prenom, mail, dateNaissance, telephone FROM personne WHERE mail = ? AND mdp = ?',
      [_username, _password],
    );

    if (results.isNotEmpty) {
      // Récupérer l'ID et le nom d'utilisateur
      final id = results.first['idPersonne'];

      final firstName = results.first['prenom'];
      final lastName = results.first['nom'];
      final number = results.first['telephone'];

      final username = results.first['mail'];

      // Stocker l'ID et le nom d'utilisateur dans les préférences partagées
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('idPersonne', id.toString());

      await prefs.setString('prenom', firstName);
      await prefs.setString('nom', lastName);
      await prefs.setString('telephone', number);

      await prefs.setString('mail', username);

      // Naviguer vers la page d'accueil
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _errorMessage = 'Mail ou Mot de passe incorrect.';
      });
    }
  }

/*   Future<Map<String, String>> getUserDataFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('idPersonne') ?? '';
    final username = prefs.getString('mail') ?? '';
    final password = prefs.getString('mdp') ?? '';

    final firstName = prefs.getString('prenom') ?? '';
    final lastName = prefs.getString('nom') ?? '';
    final number = prefs.getString('number') ?? '';

    return {
      'idPersonne': id,
      'mail': username,
      'mdp': password,
      'firstName': firstName,
      'lastName': lastName,
      'number': number
    };
  } */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Identifiant'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Identifiant requis !';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _username = value!;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Mot de passe requis !';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _password = value!;
                  },
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      _validateInputs();
                    }
                  },
                  child: const Text('Se connecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* // READ
Future<List<Map<String, dynamic>>> getItems(MySqlConnection conn) async {
  final results = await conn.query('SELECT * FROM personne');
  return results.toList().map((r) => r.fields).toList();
} */
