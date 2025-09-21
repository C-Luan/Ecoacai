import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:geolocator/geolocator.dart'; // Importa a biblioteca geolocator

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Instâncias do Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Variáveis de estado
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String? _errorMessage;

  // Controladores para o formulário
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _nomeEstabelecimentoController = TextEditingController();
  final TextEditingController _ruaController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _municipioController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _nomeEstabelecimentoController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _municipioController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  // Função para buscar os dados do usuário no Firestore
  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Nenhum usuário logado.';
        _isLoading = false;
      });
      return;
    }

    try {
      final docSnapshot = await _firestore.collection('cidadaos').doc(user.uid).get();
      if (docSnapshot.exists) {
        setState(() {
          _userData = docSnapshot.data();
        });
      } else {
        // Se o documento não existe, define _userData como null
        setState(() {
          _userData = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Falha ao carregar dados do perfil: $e';
      });
      debugPrint('Erro ao buscar dados do perfil: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Função para salvar os dados do perfil e do posto de coleta
  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Nenhum usuário logado.')),
      );
      return;
    }

    if (_nomeController.text.isEmpty || _nomeEstabelecimentoController.text.isEmpty ||
        _ruaController.text.isEmpty || _numeroController.text.isEmpty ||
        _municipioController.text.isEmpty || _estadoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Salva os dados do cidadão
      final newUserData = {
        'nome': _nomeController.text,
        'nomeEstabelecimento': _nomeEstabelecimentoController.text,
        'endereco': {
          'rua': _ruaController.text,
          'numero': _numeroController.text,
          'municipio': _municipioController.text,
          'estado': _estadoController.text,
        },
      };
      await _firestore.collection('cidadaos').doc(user.uid).set(newUserData);

      // Obtém a localização do usuário
      // final position = await _getCurrentLocation();
      // if (position == null) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Não foi possível obter a localização. Tente novamente.')),
      //   );
      //   setState(() {
      //     _isLoading = false;
      //   });
      //   return;
      // }

      // 2. Salva os dados do posto de coleta, incluindo a localização
      final newPostoData = {
        'cidadaoId': user.uid,
        'nome': _nomeEstabelecimentoController.text,
        'endereco': {
          'rua': _ruaController.text,
          'numero': _numeroController.text,
          'municipio': _municipioController.text,
          'estado': _estadoController.text,
        },
        // 'geopoint': GeoPoint(position.latitude, position.longitude),
      };
      await _firestore.collection('postos').add(newPostoData);
      
      // Navega para a tela principal (HomeScreen) após o sucesso
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Falha ao salvar dados: $e';
      });
      debugPrint('Erro ao salvar dados: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar dados: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Função para obter a localização atual do usuário
  // Future<Position?> _getCurrentLocation() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;

  //   // Testar se os serviços de localização estão habilitados
  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Serviços de localização desabilitados. Por favor, habilite-os.')),
  //     );
  //     return null;
  //   }

  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Permissão de localização negada.')),
  //       );
  //       return null;
  //     }
  //   }

  //   if (permission == LocationPermission.deniedForever) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Permissão de localização permanentemente negada. Por favor, habilite nas configurações.')),
  //     );
  //     return null;
  //   }

  //   return await Geolocator.getCurrentPosition();
  // }

  // Função para realizar o logout
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao sair: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e')),
      );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: _userData == null ? _buildRegistrationForm() : _buildProfileView(),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Complete seu cadastro para continuar',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _buildTextField(_nomeController, 'Seu nome completo'),
        const SizedBox(height: 16),
        _buildTextField(_nomeEstabelecimentoController, 'Nome do seu estabelecimento'),
        const SizedBox(height: 16),
        _buildTextField(_ruaController, 'Rua'),
        const SizedBox(height: 16),
        _buildTextField(_numeroController, 'Número'),
        const SizedBox(height: 16),
        _buildTextField(_municipioController, 'Município'),
        const SizedBox(height: 16),
        _buildTextField(_estadoController, 'Estado'),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _saveProfile,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
          ),
          child: const Text('Salvar Perfil e Posto de Coleta'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _signOut,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Sair'),
        ),
      ],
    );
  }

  Widget _buildProfileView() {
    final String nome = _userData!['nome'] ?? 'Não informado';
    final String nomeEstabelecimento = _userData!['nomeEstabelecimento'] ?? 'Não informado';
    final Map<String, dynamic> endereco = _userData!['endereco'] ?? {};
    final String rua = endereco['rua'] ?? 'Não informado';
    final String numero = endereco['numero'] ?? '';
    final String municipio = endereco['municipio'] ?? 'Não informado';
    final String estado = endereco['estado'] ?? '';
    final String enderecoCompleto = '$rua, $numero\n$municipio, $estado';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoText(context, 'Nome do Usuário', nome),
                  const SizedBox(height: 16.0),
                  _buildInfoText(context, 'Nome do Estabelecimento', nomeEstabelecimento),
                  const SizedBox(height: 16.0),
                  _buildInfoText(context, 'Endereço Completo', enderecoCompleto),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24.0),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('A edição de perfil estará disponível em breve.'),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Editar Perfil'),
          ),
        ),
        const SizedBox(height: 16.0),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _signOut,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoText(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
