import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Estado para os dados
  String _userName = 'Cidadão';
  int _totalCollections = 0;
  double _totalWeight = 0.0;
  String _nextCollectionDate = 'Carregando...';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Define a localização para formatação de data
    Intl.defaultLocale = 'pt_BR';
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Nenhum usuário logado.';
          _isLoading = false;
        });
        return;
      }

      // 1. Busca o nome do usuário
      final cidadaoDoc = await _firestore.collection('cidadaos').doc(user.uid).get();
      if (cidadaoDoc.exists) {
        _userName = cidadaoDoc.data()?['nome'] ?? 'Cidadão';
      }

      // 2. Busca os postos de coleta do usuário
      final postosSnapshot = await _firestore.collection('postos')
          .where('cidadaoId', isEqualTo: user.uid)
          .get();
      final List<String> postoIds = postosSnapshot.docs.map((doc) => doc.id).toList();

      if (postoIds.isNotEmpty) {
        // 3. Busca as solicitações de coleta relacionadas aos postos
        final solicitacoesSnapshot = await _firestore.collection('solicitacoes')
            .where('postoId', whereIn: postoIds)
            .get();

        int totalCollectionsCount = 0;
        double totalWeightCount = 0.0;
        DateTime? nextCollection;
        final now = DateTime.now();

        for (var doc in solicitacoesSnapshot.docs) {
          final data = doc.data();
          totalCollectionsCount++;
          totalWeightCount += (data['quantidadeEstimada'] as num?)?.toDouble() ?? 0.0;
          
          final dataSolicitacao = (data['dataSolicitacao'] as Timestamp?)?.toDate();
          if (dataSolicitacao != null && dataSolicitacao.isAfter(now)) {
            if (nextCollection == null || dataSolicitacao.isBefore(nextCollection)) {
              nextCollection = dataSolicitacao;
            }
          }
        }
        _totalCollections = totalCollectionsCount;
        _totalWeight = totalWeightCount;
        if (nextCollection != null) {
          _nextCollectionDate = DateFormat('d \'de\' MMMM', 'pt_BR').format(nextCollection);
        } else {
          _nextCollectionDate = 'Nenhuma agendada';
        }
      } else {
        _totalCollections = 0;
        _totalWeight = 0.0;
        _nextCollectionDate = 'Nenhuma agendada';
      }

      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Falha ao carregar dados: $e';
        _isLoading = false;
      });
      debugPrint('Erro ao carregar dados do dashboard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, $_userName!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24.0),
            // Cards de Resumo
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    title: 'Coletas Realizadas',
                    value: _totalCollections.toString(),
                    icon: Icons.shield_outlined,
                    iconColor: Theme.of(context).primaryColor,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.05),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    title: 'Resíduos Entregues',
                    value: '${_totalWeight.toStringAsFixed(1)} kg',
                    icon: Icons.inventory_2_outlined,
                    iconColor: Theme.of(context).colorScheme.secondary,
                    backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            // Resumo do Mês
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo do Mês',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Média por coleta',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          '${(_totalWeight / (_totalCollections > 0 ? _totalCollections : 1)).toStringAsFixed(1)} kg',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Próxima coleta',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          _nextCollectionDate,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, {
        required String title,
        required String value,
        required IconData icon,
        required Color iconColor,
        required Color backgroundColor,
      }) {
    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(icon, color: iconColor, size: 32.0),
            ),
            const SizedBox(height: 8.0),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
