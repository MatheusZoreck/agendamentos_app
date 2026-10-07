import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ClientePage extends StatefulWidget {
  const ClientePage({super.key});

  @override
  State<ClientePage> createState() => _ClientePageState();
}


class _ClientePageState extends State<ClientePage> {
  final nomeController = TextEditingController();
  final apelidoController = TextEditingController();
  final telefoneController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
      ),

      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('clientes')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text('Erro ao carregar clientes'),
              );
            }

            final clientes = snapshot.data?.docs ?? [];

            if (clientes.isEmpty) {
              return const Center(
                child: Text('Nenhum cliente cadastrado'),
              );
            }

            return ListView.builder(
              itemCount: clientes.length,
              itemBuilder: (context, index) {
                final cliente = clientes[index];

                final dados = cliente.data() as Map<String, dynamic>;

                final nome = dados['nome'] ?? '';
                final apelido = dados['apelido'] ?? '';
                final telefone = dados['telefone'] ?? '';

                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(nome),
                  subtitle: Text(
                    '$apelido - $telefone',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit)
                    , onPressed: () {

                    }
                ),
                );
              },
            );
          },
        ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) {
  return Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Novo Cliente',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        TextField(
          controller: nomeController,
          decoration: const InputDecoration(
            labelText: 'Nome',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          controller: apelidoController,
          decoration: const InputDecoration(
            labelText: 'Apelido',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          controller: telefoneController,
          decoration: const InputDecoration(
            labelText: 'Telefone',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: () async {
            // Salvar o cliente no Firestore
            final db = FirebaseFirestore.instance;
           await db.collection('clientes').add({
              'nome': nomeController.text,
              'apelido': apelidoController.text,
              'telefone': telefoneController.text,
            });

            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
},
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}