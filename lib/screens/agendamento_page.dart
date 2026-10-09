import 'package:agendamentos_app/firebase/database.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NovoAgendamentoScreen extends StatefulWidget {
  const NovoAgendamentoScreen({super.key});

  @override
  State<NovoAgendamentoScreen> createState() => _NovoAgendamentoScreenState();
}

class _NovoAgendamentoScreenState extends State<NovoAgendamentoScreen> {
  int etapaAtual = 0;
  

  final database = Database();
 

  final Set<String> servicosSelecionados = {};
  String? clienteSelecionadoId;
  DateTime? dataSelecionada;
  TimeOfDay? horarioSelecionado;
  bool salvandoAgendamento = false;

  
Widget etapaSelecionarCliente() {
  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
          child: Text('Erro ao carregar clientes.'),
        );
      }

      final clientes = snapshot.data?.docs ?? [];

      if (clientes.isEmpty) {
        return const Center(
          child: Text('Nenhum cliente cadastrado.'),
        );
      }

      return RadioGroup<String>(
        groupValue: clienteSelecionadoId,
        onChanged: (id) {
          setState(() {
            clienteSelecionadoId = id;
          });
        },
        child: ListView.builder(
          itemCount: clientes.length,
          itemBuilder: (context, index) {
            final cliente = clientes[index];
            final dados = cliente.data();

            final nome = dados['nome'] ?? '';
            final apelido = dados['apelido'] ?? '';
            final telefone = dados['telefone'] ?? '';

            return RadioListTile<String>(
              value: cliente.id,
              title: Text(
                apelido.toString().isNotEmpty
                    ? '$nome ($apelido)'
                    : nome.toString(),
              ),
              subtitle: Text(telefone.toString()),
            );
          },
        ),
      );
    },
  );
}


Widget etapaSelecionarServicos() {
  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
          child: Text('Erro ao carregar os serviços.'),
        );
      }

      final documentos = snapshot.data?.docs ?? [];

      if (documentos.isEmpty) {
        return const Center(
          child: Text('Nenhum serviço cadastrado.'),
        );
      }

      return ListView(
        children: documentos.map((documento) {
          final dados = documento.data();
          final nome = dados['nome'] ?? 'Serviço sem nome';
          final valor = (dados['valor'] as num?)?.toDouble() ?? 0;
          final tempo = dados['tempoMedio'] ?? 0;

          return CheckboxListTile(
            value: servicosSelecionados.contains(documento.id),
            title: Text(nome.toString()),
            subtitle: Text(
              'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}'
              ' • $tempo min',
            ),
            onChanged: (marcado) {
              setState(() {
                if (marcado == true) {
                  servicosSelecionados.add(documento.id);
                } else {
                  servicosSelecionados.remove(documento.id);
                }
              });
            },
          );
        }).toList(),
      );
    },
  );
}


  Future<void> selecionarHorario() async {
    final TimeOfDay? horario = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (horario != null) {
      setState(() {
        horarioSelecionado = horario;
      });
    }
  }

  Future<void> selecionarData() async{

    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (data != null) {
      setState(() {
        dataSelecionada = data;
      });
    }
  }

Widget etapaSelecionarDataHorario() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Escolha a data do agendamento:',
        style: TextStyle(fontSize: 16),
      ),

      const SizedBox(height: 12),

      OutlinedButton.icon(
        onPressed: selecionarData,
        icon: const Icon(Icons.calendar_month),
        label: Text(
          dataSelecionada == null
              ? 'Selecionar data'
              : '${dataSelecionada!.day.toString().padLeft(2, '0')}/'
                '${dataSelecionada!.month.toString().padLeft(2, '0')}/'
                '${dataSelecionada!.year}',
        ),
      ),

      const SizedBox(height: 24),

      const Text(
        'Escolha o horário:',
        style: TextStyle(fontSize: 16),
      ),

      const SizedBox(height: 12),

      OutlinedButton.icon(
        onPressed: selecionarHorario,
        icon: const Icon(Icons.access_time),
        label: Text(
          horarioSelecionado == null
              ? 'Selecionar horário'
              : horarioSelecionado!.format(context),
        ),
      ),
    ],
  );
}


