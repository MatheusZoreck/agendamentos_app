import 'package:flutter/material.dart';
import 'novo_agendamento_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamentos'),
      ),

      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NovoAgendamentoScreen(),
              ),
            );
          },
          child: const Text('Novo Agendamento'),
        ),
      ),
    );
  }
}