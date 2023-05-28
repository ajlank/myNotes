// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:mynotes2/extensions/list/filter.dart';
// import 'package:mynotes2/services/auth_exceptions.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' show join;
// import 'crud_exceptions.dart';

// class NotesService{
//   Database? _db;
//   List<DatabaseNote> _notes = [];
//   DatabaseUser? _user;


//    static final NotesService _shared=NotesService._sharedInstance();
    
//     NotesService._sharedInstance(){
//       _notesStreamController=StreamController<List<DatabaseNote>>.broadcast(
//         onListen: () {
//          _notesStreamController.sink.add(_notes);  
//         },
//       );
//     } 

//     factory NotesService()=>_shared;

//     late final StreamController<List<DatabaseNote>>_notesStreamController;
   
//    Stream<List<DatabaseNote>>get allNotes =>_notesStreamController.stream.filter((notes){
//      final currentUser=_user;
//      if(currentUser!=null){
//       return notes.userID==currentUser.id;
//      }else{
//       throw UserShouldBeSetBeforeReadingAllNotes();
//      }
//    });
   
//   Future<DatabaseUser> getOrCreateUser(
//     {
//       required String email,
//       bool setAsCurrentUser=true,
//       }) async {
//     try {
//       final user = await getUser(email: email);
//       if(setAsCurrentUser){
//         _user=user;
//       }
//       return user;
//     } on CouldNotFindUser {
//       final createdUser = await createUser(email: email);
//       if(setAsCurrentUser){
//         _user=createdUser;
//       }
//       return createdUser;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<void> _cachedNotes() async {
//     final allNotes = await getAllNotes();
//     _notes = allNotes.toList();
//     _notesStreamController.add(_notes);
//   }

//   Future<DatabaseNote> updateNote(
//       {required DatabaseNote note, required String text}) async {
//         await _ensureDbIsopen();
//     final db = getDatabaseOrThrow();
//     getNote(id: note.id);
//     final updateCount =
//         db.update(noteTable, {
//           textColumn: text,
//          isSyncedWithCloudColumn: 0,
//          },
//          where: 'id=?',
//          whereArgs:[note.id],
//          );
    
//     if(updateCount == 0) {
//       throw CouldNotUpdateNote();
//     } else {
//       final updateNote = await getNote(id: note.id);
//       _notes.removeWhere((note) => note.id == updateNote.id);
//       _notes.add(updateNote);
//       _notesStreamController.add(_notes);
//       return updateNote;
//     }
//   }

//   Future<Iterable<DatabaseNote>> getAllNotes() async {
//     await _ensureDbIsopen();
//     final db = getDatabaseOrThrow();
//     final notes = await db.query(noteTable);
//     return notes.map((noteRow) => DatabaseNote.fromRow(noteRow));
//   }

//   Future<DatabaseNote> getNote({required int id}) async {
//     await _ensureDbIsopen();
//     final db = getDatabaseOrThrow();
//     final notes = await db.query(
//       noteTable,
//       limit: 1,
//       where: 'id=?',
//       whereArgs: [id],
//     );
//     if (notes.isEmpty) {
//       throw CouldNotFindNote();
//     } else {
//       final note = DatabaseNote.fromRow(notes.first);
//       _notes.removeWhere((note) => note.id == id);
//       _notes.add(note);
//       _notesStreamController.add(_notes);
//       return note;
//     }
//   }

//   Future<int> deletAllNotes() async {
//     await _ensureDbIsopen();
//     final db = getDatabaseOrThrow();
//     final numberOfDeletion = db.delete(noteTable);
//     _notes = [];
//     _notesStreamController.add(_notes);
//     return numberOfDeletion;
//   }

//   Future<void> deleteNote({required int id}) async {
//     await _ensureDbIsopen();
//     final db = getDatabaseOrThrow();
//     final deletedCount = await db.delete(
//       noteTable,
//       where: 'id= ?',
//       whereArgs: [id],
//     );
//     if (deletedCount == 0) {
//       throw CouldNotDeleteNote();
//     } else {
//       _notes.removeWhere((note) => note.id == id);
//       _notesStreamController.add(_notes);
//     }
//   }

//   Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
//     await _ensureDbIsopen();
//     final db = getDatabaseOrThrow();
//     final dbUser = await getUser(email: owner.email);
//     if (dbUser != owner) {
//       throw CouldNotFindUser();
//     }
//     const text = '';
//     final noteId = await db.insert(noteTable, {
//       userIdColumn: owner.id,
//       textColumn: text,
//       isSyncedWithCloudColumn: 1,
//     });
//     final note = DatabaseNote(
//         id: noteId, userID: owner.id, text: text, isSyncedWithCloud: true);
//     _notes.add(note);
//     _notesStreamController.add(_notes);
//     return note;
//   }