Widget etapaConfirmarAgendamento() {
  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('clientes')
        .doc(clienteSelecionadoId)
        .snapshots(),
    builder: (context, clienteSnapshot) {
      if (clienteSnapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (clienteSnapshot.hasError) {
        return const Center(
          child: Text('Erro ao carregar os dados do cliente.'),
        );
      }

      final cliente = clienteSnapshot.data?.data();

      if (cliente == null) {
        return const Center(
          child: Text('Cliente não encontrado.'),
        );
      }

      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('servicos')
            .snapshots(),
        builder: (context, servicosSnapshot) {
          if (servicosSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (servicosSnapshot.hasError) {
            return const Center(
              child: Text('Erro ao carregar os serviços.'),
            );
          }

          final documentos = servicosSnapshot.data?.docs ?? [];

          final selecionados = documentos
              .where((doc) => servicosSelecionados.contains(doc.id))
              .toList();

          if (selecionados.length != servicosSelecionados.length) {
            return const Center(
              child: Text(
                'Um ou mais serviços selecionados não foram encontrados.',
              ),
            );
          }

          double valorTotal = 0;
          int tempoTotal = 0;

          for (final documento in selecionados) {
            final dados = documento.data();

            valorTotal +=
                (dados['valor'] as num?)?.toDouble() ?? 0;

            tempoTotal +=
                (dados['tempoMedio'] as num?)?.toInt() ?? 0;
          }

          final data = dataSelecionada!;
          final horario = horarioSelecionado!;

          final dataFormatada =
              '${data.day.toString().padLeft(2, '0')}/'
              '${data.month.toString().padLeft(2, '0')}/'
              '${data.year}';

          return ListView(
            children: [
              const Text(
                'Confira os dados do agendamento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Cliente'),
                subtitle: Text(
                  (cliente['apelido'] ?? '').toString().isNotEmpty
                      ? '${cliente['nome']} (${cliente['apelido']})'
                      : (cliente['nome'] ?? 'Sem nome').toString(),
                ),
              ),

              const ListTile(
                leading: Icon(Icons.spa),
                title: Text('Serviços selecionados'),
              ),

              ...selecionados.map((documento) {
                final dados = documento.data();
                final nome =
                    (dados['nome'] ?? 'Serviço').toString();
                final valor =
                    (dados['valor'] as num?)?.toDouble() ?? 0;
                final tempo =
                    (dados['tempoMedio'] as num?)?.toInt() ?? 0;

                return ListTile(
                  dense: true,
                  title: Text(nome),
                  subtitle: Text('$tempo minutos'),
                  trailing: Text(
                    'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
                  ),
                );
              }),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.payments),
                title: const Text('Valor total'),
                trailing: Text(
                  'R\$ ${valorTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.timelapse),
                title: const Text('Tempo estimado'),
                trailing: Text('$tempoTotal minutos'),
              ),

              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Data'),
                trailing: Text(dataFormatada),
              ),

              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Horário'),
                trailing: Text(horario.format(context)),
              ),
            ],
          );
        },
      );
    },
  );
}


