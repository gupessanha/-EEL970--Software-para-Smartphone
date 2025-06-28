import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// Modelos de dados
class Conversa {
  final String id;
  final DateTime criacao;
  final DateTime ultimaAlteracao;
  final List<Mensagem> mensagens;
  final Map<String, dynamic>? atributos;

  Conversa({
    required this.id,
    required this.criacao,
    required this.ultimaAlteracao,
    required this.mensagens,
    this.atributos,
  });

  factory Conversa.fromJson(Map<String, dynamic> json) {
    return Conversa(
      id: json['id'],
      criacao: DateTime.parse(json['criacao']),
      ultimaAlteracao: DateTime.parse(json['ultima_alteracao']),
      mensagens: (json['mensagens'] as List)
          .map((m) => Mensagem.fromJson(m))
          .toList(),
      atributos: json['atributos'],
    );
  }
}

class Mensagem {
  final String papel;
  final String conteudo;

  Mensagem({
    required this.papel,
    required this.conteudo,
  });

  factory Mensagem.fromJson(Map<String, dynamic> json) {
    return Mensagem(
      papel: json['papel'],
      conteudo: json['conteudo'],
    );
  }
}

class Tarefa {
  String titulo;
  bool concluida;
  DateTime? timestampConclusao;

  Tarefa({
    required this.titulo,
    this.concluida = false,
    this.timestampConclusao,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tarefa &&
          runtimeType == other.runtimeType &&
          titulo == other.titulo;

  @override
  int get hashCode => titulo.hashCode;

  factory Tarefa.fromJson(Map<String, dynamic> json) {
    return Tarefa(
      titulo: json['titulo'],
      concluida: json['concluida'] ?? false,
      timestampConclusao: json['timestampConclusao'] != null
          ? DateTime.parse(json['timestampConclusao'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'concluida': concluida,
      'timestampConclusao': timestampConclusao?.toIso8601String(),
    };
  }
}

// Serviço de API
class ApiService {
  static const String baseUrl = 'https://barra.cos.ufrj.br/rest';
  String? _token;

  Future<String> login(String email, String senha) async {
    final url = Uri.parse('$baseUrl/rpc/fazer_login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody is Map && responseBody.containsKey('token')) {
        _token = responseBody['token'];
        return _token!;
      }
      throw Exception('Formato de resposta de login inesperado.');
    } else {
      throw Exception(
        'Falha no login. Status: ${response.statusCode}, Body: ${response.body}',
      );
    }
  }

  Future<void> cadastrarUsuario({
    required String nome,
    required String email,
    required String celular,
    required String senha,
  }) async {
    final url = Uri.parse('$baseUrl/cadastro');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'celular': celular,
        'senha': senha,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Falha ao cadastrar: ${response.body}');
    }
  }

  Future<List<Conversa>> getConversas() async {
    if (_token == null) throw Exception('Token não disponível.');
    final url = Uri.parse('$baseUrl/conversas');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Conversa.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao buscar conversas: ${response.body}');
    }
  }

  Future<String> criarConversa() async {
    if (_token == null) throw Exception('Token não disponível.');
    final url = Uri.parse('$baseUrl/rpc/cria_conversa');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao criar conversa: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> enviarResposta(
    String conversaId,
    String resposta,
  ) async {
    if (_token == null) throw Exception('Token não disponível.');
    final url = Uri.parse('$baseUrl/rpc/envia_resposta');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'conversa_id': conversaId,
        'resposta': resposta,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao enviar resposta: ${response.body}');
    }
  }

  Future<List<Tarefa>?> getTarefas(String email) async {
    if (_token == null) throw Exception('Token não disponível.');
    final url = Uri.parse('$baseUrl/tarefas?email=eq.$email');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isEmpty) {
        return null;
      }
      final List<dynamic> tarefasJson = jsonDecode(data[0]['valor']);
      return tarefasJson.map((json) => Tarefa.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao buscar tarefas: ${response.body}');
    }
  }

