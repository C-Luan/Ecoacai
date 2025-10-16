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

  // Função Original: Busca a stream de coletas do posto do usuário logado
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



      // 🔹 Cria stream filtrando por ID do posto (mantendo a lógica original)
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

  // Função Original: Busca dados do posto
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

  // --------------------------------------------------------------------------
  // NOVAS FUNÇÕES DE MANIPULAÇÃO (DELETE E UPDATE)
  // --------------------------------------------------------------------------

  // NOVO: Função para deletar uma solicitação
  Future<void> _deleteSolicitation(String docId) async {
    try {
      await _firestore.collection('solicitacoes').doc(docId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agendamento excluído com sucesso.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir agendamento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NOVO: Função para salvar a nova data de agendamento
  Future<void> _updateSolicitationDate(String docId, DateTime newDate) async {
    try {
      // Converte a nova data (local 00:00:00) para UTC para salvar
      final newDateUtc = newDate.toUtc();

      await _firestore.collection('solicitacoes').doc(docId).update({
        'dataSolicitacao': Timestamp.fromDate(newDateUtc),
      });

      // Se bem-sucedido, fechar o modal e mostrar feedback
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Data de agendamento alterada para ${DateFormat('dd/MM/yyyy').format(newDate)}.'),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
    } catch (e) {
      // Garante o fechamento do modal e mostra erro
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar agendamento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NOVO: Abre o modal para alterar a data
  void _showEditDialog(String docId, DateTime currentDate) {
    // Inicializa a data selecionada com a data atual (apenas dia, mês, ano)
    DateTime? tempSelectedDate =
        DateTime(currentDate.year, currentDate.month, currentDate.day);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alterar Data de Coleta'),
          content: StatefulBuilder(
            builder: (context, setStateSB) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      'Data atual: ${DateFormat('dd/MM/yyyy').format(currentDate)}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        // Sugere a data atual se ela for futura, senão sugere hoje
                        initialDate: currentDate.isBefore(DateTime.now().subtract(const Duration(days: 1))) 
                            ? DateTime.now() 
                            : currentDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(DateTime.now().year + 2),
                        locale: const Locale('pt', 'BR'),
                        // Permite apenas datas a partir de hoje
                        selectableDayPredicate: (date) {
                          return date.isAfter(
                              DateTime.now().subtract(const Duration(days: 1)));
                        },
                      );
                      if (picked != null) {
                        setStateSB(() {
                          tempSelectedDate = picked;
                        });
                      }
                    },
                    child: Text(
                      tempSelectedDate == null ||
                              (tempSelectedDate!.day == currentDate.day &&
                                  tempSelectedDate!.month == currentDate.month &&
                                  tempSelectedDate!.year == currentDate.year)
                          ? 'Selecionar Nova Data'
                          : 'Nova Data: ${DateFormat('dd/MM/yyyy').format(tempSelectedDate!)}',
                    ),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              // Habilita o botão se uma nova data diferente foi selecionada
              onPressed: tempSelectedDate != null &&
                      (tempSelectedDate!.day != currentDate.day ||
                          tempSelectedDate!.month != currentDate.month ||
                          tempSelectedDate!.year != currentDate.year)
                  ? () => _updateSolicitationDate(docId, tempSelectedDate!)
                  : null,
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // WIDGET BUILD COM DISMISSIBLE E BOTÃO DE EDIÇÃO
  // --------------------------------------------------------------------------

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
              final doc = solicitacoes[index];
              final docId = doc.id;
              final data = doc.data();

              final postoRef = data['postoId'];
              final status = data['status'] ?? 'Pendente';
              final bool isCompleted = status == 'Concluída';
              // Permite edição/exclusão se não estiver concluída
              final bool isEditable =
                  status == 'Agendada' || status == 'Pendente'; 

              final Timestamp? timestamp = data['dataSolicitacao'] as Timestamp?;

              // Converte o Timestamp UTC para a data/hora local para exibição e edição
              final DateTime localDate =
                  timestamp != null ? timestamp.toDate().toLocal() : DateTime.now();

              final String formattedDate = timestamp != null
                  ? DateFormat("d 'de' MMMM 'de' yyyy").format(localDate)
                  : 'Data não informada';

              // 🔹 Implementação do arrastar para deletar (Dismissible)
              return Dismissible(
                key: Key(docId),
                // Só permite swipe se for editável
                direction:
                    isEditable ? DismissDirection.endToStart : DismissDirection.none,
                
                // Confirma a exclusão (mostra o AlertDialog)
                confirmDismiss: (direction) async {
                  if (!isEditable) return false;
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirmar Exclusão"),
                        content: Text(
                            "Tem certeza que deseja excluir o agendamento de $formattedDate?"),
                        actions: <Widget>[
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text("Cancelar")),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Excluir",
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
                
                // Ação de exclusão
                onDismissed: (direction) {
                  _deleteSolicitation(docId);
                },
                
                // Visual do fundo do swipe
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                
                // O conteúdo real do item
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: postoRef != null ? _buscarPosto(postoRef) : null,
                  builder: (context, postoSnapshot) {
                    final postoData = postoSnapshot.data;
                    final nomePosto = postoData?['nome'] ?? 'Posto Desconhecido';
                    final quantidade = (data['quantidadeEstimada'] as num?)
                            ?.toStringAsFixed(1) ??
                        '0.0';

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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
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
                            
                            // 🔹 Botão de Edição (Apenas se for editável)
                            // if (isEditable)
                            //   IconButton(
                            //     icon: const Icon(Icons.edit, color: Colors.blue),
                            //     onPressed: () =>
                            //         _showEditDialog(docId, localDate),
                            //   ),
                              
                            const SizedBox(width: 8.0),
                            Text(
                              '$quantidade kg',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}