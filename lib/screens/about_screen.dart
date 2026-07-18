import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  final VoidCallback onBack;

  const AboutScreen({super.key, required this.onBack});

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
                        'About App',
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
              const SizedBox(height: 40),

              Center(
                child: Column(
                  children: [
                    // Branded folded geometric logo shape representation
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFF147A6D), // Teal Logo Box
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: const Center(
                        child: Text(
                          'T',
                          style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tale Look',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Version 1.0.0',
                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.black38),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Description Info
              Text(
                'Tale Look is a professional, high-fidelity teleprompter application engineered for content creators, speakers, and corporate leaders. Crafted to capture studio-grade videos with flawless eye alignment, intelligent scroller speed controls, and segment scripting helpers.',
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 30),

              const Divider(color: Colors.black12, height: 1),
              const SizedBox(height: 24),

              // Company Credits
              Text(
                'Developed By',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 1),
              ),
              const SizedBox(height: 6),
              Text(
                'QuestraX Inc.',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF147A6D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '© 2026 QuestraX. All rights reserved.',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.black38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
