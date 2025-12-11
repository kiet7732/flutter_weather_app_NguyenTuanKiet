import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/forecast_model.dart';
import '../providers/weather_provider.dart';
import '../utils/weather_theme.dart';
import '../widgets/glass_container.dart';
import '../utils/forecast_processor.dart';

class ForecastScreen extends StatelessWidget {
  final List<ForecastModel> forecastData;
  final String cityName;
  final String? currentMainCondition;

  const ForecastScreen(
      {super.key,
      required this.forecastData,
      required this.cityName,
      this.currentMainCondition});

  @override
  Widget build(BuildContext context) {
    final dailyForecasts = ForecastProcessor.process(forecastData);
    final gradient = WeatherTheme.getGradient(currentMainCondition ?? 'sunny');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Next 5 Days',
          style: WeatherTheme.textStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: gradient,
        ),
        child: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            itemCount: dailyForecasts.length,
            itemBuilder: (context, index) {
              final forecast = dailyForecasts[index];
              return _buildForecastCard(context, forecast);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForecastCard(BuildContext context, DailyForecast forecast) {
    final provider = context.watch<WeatherProvider>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        child: Theme(
          data: ThemeData(
              dividerColor: Colors.transparent,
              unselectedWidgetColor: Colors.black54,
              colorScheme:
                  const ColorScheme.light(primary: Colors.black87)),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE').format(forecast.date), 
                  style: WeatherTheme.textStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  DateFormat('d MMM').format(forecast.date), 
                  style: WeatherTheme.textStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
            title: CachedNetworkImage(
              imageUrl: 'https://openweathermap.org/img/wn/${forecast.icon}.png',
              width: 50,
              height: 50,
              placeholder: (context, url) =>
                  const SizedBox(width: 24, height: 24),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.error, color: Colors.black87),
            ),
            trailing: Text(
              '${provider.getDisplayTemperature(forecast.maxTemp).round()}° / ${provider.getDisplayTemperature(forecast.minTemp).round()}°',
              style: WeatherTheme.textStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    const Divider(color: Colors.black12),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailItem(Icons.water_drop_outlined,
                            '${(forecast.rainChance * 100).round()}%', 'Rain'),
                        _buildDetailItem(Icons.air,
                            provider.getDisplayWindSpeed(forecast.windSpeed), 'Wind'),
                        _buildDetailItem(Icons.thermostat,
                            '${forecast.humidity}%', 'Humidity'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      forecast.description,
                      style: WeatherTheme.textStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(height: 4),
        Text(value,
            style: WeatherTheme.textStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text(label,
            style: WeatherTheme.textStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}