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

  
    void abrirEdicao(DocumentSnapshot servico) {
      final dados = servico.data() as Map<String, dynamic>;

      nomeController.text = dados['nome'] ?? '';
      valorController.text = (dados['valor'] ?? 0).toString();
      tempoController.text = (dados['tempoMedio'] ?? 0).toString();

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
                    'Editar Serviço',
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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

                  
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final valor = double.tryParse(
                            valorController.text.replaceAll(',', '.'),
                          );
                          final tempo = int.tryParse(tempoController.text);

                          if (nomeController.text.trim().isEmpty ||
                              valor == null ||
                              valor < 0 ||
                              tempo == null ||
                              tempo <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Confira os dados do serviço.'),
                              ),
                            );
                            return;
                          }

                          await FirebaseFirestore.instance
                              .collection('servicos')
                              .doc(servico.id)
                              .update({
                            'nome': nomeController.text.trim(),
                            'valor': valor,
                            'tempoMedio': tempo,
                          });

                          nomeController.clear();
                          valorController.clear();
                          tempoController.clear();

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Salvar alterações'),
                      ),
                    ),

                    const SizedBox(width: 12),

                    IconButton(
                      tooltip: 'Excluir serviço',
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirmar = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Excluir serviço'),
                              content: const Text(
                                'Tem certeza que deseja excluir este serviço?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, false);
                                  },
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context, true);
                                  },
                                  child: const Text('Excluir'),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirmar == true) {
                          await FirebaseFirestore.instance
                              .collection('servicos')
                              .doc(servico.id)
                              .delete();

                          nomeController.clear();
                          valorController.clear();
                          tempoController.clear();

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                    ),
                  ],
                )

                ],
              ),
            ),
          );
        },
      );
    }


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
                  'R\$ ${(valor as num).toStringAsFixed(2).replaceAll('.', ',')}'
                  ' - $tempoMedio min',
                ),

                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    abrirEdicao(servico); 
                  },
                ),
              );
            },
          );
        },
      ),
      // FloatingActionButton to add a new service
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          nomeController.clear();
          valorController.clear();
          tempoController.clear();
          
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