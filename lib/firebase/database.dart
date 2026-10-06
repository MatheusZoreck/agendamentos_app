import 'package:cloud_firestore/cloud_firestore.dart';

class Database{
  final db = FirebaseFirestore.instance;

  Future<void> adicionarClienteTeste() async {
    await db.collection('clientes').add({
      'nome': 'Teste',
      'telefone': '41999999999',
    });
  }
}