// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'services/user_service.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Teste FastAPI',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
//         useMaterial3: true,
//       ),
//       home: const MyHomePage(title: 'Conexão Flutter + FastAPI'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});
//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   String _mensagem = 'Aguardando requisição...';
//   bool _carregando = false;

//   Future<void> _buscarUsuarios() async {
//     setState(() {
//       _carregando = true;
//       _mensagem = 'Buscando usuários no banco...';
//     });

//     // A tela não sabe o que é HTTP ou IP, ela só pede os dados para o Service!
//     final users = await UserService.fetchUsers();

//     setState(() {
//       if (users == null) {
//         _mensagem = "Falha na conexão. O servidor está rodando?";
//       } else if (users.isEmpty) {
//         _mensagem = "Conexão de sucesso!\nMas a tabela de usuários está vazia.";
//       } else {
//         String resultado = "Usuários encontrados:\n\n";
//         for (var user in users) {
//           resultado +=
//               "👤 Nome: ${user['full_name']}\n📧 E-mail: ${user['email']}\n\n";
//         }
//         _mensagem = resultado;
//       }
//       _carregando = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         centerTitle: true,
//         title: Text(
//           widget.title,
//           style: const TextStyle(fontWeight: FontWeight.w400),
//         ),
//       ),
//       // Adicionado SingleChildScrollView para permitir rolagem se a lista for grande
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 width: double.infinity, // Ocupa toda a largura disponível
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.05),
//                       blurRadius: 10,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: _carregando
//                     ? const Center(
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                     : Text(
//                         _mensagem,
//                         // Alinhado à esquerda para a lista ficar mais fácil de ler
//                         textAlign: TextAlign.left,
//                         style: const TextStyle(
//                           fontSize: 16,
//                           height: 1.5,
//                           color: Colors.black87,
//                         ),
//                       ),
//               ),
//               const SizedBox(
//                 height: 80,
//               ), // Espaço para não ficar embaixo do botão
//             ],
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: _carregando ? null : _buscarUsuarios,
//         elevation: 2,
//         icon: const Icon(Icons.search),
//         label: const Text('Buscar Usuários'),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//     );
//   }
// }
