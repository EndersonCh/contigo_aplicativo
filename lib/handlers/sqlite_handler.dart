import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

 class SqliteHandler {
  Future<Database> getDb() async{
    String databasePath= await getDatabasesPath();
    String path =join(databasePath,'database_sqlite.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate
      );
  }
  void _onCreate(Database db, int version) async{
    await db.execute('''
      CREATE TABLE encuentro(
        idx TEXT PRIMARY KEY,
        encuen_ubicaion TEXT,
        encuen_nom TEXT,
        encuen_perfiL TEXT,
        encuen_tlf TEXT,
      );
    ''');
  }
 }
 //extends StatefulWidget {
//   const SqliteHandler({super.key});

//   @override
//   State<SqliteHandler> createState() => _SqliteHandlerState();
// }

// class _SqliteHandlerState extends State<SqliteHandler> {
//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }
//}