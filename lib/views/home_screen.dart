import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/reveal_on_scroll.dart';
import 'auth/login_screen.dart';
import 'hotels/hotel_list_screen.dart';
import '../views/booking/my_bookings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String _heroImageUrl =
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1400&q=80';

  void _openScreen(BuildContext context, Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: page,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);
    final userName = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Petra Booking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RevealOnScroll(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 1.04, end: 1),
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 300,
                            child: Image.network(
                              _heroImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppTheme.primaryNavy,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.image_outlined,
                                  color: Colors.white70,
                                  size: 54,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.60),
                                  Colors.black.withOpacity(0.18),
                                ],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 24,
                            right: 24,
                            top: 20,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.28),
                                  ),
                                ),
                                child: const Text(
                                  'PREMIUM EXPERIENCE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 24,
                            right: 24,
                            bottom: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName.isNotEmpty ? 'Welcome, $userName' : 'Welcome',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Discover premium stays in Aqaba with a seamless digital check-in experience.',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withOpacity(0.95),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                RevealOnScroll(
                  delay: const Duration(milliseconds: 120),
                  child: Center(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      children: [
                        _buildStatCard(
                          context,
                          title: 'Fast Check-In',
                          subtitle: 'Skip long queues with digital onboarding',
                          icon: Icons.flash_on_rounded,
                        ),
                        _buildStatCard(
                          context,
                          title: 'Premium Hotels',
                          subtitle: 'Curated high-rated stays in one place',
                          icon: Icons.hotel_rounded,
                        ),
                        _buildStatCard(
                          context,
                          title: 'Secure Booking',
                          subtitle: 'Protected payments',
                          icon: Icons.verified_user_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                RevealOnScroll(
                  delay: const Duration(milliseconds: 150),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFD),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2EAF2)),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: 10,
                      spacing: 12,
                      children: const [
                        _MiniInfoPill(
                          step: '1',
                          label: 'Pick your hotel',
                          icon: Icons.apartment_rounded,
                        ),
                        _MiniInfoPill(
                          step: '2',
                          label: 'Choose your room',
                          icon: Icons.bed_rounded,
                        ),
                        _MiniInfoPill(
                          step: '3',
                          label: 'Check in online',
                          icon: Icons.verified_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                RevealOnScroll(
                  delay: const Duration(milliseconds: 180),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 700;
                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _openScreen(
                                context,
                                const HotelListScreen(),
                              ),
                              icon: const Icon(Icons.search_rounded),
                              label: const Text('Explore Hotels'),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () => _openScreen(
                                context,
                                const MyBookingsScreen(),
                              ),
                              icon: const Icon(Icons.event_available_rounded),
                              label: const Text('My Bookings'),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openScreen(
                                context,
                                const HotelListScreen(),
                              ),
                              icon: const Icon(Icons.search_rounded),
                              label: const Text('Explore Hotels'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _openScreen(
                                context,
                                const MyBookingsScreen(),
                              ),
                              icon: const Icon(Icons.event_available_rounded),
                              label: const Text('My Bookings'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                RevealOnScroll(
                  delay: const Duration(milliseconds: 210),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE4EAF0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryNavy.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Trusted by travelers for secure bookings and smooth arrivals.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return _InteractiveStatCard(
      width: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryNavy.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryNavy),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MiniInfoPill extends StatelessWidget {
  const _MiniInfoPill({
    required this.step,
    required this.label,
    required this.icon,
  });

  final String step;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2EAF2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryNavy.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              step,
              style: const TextStyle(
                color: AppTheme.primaryNavy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 17, color: AppTheme.primaryNavy),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveStatCard extends StatefulWidget {
  const _InteractiveStatCard({
    required this.width,
    required this.child,
  });

  final double width;
  final Widget child;

  @override
  State<_InteractiveStatCard> createState() => _InteractiveStatCardState();
}

class _InteractiveStatCardState extends State<_InteractiveStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: widget.width,
        padding: const EdgeInsets.all(16),
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? const Color(0xFFC8D9E8) : const Color(0xFFE4EAF0),
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppTheme.primaryNavy.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}