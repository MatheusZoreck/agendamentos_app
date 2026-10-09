import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClientePage extends StatefulWidget {
  const ClientePage({super.key});

  @override
  State<ClientePage> createState() => _ClientePageState();
}


class _ClientePageState extends State<ClientePage> {
  final nomeController = TextEditingController();
  final apelidoController = TextEditingController();
  final telefoneController = TextEditingController();

void abrirEdicao(DocumentSnapshot cliente) {
  final dados = cliente.data() as Map<String, dynamic>;

  nomeController.text = dados['nome'] ?? '';
  apelidoController.text = dados['apelido'] ?? '';
  telefoneController.text = dados['telefone'] ?? '';

  showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(left: 16,
               right:  16,
              top: 16,
               bottom: MediaQuery.of(context).viewInsets.bottom + 16,),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Editar Cliente',
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
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      TelefoneInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      hintText: '(41) 99999-9999',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {

                          final telefone = telefoneController.text.replaceAll(
                RegExp(r'\D'),
                '',
              );

                if (telefone.length != 11) {
                  await showDialog<void>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        icon: const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 40,
                        ),
                        title: const Text('Telefone inválido'),
                        content: const Text(
                          'Informe um celular com DDD e 11 dígitos.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                            },
                            child: const Text('Entendi'),
                          ),
                        ],
                      );
                    },
                  );

                  return;
                }

                          await FirebaseFirestore.instance
                              .collection('clientes')
                              .doc(cliente.id)
                              .update({
                            'nome': nomeController.text,
                            'apelido': apelidoController.text,
                            'telefone': telefoneController.text,
                          });

                          Navigator.pop(context);
                        },
                        child: const Text('Salvar'),
                      ),

                      const Spacer(),

                      IconButton(
                        onPressed: () async {
                          final confirmar = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Excluir cliente'),
                                content: const Text(
                                  'Tem certeza que deseja excluir este cliente?',
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
                                .collection('clientes')
                                .doc(cliente.id)
                                .delete();

                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      }

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
                    icon: const Icon(Icons.edit),
                     onPressed: () {
                      abrirEdicao(cliente);
                    }
                ),
                );
              },
            );
          },
        ),
      // Botão flutuante para adicionar um novo cliente
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          nomeController.clear();
          apelidoController.clear();
          telefoneController.clear();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) {
              return Padding(
                padding: EdgeInsets.only(left: 16,
                 right:  16,
                 top: 16,
                 bottom: MediaQuery.of(context).viewInsets.bottom + 16,),
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
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            TelefoneInputFormatter(),
            ],
          decoration: const InputDecoration(
          labelText: 'Telefone',
          hintText: '(41) 99999-9999',
          border: OutlineInputBorder(),
             ),
            ),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: () async {
            // Salvar o cliente no Firestore
            final telefone = telefoneController.text.replaceAll(
                RegExp(r'\D'),
                '',
              );

                if (telefone.length != 11) {
                  await showDialog<void>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        icon: const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 40,
                        ),
                        title: const Text('Telefone inválido'),
                        content: const Text(
                          'Informe um celular com DDD e 11 dígitos.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                            },
                            child: const Text('Entendi'),
                          ),
                        ],
                      );
                    },
                  );

                  return;
                }

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


class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String numero = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (numero.length > 11) {
      numero = numero.substring(0, 11);
    }

    // Conta quantos números existem antes do cursor.
    final cursorOriginal =
        newValue.selection.extentOffset.clamp(0, newValue.text.length);

    final digitosAntesDoCursor = newValue.text
        .substring(0, cursorOriginal)
        .replaceAll(RegExp(r'\D'), '')
        .length;

    String formatado = numero;

    if (numero.isNotEmpty) {
      if (numero.length <= 2) {
        formatado = '($numero';
      } else {
        final ddd = numero.substring(0, 2);
        final restante = numero.substring(2);

        formatado = '($ddd) $restante';

        if (numero.length >= 10) {
          final tamanhoPrefixo = numero.length == 11 ? 5 : 4;

          formatado =
              '($ddd) '
              '${restante.substring(0, tamanhoPrefixo)}-'
              '${restante.substring(tamanhoPrefixo)}';
        }
      }
    }

    // Reposiciona o cursor considerando os dígitos digitados.
    int novoCursor = 0;
    int digitosContados = 0;

    while (novoCursor < formatado.length &&
        digitosContados < digitosAntesDoCursor) {
      if (RegExp(r'\d').hasMatch(formatado[novoCursor])) {
        digitosContados++;
      }
      novoCursor++;
    }

    // Se o cursor estiver antes de um separador, avança até uma
    // posição válida sem perder o número que está sendo editado.
    if (novoCursor < formatado.length &&
        digitosContados == digitosAntesDoCursor &&
        !RegExp(r'\d').hasMatch(formatado[novoCursor])) {
      novoCursor++;
    }

    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(
        offset: novoCursor.clamp(0, formatado.length),
      ),
    );
  }
}

