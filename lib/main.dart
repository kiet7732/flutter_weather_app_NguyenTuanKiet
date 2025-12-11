import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/location_provider.dart';
import 'providers/weather_provider.dart';
import 'screens/main_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'services/location_service.dart';
import 'services/storage_service.dart';
import 'services/weather_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Initialize Services
  final String apiKey = dotenv.env['API_KEY'] ?? '';
  
  final weatherService = WeatherService(apiKey: apiKey);
  final locationService = LocationService();
  final storageService = StorageService();

  runApp(MyApp(
    weatherService: weatherService,
    locationService: locationService,
    storageService: storageService,
  ));
}

class MyApp extends StatelessWidget {
  final WeatherService weatherService;
  final LocationService locationService;
  final StorageService storageService;

  const MyApp({
    super.key,
    required this.weatherService,
    required this.locationService,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        
        // WeatherProvider with Dependency Injection
        ChangeNotifierProvider(
          create: (_) => WeatherProvider(
            weatherService,
            locationService,
            storageService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Weather App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MainScreen(),
        routes: {
          '/search': (context) => const SearchScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
