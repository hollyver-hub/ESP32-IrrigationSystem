import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:irrigation_app/constants/globals.dart' as globals;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:irrigation_app/screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'monitor.dart';
import 'welcome.dart';

class WifiSetupScreen extends StatefulWidget {
  const WifiSetupScreen({super.key});

  @override
  State<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  final TextEditingController _passwordController = TextEditingController();
  
  String? _selectedSSID; // Agora guardamos a rede selecionada na lista
  List<String> _redesDisponiveis = []; // Lista vazia que será preenchida
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isScanningNetworks = true;

  BluetoothDevice? _espDevice;
  BluetoothCharacteristic? _writeCharacteristic;

  final String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String readNetworksUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final String writeCredsUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a9";

  @override
  void initState() {
    super.initState();
    _buscarRedesProximas();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _espDevice?.disconnect();
    super.dispose();
  }

  // Variável global para controlar a escuta do scan e evitar vazamento de memória
  StreamSubscription? _scanSubscription;

  Future<void> _buscarRedesProximas() async {
    setState(() {
      _isScanningNetworks = true;
      _selectedSSID = null;
      _redesDisponiveis = [];
    });

    // Cancela qualquer escuta anterior para evitar conflito ao recarregar
    await _scanSubscription?.cancel();
    
    // Se já houver um dispositivo conectado anteriormente, desconecta limpo
    try {
      await _espDevice?.disconnect();
    } catch (_) {}

    try {
      if (await FlutterBluePlus.isSupported == false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bluetooth não é suportado neste dispositivo.')),
          );
        }
        setState(() => _isScanningNetworks = false);
        return;
      }

