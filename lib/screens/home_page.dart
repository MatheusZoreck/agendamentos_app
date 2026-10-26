import 'package:agendamentos_app/screens/servico_page.dart';
import 'package:flutter/material.dart';
import 'agendamento_page.dart';
import 'cliente_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'historico_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String filtroAgendamentos = 'Hoje';
  Timer? _timerVerificacao;

  Future<void> excluirAgendamento(String documentoId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir agendamento'),
        content: const Text(
          'Tem certeza de que deseja excluir este agendamento? '
          'Essa ação não poderá ser desfeita.',
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
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('agendamentos')
          .doc(documentoId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento excluído com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir agendamento: $e')),
      );
    }
  }

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

    try {
      await FirebaseFirestore.instance
          .collection('agendamentos')
          .doc(documentoId)
          .update({'status': 'cancelado'});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento cancelado com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cancelar agendamento: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    verificarAgendamentos();

    _timerVerificacao = Timer.periodic(const Duration(minutes: 1), (timer) {
      verificarAgendamentos();
    });
  }

  @override
  void dispose() {
    _timerVerificacao?.cancel();
    super.dispose();
  }

  Future<void> verificarAgendamentos() async {
    final agora = DateTime.now();

    try {
      // Busca apenas agendamentos ativos sem exigir índice composto no Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('agendamentos')
          .where('status', isEqualTo: 'agendado')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      var alteracoes = 0;

      for (final documento in snapshot.docs) {
        final dados = documento.data();
        final timestamp = dados['data'] as Timestamp?;
        if (timestamp == null) continue;

        final dataHora = timestamp.toDate();
        final tempoTotal = (dados['tempoTotal'] as num?)?.toInt() ?? 0;
        final dataHoraFinal = dataHora.add(Duration(minutes: tempoTotal));

        if (agora.isAfter(dataHoraFinal)) {
          batch.update(documento.reference, {'status': 'concluído'});
          alteracoes++;
        }
      }

      if (alteracoes > 0) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Erro ao verificar agendamentos: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _obterStreamAgendamentos() {
    final agora = DateTime.now();
    final inicioHoje = DateTime(agora.year, agora.month, agora.day);
    final inicioAmanha = inicioHoje.add(const Duration(days: 1));

    Query<Map<String, dynamic>> consulta = FirebaseFirestore.instance
        .collection('agendamentos');

    if (filtroAgendamentos == 'Hoje') {
      consulta = consulta
          .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioHoje))
          .where('data', isLessThan: Timestamp.fromDate(inicioAmanha));
    } else {
      // Próximos
      consulta = consulta.where(
        'data',
        isGreaterThanOrEqualTo: Timestamp.fromDate(inicioAmanha),
      );
    }

    return consulta.orderBy('data').snapshots();
  }

  Widget _listaAgendamentos() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _obterStreamAgendamentos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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

            final timestamp = dados['data'] as Timestamp?;
            final dataHora = timestamp?.toDate() ?? DateTime.now();

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

            final valor = (dados['valorTotal'] as num?)?.toDouble() ?? 0;
            final formaPagamento = dados['formaPagamento']?.toString() ?? '';
            final formaPagamentoPendente =
                status == 'concluído' && formaPagamento.trim().isEmpty;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: formaPagamentoPendente
                      ? Colors.amber.shade800
                      : Colors.transparent,
                  width: formaPagamentoPendente ? 2 : 0,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(radius: 24, child: Text(horario)),
                title: Text(
                  (dados['clienteNome'] ?? 'Cliente sem nome').toString(),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$dataFormatada\n$servicos'),
                    if (formaPagamentoPendente)
                      const Text(
                        'Forma de pagamento pendente',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (formaPagamento.trim().isNotEmpty)
                      Text('Pagamento: $formaPagamento'),
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
                                .update({'status': 'agendado'});

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Agendamento retomado com sucesso!',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Erro ao retomar agendamento: $e',
                                ),
                              ),
                            );
                          }
                        } else if (opcao == 'cancelar') {
                          cancelarAgendamento(documentoId, status.toString());
                        } else if (opcao == 'excluir') {
                          excluirAgendamento(documentoId);
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
                        const PopupMenuItem<String>(
                          value: 'excluir',
                          child: Text(
                            'Excluir',
                            style: TextStyle(color: Colors.red),
                          ),
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
        title: const Text(
          'Agendamentos',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFFFFFCF8),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFFD7B9A9)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(Icons.spa_outlined, size: 36, color: Color(0xFF6F554B)),
                  SizedBox(height: 10),
                  Text(
                    'Agendamentos',
                    style: TextStyle(
                      color: Color(0xFF6F554B),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Menu principal',
                    style: TextStyle(color: Color(0xFF6F554B), fontSize: 13),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(
                  context,
                ); // Apenas fecha o Drawer, pois já está na Home
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Clientes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ClientePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.spa_outlined),
              title: const Text('Serviços'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ServicoPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Histórico'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoricoPage(),
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
                  child: filtroAgendamentos == 'Hoje'
                      ? ElevatedButton(
                          onPressed: () {
                            setState(() {
                              filtroAgendamentos = 'Hoje';
                            });
                          },
                          child: const Text('Hoje'),
                        )
                      : OutlinedButton(
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
                  child: filtroAgendamentos == 'Próximos'
                      ? ElevatedButton(
                          onPressed: () {
                            setState(() {
                              filtroAgendamentos = 'Próximos';
                            });
                          },
                          child: const Text('Próximos'),
                        )
                      : OutlinedButton(
                          onPressed: () {
                            setState(() {
                              filtroAgendamentos = 'Próximos';
                            });
                          },
                          child: const Text('Próximos'),
                        ),
                ),
              ],
            ),
          ),
          Expanded(child: _listaAgendamentos()),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NovoAgendamentoScreen(),
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
