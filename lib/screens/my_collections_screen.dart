import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MyCollectionsScreen extends StatefulWidget {
  const MyCollectionsScreen({super.key});

  @override
  State<MyCollectionsScreen> createState() => _MyCollectionsScreenState();
}

class _MyCollectionsScreenState extends State<MyCollectionsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Variável para armazenar o stream de dados
  Stream<QuerySnapshot<Map<String, dynamic>>>? _collectionsStream;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'pt_BR';
    _fetchCollectionsStream();
  }

  Future<void> _fetchCollectionsStream() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Nenhum usuário logado.';
          _isLoading = false;
        });
        return;
      }

      // 1. Busca os postos de coleta do usuário
      final postosSnapshot = await _firestore.collection('postos')
          .where('cidadaoId', isEqualTo: user.uid)
          .get();
      final List<String> postoIds = postosSnapshot.docs.map((doc) => doc.id).toList();

      if (postoIds.isNotEmpty) {
        // 2. Cria um stream para as solicitações de coleta relacionadas aos postos
        // O `onSnapshot` permite que a lista seja atualizada em tempo real.
        setState(() {
          _collectionsStream = _firestore.collection('solicitacoes')
              .where('postoId', whereIn: postoIds)
              .orderBy('dataSolicitacao', descending: true)
              .snapshots();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Falha ao carregar coletas: $e';
        _isLoading = false;
      });
      debugPrint('Erro ao buscar stream de coletas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(child: Text(_errorMessage!)),
      );
    }
    
    // Constrói a tela com o stream de dados
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Coletas'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _collectionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma coleta agendada.'));
          }
          
          final collections = snapshot.data!.docs;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final collection = collections[index].data() as Map<String, dynamic>;
              final bool isCompleted = collection['status'] == 'Concluida';
              final Timestamp? timestamp = collection['dataSolicitacao'] as Timestamp?;
              final String formattedDate = timestamp != null
                  ? DateFormat('d \'de\' MMMM \'de\' yyyy').format(timestamp.toDate())
                  : 'Data não informada';

              return Card(
                color: isCompleted ? Colors.green[50] : Colors.blue[50],
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle_outline : Icons.schedule,
                        color: isCompleted
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).primaryColor,
                        size: 32.0,
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              collection['status'],
                              style: TextStyle(
                                color: isCompleted
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(collection['quantidadeEstimada'] as num?)?.toStringAsFixed(1) ?? '0.0'} kg',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
