import 'package:flutter/material.dart';
import '../models/air_quality_model.dart';

class AirQualityCard extends StatelessWidget {
  final AirQualityModel airQuality;

  const AirQualityCard({super.key, required this.airQuality});

  @override
  Widget build(BuildContext context) {
    final aqiData = _getAqiData(airQuality.aqi);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.air, color: Colors.black87),
              const SizedBox(width: 8),
              Text(
                'Air Quality',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aqiData['status'] as String,
                    style: TextStyle(
                      color: aqiData['color'] as Color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    aqiData['message'] as String,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (aqiData['color'] as Color).withOpacity(0.2),
                  border: Border.all(color: aqiData['color'] as Color, width: 2),
                ),
                child: Text(
                  '${airQuality.aqi}',
                  style: TextStyle(
                    color: aqiData['color'] as Color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.black12),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPollutantItem('PM2.5', airQuality.pm2_5),
              _buildPollutantItem('CO', airQuality.co),
              _buildPollutantItem('O3', airQuality.o3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPollutantItem(String label, double value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value.toStringAsFixed(1),
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Map<String, dynamic> _getAqiData(int aqi) {
    switch (aqi) {
      case 1: return {'status': 'Good', 'color': Colors.greenAccent, 'message': 'Enjoy the outdoors!'};
      case 2: return {'status': 'Fair', 'color': Colors.yellowAccent, 'message': 'Acceptable quality.'};
      case 3: return {'status': 'Moderate', 'color': Colors.orangeAccent, 'message': 'Sensitive groups should limit outdoor exertion.'};
      case 4: return {'status': 'Poor', 'color': Colors.redAccent, 'message': 'Avoid prolonged outdoor exertion.'};
      case 5: return {'status': 'Very Poor', 'color': Colors.purpleAccent, 'message': 'Stay indoors.'};
      default: return {'status': 'Unknown', 'color': Colors.grey, 'message': ''};
    }
  }
}