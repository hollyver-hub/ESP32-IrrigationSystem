import 'package:flutter/material.dart';
import 'package:irrigation_app/constants/globals.dart' as globals;

class ManualControlScreen extends StatefulWidget {
  const ManualControlScreen({super.key});

  @override
  State<ManualControlScreen> createState() => _ManualControlScreenState();
}

class _ManualControlScreenState extends State<ManualControlScreen> {
  bool manualControl = false;
  List<bool> irrigationStatus = [true, true, true, true];

  Widget _buildSwitchCard(String title, bool value, ValueChanged<bool>? onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        value: value,
        activeColor: globals.green_primary,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildTestButton(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF333333),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Teste', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Controle Manual', 
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color, 
            fontWeight: FontWeight.bold
          )
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSwitchCard('Controle Manual', manualControl, (val) {
              setState(() {
                manualControl = val;
                if (!val) {
                  irrigationStatus = [true, true, true, true];
                }
              });
            }),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Atenção: Desativar essa opção implica na ativação dos sistemas de irrigação de forma automática.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            
            AnimatedOpacity(
              opacity: manualControl ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 300), 
              child: IgnorePointer(
                ignoring: !manualControl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('Ativar/Desativar Sistemas de Irrigação', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    
                    ...List.generate(4, (index) => _buildSwitchCard(
                      'Irrigação ${index + 1} - Sensor ${['X', 'Y', 'Z', 'W'][index]}',
                      irrigationStatus[index],
                      (val) => setState(() => irrigationStatus[index] = val),
                    )),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text("Bombas D'Água", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    
                    ...List.generate(4, (index) => _buildTestButton("Bomba D'Água ${index + 1}")),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('Alertas', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    
                    _buildTestButton('Nível do Reservatório'),
                    _buildTestButton('Voltagem'),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                           Text(
                            'Envio de Notificação Teste', 
                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Insira aqui o Texto da Notif.',
                              filled: true,
                              fillColor: Theme.of(context).scaffoldBackgroundColor,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF333333),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Enviar', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
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
}