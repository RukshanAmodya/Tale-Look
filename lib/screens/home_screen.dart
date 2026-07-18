import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onSelectProject;
  final VoidCallback onSeeTemplates;
  final VoidCallback onSelectAbout;
  final VoidCallback onSelectPrivacy;
  final VoidCallback onCreateNewProject; // Callback when project is created

  const HomeScreen({
    super.key,
    required this.onSelectProject,
    required this.onSeeTemplates,
    required this.onSelectAbout,
    required this.onSelectPrivacy,
    required this.onCreateNewProject,
  });

  void _showCreateProjectSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Swipe Indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                'Create new project',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              
              // 1. Do it Yourself!
              _buildBottomSheetOption(
                context: context,
                title: 'Do it Yourself!',
                subtitle: 'Start writing a script for your next video from scratch.',
                emoji: '📝',
                emojiBgColor: const Color(0xFFFBBF24), // Yellow
                onTap: () {
                  Navigator.pop(context);
                  onCreateNewProject(); // Navigate to project workspace
                },
              ),
              const SizedBox(height: 12),
              
              // 2. With guided templates
              _buildBottomSheetOption(
                context: context,
                title: 'With guided templates',
                subtitle: 'Create your script using one of our guided templates.',
                emoji: '📚',
                emojiBgColor: const Color(0xFF0F322E), // Dark Teal
                onTap: () {
                  Navigator.pop(context);
                  onSeeTemplates();
                },
              ),
              const SizedBox(height: 12),
              
              // 3. Let us write your script
              _buildBottomSheetOption(
                context: context,
                title: 'Let us write your script',
                subtitle: 'Just fill out a questionnaire and we\'ll write you an script.',
                emoji: '✏️',
                emojiBgColor: const Color(0xFFEF4444), // Red
                onTap: () {
                  Navigator.pop(context);
                  // Simulates submitting questionnaire
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Questionnaire submitted! Our team will write your script.'),
                      backgroundColor: Color(0xFF147A6D),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String emoji,
    required Color emojiBgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F4F0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: emojiBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Home',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      
                      PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.settings, color: Colors.black, size: 18),
                        ),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (val) {
                          if (val == 'about') {
                            onSelectAbout();
                          } else if (val == 'privacy') {
                            onSelectPrivacy();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'about',
                            child: Text('About QuestraX', style: GoogleFonts.outfit(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                          PopupMenuItem(
                            value: 'privacy',
                            child: Text('Privacy Policy', style: GoogleFonts.outfit(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent Projects
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent projects',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      Text(
                        'See all >',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF147A6D)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: onSelectProject,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F322E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Team Intro',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Hi there! My name is Alex ...',
                            style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Icon(Icons.mic, color: Color(0xFF14C8A6), size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'Medium intro',
                                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF14C8A6)),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Content Plans
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Content plans',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      Text(
                        'See all >',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF147A6D)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildContentPlanCard('Introduce yourself', '3 templates', const Color(0xFFFF9E1B)),
                        const SizedBox(width: 16),
                        _buildContentPlanCard('Explain a topic', '8 templates', const Color(0xFFFADE32)),
                        const SizedBox(width: 16),
                        _buildContentPlanCard('Pitch product', '5 templates', const Color(0xFFBB9CFF)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Templates Selector Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Templates',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      GestureDetector(
                        onTap: onSeeTemplates,
                        child: Text(
                          'See all >',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF147A6D)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pitch Your Company', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Color(0xFFFFF0F2), shape: BoxShape.circle),
                                child: const Text('🥁', style: TextStyle(fontSize: 12)),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Introduce Your Service', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Color(0xFFE8F2FF), shape: BoxShape.circle),
                                child: const Text('💬', style: TextStyle(fontSize: 12)),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Curved Branded Bottom Navigation Bar (Dribbble style)
            _buildCustomBottomNavBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContentPlanCard(String title, String count, Color bgColor) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('❞', style: TextStyle(fontSize: 28, color: Colors.black38)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 4),
              Text(
                count,
                style: GoogleFonts.outfit(fontSize: 10, color: Colors.black54),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCustomBottomNavBar(BuildContext context) {
    return Positioned(
      bottom: 12,
      left: 16,
      right: 16,
      height: 72,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.home_outlined, color: Color(0xFF147A6D), size: 24),
            const Icon(Icons.explore_outlined, color: Colors.black38, size: 24),
            
            // Centered green Floating Action Button
            GestureDetector(
              onTap: () => _showCreateProjectSheet(context),
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFF147A6D),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
            
            const Icon(Icons.notifications_none_outlined, color: Colors.black38, size: 24),
            const Icon(Icons.sentiment_satisfied_alt, color: Colors.black38, size: 24),
          ],
        ),
      ),
    );
  }
}
