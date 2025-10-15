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

      // 🔹 Busca referências dos postos do cidadão logado
      final postosSnapshot = await _firestore
          .collection('postos')
          .where('cidadaoId', isEqualTo: user.uid)
          .limit(1)
          .get();

      final postoRefs = postosSnapshot.docs
          .map((doc) => doc.reference)
          .toList();

      if (postoRefs.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 🔹 Cria stream filtrando por referências (não por ID string)
      setState(() {
        _collectionsStream = _firestore
            .collection('solicitacoes')
            .where('postoId', isEqualTo: postosSnapshot.docs.first.id)
            .orderBy('dataSolicitacao', descending: true)
            .snapshots();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Falha ao carregar coletas: $e';
        _isLoading = false;
      });
      debugPrint('Erro ao buscar stream de coletas: $e');
    }
  }

  Future<Map<String, dynamic>?> _buscarPosto(String postoRef) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('postos')
          .doc(postoRef)
          .get();
      return snapshot.data();
    } catch (e) {
      debugPrint('Erro ao buscar posto: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(body: Center(child: Text(_errorMessage!)));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Coletas'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

          final solicitacoes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: solicitacoes.length,
            itemBuilder: (context, index) {
              final data = solicitacoes[index].data();

              final postoRef = data['postoId'];
              final status = data['status'] ?? 'Pendente';
              final bool isCompleted = status == 'Concluída';
              final Timestamp? timestamp =
                  data['dataSolicitacao'] as Timestamp?;
              final String formattedDate = timestamp != null
                  ? DateFormat(
                      "d 'de' MMMM 'de' yyyy",
                    ).format(timestamp.toDate())
                  : 'Data não informada';

              return FutureBuilder<Map<String, dynamic>?>(
                future: postoRef != null ? _buscarPosto(postoRef) : null,
                builder: (context, postoSnapshot) {
                  final postoData = postoSnapshot.data;
                  final nomePosto = postoData?['nome'] ?? 'Posto Desconhecido';

                  return Card(
                    color: isCompleted ? Colors.green[50] : Colors.blue[50],
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.check_circle_outline
                                : Icons.schedule,
                            color: isCompleted
                                ? Colors.green
                                : Theme.of(context).primaryColor,
                            size: 32.0,
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nomePosto,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  formattedDate,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: isCompleted
                                        ? Colors.green
                                        : Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${(data['quantidadeEstimada'] as num?)?.toStringAsFixed(1) ?? '0.0'} kg',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
