import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hotel_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hotel_card.dart';
import '../../widgets/reveal_on_scroll.dart';
import 'hotel_detail_screen.dart';

class HotelListScreen extends StatefulWidget {
  const HotelListScreen({super.key});

  @override
  State<HotelListScreen> createState() => _HotelListScreenState();
}

class _HotelListScreenState extends State<HotelListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HotelProvider>(context, listen: false).fetchHotels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotels in Aqaba'),
      ),
      body: Consumer<HotelProvider>(
        builder: (context, hotelProvider, child) {
          if (hotelProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (hotelProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${hotelProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: hotelProvider.fetchHotels,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }
          if (hotelProvider.hotels.isEmpty) {
            return Center(
              child: Text(
                "No hotels available",
                style: theme.textTheme.titleMedium,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: hotelProvider.fetchHotels,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryNavy, Color(0xFF225A7D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Your Perfect Stay',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Curated hotels with seamless digital check-in.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                ...hotelProvider.hotels.asMap().entries.map((entry) {
                  final index = entry.key;
                  final hotel = entry.value;
                  return RevealOnScroll(
                    delay: Duration(milliseconds: 80 * index),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: HotelCard(
                        hotel: hotel,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HotelDetailScreen(hotelId: hotel.id),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}