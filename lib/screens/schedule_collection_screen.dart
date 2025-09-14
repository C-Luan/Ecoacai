import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleCollectionScreen extends StatefulWidget {
  const ScheduleCollectionScreen({super.key});

  @override
  State<ScheduleCollectionScreen> createState() =>
      _ScheduleCollectionScreenState();
}

class _ScheduleCollectionScreenState extends State<ScheduleCollectionScreen> {
  DateTime? _selectedDate;
  final List<int> _availableDays = [5, 8, 12, 15, 19, 22, 26, 29];
  DateTime _focusedDay = DateTime.now();
  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Garante que o mês focado é o mês atual ao iniciar.
    _focusedDay = DateTime.now();
  }

  void _confirmSchedule() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma data para o agendamento.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Coleta agendada para ${DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDate!)}.'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
    Navigator.pop(context);
  }

  bool _isDateAvailable(DateTime date) {
    // Bloqueia datas passadas
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return false;
    }
    // Verifica se o dia do mês está na lista de dias disponíveis
    return _availableDays.contains(date.day);
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
            _buildCalendar(),
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
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24.0),
            FilledButton(
              onPressed: _selectedDate != null ? _confirmSchedule : null,
              style: FilledButton.styleFrom(
                backgroundColor: _selectedDate != null ? const Color(0xFF059669) : Colors.grey.shade400,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar Agendamento'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    // Calcula o primeiro dia do mês focado
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    // Calcula o último dia do mês focado
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    // Quantidade de dias no mês focado
    final daysInMonth = lastDayOfMonth.day;
    // Dia da semana do primeiro dia do mês (1 para segunda, 7 para domingo)
    final firstWeekday = firstDayOfMonth.weekday; // De 1 (segunda) a 7 (domingo)

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
                      _selectedDate = null; // Limpa a seleção ao mudar de mês
                    });
                  },
                ),
                Text(
                  // Exibe o mês e ano formatados
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
                      _selectedDate = null; // Limpa a seleção ao mudar de mês
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            // Cabeçalho dos dias da semana
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
              itemCount: (firstWeekday % 7) + daysInMonth, // Total de células a serem preenchidas
              itemBuilder: (context, index) {
                // Calcula o dia do mês para a célula atual
                final day = index - (firstWeekday % 7) + 1; // Ajusta para domingo ser o primeiro dia da semana (índice 0)

                if (day <= 0 || day > daysInMonth) {
                  return const SizedBox(); // Células vazias para preencher o início ou fim do GridView
                }

                final date = DateTime(_focusedDay.year, _focusedDay.month, day);
                final isAvailable = _isDateAvailable(date);
                final isSelected = _selectedDate != null &&
                    date.day == _selectedDate!.day &&
                    date.month == _selectedDate!.month &&
                    date.year == _selectedDate!.year;

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
                      child: Text(
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