import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SqliteHandler {
  Future<Database> openMyDatabase() async{
    final databasePath = await getDatabasesPath();
    final path = join(databasePath,'mydatabase.db');
    
    return openDatabase(
      path,
      version:1,
      onCreate: (db,version )async{
        await db.execute('''
          CREATE TABLE encuentros (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ubicacion TEXT,
            nombre TEXT,
            perfil TEXT,
            telefono TEXT)
            ''');
      },
    );
  }
  Future<void> addData({
    required String ubicacion,
    required String nombre,
    required String perfil,
    required String telefono,
    }) async{
    final db =await openMyDatabase();
    await db.insert(
      'encuentros',
       {
        'ubicacion':ubicacion,
        'nombre':nombre,
        'perfil': perfil,
        'telefono':telefono,

       },
    conflictAlgorithm: ConflictAlgorithm.replace
    );
    await db.close();
  }
  
  Future<List<Map<String,dynamic>>> obtenerDatos() async{
    final db =await openMyDatabase();
    final data=await db.query('encuentros');
    await db.close();
    return data;
  }
}