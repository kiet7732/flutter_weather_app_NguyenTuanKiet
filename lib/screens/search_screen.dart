import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/weather_provider.dart';
import '../utils/weather_theme.dart';
import '../widgets/glass_container.dart';
import 'home_screen.dart'; // Importing to reuse WeatherPage for search results

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final provider = context.read<WeatherProvider>();
    
    try {
      // 1. Fetch Weather
      await provider.fetchWeatherByCity(query);
      
      // 2. Add to History (if successful)
      await provider.addToHistory(query);
      
      if (!mounted) return;
      
      // 3. Navigate to Result Page
      // We push a new Scaffold containing the WeatherPage for the searched city
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                // Allow toggling favorite from the result view
                Consumer<WeatherProvider>(
                  builder: (context, provider, _) {
                    final isFav = provider.isFavorite(query);
                    return IconButton(
                      icon: Icon(isFav ? Icons.star : Icons.star_border, color: Colors.white),
                      onPressed: () async {
                         try {
                           await provider.toggleFavorite(query);
                         } catch (e) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                           );
                         }
                      },
                    );
                  }
                )
              ],
            ),
            body: WeatherPage(locationKey: query),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("City not found")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, child) {
        // Use current weather condition for background, or default to sunny
        final condition = provider.currentWeather?.mainCondition ?? 'sunny';
        final gradient = WeatherTheme.getGradient(condition);

        return Scaffold(
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: BoxDecoration(gradient: gradient),
            child: SafeArea(
              child: Column(
                children: [
                  // --- Search Bar ---
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.roboto(color: Colors.white),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          hintText: 'Search City...',
                          hintStyle: GoogleFonts.roboto(color: Colors.white60),
                          border: InputBorder.none,
                          icon: const Icon(Icons.search, color: Colors.white),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white60),
                            onPressed: () => _searchController.clear(),
                          ),
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: _performSearch,
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // --- Section 1: Favorites ---
                        if (provider.favoriteCities.isNotEmpty) ...[
                          Text(
                            "Favorite Cities",
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: WeatherTheme.textShadow,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: provider.favoriteCities.map((city) {
                              return GestureDetector(
                                onTap: () => _performSearch(city),
                                child: GlassContainer(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        city,
                                        style: GoogleFonts.roboto(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 30),
                        ],

                        // --- Section 2: Recent Searches ---
                        if (provider.searchHistory.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Recent Searches",
                                style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: WeatherTheme.textShadow,
                                ),
                              ),
                              TextButton(
                                onPressed: () => provider.clearHistory(),
                                child: Text(
                                  "Clear All",
                                  style: GoogleFonts.roboto(color: Colors.white70),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...provider.searchHistory.map((city) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GlassContainer(
                                padding: EdgeInsets.zero,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  title: Text(
                                    city,
                                    style: GoogleFonts.roboto(color: Colors.white),
                                  ),
                                  leading: const Icon(Icons.history, color: Colors.white70),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                                    onPressed: () => provider.removeFromHistory(city),
                                  ),
                                  onTap: () => _performSearch(city),
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}