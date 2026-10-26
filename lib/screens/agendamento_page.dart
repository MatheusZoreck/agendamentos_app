import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NovoAgendamentoScreen extends StatefulWidget {
  final String? agendamentoId;
  const NovoAgendamentoScreen({super.key, this.agendamentoId});

  @override
  State<NovoAgendamentoScreen> createState() => _NovoAgendamentoScreenState();
}

class _NovoAgendamentoScreenState extends State<NovoAgendamentoScreen> {
  int etapaAtual = 0;

  final Set<String> servicosSelecionados = {};
  String? clienteSelecionadoId;
  String? formaPagamentoSelecionada;
  DateTime? dataSelecionada;
  TimeOfDay? horarioSelecionado;
  bool salvandoAgendamento = false;
  late bool carregandoAgendamento = widget.agendamentoId != null;

  @override
  void initState() {
    super.initState();

    if (widget.agendamentoId != null) {
      carregarAgendamento();
    }
  }

  Future<void> carregarAgendamento() async {
    try {
      final documento = await FirebaseFirestore.instance
          .collection('agendamentos')
          .doc(widget.agendamentoId)
          .get();

      if (!documento.exists || documento.data() == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agendamento não encontrado.')),
        );
        Navigator.of(context).pop();
        return;
      }

      final dados = documento.data()!;
      final timestamp = dados['data'] as Timestamp?;
      if (timestamp == null) {
        throw Exception('Data do agendamento inválida.');
      }
      final dataHora = timestamp.toDate();

      final servicos = dados['servicos'] as List<dynamic>? ?? [];

      if (!mounted) return;

      setState(() {
        clienteSelecionadoId = dados['clienteId'] as String?;
        formaPagamentoSelecionada = dados['formaPagamento']?.toString();

        servicosSelecionados
          ..clear()
          ..addAll(
            servicos
                .map((servico) => servico['servicoId']?.toString() ?? '')
                .where((id) => id.isNotEmpty),
          );

        dataSelecionada = DateTime(dataHora.year, dataHora.month, dataHora.day);

        horarioSelecionado = TimeOfDay(
          hour: dataHora.hour,
          minute: dataHora.minute,
        );
      });
    } catch (erro) {
      debugPrint('Erro ao carregar agendamento: $erro');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar agendamento: $erro')),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          carregandoAgendamento = false;
        });
      }
    }
  }

  Widget etapaSelecionarCliente() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('clientes').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Erro ao carregar clientes.'));
        }

        final clientes = snapshot.data?.docs ?? [];

        if (clientes.isEmpty) {
          return const Center(child: Text('Nenhum cliente cadastrado.'));
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2420),
                  ),
                ),
                subtitle: Text(
                  telefone.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5A4940),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget etapaSelecionarServicos() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('servicos').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Erro ao carregar os serviços.'));
        }

        final documentos = snapshot.data?.docs ?? [];

        if (documentos.isEmpty) {
          return const Center(child: Text('Nenhum serviço cadastrado.'));
        }

        return ListView(
          children: documentos.map((documento) {
            final dados = documento.data();
            final nome = dados['nome'] ?? 'Serviço sem nome';
            final valor = (dados['valor'] as num?)?.toDouble() ?? 0;
            final tempo = dados['tempoMedio'] ?? 0;

            return CheckboxListTile(
              value: servicosSelecionados.contains(documento.id),
              title: Text(
                nome.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2420),
                ),
              ),
              subtitle: Text(
                'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}'
                ' • $tempo min',
                style: const TextStyle(fontSize: 14, color: Color(0xFF5A4940)),
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
      initialTime: horarioSelecionado ?? TimeOfDay.now(),
    );

    if (horario != null) {
      setState(() {
        horarioSelecionado = horario;
      });
    }
  }

  Future<void> selecionarData() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: dataSelecionada ?? DateTime.now(),
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
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2420),
          ),
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
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Escolha o horário:',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2420),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: selecionarHorario,
          icon: const Icon(Icons.access_time),
          label: Text(
            horarioSelecionado == null
                ? 'Selecionar horário'
                : horarioSelecionado!.format(context),
            style: const TextStyle(fontSize: 16),
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
            child: Text(
              'Erro ao carregar os dados do cliente.',
              style: TextStyle(fontSize: 16, color: Color(0xFF2C2420)),
            ),
          );
        }

        final cliente = clienteSnapshot.data?.data();

        if (cliente == null) {
          return const Center(
            child: Text(
              'Cliente não encontrado.',
              style: TextStyle(fontSize: 16, color: Color(0xFF2C2420)),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('servicos').snapshots(),
          builder: (context, servicosSnapshot) {
            if (servicosSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (servicosSnapshot.hasError) {
              return const Center(
                child: Text(
                  'Erro ao carregar os serviços.',
                  style: TextStyle(fontSize: 16, color: Color(0xFF2C2420)),
                ),
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
                  style: TextStyle(fontSize: 16, color: Color(0xFF2C2420)),
                ),
              );
            }

            double valorTotal = 0;
            int tempoTotal = 0;

            for (final documento in selecionados) {
              final dados = documento.data();

              valorTotal += (dados['valor'] as num?)?.toDouble() ?? 0;

              tempoTotal += (dados['tempoMedio'] as num?)?.toInt() ?? 0;
            }

            final data = dataSelecionada;
            final horario = horarioSelecionado;

            if (data == null || horario == null) {
              return const Center(
                child: Text(
                  'Data ou horário não definidos.',
                  style: TextStyle(fontSize: 16, color: Color(0xFF2C2420)),
                ),
              );
            }

            final dataFormatada =
                '${data.day.toString().padLeft(2, '0')}/'
                '${data.month.toString().padLeft(2, '0')}/'
                '${data.year}';

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Confira os dados do agendamento',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2420),
                    ),
                  ),
                ),
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEDE0D4),
                    child: Icon(Icons.face_2, color: Color(0xFF6F4E37)),
                  ),
                  title: const Text(
                    'Cliente',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6F554B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    (cliente['apelido'] ?? '').toString().isNotEmpty
                        ? '${cliente['nome']} (${cliente['apelido']})'
                        : (cliente['nome'] ?? 'Sem nome').toString(),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2420),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Icon(Icons.content_cut, size: 20, color: Color(0xFF6F4E37)),
                    SizedBox(width: 8),
                    Text(
                      'Serviços selecionados',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2420),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...selecionados.map((documento) {
                  final dados = documento.data();
                  final nome = (dados['nome'] ?? 'Serviço').toString();
                  final valor = (dados['valor'] as num?)?.toDouble() ?? 0;
                  final tempo = (dados['tempoMedio'] as num?)?.toInt() ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5D7CD)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nome,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C2420),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$tempo minutos',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF5A4940),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C2420),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                seletorFormaPagamento(),
                const Divider(height: 28),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5D7CD)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.payments_outlined,
                                color: Colors.green,
                                size: 24,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Valor total',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C2420),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'R\$ ${valorTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.timelapse,
                                color: Color(0xFF6F4E37),
                                size: 22,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Tempo estimado',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A3B32),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$tempoTotal minutos',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C2420),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.calendar_month,
                                color: Color(0xFF6F4E37),
                                size: 22,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Data',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A3B32),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            dataFormatada,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C2420),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.access_time,
                                color: Color(0xFF6F4E37),
                                size: 22,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Horário',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A3B32),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            horario.format(context),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C2420),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> adicionarFormaPagamento() async {
    final nome = await showDialog<String>(
      context: context,
      builder: (context) => const _FormaPagamentoDialog(),
    );

    if (nome == null || nome.isEmpty) return;

    try {
      final formasPagamento = FirebaseFirestore.instance.collection(
        'formasPagamento',
      );
      final existentes = await formasPagamento.get();
      QueryDocumentSnapshot<Map<String, dynamic>>? formaExistente;
      for (final documento in existentes.docs) {
        final nomeExistente = (documento.data()['nome'] ?? '')
            .toString()
            .trim();
        if (nomeExistente.toLowerCase() == nome.toLowerCase()) {
          formaExistente = documento;
          break;
        }
      }

      final nomeSalvo = formaExistente == null
          ? nome
          : (formaExistente.data()['nome'] ?? nome).toString();

      if (formaExistente == null) {
        await formasPagamento.add({'nome': nome});
      }

      if (mounted) {
        setState(() {
          formaPagamentoSelecionada = nomeSalvo;
        });
      }
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar forma de pagamento: $erro')),
      );
    }
  }

  Widget seletorFormaPagamento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Forma de pagamento (opcional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2420),
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('formasPagamento')
              .orderBy('nome')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                'Erro ao carregar formas de pagamento: ${snapshot.error}',
              );
            }

            final nomes = (snapshot.data?.docs ?? [])
                .map((documento) => documento.data()['nome']?.toString() ?? '')
                .where((nome) => nome.isNotEmpty)
                .toSet()
                .toList();

            final formaAtual = formaPagamentoSelecionada;
            if (formaAtual != null && !nomes.contains(formaAtual)) {
              nomes.add(formaAtual);
            }

            return Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: formaAtual,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Selecione uma forma',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Não informada'),
                      ),
                      ...nomes.map(
                        (nome) => DropdownMenuItem<String>(
                          value: nome,
                          child: Text(nome),
                        ),
                      ),
                    ],
                    onChanged: (forma) {
                      setState(() {
                        formaPagamentoSelecionada = forma;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: adicionarFormaPagamento,
                  tooltip: 'Adicionar forma de pagamento',
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<bool> verificarConflito(DateTime novaData, int novoTempo) async {
    final novaDataFinal = novaData.add(Duration(minutes: novoTempo));

    final inicioDia = DateTime(novaData.year, novaData.month, novaData.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    // Busca apenas os agendamentos daquele dia para melhor performance e menor custo
    final snapshot = await FirebaseFirestore.instance
        .collection('agendamentos')
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
        .where('data', isLessThan: Timestamp.fromDate(fimDia))
        .get();

    for (final documento in snapshot.docs) {
      // Na edição, ignora o próprio agendamento.
      if (documento.id == widget.agendamentoId) {
        continue;
      }

      final dados = documento.data();

      // Considera apenas agendamentos com status "agendado"
      if (dados['status'] != 'agendado') {
        continue;
      }

      final timestamp = dados['data'] as Timestamp?;
      if (timestamp == null) {
        continue;
      }

      final inicioExistente = timestamp.toDate();
      final tempoExistente = (dados['tempoTotal'] as num?)?.toInt() ?? 0;

      final fimExistente = inicioExistente.add(
        Duration(minutes: tempoExistente),
      );

      // Verifica se os intervalos se sobrepõem.
      final existeConflito =
          novaData.isBefore(fimExistente) &&
          novaDataFinal.isAfter(inicioExistente);

      if (existeConflito) {
        return true;
      }
    }

    return false;
  }

  Future<bool> confirmarConflito() async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Atenção: conflito de horário'),
          content: const Text(
            'Já existe um atendimento nesse intervalo. '
            'Deseja continuar mesmo assim?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Escolher outro horário'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Continuar mesmo assim'),
            ),
          ],
        );
      },
    );

    return resultado ?? false;
  }

  Future<void> salvarAgendamento() async {
    if (salvandoAgendamento) return;

    if (clienteSelecionadoId == null ||
        dataSelecionada == null ||
        horarioSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todas as etapas antes de finalizar.'),
        ),
      );
      return;
    }

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

      final temConflito = await verificarConflito(dataHora, tempoTotal);

      if (temConflito) {
        if (!mounted) return;

        final continuar = await confirmarConflito();

        if (!continuar) {
          setState(() {
            etapaAtual = 2; // Volta para a etapa de seleção de data e horário
          });
          return;
        }
      }

      // Referência à coleção de agendamentos.
      final colecao = FirebaseFirestore.instance.collection('agendamentos');

      // Dados que podem ser alterados na edição.
      final dadosAgendamento = {
        'clienteId': clienteSelecionadoId,
        'clienteNome': cliente['nome'] ?? '',
        'servicos': listaServicos,
        'formaPagamento': formaPagamentoSelecionada,
        'valorTotal': valorTotal,
        'tempoTotal': tempoTotal,
        'data': Timestamp.fromDate(dataHora),
      };

      if (widget.agendamentoId == null) {
        // Cadastro: cria um novo documento.
        await colecao.add({
          ...dadosAgendamento,
          'criadoEm': FieldValue.serverTimestamp(),
          'status': 'agendado',
        });
      } else {
        // Edição: atualiza o documento existente.
        await colecao.doc(widget.agendamentoId).update(dadosAgendamento);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.agendamentoId == null
                ? 'Agendamento salvo com sucesso!'
                : 'Agendamento atualizado com sucesso!',
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar agendamento: $e')));
    } finally {
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
        const SnackBar(content: Text('Selecione um cliente para continuar.')),
      );
      return;
    }

    if (etapaAtual == 1 && servicosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um serviço.')),
      );
      return;
    }

    if (etapaAtual == 2 &&
        (dataSelecionada == null || horarioSelecionado == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a data e o horário.')),
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
    if (carregandoAgendamento) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: !salvandoAgendamento,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.agendamentoId == null
                ? 'Novo Agendamento'
                : 'Editar Agendamento',
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Etapa ${etapaAtual + 1} de 4',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A3B32),
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: (etapaAtual + 1) / 4,
                backgroundColor: const Color(0xFFE2D5CC),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF8B5E4D),
                ),
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 24),
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
                    color: Color(0xFF2C2420),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: etapaAtual == 0
                    ? etapaSelecionarCliente()
                    : etapaAtual == 1
                    ? etapaSelecionarServicos()
                    : etapaAtual == 2
                    ? etapaSelecionarDataHorario()
                    : etapaConfirmarAgendamento(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (etapaAtual > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: salvandoAgendamento ? null : voltarEtapa,
                        child: const Text('Voltar'),
                      ),
                    ),
                  if (etapaAtual > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
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
                                color: Colors.white,
                              ),
                            )
                          : Text(etapaAtual == 3 ? 'Finalizar' : 'Continuar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormaPagamentoDialog extends StatefulWidget {
  const _FormaPagamentoDialog();

  @override
  State<_FormaPagamentoDialog> createState() => _FormaPagamentoDialogState();
}

class _FormaPagamentoDialogState extends State<_FormaPagamentoDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar forma de pagamento'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Nome',
          hintText: 'Ex.: Pix, dinheiro ou cartão',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}
