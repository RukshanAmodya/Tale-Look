import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProjectDetailsScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onWriteScript;
  final VoidCallback onRecordClips;

  const ProjectDetailsScreen({
    super.key,
    required this.onBack,
    required this.onWriteScript,
    required this.onRecordClips,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: SafeArea(
        child: Column(
          children: [
            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
                  ),
                  Text(
                    'Project X',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Icon(Icons.more_vert, color: Colors.black, size: 20),
                ],
              ),
            ),

            // Tab switcher: Overview | Task Manager | Team
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTabItem('Overview', true),
                  _buildTabItem('Task Manager', false),
                  _buildTabItem('Team', false),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    // Mockup Image Portrait Card of Lady with play button
                    Container(
                      width: 160,
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD166), // Orange bg
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Graphic face outline representation
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.face, color: Colors.black45, size: 80),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Short intro',
                                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              )
                            ],
                          ),
                          // Central Play Button
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFF147A6D),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // List of Wizard Steps
                    _buildStepRow('Write a script', Icons.text_fields, onWriteScript),
                    const SizedBox(height: 12),
                    _buildStepRow('Record your clips', Icons.videocam, onRecordClips),
                    const SizedBox(height: 12),
                    _buildStepRow('Final edits', Icons.layers, () {}),
                    
                    const SizedBox(height: 40),
                    // Action button
                    Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBEAE4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Complete steps above to generate video',
                          style: GoogleFonts.outfit(
                            color: Colors.black38,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String title, bool active) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            color: active ? const Color(0xFF147A6D) : Colors.black45,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        if (active) ...[
          const SizedBox(height: 6),
          Container(width: 40, height: 2.5, color: const Color(0xFF147A6D)),
        ]
      ],
    );
  }

  Widget _buildStepRow(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F2EC),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF147A6D), size: 18),
            ),
            const SizedBox(width: 14),
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
            const Icon(Icons.arrow_forward_ios, color: Colors.black26, size: 14),
          ],
        ),
      ),
    );
  }
}
