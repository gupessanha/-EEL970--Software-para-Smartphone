import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class Tarefa {
  String titulo;
  bool concluida;
  bool emExclusao;
  DateTime? timestampConclusao;

  Tarefa({
    required this.titulo,
    this.concluida = false,
    this.emExclusao = false,
    this.timestampConclusao,
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Tarefas',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  final List<Tarefa> _tarefas = [];

  void _adicionarTarefa() {
    String texto = _controller.text.trim();
    if (texto.isEmpty) return;

    bool jaExiste = _tarefas.any((t) => t.titulo == texto);
    if (jaExiste) return;

    setState(() {
      _tarefas.insert(0, Tarefa(titulo: texto));
      _controller.clear();
    });
  }

  void _removerTarefa(int index) {
    setState(() {
      _tarefas[index].emExclusao = true;
    });

    Future.delayed(Duration(seconds: 3), () {
      if (!mounted) return;
      if (_tarefas.length > index && _tarefas[index].emExclusao) {
        setState(() {
          _tarefas.removeAt(index);
        });
      }
    });
  }

  void _desfazerRemocao(int index) {
    setState(() {
      _tarefas[index].emExclusao = false;
    });
  }

  void _alternarConclusao(int index) {
    setState(() {
      final tarefa = _tarefas[index];

      tarefa.concluida = !tarefa.concluida;
      tarefa.timestampConclusao = tarefa.concluida ? DateTime.now() : null;

      _tarefas.removeAt(index);

      final naoConcluidas = _tarefas.where((t) => !t.concluida).toList();
      final concluidas = _tarefas.where((t) => t.concluida).toList()
        ..sort(
          (a, b) => b.timestampConclusao!.compareTo(a.timestampConclusao!),
        );

      if (tarefa.concluida) {
        concluidas.insert(0, tarefa);
      } else {
        naoConcluidas.add(tarefa);
      }

      _tarefas
        ..clear()
        ..addAll(naoConcluidas + concluidas);
    });
  }

  Widget _construirItem(Tarefa tarefa, int index, bool isEven) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tarefa.emExclusao
            ? Colors.red[100]
            : (isEven ? Colors.blue[50] : Colors.white),
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(
              51,
              158,
              158,
              158,
            ), // equivalente a grey[600] com 20% de opacidade
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: tarefa.concluida,
            onChanged: tarefa.emExclusao
                ? null
                : (_) => _alternarConclusao(index),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tarefa.titulo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: tarefa.emExclusao ? Colors.red : null,
                    decoration: tarefa.concluida
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (tarefa.timestampConclusao != null)
                  Text(
                    'Concluída em: ${tarefa.timestampConclusao}',
                    style: TextStyle(
                      fontSize: 12,
                      color: tarefa.emExclusao ? Colors.red : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          tarefa.emExclusao
              ? TextButton(
                  onPressed: () => _desfazerRemocao(index),
                  child: Text('Desfazer'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                )
              : IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removerTarefa(index),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lista de Tarefas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _adicionarTarefa(),
                    decoration: InputDecoration(
                      labelText: 'Nova Tarefa',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _adicionarTarefa,
                  child: Text('Incluir'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tarefas.length,
              itemBuilder: (context, index) {
                final tarefa = _tarefas[index];
                final isEven = index % 2 == 0;

                return Dismissible(
                  key: ValueKey(tarefa.titulo + index.toString()),
                  direction: DismissDirection.horizontal,
                  background: Container(
                    color: Colors.green,
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: 20),
                    child: Icon(Icons.check, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    if (tarefa.emExclusao) return false;

                    if (direction == DismissDirection.startToEnd) {
                      _alternarConclusao(index);
                      return false;
                    } else {
                      _removerTarefa(index);
                      return false;
                    }
                  },
                  child: _construirItem(tarefa, index, isEven),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
