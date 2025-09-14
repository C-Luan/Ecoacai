import 'package:flutter/material.dart';

class MyCollectionsScreen extends StatelessWidget {
  const MyCollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> collections = [
      {'date': '12 de Janeiro', 'status': 'Concluída', 'quantity': 25.0},
      {'date': '15 de Janeiro', 'status': 'Agendada', 'quantity': 30.0},
      {'date': '8 de Janeiro', 'status': 'Concluída', 'quantity': 18.0},
      {'date': '5 de Janeiro', 'status': 'Concluída', 'quantity': 22.0},
    ];

    return Scaffold(
 
      appBar: AppBar(
        title: const Text('Minhas Coletas'),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: collections.length,
        itemBuilder: (context, index) {
          final collection = collections[index];
          final bool isCompleted = collection['status'] == 'Concluída';

          return Card(
            color:isCompleted? Colors.green[50]:Colors.blue[50],
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
                          collection['date'],
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
                    '${collection['quantity']} kg',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}