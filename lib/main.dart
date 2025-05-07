import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:yaml/yaml.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'update_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ScannerProvider(),
      child: const BarcodeApp(),
    ),
  );
}

// Classe auxiliar para obter informações do app dinamicamente
class AppInfo {
  static String appName = 'Leitor de Código de Barras';
  static String version = '1.0.0';
  static String releaseDate = '';
  static bool _initialized = false;
  
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Método 1: Usar package_info_plus para obter informações diretas do pacote instalado
      final packageInfo = await PackageInfo.fromPlatform();
      appName = packageInfo.appName.isEmpty ? 'Leitor de Código de Barras' : packageInfo.appName;
      version = packageInfo.version;
      
      // Método 2 (fallback): Ler do asset pubspec.yaml
      if (version == '1.0.0' || version.isEmpty) {
        try {
          final yamlString = await rootBundle.loadString('pubspec.yaml');
          final yaml = loadYaml(yamlString);
          
          if (yaml['version'] != null) {
            // Remove o versionCode (parte após o +)
            version = yaml['version'].toString().split('+')[0];
          }
        } catch (e) {
          debugPrint('Erro ao carregar pubspec.yaml: $e');
        }
      }
      
      // Configurar a data como a data atual
      final dateFormat = DateFormat('dd \'de\' MMMM \'de\' yyyy', 'pt_BR');
      releaseDate = dateFormat.format(DateTime.now());
      _initialized = true;
    } catch (e) {
      debugPrint('Erro ao carregar informações do app: $e');
      // Usar os valores padrão em caso de erro
      releaseDate = '29 de abril de 2025';
    }
  }
}

class BarcodeApp extends StatelessWidget {
  const BarcodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inicializa as informações do app
    AppInfo.initialize();
    
