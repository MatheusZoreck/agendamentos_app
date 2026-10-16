
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {



 // 1. Variáveis da classe
  late DateTime dataInicial;
  late DateTime dataFinal;

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

    dataFinal = DateTime(
      hoje.year,
      hoje.month,
      hoje.day,
    );
  }

  // 3. selecionarData()
 Future<void> selecionarData(bool inicial) async {
  final dataSelecionada = await showDatePicker(
    context: context,
    initialDate: inicial ? dataInicial : dataFinal.subtract(
      const Duration(days: 1),
    ),
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
    .where(
      'status',
      whereIn: ['concluído', 'cancelado'],
    )
    .where(
      'data',
      isGreaterThanOrEqualTo: Timestamp.fromDate(dataInicial),
    )
    .where(
      'data',
      isLessThan: Timestamp.fromDate(dataFinal),
    )
    .orderBy('data', descending: true)
    .limit(20)
    .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (snapshot.hasError) {
        return Center(
          child: Text(
            'Erro ao carregar histórico:\n${snapshot.error}',
          ),
        );
      }

      final documentos = snapshot.data?.docs ?? [];

      final atendimentosConcluidos = documentos.where((documento) {
        return documento.data()['status'] == 'concluído';
      }).toList();

      final quantidadeAtendimentos = atendimentosConcluidos.length;

      final valorTotal = atendimentosConcluidos.fold<double>(
        0,
        (total, documento) {
          final dados = documento.data();
          final valor = (dados['valorTotal'] as num?)?.toDouble() ?? 0;

          return total + valor;
        },
      );

      if (documentos.isEmpty) {
        return const Center(
          child: Text('Nenhum atendimento no histórico.'),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: documentos.length,
        itemBuilder: (context, index) {
          final dados = documentos[index].data();
          final dataHora = (dados['data'] as Timestamp).toDate();

          final dataFormatada =
              '${dataHora.day.toString().padLeft(2, '0')}/'
              '${dataHora.month.toString().padLeft(2, '0')}/'
              '${dataHora.year}';

          final horario =
              '${dataHora.hour.toString().padLeft(2, '0')}:'
              '${dataHora.minute.toString().padLeft(2, '0')}';

          final servicos =
              (dados['servicos'] as List<dynamic>? ?? [])
                  .map((servico) => servico['nome'] ?? 'Serviço')
                  .join(', ');

          final status = dados['status'] ?? 'concluído';
          final valor =
              (dados['valorTotal'] as num?)?.toDouble() ?? 0;

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(
                  status == 'concluído'
                      ? Icons.check
                      : Icons.close,
                ),
              ),
              title: Text(
                (dados['clienteNome'] ?? 'Cliente sem nome')
                    .toString(),
              ),
              subtitle: Text(
                '$dataFormatada às $horario\n'
                '$servicos\n'
                'Status: ${status.toString().toUpperCase()}',
              ),
              isThreeLine: true,
              trailing: Text(
                'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
              ),
            ),
          );
        },
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
              formatarData(
                dataFinal.subtract(const Duration(days: 1)),
              ),
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
      appBar: AppBar(
        title: const Text('Histórico de Agendamentos'),
      ),
      body: Column(
        children: [
          construirFiltros(),
          Expanded(
            child: listarAgendamentos(),
          ),
        ],
      ),
    );
  }
}
