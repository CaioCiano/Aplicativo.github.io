import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PlanetListScreen(),
    );
  }
}

class Planet {
  int? id;
  String name;
  String nickname;
  double distance;
  double size;

  Planet({this.id, required this.name, this.nickname = '', required this.distance, required this.size});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nickname': nickname,
      'distance': distance,
      'size': size,
    };
  }

  factory Planet.fromMap(Map<String, dynamic> map) {
    return Planet(
      id: map['id'],
      name: map['name'],
      nickname: map['nickname'] ?? '',
      distance: map['distance'],
      size: map['size'],
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

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
        nickname TEXT,
        distance REAL NOT NULL,
        size REAL NOT NULL
      )
    ''');
  }

  Future<int> insertPlanet(Planet planet) async {
    final db = await instance.database;
    return await db.insert('planets', planet.toMap());
  }

  Future<List<Planet>> getPlanets() async {
    final db = await instance.database;
    final result = await db.query('planets');
    return result.map((json) => Planet.fromMap(json)).toList();
  }

  Future<int> updatePlanet(Planet planet) async {
    final db = await instance.database;
    return await db.update(
      'planets',
      planet.toMap(),
      where: 'id = ?',
      whereArgs: [planet.id],
    );
  }

  Future<int> deletePlanet(int id) async {
    final db = await instance.database;
    return await db.delete('planets', where: 'id = ?', whereArgs: [id]);
  }
}

class PlanetListScreen extends StatefulWidget {
  @override
  _PlanetListScreenState createState() => _PlanetListScreenState();
}

class _PlanetListScreenState extends State<PlanetListScreen> {
  List<Planet> planets = [];

  @override
  void initState() {
    super.initState();
    _loadPlanets();
  }

  Future<void> _loadPlanets() async {
    final data = await DatabaseHelper.instance.getPlanets();
    setState(() {
      planets = data;
    });
  }

  void _deletePlanet(int id) async {
    await DatabaseHelper.instance.deletePlanet(id);
    _loadPlanets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Planetas')),
      body: ListView.builder(
        itemCount: planets.length,
        itemBuilder: (context, index) {
          final planet = planets[index];
          return ListTile(
            title: Text(planet.name),
            subtitle: Text(planet.nickname.isNotEmpty ? planet.nickname : 'Sem apelido'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deletePlanet(planet.id!),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {},
      ),
    );
  }
}
