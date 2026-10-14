import 'package:agendamentos_app/screens/servico_page.dart';
import 'package:flutter/material.dart';
import 'agendamento_page.dart';
import 'cliente_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String filtroAgendamentos = 'Hoje';
  Timer? _timerVerificacao;

  Future<void> cancelarAgendamento(
  String documentoId,
  String statusAtual,

  ) async {
    final confirmar = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Cancelar agendamento'),
    content: Text(
      statusAtual == 'concluído'
          ? 'Este atendimento já está concluído. Deseja realmente cancelá-lo?'
          : 'Tem certeza de que deseja cancelar este agendamento?',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Voltar'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        child: const Text('Confirmar cancelamento'),
      ),
    ],
  ),
  
);
  if (confirmar != true) return;

  await FirebaseFirestore.instance
    .collection('agendamentos')
    .doc(documentoId)
    .update({
      'status': 'cancelado',
    });

  }

  @override
void initState() {
  super.initState();

  verificarAgendamentos();

  _timerVerificacao = Timer.periodic(
    const Duration(minutes: 1),
    (timer) {
      verificarAgendamentos();
    },
  );
}

  @override
  void dispose() {
    _timerVerificacao?.cancel();
    super.dispose();
  }

Future<void> verificarAgendamentos() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('agendamentos')
      .get();

  for (final documento in snapshot.docs) {
    final dados = documento.data();

    final status = dados['status'] ?? 'agendado';

    final dataHora = (dados['data'] as Timestamp).toDate();

    final tempoTotal = (dados['tempoTotal'] as num?)?.toInt() ?? 0;

    final dataHoraFinal = dataHora.add(
      Duration(minutes: tempoTotal),
    );

    final agora = DateTime.now();

    if (status == 'agendado' && agora.isAfter(dataHoraFinal)) {
      await documento.reference.update({
        'status': 'concluído',
      });
    }
  }
}
  
Widget _listaAgendamentos() {
  final agora = DateTime.now();

  final inicioHoje = DateTime(
    agora.year,
    agora.month,
    agora.day,
  );

  final inicioAmanha = inicioHoje.add(
    const Duration(days: 1),
  );

  Query<Map<String, dynamic>> consulta =
      FirebaseFirestore.instance.collection('agendamentos');

  if (filtroAgendamentos == 'Hoje') {
      consulta = consulta
          .where(
            'data',
            isGreaterThanOrEqualTo: Timestamp.fromDate(inicioHoje),
          )
          .where(
            'data',
            isLessThan: Timestamp.fromDate(inicioAmanha),
          );
    } else if (filtroAgendamentos == 'Próximos') {
      consulta = consulta.where(
        'data',
        isGreaterThanOrEqualTo: Timestamp.fromDate(inicioAmanha),
      );
    } else {
      consulta = consulta.where(
        'status',
        whereIn: ['concluído', 'cancelado'],
      );
    }

  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: consulta.orderBy('data').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (snapshot.hasError) {
        return Center(
          child: Text('Erro ao carregar agendamentos:\n${snapshot.error}'),
        );
      }

      final documentos = snapshot.data?.docs ?? [];

      if (documentos.isEmpty) {
        return Center(
          child: Text(
            filtroAgendamentos == 'Hoje'
                ? 'Nenhum agendamento para hoje.'
                : 'Nenhum próximo agendamento.',
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: documentos.length,
        itemBuilder: (context, index) {
          final dados = documentos[index].data();

          final status = dados['status'] ?? 'agendado';

          final corStatus = status == 'concluído'
          ? Colors.green
          : status == 'cancelado'
              ? Colors.red
              : Colors.blue;

          final dataHora = (dados['data'] as Timestamp).toDate();
       

          final horario =
              '${dataHora.hour.toString().padLeft(2, '0')}:'
              '${dataHora.minute.toString().padLeft(2, '0')}';

          final dataFormatada =
              '${dataHora.day.toString().padLeft(2, '0')}/'
              '${dataHora.month.toString().padLeft(2, '0')}/'
              '${dataHora.year}';

          final servicos = (dados['servicos'] as List<dynamic>? ?? [])
              .map((servico) => servico['nome'] ?? 'Serviço')
              .join(', ');

          final valor =
              (dados['valorTotal'] as num?)?.toDouble() ?? 0;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(horario),
                radius: 24,
              ),
              title: Text(
                (dados['clienteNome'] ?? 'Cliente sem nome').toString(),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$dataFormatada\n$servicos'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: corStatus.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toString().toUpperCase(),
                      style: TextStyle(
                        color: corStatus,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                PopupMenuButton<String>(
                  
                  onSelected: (opcao) async {
                    final documentoId = documentos[index].id;

                    if (opcao == 'editar') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NovoAgendamentoScreen(
                            agendamentoId: documentoId,
                          ),
                        ),
                      );
                    } else if (opcao == 'retomar') {
                      try {
                        await FirebaseFirestore.instance
                            .collection('agendamentos')
                            .doc(documentoId)
                            .update({
                          'status': 'agendado',
                        });

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Agendamento retomado com sucesso!'),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao retomar agendamento: $e'),
                          ),
                        );
                      }
                    } else if (opcao == 'cancelar') {
                      cancelarAgendamento(documentoId, status.toString());
                    }
                  },

                  itemBuilder: (context) => [
                    if (status != 'cancelado')
                      const PopupMenuItem<String>(
                        value: 'editar',
                        child: Text('Editar '),
                      ),
                    if (status == 'cancelado')
                      const PopupMenuItem<String>(
                        value: 'retomar',
                        child: Text('Retomar'),
                      ),
                    if (status != 'cancelado')
                      const PopupMenuItem<String>(
                        value: 'cancelar',
                        child: Text('Cancelar'),
                      ),
                  ],
                ),
              ],
            ),
            ),
          );
        },
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamentos'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              child: Text('Menu'),
            ),
            ListTile(
              title: const Text('Home'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('clientes'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientePage(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('serviços'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ServicoPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          filtroAgendamentos = 'Hoje';
                        });
                      },
                      child: const Text('Hoje'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          filtroAgendamentos = 'Próximos';
                        });
                      },
                      child: const Text('Próximos'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          filtroAgendamentos = 'Histórico';
                        });
                      },
                      child: const Text('Histórico'),
                    ),
                  ),
                ],
              ),
            ),

             Expanded(
              child: _listaAgendamentos(),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const NovoAgendamentoScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Novo Agendamento'),
                ),
              ),
            ),
          ],
        ),
      
    );
  }
}