import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ServicoPage extends StatefulWidget {
  const ServicoPage({super.key});

  @override
  State<ServicoPage> createState() => _ServicoPageState();
}

class _ServicoPageState extends State<ServicoPage> {

  final nomeController = TextEditingController();
  final valorController = TextEditingController();
  final tempoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Serviços'),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('servicos')
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Erro ao carregar serviços'),
            );
          }

          final servicos = snapshot.data?.docs ?? [];

          if (servicos.isEmpty) {
            return const Center(
              child: Text('Nenhum serviço cadastrado'),
            );
          }

          return ListView.builder(
            itemCount: servicos.length,

            itemBuilder: (context, index) {

              final servico = servicos[index];

              final dados =
                  servico.data() as Map<String, dynamic>;

              final nome = dados['nome'] ?? '';
              final valor = dados['valor'] ?? 0;
              final tempoMedio = dados['tempoMedio'] ?? 0;

              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.spa),
                ),

                title: Text(nome),

                subtitle: Text(
                  'R\$ $valor - $tempoMedio min',
                ),

                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    
                  },
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
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Novo Serviço',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do serviço',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: valorController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Valor',
                          prefixText: 'R\$ ',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: tempoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tempo médio (minutos)',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: () async {
                          final db = FirebaseFirestore.instance;

                          await db.collection('servicos').add({
                            'nome': nomeController.text,
                            'valor': double.parse(valorController.text.replaceAll(',', '.')),
                            'tempoMedio': int.parse(tempoController.text),
                          });

                          nomeController.clear();
                          valorController.clear();
                          tempoController.clear();

                          Navigator.pop(context);
                        },
                        child: const Text('Salvar'),
                      ),
                    ],
                  ),
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