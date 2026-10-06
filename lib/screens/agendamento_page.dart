import 'package:agendamentos_app/firebase/database.dart';
import 'package:flutter/material.dart';

class NovoAgendamentoScreen extends StatefulWidget {
  const NovoAgendamentoScreen({super.key});

  @override
  State<NovoAgendamentoScreen> createState() => _NovoAgendamentoScreenState();
}

class _NovoAgendamentoScreenState extends State<NovoAgendamentoScreen> {
  final database = Database();
  final List<String> clientes = [
    'Maria',
    'João',
    'Ana',
    'Carlos',
  ];

  final List<String> servicos = [
    'Corte',
    'Manicure',
    'Pedicure',
    'Massagem',
  ];

  String? clienteSelecionado;
  DateTime? dataSelecionada;
  TimeOfDay? horarioSelecionado;
  String? servicoSelecionado;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Agendamento'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cliente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Selecione o cliente',
              ),

              initialValue: clienteSelecionado,

              items: clientes.map((cliente) {
                return DropdownMenuItem<String>(
                  value: cliente,
                  child: Text(cliente),
                );
              }).toList(),

              onChanged: (valor) {
                setState(() {
                  clienteSelecionado = valor;
                });
              },
            ),
            const Text(
              'Serviço',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Selecione o serviço',
              ),

              initialValue: servicoSelecionado,

              items: servicos.map((servico) {
                return DropdownMenuItem<String>(
                  value: servico,
                  child: Text(servico),
                );
              }).toList(),

              onChanged: (valor) {
                setState(() {
                  servicoSelecionado = valor;
                });
              },
            ),
            const SizedBox(height:20),
            const Text(
              'Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            TextFormField(
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Selecione a data',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              controller: TextEditingController(
                text:dataSelecionada == null
                    ? ''
                    :'${dataSelecionada!.day}/${dataSelecionada!.month}/${dataSelecionada!.year}',
              ),
              onTap: () {
                selecionarData();
              },
            ),
            const SizedBox(height:20),
            const Text(
              'Horário',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Selecione o horário',
                suffixIcon: Icon(Icons.access_time),
              ),
              controller: TextEditingController(
                text: horarioSelecionado == null
                    ? ''
                    :'${horarioSelecionado!.hour}:${horarioSelecionado!.minute}',
              ),
              onTap: () {
                selecionarHorario();
              },
            ),
            
            
          ],
        ),
      ),
    );
  }
}