      var adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (e) {
          print("Usuário negou ou sistema bloqueou a ativação do Bluetooth: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Por favor, ative o Bluetooth para configurar a estação.'),
                backgroundColor: Colors.orange,
              ),
            );
            setState(() => _isScanningNetworks = false);
          }
          return;
        }
      }

      // 3. Inicia a varredura por dispositivos BLE com limite de 20 segundos
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 20 ));

      bool dispositivoEncontrado = false;

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
          String deviceName = r.device.advName.isNotEmpty ? r.device.advName : r.device.platformName;

          if (deviceName == "EVE_Config" && !dispositivoEncontrado) {
            dispositivoEncontrado = true;
            await FlutterBluePlus.stopScan();
            _espDevice = r.device;

            // Conecta ao ESP32
            await _espDevice!.connect(license: License.nonprofit);
            
            // Descobre os serviços
            List<BluetoothService> services = await _espDevice!.discoverServices();
            for (BluetoothService service in services) {
              if (service.uuid.toString() == serviceUuid) {
                for (BluetoothCharacteristic characteristic in service.characteristics) {
                  
                  if (characteristic.uuid.toString() == writeCredsUuid) {
                    _writeCharacteristic = characteristic;
                  }

                  // Lê a característica que contém a lista de SSIDs
                  if (characteristic.uuid.toString() == readNetworksUuid) {
                    // Força a leitura direta do hardware, ignorando caches do celular
                    List<int> value = await characteristic.read();
                    String decoded = utf8.decode(value);
                    
                    if (decoded.isNotEmpty && mounted) {
                      setState(() {
                        _redesDisponiveis = decoded.split(',')
                            .where((s) => s.trim().isNotEmpty)
                            .toList();
                      });
                    }
                  }
                }
              }
            }
            if (mounted) {
              setState(() {
                _isScanningNetworks = false;
              });
            }
            break;
          }
        }
      });

      // Trava de segurança: se passar de 20 segundos sem achar o ESP32
      Future.delayed(const Duration(seconds: 20), () {
        if (_isScanningNetworks && mounted) {
          FlutterBluePlus.stopScan();
          setState(() {
            _isScanningNetworks = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estação E.V.E. não encontrada. Verifique se ela está ligada.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });

    } catch (e) {
      print("Erro no BLE: $e");
      if (mounted) {
        setState(() {
          _isScanningNetworks = false;
        });
      }
    }
  }

// 2. Envia os dados, valida o sucesso e redireciona
  void _enviarCredenciais() async {
    FocusScope.of(context).unfocus();

    if (_selectedSSID == null || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma rede e insira a senha.'),
          backgroundColor: globals.red_graphic,
        ),
      );
      return;
    }

    if (_writeCharacteristic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Conexão com a estação perdida. Busque novamente.'),
          backgroundColor: globals.red_graphic,
        ),
      );
      return;
    }

    // Ativa o ícone de carregamento no botão
    setState(() {
      _isLoading = true;
    });

    try {
      // Prepara a string no formato "SSID|SENHA"
      String payload = "$_selectedSSID|${_passwordController.text}";
      List<int> bytes = utf8.encode(payload);

      await _writeCharacteristic!.write(bytes);

      // Aguarda o ESP32 testar a senha (20 segundos)
      await Future.delayed(const Duration(seconds: 20));

      bool aindaConectado = false;
      try {
        aindaConectado = await _espDevice?.isConnected ?? false;
      } catch (_) {
        aindaConectado = false;
      }

      // Se a conexão caiu, significa que o ESP32 reiniciou com sucesso (senha correta!)
      if (!aindaConectado) {
        // Salva na memória do celular que a estação já foi configurada
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('esp_configurado', true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estação E.V.E. configurada com sucesso!'),
              backgroundColor: globals.green_primary,
            ),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()), 
            (route) => false,
          );
        }
      } else {
        // Se ainda está conectado, a placa não reiniciou (senha incorreta ou falha)
        setState(() {
          _isLoading = false;
        });

        try {
          await _espDevice?.disconnect();
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Senha incorreta ou falha na conexão. Tente novamente.'),
              backgroundColor: globals.red_graphic,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro de comunicação. Tente novamente.'),
            backgroundColor: globals.red_graphic,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: globals.green_primary.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.wifi_tethering,
                  size: 48,
                  color: globals.green_primary,
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                'Configurar Wi-Fi\nda Estação',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Selecione a rede 2.4GHz do local onde a estação E.V.E. está instalada. O envio será feito via Bluetooth.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              
              const SizedBox(height: 48),

              // --- SELEÇÃO DE REDE (DROPDOWN) ---
             Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Redes Disponíveis (SSID)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  // Botão de recarregar redes
                  IconButton(
                    // AQUI ESTÁ O AJUSTE: Chama _buscarRedesProximas() para refazer a conexão e o scan
                    onPressed: _isScanningNetworks ? null : _buscarRedesProximas,
                    icon: _isScanningNetworks 
                      ? const SizedBox(
                          width: 16, 
                          height: 16, 
                          child: CircularProgressIndicator(strokeWidth: 2)
                        )
                      : Icon(Icons.refresh, color: globals.green_primary, size: 20),
                    tooltip: 'Escanear novamente',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              DropdownButtonFormField<String>(
                value: _selectedSSID,
                dropdownColor: globals.white_background_primary,
                icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).textTheme.bodyMedium?.color),
                decoration: InputDecoration(
                  hintText: _isScanningNetworks ? 'Buscando redes...' : 'Selecione uma rede',
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  prefixIcon: Icon(
                    Icons.router_outlined, 
                    color: Theme.of(context).textTheme.bodyMedium?.color
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _redesDisponiveis.map((String ssid) {
                  return DropdownMenuItem<String>(
                    value: ssid,
                    child: Text(
                      ssid, 
                      style: TextStyle(color: globals.white_background_text),
                    ),
                  );
                }).toList(),
                onChanged: _isScanningNetworks ? null : (String? novoValor) {
                  setState(() {
                    _selectedSSID = novoValor;
                  });
                },
              ),

              const SizedBox(height: 24),

              // --- CAMPO: SENHA ---
              Text(
                'Senha do Wi-Fi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Insira a senha',
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).textTheme.bodyMedium?.color),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // --- BOTÃO DE ENVIO ---
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _enviarCredenciais,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: globals.green_primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.black87,
                            strokeWidth: 3,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bluetooth, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Enviar para a Estação',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}