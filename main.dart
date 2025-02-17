import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(PlanetApp());
}

class PlanetApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: PlanetHomeScreen(),
    );
  }
}

class Planet {
  int? id;
  String name;
  String alias;
  double distance;
  double diameter;

  Planet({this.id, required this.name, this.alias = '', required this.distance, required this.diameter});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'alias': alias,
      'distance': distance,
      'diameter': diameter,
    };
  }

  factory Planet.fromMap(Map<String, dynamic> map) {
    return Planet(
      id: map['id'],
      name: map['name'],
      alias: map['alias'] ?? '',
      distance: map['distance'],
      diameter: map['diameter'],
    );
  }
}

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('planets.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE planets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        alias TEXT,
        distance REAL NOT NULL,
        diameter REAL NOT NULL
      )
    ''');
  }
}

class PlanetHomeScreen extends StatefulWidget {
  @override
  _PlanetHomeScreenState createState() => _PlanetHomeScreenState();
}

class _PlanetHomeScreenState extends State<PlanetHomeScreen> {
  List<Planet> planets = [];

  @override
  void initState() {
    super.initState();
    _loadPlanets();
  }

  Future<void> _loadPlanets() async {
    final data = await DBHelper.instance.getPlanets();
    setState(() {
      planets = data;
    });
  }

  void _deletePlanet(int id) async {
    await DBHelper.instance.deletePlanet(id);
    _loadPlanets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lista de Planetas')),
      body: ListView.builder(
        itemCount: planets.length,
        itemBuilder: (context, index) {
          final planet = planets[index];
          return ListTile(
            title: Text(planet.name),
            subtitle: Text(planet.alias.isNotEmpty ? planet.alias : 'Sem apelido'),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deletePlanet(planet.id!),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
        onPressed: () {},
      ),
    );
  }
}
