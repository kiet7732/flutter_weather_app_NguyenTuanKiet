import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/weather_provider.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/custom_error_widget.dart';
import '../widgets/air_quality_card.dart';
import '../widgets/glass_container.dart';
import '../utils/date_formatter.dart';
import '../utils/weather_theme.dart';
import '../models/forecast_model.dart';
import '../models/weather_model.dart';
import '../models/air_quality_model.dart';
import 'forecast_screen.dart';

// Key đặc biệt để định danh vị trí hiện tại của user trong PageView.
const String _currentLocationKey = "CURRENT_LOCATION";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final PageController _pageController;
  List<String> _locations = [_currentLocationKey];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();

    // Lấy data thời tiết cho vị trí hiện tại ngay khi app khởi động.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().fetchDataForLocation(_currentLocationKey);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Khi app quay lại từ background, cập nhật lại vị trí hiện tại
      context.read<WeatherProvider>().fetchWeatherByLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dùng Consumer để lấy danh sách thành phố yêu thích và rebuild lại list locations.
    return Consumer<WeatherProvider>(
      builder: (context, provider, child) {
        // Cập nhật lại list locations mỗi khi mục yêu thích thay đổi.
        _locations = [_currentLocationKey, ...provider.favoriteCities];

        return Scaffold(
          body: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _locations.length,
                onPageChanged: (index) {
                  // Khi user vuốt sang trang mới, fetch data cho location đó.
                  // Provider sẽ tự check để không fetch lại nếu data đã có.
                  provider.fetchDataForLocation(_locations[index]);
                },
                itemBuilder: (context, index) {
                  final locationKey = _locations[index];
                  // Mỗi trang trong PageView là một WeatherPage độc lập.
                  return WeatherPage(locationKey: locationKey);
                },
              ),
              // Page Indicator at the bottom
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: _locations.length,
                    effect: WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: Colors.white,
                      dotColor: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Widget này thể hiện nội dung của một trang trong PageView.
class WeatherPage extends StatelessWidget {
  final String locationKey;

  const WeatherPage({super.key, required this.locationKey});

  // Chuyển sang màn hình dự báo chi tiết.
  void _navigateToForecast(BuildContext context, List<ForecastModel> forecast, String cityName, String? condition) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => 
      ForecastScreen(forecastData: forecast, cityName: cityName, currentMainCondition: condition)));
  }

  @override
  Widget build(BuildContext context) {
    // Consumer này sẽ rebuild WeatherPage mỗi khi provider notify.
    return Consumer<WeatherProvider>(
      builder: (context, provider, child) {
        // Lấy data tương ứng cho location key của trang này.
        final state = provider.getStateForLocation(locationKey);
        final weather = provider.getWeatherForLocation(locationKey);
        final forecast = provider.getForecastForLocation(locationKey);
        final airQuality = provider.getAirQualityForLocation(locationKey);
        final errorMessage = provider.getErrorForLocation(locationKey);

        final gradient = WeatherTheme.getGradient(weather?.mainCondition ?? 'sunny');

        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(gradient: gradient),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => provider.fetchDataForLocation(locationKey, forceRefresh: true),
              child: _buildPageContent(context, provider, state, weather, forecast, airQuality, errorMessage),
            ),
          ),
        );
      },
    );
  }

  // Build UI chính cho trang thời tiết.
  Widget _buildPageContent(
    BuildContext context,
    WeatherProvider provider,
    WeatherState state,
    WeatherModel? weather,
    List<ForecastModel>? forecast,
    AirQualityModel? airQuality,
    String? errorMessage,
  ) {
    switch (state) {
      case WeatherState.loading:
      case WeatherState.initial:
        return const LoadingShimmer();
      case WeatherState.error:
        return CustomErrorWidget(
          message: errorMessage ?? 'An unknown error occurred.',
          onRetry: () => provider.fetchDataForLocation(locationKey),
        );
      case WeatherState.loaded:
        if (weather == null) {
          return CustomErrorWidget(
            message: 'No weather data available.',
            onRetry: () => provider.fetchDataForLocation(locationKey),
          );
        }
        // Dùng ListView để có thể cuộn và hỗ trợ pull-to-refresh.
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // Offline Banner
              if (provider.isOffline) ...[
                _buildOfflineBanner(context, provider.lastUpdated),
                const SizedBox(height: 10),
              ],
                

              const SizedBox(height: 20),
              // Section 1: Hero
              _buildHeroSection(context, weather),
              const SizedBox(height: 30),
              
              // Section 2: Hourly Forecast
              if (forecast != null && forecast.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today",
                      style: WeatherTheme.textStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    TextButton(
                      onPressed: () => _navigateToForecast(context, forecast, weather.cityName, weather.mainCondition),
                      child: Text(
                        "7-Day Forecast >",
                        style: GoogleFonts.roboto(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: forecast.length > 8 ? 8 : forecast.length, // Chỉ hiện tầm 8 mục (24h)
                    itemBuilder: (context, index) {
                      final item = forecast[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                provider.getFormattedTime(item.dateTime),
                                style: WeatherTheme.textStyle(color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              CachedNetworkImage(
                                imageUrl: 'https://openweathermap.org/img/wn/${item.icon}.png',
                                width: 40,
                                height: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${provider.getDisplayTemperature(item.temperature).round()}°',
                                style: WeatherTheme.textStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
              ],

              // Air Quality
              if (airQuality != null) AirQualityCard(airQuality: airQuality),
              const SizedBox(height: 20),

              // Section 3: Details Bento Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 1.4,
                children: [
                  _buildDetailItem(Icons.water_drop_outlined, "Humidity", "${weather.humidity}%"),
                  _buildDetailItem(Icons.air, "Wind", provider.getDisplayWindSpeed(weather.windSpeed)),
                  _buildDetailItem(Icons.speed, "Pressure", "${weather.pressure} hPa"),
                  _buildDetailItem(Icons.visibility_outlined, "Visibility", "${(weather.visibility ?? 0) / 1000} km"),
                ],
              ),
              const SizedBox(height: 100), // Padding dưới để không bị page indicator che mất.
            ],
          ),
        );
    }
  }

  // Build banner thông báo offline.
  Widget _buildOfflineBanner(BuildContext context, DateTime? lastUpdated) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Offline. Data from ${lastUpdated != null ? DateFormatter.formatTime(lastUpdated) : '...'}",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => context.read<WeatherProvider>().fetchDataForLocation(_currentLocationKey, forceRefresh: true),
            child: const Icon(Icons.refresh, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // Build khu vực "hero" hiển thị thông tin chính.
  Widget _buildHeroSection(BuildContext context, WeatherModel weather) {
    final provider = context.watch<WeatherProvider>();
    return Column(
      children: [
        Text(
          weather.cityName, 
          style: WeatherTheme.textStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        Text(
          DateFormatter.formatDate(weather.dateTime),
          style: WeatherTheme.textStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        CachedNetworkImage(
          imageUrl: 'https://openweathermap.org/img/wn/${weather.icon}@4x.png',
          height: 180,
          width: 180,
          fit: BoxFit.contain,
        ),
        Text(
          '${provider.getDisplayTemperature(weather.temperature).round()}°',
          style: WeatherTheme.textStyle(fontSize: 90, fontWeight: FontWeight.w300, color: Colors.black87).copyWith(height: 1.0),
        ),
        Text(
          weather.description.toUpperCase(),
          style: WeatherTheme.textStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black54).copyWith(
            letterSpacing: 2.0,
          )
        ),
      ],
    );
  }

  // Build một ô thông tin chi tiết trong grid.
  Widget _buildDetailItem(IconData icon, String label, String value) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Icon(icon, color: Colors.black54, size: 24),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(label, style: WeatherTheme.textStyle(fontSize: 14, color: Colors.black87)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(value,
                style: WeatherTheme.textStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)
            ),
          ),
        ],
      ),
    );
  }
}
