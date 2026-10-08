import 'package:agendamentos_app/screens/servico_page.dart';
import 'package:flutter/material.dart';
import 'agendamento_page.dart';
import 'cliente_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  
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

      body: 
         Center(
           child: FloatingActionButton(
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