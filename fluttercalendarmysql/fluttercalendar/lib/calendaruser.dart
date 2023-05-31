import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mysql1/mysql1.dart';
import 'package:shared_preferences/shared_preferences.dart';

// connexion Base de données
void main() async {
  final conn = await MySqlConnection.connect(ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: 'root',
    db: 'equestreproject',
  ));
  runApp(CalendarUser(conn: conn));
}

// Class principale pour exécuter l'application
class CalendarUser extends StatelessWidget {
  // Objet Initialisé pour de la base de donnée
  final MySqlConnection conn;

  const CalendarUser({Key? key, required this.conn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: CalendarScreen(conn: conn),
        ),
      ),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  final MySqlConnection conn;

  const CalendarScreen({Key? key, required this.conn}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    /* S'assurer que loadUser soit charger complètement avant d'utiliser getData */
    _loadUserDataFromSharedPreferences().then((_) {
      getData();
    });
  }

  String nom = '';
  String idPersonneString = '';
  /* Le late sert à retarder l'initialisation de la variable afin d'attendre le loadUser */
  int idPersonne = 0;

// On récupère le nom d'utilisateur - START
  Future<void> _loadUserDataFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      idPersonneString = prefs.getString('idPersonne') ?? '';
      idPersonne = int.tryParse(idPersonneString) ?? 0;
      nom = prefs.getString('nom') ?? '';
    });
  }
  // On récupère le nom d'utilisateur - END

  // On récupère les données du SELECT - START
  void getData() async {
    final items = await getItems(widget.conn, idPersonne);
    setState(
      () {
        _events = {};
        for (var item in items) {
          DateTime startEvent = item['startEvent'];
          String title = item['title'];
          String id = item['id'].toString();
          String presence = item['presence'].toString();

          if (_events[startEvent] == null) {
            _events[startEvent] = ['$id,$title,$presence'];
          } else {
            _events[startEvent]!.add('$id,$title,$presence');
          }
        }
      },
    );
  }
  // On récupère les données du SELECT - END

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Gestion de vos cours : $nom"),
        TableCalendar(
          firstDay: DateTime.utc(2020, 01, 01),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: (day) {
            return _events[day] ?? [];
          },
        ),
        _events[_selectedDay]?.isNotEmpty == true
            ? Expanded(
                child: ListView.builder(
                  itemCount: _events[_selectedDay]?.length ?? 0,
                  itemBuilder: (context, index) {
                    final event = _events[_selectedDay]![index];
                    final parts = event.split(',');
                    final id = int.parse(parts[0]);
                    final title = parts[1];
                    final presence = parts[2];

                    return Container(
                      color: const Color.fromARGB(255, 56, 56, 56),
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (presence.toString() == "1")
                            TextButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.green),
                              ),
                              onPressed: () async {
                                await updateItem(widget.conn, id, 0);
                                setState(
                                  () {
                                    getData();
                                  },
                                );
                              },
                              child: const Text(
                                'Présent',
                                style: TextStyle(
                                    fontSize: 14.0, color: Colors.white),
                              ),
                            ),
                          if (presence.toString() == "0")
                            TextButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.red),
                              ),
                              onPressed: () async {
                                await updateItem(widget.conn, id, 1);
                                setState(() {
                                  getData();
                                });
                              },
                              child: const Text(
                                'Absent',
                                style: TextStyle(
                                    fontSize: 14.0, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              )
            : Container(
                margin: const EdgeInsets.only(top: 35),
                child: const Text(
                  "Aucun évènement à ce jour",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ],
    );
  }
}

// READ
Future<List<Map<String, dynamic>>> getItems(
    MySqlConnection conn, int idPersonne) async {
  final results = await conn.query(
      'SELECT id, title, startEvent, presence FROM events E INNER JOIN inscription_cours I ON E.id = I.idC WHERE idP = ?',
      [idPersonne]);
  return results.toList().map((r) => r.fields).toList();
}

// UPDATE
Future<void> updateItem(MySqlConnection conn, int id, int actif) async {
  await conn.query(
      'UPDATE inscription_cours SET presence = ? WHERE idC = ?', [actif, id]);
}
