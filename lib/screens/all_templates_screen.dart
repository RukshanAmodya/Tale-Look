import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AllTemplatesScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSelectTemplate;

  const AllTemplatesScreen({
    super.key,
    required this.onBack,
    required this.onSelectTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Center(
                      child: Text(
                        'All templates',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24), // spacing block
                ],
              ),
              const SizedBox(height: 20),

              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E4DE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.black38, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search',
                          hintStyle: GoogleFonts.outfit(color: Colors.black38, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Scrollable list
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildTemplateItem('Your Business Overview', '🔍', const Color(0xFF142B3F), onSelectTemplate),
                    _buildTemplateItem('Introduce Yourself in 60 Seconds', '👋', const Color(0xFFC83A3A), onSelectTemplate),
                    _buildTemplateItem('Employee Experience Video', '🐝', const Color(0xFF14C85E), onSelectTemplate),
                    _buildTemplateItem('Explain Problem & Give a Solution', '🏆', const Color(0xFFFACC15), onSelectTemplate),
                    _buildTemplateItem('Promote a Cause', '🎁', const Color(0xFF3B82F6), onSelectTemplate),
                    _buildTemplateItem('LinkedIn Profile Introduction', '🎙️', const Color(0xFF6366F1), onSelectTemplate),
                    _buildTemplateItem('Introduce Your Service / Product', '💬', const Color(0xFF2563EB), onSelectTemplate),
                    _buildTemplateItem('Pitch Your Company to Investors', '🥁', const Color(0xFFEF4444), onSelectTemplate),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateItem(String title, String emoji, Color iconBgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 14)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
