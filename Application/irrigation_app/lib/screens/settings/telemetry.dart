import 'package:flutter/material.dart';
import 'package:irrigation_app/constants/globals.dart' as globals;

class TelemetryScreen extends StatelessWidget {
  const TelemetryScreen({super.key});

  Widget _buildDataRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color)),
          Text(value, style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
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
          icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Telemetria e Diagnóstico',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, height: 1.2),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Sensores de Umidade'),
            _buildDataRow(context, 'Sensor X:', 'DADOS'),
            _buildDataRow(context, 'Sensor Y:', 'DADOS'),
            _buildDataRow(context, 'Sensor Z:', 'DADOS'),
            _buildDataRow(context, 'Sensor W:', 'DADOS'),

            _buildSectionTitle(context, 'Voltagem'),
            _buildDataRow(context, 'Nível da Bateria:', 'DADOS'),
            _buildDataRow(context, 'Placas Solares:', 'DADOS'),

            _buildSectionTitle(context, 'Diagnóstico da Rede'),
            _buildDataRow(context, 'STATUS:', 'DADOS'),
            _buildDataRow(context, 'NOME DA REDE:', 'DADOS'),
            _buildDataRow(context, 'IP:', 'DADOS'),
            _buildDataRow(context, 'MAC:', 'DADOS'),
            _buildDataRow(context, 'PING:', 'DADOS'),
          ],
        ),
      ),
    );
  }
}