import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/providers/weather_provider.dart';
import 'package:weather_app/screens/forecast_screen.dart';
import 'package:weather_app/screens/home_screen.dart';
import 'package:weather_app/screens/search_screen.dart';
import 'package:weather_app/screens/settings_screen.dart';
import 'package:weather_app/utils/weather_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    SearchScreen(),
    // ForecastScreen needs data, so we'll handle it in the builder
    SizedBox.shrink(), 
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, child) {
        final condition = provider.currentWeather?.mainCondition ?? 'sunny';
        final gradient = WeatherTheme.getGradient(condition);

        // Handle ForecastScreen separately as it requires data
        final List<Widget> screens = [
          const HomeScreen(),
          const SearchScreen(),
          provider.forecast.isNotEmpty
              ? ForecastScreen(
                  forecastData: provider.forecast,
                  cityName: provider.currentWeather?.cityName ?? 'Forecast',
                  currentMainCondition: condition,
                )
              : const Center(child: Text("No forecast data available.", style: TextStyle(color: Colors.white))),
          const SettingsScreen(),
        ];

        return Scaffold(
          extendBody: true, // Allow body to go behind the nav bar
          body: Container(
            decoration: BoxDecoration(gradient: gradient),
            child: IndexedStack(
              index: _selectedIndex,
              children: screens,
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_outlined),
                  activeIcon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined),
                  activeIcon: Icon(Icons.calendar_today),
                  label: 'Forecast',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withOpacity(0.6),
              showSelectedLabels: false,
              showUnselectedLabels: false,
            ),
          ),
        );
      },
    );
  }
}