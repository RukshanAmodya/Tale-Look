import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final VoidCallback onBack;

  const PrivacyPolicyScreen({super.key, required this.onBack});

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
                  Expanded(
                    child: Center(
                      child: Text(
                        'Privacy Policy',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
              const SizedBox(height: 30),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tale Look Privacy Terms',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Last updated: July 18, 2026',
                        style: GoogleFonts.outfit(fontSize: 11, color: Colors.black38),
                      ),
                      const SizedBox(height: 20),

                      _buildSectionHeader('1. Data Collection & Camera Access'),
                      _buildSectionBody(
                        'Tale Look requires local camera and microphone permissions to capture video clips while scrolling your teleprompter text. All recorded videos are saved directly to your device\'s gallery. QuestraX does not collect, transmit, or store any video or audio recordings on external servers.'
                      ),
                      
                      _buildSectionHeader('2. Local Script Data Storage'),
                      _buildSectionBody(
                        'All scripts, segments, and brand color selections are stored locally on your device. Clearing app data or uninstalling the app will permanently delete these files.'
                      ),
                      
                      _buildSectionHeader('3. Third-party SDK Integrations'),
                      _buildSectionBody(
                        'We utilize native Android and iOS camera SDKs to guarantee hardware alignment. We do not integrate data-harvesting trackers or analytics tools that compromise your creative flow.'
                      ),

                      _buildSectionHeader('4. Contact Information'),
                      _buildSectionBody(
                        'For questions or feedback regarding our software guidelines, reach out directly to developer support at support@questrax.com.'
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF147A6D),
        ),
      ),
    );
  }

  Widget _buildSectionBody(String body) {
    return Text(
      body,
      style: GoogleFonts.outfit(
        fontSize: 13,
        color: Colors.black54,
        height: 1.5,
      ),
    );
  }
}
