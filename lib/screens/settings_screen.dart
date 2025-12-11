import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/weather_provider.dart';
import '../utils/weather_theme.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, child) {
        // Get current weather condition for dynamic background
        final condition = provider.currentWeather?.mainCondition ?? 'sunny';
        final gradient = WeatherTheme.getGradient(condition);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Settings',
              style: WeatherTheme.textStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            centerTitle: true,
          ),
          body: Container(
            decoration: BoxDecoration(gradient: gradient),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Text(
                        "Unit Settings", 
                        style: WeatherTheme.textStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 20),
                      // Temperature Unit
                      _buildSwitchTile(
                        title: 'Temperature Unit',
                        subtitle: provider.isCelsius ? 'Celsius (°C)' : 'Fahrenheit (°F)',
                        value: provider.isCelsius,
                        icon: Icons.thermostat,
                        onChanged: (_) => provider.toggleTemperatureUnit(),
                      ),
                      const Divider(color: Colors.black12),

                      // Time Format
                      _buildSwitchTile(
                        title: 'Time Format',
                        subtitle: provider.is24HourFormat ? '24 Hour' : '12 Hour',
                        value: provider.is24HourFormat,
                        icon: Icons.access_time,
                        onChanged: (_) => provider.toggleTimeFormat(),
                      ),
                      const Divider(color: Colors.black12),

                      // Wind Speed Unit
                      ListTile(
                        leading: const Icon(Icons.air, color: Colors.black87),
                        title: Text(
                          'Wind Speed Unit',
                          style: WeatherTheme.textStyle(fontSize: 16, color: Colors.black87),
                        ),
                        trailing: DropdownButton<String>(
                          value: provider.windSpeedUnit,
                          dropdownColor: Colors.white,
                          style: GoogleFonts.roboto(color: Colors.black87),
                          underline: Container(),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
                          items: ['m/s', 'km/h', 'mph'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              provider.setWindSpeedUnit(newValue);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: WeatherTheme.textStyle(fontSize: 16, color: Colors.black87)),
      subtitle: Text(subtitle, style: WeatherTheme.textStyle(fontSize: 14, color: Colors.black54)),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: Colors.black87),
      activeThumbImage: null,
      activeTrackColor: Colors.black12,
      inactiveThumbColor: Colors.grey,
      inactiveTrackColor: Colors.transparent,
    );
  }
}