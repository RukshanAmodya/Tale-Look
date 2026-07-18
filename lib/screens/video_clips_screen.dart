import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VideoClipsScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onStartRecording;

  const VideoClipsScreen({
    super.key,
    required this.onBack,
    required this.onStartRecording,
  });

  @override
  State<VideoClipsScreen> createState() => _VideoClipsScreenState();
}

class _VideoClipsScreenState extends State<VideoClipsScreen> {
  bool _isScriptTab = true; // true = Script, false = Record
  
  // Controllers for mock user scripts
  final TextEditingController _overviewController = TextEditingController();
  final TextEditingController _clientsController = TextEditingController();
  final TextEditingController _problemController = TextEditingController();

  @override
  void dispose() {
    _overviewController.dispose();
    _clientsController.dispose();
    _problemController.dispose();
    super.dispose();
  }

  int _getWordCount(String text) {
    return text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
  }

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
                    onTap: widget.onBack,
                    child: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
                  ),
                  Text(
                    'My project',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Icon(Icons.more_vert, color: Colors.black, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Tab toggles matching mockups: Script | Record
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E4DE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    // Script Tab
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isScriptTab = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _isScriptTab ? const Color(0xFF147A6D) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Script',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: _isScriptTab ? Colors.white : Colors.black54,
                                fontWeight: _isScriptTab ? FontWeight.bold : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Record Tab
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isScriptTab = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isScriptTab ? const Color(0xFF147A6D) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Record',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: !_isScriptTab ? Colors.white : Colors.black54,
                                fontWeight: !_isScriptTab ? FontWeight.bold : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Toggleable Workspace Area
            Expanded(
              child: _isScriptTab 
                  ? _buildScriptWorkspace() 
                  : _buildRecordWorkspace(),
            ),
          ],
        ),
      ),
    );
  }

  // Frame 3: Script Writing Workspace
  Widget _buildScriptWorkspace() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildScriptInputField('Product overview', _overviewController),
        const SizedBox(height: 20),
        _buildScriptInputField('Clients', _clientsController),
        const SizedBox(height: 20),
        _buildScriptInputField('Problem', _problemController),
        const SizedBox(height: 24),
        
        // Add new video clip green button
        GestureDetector(
          onTap: () {},
          child: Row(
            children: [
              const Icon(Icons.add, color: Color(0xFF147A6D), size: 16),
              const SizedBox(width: 6),
              Text(
                'Add a new video clip',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF147A6D),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildScriptInputField(String sectionTitle, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              sectionTitle,
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Icon(Icons.lightbulb_outline, color: Colors.black38, size: 16),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: controller,
                maxLines: 4,
                onChanged: (val) => setState(() {}),
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Type your clip content here...',
                  hintStyle: TextStyle(color: Colors.black12, fontSize: 13),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_getWordCount(controller.text)} / 2500',
                style: GoogleFonts.outfit(fontSize: 10, color: Colors.black26),
              )
            ],
          ),
        )
      ],
    );
  }

  // Frame 4: Record Video Clips list Workspace
  Widget _buildRecordWorkspace() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildRecordClipCard('Product overview', 'Video clip A'),
        const SizedBox(height: 16),
        _buildRecordClipCard('Clients', 'Video clip A'),
        const SizedBox(height: 16),
        _buildRecordClipCard('Problem', 'Video clip A'),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildRecordClipCard(String category, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              
              // Red Record Action Button
              GestureDetector(
                onTap: widget.onStartRecording,
                child: Row(
                  children: [
                    const Icon(Icons.fiber_manual_record, color: Color(0xFFEF4444), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Record',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