  Future<void> criarListaDeTarefas(String email, List<Tarefa> tarefas) async {
    if (_token == null) throw Exception('Token não disponível.');
    final url = Uri.parse('$baseUrl/tarefas');
    final List<Map<String, dynamic>> tarefasJson = tarefas
        .map((t) => t.toJson())
        .toList();
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({'email': email, 'valor': jsonEncode(tarefasJson)}),
    );
    if (response.statusCode != 201) {
      throw Exception('Falha ao criar lista de tarefas: ${response.body}');
    }
  }

  Future<void> atualizarTarefas(String email, List<Tarefa> tarefas) async {
    if (_token == null) throw Exception('Token não disponível.');
    final url = Uri.parse('$baseUrl/tarefas?email=eq.$email');
    final List<Map<String, dynamic>> tarefasJson = tarefas
        .map((t) => t.toJson())
        .toList();
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({'valor': jsonEncode(tarefasJson)}),
    );
    if (response.statusCode != 204) {
      throw Exception('Falha ao atualizar tarefas: ${response.body}');
    }
  }
}

// Widgets base
class MainDrawer extends StatelessWidget {
  final String currentPage;
  final ApiService apiService;
  final String userEmail;

  const MainDrawer({
    Key? key,
    required this.currentPage,
    required this.apiService,
    required this.userEmail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.account_circle,
                  size: 64,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  userEmail,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.list),
            title: Text('Lista de Tarefas'),
            selected: currentPage == 'tasks',
            onTap: () {
              Navigator.pop(context);
              if (currentPage != 'tasks') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyHomePage(
                      apiService: apiService,
                      userEmail: userEmail,
                    ),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.chat),
            title: Text('Chat'),
            selected: currentPage == 'chat',
            onTap: () {
              Navigator.pop(context);
              if (currentPage != 'chat') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      apiService: apiService,
                      userEmail: userEmail,
                    ),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.add_comment),
            title: Text('Iniciar outra conversa'),
            onTap: () async {
              Navigator.pop(context);
              try {
                await apiService.criarConversa();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      apiService: apiService,
                      userEmail: userEmail,
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao criar nova conversa: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => LoginPage(apiService: ApiService()),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

// PONTO DE ENTRADA DO APP
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final ApiService apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Tarefas',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(apiService: apiService),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginPage extends StatefulWidget {
  final ApiService apiService;
  const LoginPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usuarioController = TextEditingController();
  final _senhaController = TextEditingController();
  String? _erro;
  bool _isLoading = false;

  void _entrar() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });
    try {
      final email = _usuarioController.text.trim();
      final senha = _senhaController.text.trim();
      await widget.apiService.login(email, senha);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MyHomePage(apiService: widget.apiService, userEmail: email),
        ),
      );
    } catch (e) {
      setState(() => _erro = e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _irParaCadastro() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CadastroPage(apiService: widget.apiService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _usuarioController,
              decoration: InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _senhaController,
              decoration: InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            SizedBox(height: 16),
            if (_erro != null)
              Text(
                _erro!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            SizedBox(height: 12),
            if (_isLoading)
              CircularProgressIndicator()
            else
              ElevatedButton(onPressed: _entrar, child: Text('Entrar')),
            TextButton(
              onPressed: _irParaCadastro,
              child: Text('Ainda não tem conta? Cadastre-se'),
            ),
          ],
        ),
      ),
    );
  }
}