    return MaterialApp(
      title: 'Leitor de Código IFSUL',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFD1B5E20), // Verde do IFSUL
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/settings': (context) => const SettingsPage(),
        '/about': (context) => const AboutPage(),
      },
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: const Center(
        child: Text(
          'Em breve',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  bool _isLoading = true;
  bool _isCheckingForUpdates = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String _updateMessage = '';
  bool _showUpdateMessage = false;
  bool _showSettings = false;
  
  final UpdateService _updateService = UpdateService();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _loadServerSettings();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAppInfo() async {
    await AppInfo.initialize();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadServerSettings() async {
    _ipController.text = _updateService.serverIp;
    _portController.text = _updateService.serverPort.toString();
  }
  
  // Método para verificar atualizações
  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingForUpdates = true;
      _showUpdateMessage = false;
    });
    
    final result = await _updateService.checkForUpdates();
    
    if (mounted) {
      setState(() {
        _isCheckingForUpdates = false;
        _showUpdateMessage = true;
        _updateMessage = result.message;
        
        // Se houver uma atualização, mostrar o botão para atualizar
        if (result.status == UpdateStatus.updateAvailable) {
          _showUpdateDialog(result);
        } else if (result.status == UpdateStatus.serverUnavailable) {
          // Se o servidor estiver indisponível, possibilitar alterar configurações
          _showServerConfigDialog(result.error);
        }
      });
      
      // Esconder mensagem após alguns segundos
      if (result.status != UpdateStatus.updateAvailable) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showUpdateMessage = false;
            });
          }
        });
      }
    }
  }
  
  // Diálogo para confirmar atualização
  void _showUpdateDialog(UpdateCheckResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova versão disponível'),
        content: Text('Deseja baixar e instalar a versão ${result.latestVersion ?? 'mais recente'}?'),
        actions: [
          TextButton(
            child: const Text('CANCELAR'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('ATUALIZAR'),
            onPressed: () {
              Navigator.of(context).pop();
              _downloadAndInstallUpdate();
            },
          ),
        ],
      ),
    );
  }
  
  // Diálogo para configuração do servidor quando indisponível
  void _showServerConfigDialog(String? errorDetail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Servidor indisponível'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Não foi possível conectar ao servidor de atualizações.'),
            const SizedBox(height: 8),
            if (errorDetail != null)
              Text(
                'Erro: $errorDetail',
                style: TextStyle(fontSize: 12, color: Colors.red[700]),
              ),
            const SizedBox(height: 16),
            const Text('Deseja configurar o endereço do servidor?'),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('CANCELAR'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('CONFIGURAR'),
            onPressed: () {
              Navigator.of(context).pop();
              _toggleSettings();
            },
          ),
        ],
      ),
    );
  }
  
  // Alterna a visibilidade das configurações do servidor
  void _toggleSettings() {
    setState(() {
      _showSettings = !_showSettings;
      if (!_showSettings) {
        // Se esconder as configurações, carregar os valores atuais
        _loadServerSettings();
      }
    });
  }
  
  // Salva as configurações do servidor
  Future<void> _saveServerSettings() async {
    final String ip = _ipController.text.trim();
    final int port = int.tryParse(_portController.text.trim()) ?? 8085;
    
    if (ip.isNotEmpty) {
      await _updateService.setServerIp(ip);
      await _updateService.setServerPort(port);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações de servidor salvas'),
            duration: Duration(seconds: 2),
          ),
        );
        
        setState(() {
          _showSettings = false;
        });
      }
    }
  }
  
  // Método para baixar e instalar a atualização
  Future<void> _downloadAndInstallUpdate() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _updateMessage = 'Iniciando download...';
      _showUpdateMessage = true;
    });
    
    final result = await _updateService.downloadAndInstallUpdate(
      onProgress: (progress) {
        setState(() {
          _downloadProgress = progress;
          _updateMessage = 'Download em andamento: ${(progress * 100).toStringAsFixed(0)}%';
        });
      },
    );
    
    if (mounted) {
      setState(() {
        _isDownloading = false;
        _updateMessage = result.message;
        
        if (!result.success && result.error != null) {
          _updateMessage += '\nErro: ${result.error}';
        }
      });
      
      // Esconder mensagem após alguns segundos se não for sucesso
      if (!result.success) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _showUpdateMessage = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: Icon(_showSettings ? Icons.close : Icons.settings),
            onPressed: _toggleSettings,
            tooltip: _showSettings ? 'Fechar configurações' : 'Configurações do servidor',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
                // Conteúdo principal (informações sobre o app)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 80,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppInfo.appName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppInfo.version,
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppInfo.releaseDate,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'Desenvolvido pelo IFSUL',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
                
                // Configurações do servidor (visível apenas quando _showSettings é true)
                if (_showSettings)
                  Positioned.fill(
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Configurações do servidor',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Endereço IP do servidor:'),
                          TextField(
                            controller: _ipController,
                            keyboardType: TextInputType.text,
                            decoration: const InputDecoration(
                              hintText: 'Ex: 192.168.0.100',
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Porta:'),
                          TextField(
                            controller: _portController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Ex: 8085',
                            ),
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: _saveServerSettings,
                              child: const Text('SALVAR'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Observação: O servidor precisa estar acessível a partir do dispositivo móvel. '
                            'Certifique-se de que ambos estejam na mesma rede.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Botão de verificar atualizações
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      children: [
                        // Mensagem de status da atualização
                        if (_showUpdateMessage)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _updateMessage,
                                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                                  textAlign: TextAlign.center,
                                ),
                                if (_isDownloading)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: LinearProgressIndicator(
                                      value: _downloadProgress,
                                      backgroundColor: colorScheme.onSurfaceVariant.withOpacity(0.2),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                        // Botão de verificar atualizações
                        ElevatedButton.icon(
                          onPressed: (_isCheckingForUpdates || _isDownloading || _showSettings)
                              ? null
                              : _checkForUpdates,
                          icon: _isCheckingForUpdates
                              ? Container(
                                  width: 24,
                                  height: 24,
                                  padding: const EdgeInsets.all(2.0),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.system_update),
                          label: Text(_isCheckingForUpdates
                              ? 'Verificando...'
                              : 'Verificar atualizações'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.onPrimaryContainer,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _scanBarcode(BuildContext context) async {
    final provider = Provider.of<ScannerProvider>(context, listen: false);
    try {
      final barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#1B5E20', // Cor do botão (verde IFSUL)
        'Cancelar',
        true,
        ScanMode.BARCODE,
      );

      // Se o usuário cancelou o scan
      if (barcodeScanRes == '-1') return;
      
      provider.addScan(barcodeScanRes);
    } on PlatformException {
      // Tratar erros de plataforma
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao scanear. Tente novamente.'),
        ),
      );
    }
  }

  void _copySelectedToClipboard(BuildContext context) {
    final provider = Provider.of<ScannerProvider>(context, listen: false);
    final selectedScans = provider.getSelectedScans();
    
    if (selectedScans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum código selecionado'),
        ),
      );
      return;
    }
    
    // Juntar os códigos com quebras de linha sem pontuação ou separadores
    final textToCopy = selectedScans.join('\n');
    
    Clipboard.setData(ClipboardData(text: textToCopy)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selectedScans.length} código(s) copiado(s) para a área de transferência'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
  
  void _deleteSelected(BuildContext context) {
    final provider = Provider.of<ScannerProvider>(context, listen: false);
    final count = provider.removeSelected();
    
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count código(s) removido(s)'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScannerProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leitor de Código de Barras'),
        backgroundColor: colorScheme.primaryContainer,
        actions: provider.isSelectionMode && provider.scans.isNotEmpty
            ? [
                // Botão de copiar
                IconButton(
                  icon: Icon(Icons.copy, color: colorScheme.onPrimaryContainer),
                  onPressed: () => _copySelectedToClipboard(context),
                  tooltip: 'Copiar selecionados',
                ),
                // Botão de excluir
                IconButton(
                  icon: Icon(Icons.delete, color: colorScheme.error),
                  onPressed: () => _deleteSelected(context),
                  tooltip: 'Excluir selecionados',
                ),
                // Botão para limpar seleção
                IconButton(
                  icon: Icon(Icons.close, color: colorScheme.onPrimaryContainer),
                  onPressed: () => provider.toggleSelectionMode(false),
                  tooltip: 'Cancelar seleção',
                ),
              ]
            : [
                // Menu principal unificado
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'settings') {
                      Navigator.pushNamed(context, '/settings');
                    } else if (value == 'about') {
                      Navigator.pushNamed(context, '/about');
                    } else if (value == 'select_all' && provider.scans.isNotEmpty) {
                      provider.toggleSelectionMode(true);
                      provider.selectAll(true);
                    } else if (value == 'delete_all' && provider.scans.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Apagar todos os códigos?'),
                          content: const Text('Esta ação não pode ser desfeita.'),
                          actions: [
                            TextButton(
                              child: const Text('CANCELAR'),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                            TextButton(
                              child: const Text('APAGAR'),
                              onPressed: () {
                                provider.clearScans();
                                Navigator.of(ctx).pop();
                              },
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    if (provider.scans.isNotEmpty) ...[
                      const PopupMenuItem(
                        value: 'select_all',
                        child: ListTile(
                          leading: Icon(Icons.select_all),
                          title: Text('Selecionar todos'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete_all',
                        child: ListTile(
                          leading: Icon(Icons.delete_forever),
                          title: Text('Apagar todos'),
                        ),
                      ),
                      const PopupMenuDivider(),
                    ],
                    const PopupMenuItem(
                      value: 'settings',
                      child: ListTile(
                        leading: Icon(Icons.settings),
                        title: Text('Configurações'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'about',
                      child: ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('Sobre'),
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: provider.scans.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 80,
                    color: colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum código escaneado.\nAperte o botão abaixo para começar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (provider.isSelectionMode) 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Checkbox(
                          value: provider.areAllSelected(),
                          onChanged: (value) => provider.selectAll(value ?? false),
                        ),
                        Text(
                          'Selecionar todos (${provider.selectedCount}/${provider.scans.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.scans.length,
                    itemBuilder: (context, index) {
                      final scan = provider.scans[index];
                      final isSelected = provider.isSelected(index);
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: isSelected ? 4 : 1,
                        color: isSelected ? colorScheme.primaryContainer.withOpacity(0.3) : null,
                        child: InkWell(
                          onLongPress: () {
                            if (!provider.isSelectionMode) {
                              provider.toggleSelectionMode(true);
                              provider.toggleSelection(index);
                            }
                          },
                          onTap: () {
                            if (provider.isSelectionMode) {
                              provider.toggleSelection(index);
                            }
                          },
                          child: ListTile(
                            leading: provider.isSelectionMode
                                ? Checkbox(
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      provider.toggleSelection(index);
                                    },
                                  )
                                : CircleAvatar(
                                    backgroundColor: colorScheme.primary,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                            title: Text(
                              scan,
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: provider.isSelectionMode
                                ? null
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 20),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: scan))
                                              .then((_) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Código copiado'),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          });
                                        },
                                        tooltip: 'Copiar código',
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, size: 20, color: colorScheme.error),
                                        onPressed: () => provider.removeScan(index),
                                        tooltip: 'Excluir código',
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.isSelectionMode
            ? null
            : () => _scanBarcode(context),
        backgroundColor: provider.isSelectionMode 
            ? colorScheme.surfaceVariant
            : colorScheme.primary,
        foregroundColor: provider.isSelectionMode 
            ? colorScheme.onSurfaceVariant.withOpacity(0.5)
            : colorScheme.onPrimary,
        label: const Text('Escanear'),
        icon: const Icon(Icons.qr_code_scanner),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class ScannerProvider extends ChangeNotifier {
  List<String> _scans = [];
  Set<int> _selectedIndices = {};
  bool _isSelectionMode = false;
  
  ScannerProvider() {
    _loadScans();
  }
  
  List<String> get scans => _scans;
  bool get isSelectionMode => _isSelectionMode;
  int get selectedCount => _selectedIndices.length;
  
  bool isSelected(int index) => _selectedIndices.contains(index);
  
  bool areAllSelected() => 
      _scans.isNotEmpty && _selectedIndices.length == _scans.length;
  
  void toggleSelectionMode(bool mode) {
    _isSelectionMode = mode;
    if (!mode) {
      _selectedIndices.clear();
    }
    notifyListeners();
  }
  
  void toggleSelection(int index) {
    if (_selectedIndices.contains(index)) {
      _selectedIndices.remove(index);
      if (_selectedIndices.isEmpty) {
        _isSelectionMode = false;
      }
    } else {
      _selectedIndices.add(index);
    }
    notifyListeners();
  }
  
  void selectAll(bool select) {
    if (select) {
      for (var i = 0; i < _scans.length; i++) {
        _selectedIndices.add(i);
      }
    } else {
      _selectedIndices.clear();
    }
    notifyListeners();
  }
  
  List<String> getSelectedScans() {
    final List<String> selected = [];
    final List<int> sortedIndices = _selectedIndices.toList()..sort();
    
    for (var i in sortedIndices) {
      selected.add(_scans[i]);
    }
    return selected;
  }
  
  int removeSelected() {
    if (_selectedIndices.isEmpty) return 0;
    
    final count = _selectedIndices.length;
    final sortedIndices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
    
    for (var i in sortedIndices) {
      _scans.removeAt(i);
    }
    
    _selectedIndices.clear();
    _isSelectionMode = false;
    _saveScans();
    notifyListeners();
    return count;
  }
  
  Future<void> _loadScans() async {
    final prefs = await SharedPreferences.getInstance();
    final scans = prefs.getStringList('scans') ?? [];
    _scans = scans;
    notifyListeners();
  }
  
  Future<void> _saveScans() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('scans', _scans);
  }
  
  void addScan(String code) {
    _scans.add(code);
    _saveScans();
    notifyListeners();
  }
  
  void removeScan(int index) {
    _scans.removeAt(index);
    _saveScans();
    notifyListeners();
  }
  
  void clearScans() {
    _scans.clear();
    _selectedIndices.clear();
    _isSelectionMode = false;
    _saveScans();
    notifyListeners();
  }
}