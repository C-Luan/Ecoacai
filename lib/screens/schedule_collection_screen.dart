import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleCollectionScreen extends StatefulWidget {
  const ScheduleCollectionScreen({super.key});

  @override
  State<ScheduleCollectionScreen> createState() =>
      _ScheduleCollectionScreenState();
}

class _ScheduleCollectionScreenState extends State<ScheduleCollectionScreen> {
  DateTime? _selectedDate;
  DateTime _focusedDay = DateTime.now();
  final _quantityController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSaving = false;
  bool _isLoadingCounts = true;
  Map<int, int> _collectionCounts = {};

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'pt_BR';
    _focusedDay = DateTime.now();
    _fetchCollectionCountsForMonth(_focusedDay);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  // Função para buscar a contagem de coletas para o mês em foco
  Future<void> _fetchCollectionCountsForMonth(DateTime month) async {
    setState(() {
      _isLoadingCounts = true;
    });

    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    try {
      final snapshot = await _firestore
          .collection('solicitacoes')
          .where('dataSolicitacao', isGreaterThanOrEqualTo: startOfMonth)
          .where('dataSolicitacao', isLessThanOrEqualTo: endOfMonth)
          .get();

      final Map<int, int> counts = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('dataSolicitacao')) {
          final Timestamp timestamp = data['dataSolicitacao'];
          final day = timestamp.toDate().day;
          counts[day] = (counts[day] ?? 0) + 1;
        }
      }
      setState(() {
        _collectionCounts = counts;
      });
    } catch (e) {
      debugPrint('Erro ao buscar contagem de coletas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar os dias disponíveis: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingCounts = false;
      });
    }
  }

  // Função para salvar o agendamento no Firebase
  Future<void> _scheduleCollection() async {
    final user = _auth.currentUser;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma data para o agendamento.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Nenhum usuário logado.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 1. Busca o posto de coleta do usuário
      final postoSnapshot = await _firestore.collection('postos')
          .where('cidadaoId', isEqualTo: user.uid)
          .get();

      if (postoSnapshot.docs.isEmpty) {
        throw Exception('Nenhum posto de coleta encontrado para o seu perfil. Por favor, cadastre um.');
      }

      final postoId = postoSnapshot.docs.first.id;

      // 2. Cria o novo documento de solicitação
      final double quantidade = double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0.0;
      final newSolicitacao = {
        'postoId': postoId,
        'dataSolicitacao': Timestamp.fromDate(_selectedDate!),
        'quantidadeEstimada': quantidade,
        'status': 'Agendada',
        'dataCriacao': FieldValue.serverTimestamp(),
      };

      // 3. Adiciona o documento na coleção 'solicitacoes'
      await _firestore.collection('solicitacoes').add(newSolicitacao);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Coleta agendada para ${DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDate!)}.'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro do Firebase: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao agendar coleta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  bool _isDateAvailable(DateTime date) {
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return false;
    }
    final count = _collectionCounts[date.day] ?? 0;
    return count < 50;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Coleta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _isLoadingCounts
                ? const Center(child: CircularProgressIndicator())
                : _buildCalendar(),
            const SizedBox(height: 24.0),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantidade de Resíduos (opcional)',
                hintText: 'Ex: 25 kg',
                prefixIcon: const Icon(Icons.scale_outlined),
                suffixText: 'kg',
                suffixStyle: Theme.of(context).textTheme.bodyLarge,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24.0),
            FilledButton(
              onPressed: _isSaving || _selectedDate == null ? null : _scheduleCollection,
              style: FilledButton.styleFrom(
                backgroundColor: _selectedDate != null ? const Color(0xFF059669) : Colors.grey.shade400,
                foregroundColor: Colors.white,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Confirmar Agendamento'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;

    return Card(
      color: Colors.blueGrey[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                      _selectedDate = null;
                      _fetchCollectionCountsForMonth(_focusedDay);
                    });
                  },
                ),
                Text(
                  DateFormat.yMMMM('pt_BR').format(_focusedDay),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                      _selectedDate = null;
                      _fetchCollectionCountsForMonth(_focusedDay);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                'Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'
              ].map((day) => Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))).toList(),
            ),
            const SizedBox(height: 8.0),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: (firstWeekday % 7) + daysInMonth,
              itemBuilder: (context, index) {
                final day = index - (firstWeekday % 7) + 1;

                if (day <= 0 || day > daysInMonth) {
                  return const SizedBox();
                }

                final date = DateTime(_focusedDay.year, _focusedDay.month, day);
                final isAvailable = _isDateAvailable(date);
                final isSelected = _selectedDate != null &&
                    date.day == _selectedDate!.day &&
                    date.month == _selectedDate!.month &&
                    date.year == _selectedDate!.year;
                
                final count = _collectionCounts[date.day] ?? 0;

                return GestureDetector(
                  onTap: isAvailable
                      ? () {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).colorScheme.secondary : (isAvailable ? Theme.of(context).colorScheme.secondary.withOpacity(0.1) : Colors.transparent),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: isAvailable ? Theme.of(context).colorScheme.secondary : Colors.transparent,
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : isAvailable
                                      ? Theme.of(context).textTheme.bodyLarge?.color
                                      : Colors.grey[400],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (isAvailable && count > 0)
                            Text(
                              '$count/50',
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? Colors.white70 : Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
