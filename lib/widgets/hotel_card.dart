import 'package:flutter/material.dart';
import '../models/hotel_model.dart';
import '../theme/app_theme.dart';

class HotelCard extends StatefulWidget {
  final HotelModel hotel;
  final VoidCallback onTap;

  const HotelCard({
    super.key,
    required this.hotel,
    required this.onTap,
  });

  @override
  State<HotelCard> createState() => _HotelCardState();
}

class _HotelCardState extends State<HotelCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..translate(0.0, _hovered ? -3.0 : 0.0),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 10,
                      child: hotel.images.isNotEmpty
                          ? Image.network(
                              hotel.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _fallbackImage(),
                            )
                          : _fallbackImage(),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: AppTheme.accentGold, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${hotel.starRating ?? 4} Star',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel.name,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppTheme.textMuted, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${hotel.city ?? 'Aqaba'}, ${hotel.country ?? 'Jordan'}',
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (hotel.description != null && hotel.description!.isNotEmpty)
                        Text(
                          hotel.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: hotel.amenities.take(3).map((amenity) {
                          return Chip(
                            label: Text(
                              amenity,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: const Color(0xFFE8EEF3),
      alignment: Alignment.center,
      child: const Icon(Icons.hotel_rounded, size: 54, color: AppTheme.primaryNavy),
    );
  }
}