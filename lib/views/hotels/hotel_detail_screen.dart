import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/hotel_model.dart';
import '../../providers/hotel_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/reveal_on_scroll.dart';
import '../rooms/room_selection_screen.dart';

class HotelDetailScreen extends StatelessWidget {
  final int hotelId;

  const HotelDetailScreen({super.key, required this.hotelId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hotel Details')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RoomSelectionScreen(hotelId: hotelId),
              ),
            );
          },
          icon: const Icon(Icons.bed_rounded),
          label: const Text('View Rooms & Book'),
        ),
      ),
      body: FutureBuilder<HotelModel?>(
        future: Provider.of<HotelProvider>(context, listen: false).getHotelById(hotelId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(
              child: Text('Failed to load hotel details'),
            );
          }

          final hotel = snapshot.data!;
          final imageList = hotel.images.isNotEmpty
              ? hotel.images
              : const [
                  'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=1400&q=80'
                ];

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RevealOnScroll(
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 300,
                        width: double.infinity,
                        child: Image.network(
                          imageList.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallbackHeader(),
                        ),
                      ),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.5),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hotel.name,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${hotel.address ?? ''} ${hotel.city ?? ''} ${hotel.country ?? ''}'.trim(),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.white.withOpacity(0.92),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RevealOnScroll(
                        delay: const Duration(milliseconds: 80),
                        child: Row(
                          children: [
                            if (hotel.starRating != null)
                              _infoBadge(Icons.star_rounded, '${hotel.starRating} Stars'),
                            const SizedBox(width: 10),
                            _infoBadge(Icons.verified_rounded, 'Premium Service'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (hotel.description != null && hotel.description!.isNotEmpty)
                        RevealOnScroll(
                          delay: const Duration(milliseconds: 140),
                          child: _sectionCard(
                            context,
                            title: 'About This Hotel',
                            child: Text(
                              hotel.description!,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      RevealOnScroll(
                        delay: const Duration(milliseconds: 190),
                        child: _sectionCard(
                          context,
                          title: 'Hotel Photos',
                          child: GridView.builder(
                            itemCount: imageList.length.clamp(0, 6),
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.2,
                            ),
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  imageList[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFE8EEF3),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.photo_rounded,
                                      color: AppTheme.primaryNavy,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (hotel.amenities.isNotEmpty)
                        RevealOnScroll(
                          delay: const Duration(milliseconds: 230),
                          child: _sectionCard(
                            context,
                            title: 'Amenities',
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: hotel.amenities
                                  .map((amenity) => Chip(label: Text(amenity)))
                                  .toList(),
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      if (hotel.phone != null || hotel.email != null)
                        RevealOnScroll(
                          delay: const Duration(milliseconds: 270),
                          child: _sectionCard(
                            context,
                            title: 'Contact',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hotel.phone != null)
                                  _contactRow(Icons.phone_rounded, hotel.phone!),
                                if (hotel.email != null) ...[
                                  const SizedBox(height: 8),
                                  _contactRow(Icons.email_rounded, hotel.email!),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE3EAF1)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.accentGold, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }

  Widget _fallbackHeader() {
    return Container(
      color: const Color(0xFF1E4E6A),
      alignment: Alignment.center,
      child: const Icon(Icons.hotel_rounded, size: 60, color: Colors.white),
    );
  }
}