class CadastroPage extends StatefulWidget {
  final ApiService apiService;
  const CadastroPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _celularController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;
  bool _isLoading = false;
  String? _erro;
  final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  
  void _tentarCadastro() async {
    if (!_formKey.currentState!.validate()) return;
    final senha = _senhaController.text;
    final confirmarSenha = _confirmarSenhaController.text;
    if (senha != confirmarSenha) {
      setState(() => _erro = 'As senhas não coincidem');
      return;
    }
    setState(() {
      _isLoading = true;
      _erro = null;
    });
    try {
      await widget.apiService.cadastrarUsuario(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        celular: _celularController.text.trim(),
        senha: senha,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cadastro realizado com sucesso!')),
      );
    } catch (e) {
      setState(() => _erro = e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(labelText: 'Nome completo'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe o nome' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Informe o e-mail';
                  if (!_emailRegex.hasMatch(value)) return 'E-mail inválido';
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _celularController,
                decoration: InputDecoration(labelText: 'Celular'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe o celular' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _senhaController,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _senhaVisivel ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _senhaVisivel = !_senhaVisivel),
                  ),
                ),
                obscureText: !_senhaVisivel,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe a senha' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _confirmarSenhaController,
                decoration: InputDecoration(
                  labelText: 'Confirmar senha',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmarSenhaVisivel
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () => _confirmarSenhaVisivel = !_confirmarSenhaVisivel,
                    ),
                  ),
                ),
                obscureText: !_confirmarSenhaVisivel,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Confirme a senha' : null,
              ),
              SizedBox(height: 16),
              if (_erro != null)
                Text(
                  _erro!,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 12),
              if (_isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _tentarCadastro,
                  child: Text('Cadastrar'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final ApiService apiService;
  final String userEmail;
  final List<String>? newTasks; // Added
  final bool replaceExisting; // Added

  const MyHomePage({
    Key? key,
    required this.apiService,
    required this.userEmail,
    this.newTasks, // Added
    this.replaceExisting = false, // Added with default
  }) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  List<Tarefa> _tarefas = [];
  bool _isLoading = true;
  String? _erro;
  bool _servidorPossuiRegistro = false;
  Timer? _debounce;

  final Map<Object, GlobalKey> _itemKeys = {};
  int? _indexEmExclusao;

  // Estados para a animação
  Widget? _animatingItemWidget;
  Rect? _startRect;
  Rect? _endRect;
  bool _isAnimatingCompletion = false;
  int? _hiddenTaskIndex;

  @override
  void initState() {
    super.initState();
    _carregarTarefas().then((_) {
      // After tasks are loaded, process new tasks from chat if any
      if (widget.newTasks != null && widget.newTasks!.isNotEmpty) {
        _adicionarTarefasDoChat(widget.newTasks!, widget.replaceExisting);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _carregarTarefas() async {
    try {
      final tarefasDoServidor = await widget.apiService.getTarefas(
        widget.userEmail,
      );
      setState(() {
        if (tarefasDoServidor != null) {
          _tarefas = tarefasDoServidor;
          _servidorPossuiRegistro = true;
        } else {
          _tarefas = [];
          _servidorPossuiRegistro = false;
        }
        _isLoading = false;
        _erro = null;
      });
    } catch (e) {
      setState(() {
        _erro = "Não foi possível carregar tarefas. Tente novamente.";
        _isLoading = false;
      });
    }
  }

  Future<void> _salvarTarefas() async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        if (_servidorPossuiRegistro) {
          await widget.apiService.atualizarTarefas(widget.userEmail, _tarefas);
        } else {
          await widget.apiService.criarListaDeTarefas(
            widget.userEmail,
            _tarefas,
          );
          if (mounted) {
            setState(() {
              _servidorPossuiRegistro = true;
            });
          }
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao salvar: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _adicionarTarefa() {
    String texto = _controller.text.trim();
    if (texto.isEmpty) return;

    bool jaExiste = _tarefas.any(
      (t) => t.titulo.toLowerCase() == texto.toLowerCase(),
    );
    if (jaExiste) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Essa tarefa já existe!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _tarefas.insert(0, Tarefa(titulo: texto));
      _controller.clear();
    });
    _salvarTarefas();
  }

  void _adicionarTarefasDoChat(List<String> novasTarefas, bool substituir) {
    setState(() {
      if (substituir) {
        _tarefas.clear();
      }
      for (String titulo in novasTarefas) {
        bool jaExiste = _tarefas.any(
          (t) => t.titulo.toLowerCase() == titulo.toLowerCase(),
        );
        if (!jaExiste) {
          _tarefas.add(Tarefa(titulo: titulo));
        }
      }
    });
    _salvarTarefas();
  }

  void _removerTarefa(int index) {
    setState(() {
      _indexEmExclusao = index;
    });

    Future.delayed(Duration(seconds: 3), () {
      if (!mounted) return;
      if (_tarefas.length > index && _indexEmExclusao == index) {
        setState(() {
          _tarefas.removeAt(index);
          _indexEmExclusao = null;
        });
        _salvarTarefas();
      }
    });
  }

  void _desfazerRemocao() {
    setState(() {
      _indexEmExclusao = null;
    });
  }

  void _alternarConclusao(int index) async {
    if (_isAnimatingCompletion) return;

    final tarefa = _tarefas[index];

    if (tarefa.concluida) {
      setState(() {
        tarefa.concluida = false;
        tarefa.timestampConclusao = null;
        _ordenarLista();
      });
      _salvarTarefas();
      return;
    }

    // Animação de conclusão
    final itemKey = _itemKeys[tarefa]!;
    final renderBox = itemKey.currentContext!.findRenderObject() as RenderBox;
    final startOffset = renderBox.localToGlobal(Offset.zero);
    _startRect = startOffset & renderBox.size;

    int targetIndex = _tarefas.where((t) => !t.concluida).length - 1;
    if (targetIndex < 0) targetIndex = 0;

    final targetKey = _itemKeys[_tarefas[targetIndex]]!;
    final targetRenderBox =
        targetKey.currentContext!.findRenderObject() as RenderBox;
    final listOffset = (context.findRenderObject() as RenderBox).localToGlobal(
      Offset.zero,
    );
    _endRect =
        (targetRenderBox.localToGlobal(listOffset) & targetRenderBox.size);

    _animatingItemWidget = _construirItem(tarefa, index, isOverlay: true);

    setState(() {
      _isAnimatingCompletion = true;
      _hiddenTaskIndex = index;
    });

    await Future.delayed(Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() {
      tarefa.concluida = true;
      tarefa.timestampConclusao = DateTime.now();
      _ordenarLista();

      _isAnimatingCompletion = false;
      _animatingItemWidget = null;
      _hiddenTaskIndex = null;
    });
    _salvarTarefas();
  }

  void _ordenarLista() {
    _tarefas.sort((a, b) {
      if (a.concluida && !b.concluida) return 1;
      if (!a.concluida && b.concluida) return -1;
      if (a.concluida && b.concluida) {
        return b.timestampConclusao!.compareTo(a.timestampConclusao!);
      }
      return 0;
    });
  }

  Widget _construirItem(Tarefa tarefa, int index, {bool isOverlay = false}) {
    if (!isOverlay) {
      _itemKeys.putIfAbsent(tarefa, () => GlobalKey());
    }

    final bool emExclusao = _indexEmExclusao == index;

    return Opacity(
      opacity: _hiddenTaskIndex == index ? 0.0 : 1.0,
      child: Container(
        key: isOverlay ? null : _itemKeys[tarefa],
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: emExclusao
              ? Colors.red[100]
              : (index.isEven ? Colors.blue[50] : Colors.white),
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
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
              onChanged: emExclusao
                  ? null
                  : (value) => _alternarConclusao(index),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tarefa.titulo,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: emExclusao ? Colors.red : null,
                      decoration: tarefa.concluida
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (tarefa.timestampConclusao != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Concluída em: ${tarefa.timestampConclusao!.day}/${tarefa.timestampConclusao!.month} às ${tarefa.timestampConclusao!.hour}:${tarefa.timestampConclusao!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: emExclusao ? Colors.red : Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            emExclusao
                ? TextButton(
                    onPressed: _desfazerRemocao,
                    child: Text('Desfazer'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  )
                : IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removerTarefa(index),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lista de Tarefas')),
      drawer: MainDrawer(
        currentPage: 'tasks',
        apiService: widget.apiService,
        userEmail: widget.userEmail,
      ),
      body: Stack(
        children: [
          Column(
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
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _erro != null
                        ? Center(child: Text(_erro!))
                        : ListView.builder(
                            padding: EdgeInsets.only(bottom: 80),
                            itemCount: _tarefas.length,
                            itemBuilder: (context, index) {
                              final tarefa = _tarefas[index];
                              return Dismissible(
                                key: ValueKey(tarefa),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 20),
                                  child: Icon(Icons.delete, color: Colors.white),
                                ),
                                confirmDismiss: (direction) async {
                                  if (_indexEmExclusao == index) return false;
                                  _removerTarefa(index);
                                  return false;
                                },
                                child: _construirItem(tarefa, index),
                              );
                            },
                          ),
              ),
            ],
          ),
          if (_isAnimatingCompletion && _animatingItemWidget != null)
            AnimatedPositioned(
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              top: _endRect!.top,
              left: _endRect!.left,
              width: _startRect!.width,
              height: _startRect!.height,
              child: TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 500),
                tween: Tween(begin: -0.05, end: 0.0),
                builder: (context, angle, child) {
                  return Transform.rotate(angle: angle, child: child);
                },
                child: Material(
                  color: Colors.transparent,
                  child: _animatingItemWidget,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final ApiService apiService;
  final String userEmail;

  const ChatPage({
    Key? key,
    required this.apiService,
    required this.userEmail,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Mensagem> _mensagens = [];
  String? _conversaId;
  bool _isLoading = true;
  bool _enviandoMensagem = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _inicializarChat();
  }

  Future<void> _inicializarChat() async {
    try {
      final conversas = await widget.apiService.getConversas();
      
      if (conversas.isNotEmpty) {
        // Usa a conversa mais recente
        final conversa = conversas.first;
        setState(() {
          _conversaId = conversa.id;
          _mensagens = conversa.mensagens;
          _isLoading = false;
        });
      } else {
        // Cria nova conversa
        final novaConversaId = await widget.apiService.criarConversa();
        setState(() {
          _conversaId = novaConversaId;
          _isLoading = false;
        });
        
        // Recarrega para pegar a mensagem inicial
        await _recarregarConversa();
      }
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar chat: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _recarregarConversa() async {
    if (_conversaId == null) return;
    
    try {
      final conversas = await widget.apiService.getConversas();
      final conversa = conversas.firstWhere((c) => c.id == _conversaId);
      
      setState(() {
        _mensagens = conversa.mensagens;
      });
      
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao recarregar conversa: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _enviarMensagem() async {
    final texto = _messageController.text.trim();
    if (texto.isEmpty || _enviandoMensagem || _conversaId == null) return;

    if (texto.length > 140) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A mensagem pode ter no máximo 140 caracteres'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _enviandoMensagem = true;
      _mensagens.add(Mensagem(papel: 'usuario', conteudo: texto));
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      final resposta = await widget.apiService.enviarResposta(_conversaId!, texto);
      
      if (resposta.containsKey('pergunta')) {
        setState(() {
          _mensagens.add(Mensagem(
            papel: 'assistente',
            conteudo: resposta['pergunta'],
          ));
        });
      } else if (resposta.containsKey('tarefas')) {
        final List<String> tarefas = List<String>.from(resposta['tarefas']);
        
        // Mostra diálogo para escolher o que fazer com as tarefas
        _mostrarDialogoTarefas(tarefas);
        
        setState(() {
          _mensagens.add(Mensagem(
            papel: 'assistente',
            conteudo: 'Lista de tarefas gerada! Escolha uma opção acima.',
          ));
        });
      }
      
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar mensagem: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Remove a mensagem do usuário se houve erro
      setState(() {
        _mensagens.removeLast();
      });
    } finally {
      setState(() {
        _enviandoMensagem = false;
      });
    }
  }

  void _mostrarDialogoTarefas(List<String> tarefas) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ChatGPT gerou uma lista de tarefas!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text('Tarefas sugeridas:'),
              SizedBox(height: 8),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: tarefas.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text('• ${tarefas[index]}'),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Continuar chat
                },
                child: Text('Continuar o chat'),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyHomePage( // Changed from TaskListWithNewTasks to MyHomePage
                        apiService: widget.apiService,
                        userEmail: widget.userEmail,
                        newTasks: tarefas,
                        replaceExisting: true,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text('Criar lista apagando as tarefas anteriores'),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyHomePage( // Changed from TaskListWithNewTasks to MyHomePage
                        apiService: widget.apiService,
                        userEmail: widget.userEmail,
                        newTasks: tarefas,
                        replaceExisting: false,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('Adicionar à lista existente'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageBubble(Mensagem mensagem) {
    final isUser = mensagem.papel == 'usuario';
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          mensagem.conteudo,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _recarregarConversa,
          ),
        ],
      ),
      drawer: MainDrawer(
        currentPage: 'chat',
        apiService: widget.apiService,
        userEmail: widget.userEmail,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _erro != null
                    ? Center(child: Text(_erro!))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(8),
                        itemCount: _mensagens.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_mensagens[index]);
                        },
                      ),
          ),
          if (_enviandoMensagem)
            Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(width: 8),
                  Text('Enviando mensagem...'),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_enviandoMensagem,
                    maxLength: 140,
                    decoration: InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _enviarMensagem(),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _enviandoMensagem ? null : _enviarMensagem,
                  child: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}