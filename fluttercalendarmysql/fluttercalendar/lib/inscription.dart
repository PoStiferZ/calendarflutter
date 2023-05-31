import 'package:flutter/material.dart';
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
  runApp(EventList(conn: conn));
}

class EventList extends StatelessWidget {
  final MySqlConnection conn;

  const EventList({Key? key, required this.conn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: EventListScreen(conn: conn),
        ),
      ),
    );
  }
}

class EventListScreen extends StatefulWidget {
  final MySqlConnection conn;

  const EventListScreen({Key? key, required this.conn}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _EventListScreenState createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  List<Map<String, dynamic>> _eventItems = [];
  int idPersonne = 0;

  @override
  void initState() {
    super.initState();
    _loadUserDataFromSharedPreferences().then((_) {
      getData();
    });
  }

  String idPersonneString = '';

  Future<void> _loadUserDataFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      idPersonneString = prefs.getString('idPersonne') ?? '';
      idPersonne = int.tryParse(idPersonneString) ?? 0;
    });
  }

  Future<void> getData() async {
    final items = await getItems(widget.conn);
    setState(() {
      _eventItems = items;
    });
  }

  Future<bool> addItem(int idPersonne, int idRecurrence) async {
    try {
      var results = await widget.conn.query(
        'SELECT id FROM events WHERE idRecurrence = ?',
        [idRecurrence],
      );

      var idCoursList = results.map((r) => r['id']);

      var success = true;
      for (var unCours in idCoursList) {
        var insertResult = await widget.conn.query(
          'INSERT INTO inscription_cours (idP, idC, idRecurrence, presence) VALUES (?, ?, ?, 1)',
          [idPersonne, unCours, idRecurrence],
        );

        success = success && insertResult.isNotEmpty;
      }

      return success;
    } catch (e) {
      // Log or handle the error here.
      return false;
    }
  }

  Future<bool> deleteItem(int idPersonne, int idRecurrence) async {
    try {
      var deleteResult = await widget.conn.query(
        'DELETE FROM inscription_cours WHERE idP = ? AND idRecurrence = ?',
        [idPersonne, idRecurrence],
      );

      return deleteResult.isNotEmpty;
    } catch (e) {
      // Log or handle the error here.
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des événements'),
      ),
      body: ListView.builder(
        itemCount: _eventItems.length,
        itemBuilder: (context, index) {
          final item = _eventItems[index];
          final title = item['title'] as String;
          final idRecurrence = item['idRecurrence'] as int;
          return ListTile(
            title: Text('Title: $title\nID de récurrence: $idRecurrence'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await addItem(idPersonne, idRecurrence);
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    await deleteItem(idPersonne, idRecurrence);
                  },
                  child: const Icon(Icons.delete),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<List<Map<String, dynamic>>> getItems(MySqlConnection conn) async {
  final results = await conn.query(
    'SELECT DISTINCT title, idRecurrence FROM events',
  );
  return results.toList().map((r) => r.fields).toList();
}