Future<void> salvarAgendamento() async {
  if (salvandoAgendamento) return;

  setState(() {
    salvandoAgendamento = true;
  });
  try {
    // Busca os dados do cliente selecionado.
    final clienteDoc = await FirebaseFirestore.instance
        .collection('clientes')
        .doc(clienteSelecionadoId)
        .get();

    if (!clienteDoc.exists || clienteDoc.data() == null) {
      throw Exception('Cliente não encontrado.');
    }

    final cliente = clienteDoc.data()!;

    // Busca os serviços cadastrados.
    final servicosSnapshot = await FirebaseFirestore.instance
        .collection('servicos')
        .get();

    final documentosSelecionados = servicosSnapshot.docs
        .where((doc) => servicosSelecionados.contains(doc.id))
        .toList();

    if (documentosSelecionados.length != servicosSelecionados.length) {
      throw Exception('Um ou mais serviços não foram encontrados.');
    }

    double valorTotal = 0;
    int tempoTotal = 0;

    final listaServicos = documentosSelecionados.map((doc) {
      final dados = doc.data();
      final valor = (dados['valor'] as num?)?.toDouble() ?? 0;
      final tempo = (dados['tempoMedio'] as num?)?.toInt() ?? 0;

      valorTotal += valor;
      tempoTotal += tempo;

      return {
        'servicoId': doc.id,
        'nome': dados['nome'] ?? 'Serviço',
        'valor': valor,
        'tempoMedio': tempo,
      };
    }).toList();

    // Combina a data escolhida com o horário selecionado.
    final dataHora = DateTime(
      dataSelecionada!.year,
      dataSelecionada!.month,
      dataSelecionada!.day,
      horarioSelecionado!.hour,
      horarioSelecionado!.minute,
    );

    // Grava o agendamento no Firestore.
    await FirebaseFirestore.instance
        .collection('agendamentos')
        .add({
      'clienteId': clienteSelecionadoId,
      'clienteNome': cliente['nome'] ?? '',
      'servicos': listaServicos,
      'valorTotal': valorTotal,
      'tempoTotal': tempoTotal,
      'data': Timestamp.fromDate(dataHora),
      'criadoEm': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Agendamento salvo com sucesso!'),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro ao salvar agendamento: $e'),
      ),
    );
  }
  finally {
    if (mounted) {
      setState(() {
        salvandoAgendamento = false;
      });
    }
  }
}


  void avancarEtapa() {
    if (etapaAtual == 0 && clienteSelecionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um cliente para continuar.'),
        ),
      );
      return;
    }

    if (etapaAtual == 1 && servicosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um serviço.'),
        ),
      );
      return;
    }

    if (etapaAtual == 2 &&
      (dataSelecionada == null || horarioSelecionado == null)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selecione a data e o horário.'),
      ),
    );
    return;
  }

    if (etapaAtual < 3) {
      setState(() {
        etapaAtual++;
      });
    }
  }

void voltarEtapa() {
      if (etapaAtual > 0) {
        setState(() {
          etapaAtual--;
        });
      }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Agendamento'),
      ),

      body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Etapa ${etapaAtual + 1} de 4',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              LinearProgressIndicator(
                value: (etapaAtual + 1) / 4,
              ),

              const SizedBox(height: 32),

              Center(
                child: Text(
                  [
                    'Selecionar cliente',
                    'Selecionar serviços',
                    'Escolher data e horário',
                    'Confirmar agendamento',
                  ][etapaAtual],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Expanded(
                child: etapaAtual == 0
                    ? etapaSelecionarCliente()
                    : etapaAtual == 1
                        ? etapaSelecionarServicos()
                        : etapaAtual == 2
                            ? etapaSelecionarDataHorario()
                            : etapaConfirmarAgendamento(),

              ),

              Row(
                children: [
                  if (etapaAtual > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: voltarEtapa,
                        child: const Text('Voltar'),
                      ),
                    ),

          if (etapaAtual > 0)
            const SizedBox(width: 12),

          Expanded(
            child: 
                ElevatedButton(
                  onPressed: salvandoAgendamento
                      ? null
                      : etapaAtual == 3
                          ? salvarAgendamento
                          : avancarEtapa,
                  child: salvandoAgendamento
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          etapaAtual == 3 ? 'Finalizar' : 'Continuar',
                        ),
                ),

          ),
        ],
      ),
    ],
  ),
),
    );
  }
}