//   Future<DatabaseUser> getUser({required String email}) async {
//     await _ensureDbIsopen();
//     final db = getDatabaseOrThrow();
//     final results = await db.query(userTable,
//         limit: 1, where: 'email=?', whereArgs: [email.toLowerCase()]);
//     if (results.isEmpty) {
//       throw CouldNotFindUser();
//     } else {
//       return DatabaseUser.fromRow(results.first);
//     }
//   }

//   Future<DatabaseUser> createUser({required String email}) async {
//      await _ensureDbIsopen();
//     final db = getDatabaseOrThrow();
//     final result = await db.query(userTable,
//         limit: 1, where: 'email=?', whereArgs: [email.toLowerCase()]);
//     if (result.isNotEmpty) {
//       throw UserAlreadyExists();
//     }
//     final userId =
//         await db.insert(userTable, {emailColumn: email.toLowerCase()});
//     return DatabaseUser(id: userId, email: email);
//   }

//   Future<void> deleteUser({required String email}) async {
//     await _ensureDbIsopen();
//     final db = getDatabaseOrThrow();
//     final deleteCount = await db
//         .delete(userTable, where: 'email= ?', whereArgs: [email.toLowerCase()]);
//     if (deleteCount != 1) {
//       throw CouldNotDeleteUser();
//     }
//   }

//   Database getDatabaseOrThrow() {
//     final db = _db;
//     if (db == null) {
//       throw DatabaseIsNotOpenException();
//     } else {
//       return db;
//     }
//   }

//   Future<void> close() async {
//     final db = _db;

//     if (db == null) {
//       throw DatabaseIsNotOpenException();
//     } else {
//       await db.close();
//       _db = null;
//     }
//   }
 
//   Future<void>_ensureDbIsopen()async{
//       try{
//         await open(); 
//       } on DatabaseIsAlreadyOpenException{
//         //code
//       }
//   }

//   Future<void> open() async {
//     if (_db != null) {
//       throw DatabaseIsAlreadyOpenException();
//     }
//     try {
//       final docsPath = await getApplicationDocumentsDirectory();
//       final dbPath = join(docsPath.path, dbName);
//       final db = await openDatabase(dbPath);
//       _db = db;

//       await db.execute(createUserTable);
//       await db.execute(createNoteTable);
//       await _cachedNotes();
//     } on MissingPlatformDirectoryException {
//       throw UnableToGetDocumentDirectory();
//     }
//   }
// }

// @immutable
// class DatabaseUser {
//   final int id;
//   final String email;

//   const DatabaseUser({required this.id, required this.email});

//   DatabaseUser.fromRow(Map<String, Object?> map)
//       : id = map[idColumn] as int,
//         email = map[emailColumn] as String;

//   @override
//   String toString() => 'User: ID: $id , email:$email';

//   @override
//   bool operator ==(covariant DatabaseUser other) => id == other.id;

//   @override
//   int get hashCode => id.hashCode;
// }

// @immutable
// class DatabaseNote {
//   final int id;
//   final int userID;
//   final String text;
//   final bool isSyncedWithCloud;

//   const DatabaseNote(
//       {required this.id,
//       required this.userID,
//       required this.text,
//       required this.isSyncedWithCloud});

//   DatabaseNote.fromRow(Map<String, Object?> map)
//       : id = map[idColumn] as int,
//         userID = map[userIdColumn] as int,
//         text = map[textColumn] as String,
//         isSyncedWithCloud =
//             (map[isSyncedWithCloudColumn] as int) == 1 ? true : false;

//   @override
//   String toString() =>
//       'Note: ID: $id , userId: $userID, text: $text, isSyncedWithCloud: $isSyncedWithCloud';

//   @override
//   bool operator ==(covariant DatabaseNote other) => id == other.id;

//   @override
//   int get hashCode => id.hashCode;
// }

// const idColumn = "id";
// const emailColumn = "email";
// const userIdColumn = "user_id";
// const textColumn = "text";
// const isSyncedWithCloudColumn = "is_synced_with_cloud";
// const dbName = 'notes.db';
// const userTable = 'user';
// const noteTable = 'note';
// const createUserTable = '''
//         CREATE TABLE IF NOT EXISTS "user" (
//       "id"	INTEGER NOT NULL,
//       "email"	TEXT NOT NULL UNIQUE,
//       PRIMARY KEY("id" AUTOINCREMENT)
//     );
//    ''';
// const createNoteTable = ''' 
//           CREATE TABLE IF NOT EXISTS "note" (
//         "id"	INTEGER NOT NULL,
//         "user_id"	INTEGER NOT NULL,
//         "text"	TEXT,
//         "is_synced_with_cloud"	INTEGER NOT NULL DEFAULT 0,
//         FOREIGN KEY("user_id") REFERENCES "user"("id"),
//         PRIMARY KEY("id" AUTOINCREMENT)
//       );
//  ''';