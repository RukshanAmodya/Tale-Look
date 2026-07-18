import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onSelectProject;
  final VoidCallback onSeeTemplates;
  final VoidCallback onSelectAbout;
  final VoidCallback onSelectPrivacy;

  const HomeScreen({
    super.key,
    required this.onSelectProject,
    required this.onSeeTemplates,
    required this.onSelectAbout,
    required this.onSelectPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
                  
                  // Production-Ready Settings Menu Button
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
              const SizedBox(height: 30),
            ],
          ),
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
}
