import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'agendamento_page.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  // 1. Variáveis da classe
  late DateTime dataInicial;
  late DateTime dataFinal;

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
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir agendamento: $erro')),
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
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cancelar agendamento: $erro')),
      );
    }
  }

  Future<void> retomarAgendamento(String documentoId) async {
    try {
      await FirebaseFirestore.instance
          .collection('agendamentos')
          .doc(documentoId)
          .update({'status': 'agendado'});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento retomado com sucesso!')),
      );
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao retomar agendamento: $erro')),
      );
    }
  }

  // 2. initState()
  @override
  void initState() {
    super.initState();

    final hoje = DateTime.now();

    dataInicial = DateTime(
      hoje.year,
      hoje.month,
      hoje.day,
    ).subtract(const Duration(days: 7));

    dataFinal = DateTime(hoje.year, hoje.month, hoje.day);
  }

  // 3. selecionarData()
  Future<void> selecionarData(bool inicial) async {
    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: inicial
          ? dataInicial
          : dataFinal.subtract(const Duration(days: 1)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );

    if (dataSelecionada == null) return;

    setState(() {
      if (inicial) {
        dataInicial = DateTime(
          dataSelecionada.year,
          dataSelecionada.month,
          dataSelecionada.day,
        );
      } else {
        dataFinal = DateTime(
          dataSelecionada.year,
          dataSelecionada.month,
          dataSelecionada.day,
        ).add(const Duration(days: 1));
      }
    });
  }

  // 4. listarAgendamentos()
  Widget listarAgendamentos() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('agendamentos')
          .where('status', whereIn: ['concluído', 'cancelado'])
          .where(
            'data',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dataInicial),
          )
          .where('data', isLessThan: Timestamp.fromDate(dataFinal))
          .orderBy('data', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erro ao carregar histórico:\n${snapshot.error}'),
          );
        }

        final documentos = snapshot.data?.docs ?? [];

        final atendimentosConcluidos = documentos.where((documento) {
          return documento.data()['status'] == 'concluído';
        }).toList();

        final quantidadeAtendimentos = atendimentosConcluidos.length;

        final valorTotal = atendimentosConcluidos.fold<double>(0, (
          total,
          documento,
        ) {
          final dados = documento.data();
          final valor = (dados['valorTotal'] as num?)?.toDouble() ?? 0;

          return total + valor;
        });

        if (documentos.isEmpty) {
          return const Center(child: Text('Nenhum atendimento no histórico.'));
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Atendimentos'),
                            const SizedBox(height: 8),
                            Text(
                              '$quantidadeAtendimentos',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Valor total'),
                            const SizedBox(height: 8),
                            Text(
                              'R\$ ${valorTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: documentos.length,
                itemBuilder: (context, index) {
                  final dados = documentos[index].data();
                  final timestamp = dados['data'] as Timestamp?;
                  final dataHora = timestamp != null
                      ? timestamp.toDate()
                      : DateTime.now();

                  final dataFormatada =
                      '${dataHora.day.toString().padLeft(2, '0')}/'
                      '${dataHora.month.toString().padLeft(2, '0')}/'
                      '${dataHora.year}';

                  final horario =
                      '${dataHora.hour.toString().padLeft(2, '0')}:'
                      '${dataHora.minute.toString().padLeft(2, '0')}';

                  final servicos = (dados['servicos'] as List<dynamic>? ?? [])
                      .map((servico) => servico['nome'] ?? 'Serviço')
                      .join(', ');

                  final status = dados['status'] ?? 'concluído';
                  final isConcluido = status == 'concluído';
                  final corStatus = isConcluido ? Colors.green : Colors.red;
                  final formaPagamento =
                      dados['formaPagamento']?.toString() ?? '';
                  final formaPagamentoPendente =
                      isConcluido && formaPagamento.trim().isEmpty;
                  final valor = (dados['valorTotal'] as num?)?.toDouble() ?? 0;

                  final documentoId = documentos[index].id;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: formaPagamentoPendente
                            ? Colors.amber.shade800
                            : corStatus,
                        width: formaPagamentoPendente ? 2 : 1.5,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: corStatus.withValues(alpha: 0.15),
                        child: Icon(
                          isConcluido ? Icons.check : Icons.close,
                          color: corStatus,
                        ),
                      ),
                      title: Text(
                        (dados['clienteNome'] ?? 'Cliente sem nome').toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('$dataFormatada às $horario'),
                          if (servicos.isNotEmpty) Text(servicos),
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
                              vertical: 3,
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
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (opcao) {
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
                                retomarAgendamento(documentoId);
                              } else if (opcao == 'cancelar') {
                                cancelarAgendamento(
                                  documentoId,
                                  status.toString(),
                                );
                              } else if (opcao == 'excluir') {
                                excluirAgendamento(documentoId);
                              }
                            },
                            itemBuilder: (context) => [
                              if (status != 'cancelado')
                                const PopupMenuItem<String>(
                                  value: 'editar',
                                  child: Text('Editar'),
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
              ),
            ),
          ],
        );
      },
    );
  }

  // 5. construirFiltros()
  Widget construirFiltros() {
    String formatarData(DateTime data) {
      return '${data.day.toString().padLeft(2, '0')}/'
          '${data.month.toString().padLeft(2, '0')}/'
          '${data.year}';
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => selecionarData(true),
              icon: const Icon(Icons.calendar_month),
              label: Text(formatarData(dataInicial)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => selecionarData(false),
              icon: const Icon(Icons.event),
              label: Text(
                formatarData(dataFinal.subtract(const Duration(days: 1))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Agendamentos')),
      body: Column(
        children: [
          construirFiltros(),
          Expanded(child: listarAgendamentos()),
        ],
      ),
    );
  }
}
