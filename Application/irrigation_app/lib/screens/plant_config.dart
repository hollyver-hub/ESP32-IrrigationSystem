import 'package:flutter/material.dart';
import 'package:irrigation_app/constants/globals.dart' as globals;

class PlantConfigScreen extends StatefulWidget {
  final String nomeAtual;
  final double umidadeAlvoAtual;

  const PlantConfigScreen({
    super.key,
    required this.nomeAtual,
    required this.umidadeAlvoAtual,
  });

  @override
  State<PlantConfigScreen> createState() => _PlantConfigScreenState();
}

class _PlantConfigScreenState extends State<PlantConfigScreen> {
  late TextEditingController _nomeController;
  late double _nivelUmidade;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.nomeAtual);
    _nivelUmidade = widget.umidadeAlvoAtual;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.nomeAtual,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color, 
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                Text(
                  'Sensor ${(widget.nomeAtual.split(' ').last)}', 
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              Center(
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Abrir galeria de fotos...')),
                    );
                  },
                  child: Container(
                    width: 300,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 70,
                          color: Colors.black.withOpacity(0.8),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              Text(
                'Nome',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nomeController,
                maxLines: 1, 
                decoration: InputDecoration(
                  hintText: 'Insira aqui o novo nome para sua planta',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: globals.green_primary),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Umidade Mínima do Solo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    '${(_nivelUmidade * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color, 
                    ),
                  ),
                ],
              ),
              
              // --- SLIDER ---
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Theme.of(context).textTheme.bodyLarge?.color,
                  inactiveTrackColor: Colors.grey.shade300,
                  thumbColor: Theme.of(context).textTheme.bodyLarge?.color,
                  overlayColor: Colors.black.withOpacity(0.1),
                  trackHeight: 4.0,
                ),
                child: Slider(
                  value: _nivelUmidade,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100, 
                  onChanged: (double novoValor) {
                    setState(() {
                      _nivelUmidade = novoValor;
                    });
                  },
                ),
              ),
              
              Text(
                'A bomba será ligada automaticamente quando a\numidade do solo cair para este limite mínimo.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 64),

              const SizedBox(height: 150),

              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: () {
                    // Aqui você integrará futuramente o envio do novo limite
                    // para o ESP32 via HTTP/MQTT e a atualização do estado global.
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333333), 
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Salvar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}