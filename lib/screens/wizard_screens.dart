import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ----------------------------------------------------
// WIZARD STEP 1 SCREEN
// ----------------------------------------------------
class WizardStep1Screen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;

  const WizardStep1Screen({
    super.key,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<WizardStep1Screen> createState() => _WizardStep1ScreenState();
}

class _WizardStep1ScreenState extends State<WizardStep1Screen> {
  String _selectedTone = 'Upbeat';
  String _selectedMusic = 'Jazz - Classical';
  
  // Checkbox states
  bool _includeIntro = true;
  bool _includeOutro = false;
  bool _includeTopicCard = false;
  bool _includeSpeakerCards = false;
  bool _includeSubtitles = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Step 1 / 2',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            
            // Linear Progress line indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: const LinearProgressIndicator(
                  value: 0.50,
                  backgroundColor: Color(0xFFE5E4DE),
                  color: Color(0xFF147A6D),
                  minHeight: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'General',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 24),

                    // Tone & Pace Section
                    Text(
                      'What\'s the tone and pace you would like for the video?',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      children: [
                        _buildChoiceChip('Upbeat', _selectedTone == 'Upbeat', (sel) {
                          setState(() => _selectedTone = 'Upbeat');
                        }),
                        _buildChoiceChip('Medium', _selectedTone == 'Medium', (sel) {
                          setState(() => _selectedTone = 'Medium');
                        }),
                        _buildChoiceChip('Easy-going', _selectedTone == 'Easy-going', (sel) {
                          setState(() => _selectedTone = 'Easy-going');
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Music Genre Section
                    Text(
                      'What type of music would you like?',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildChoiceChip('Electronic / Hip Hop', _selectedMusic == 'Electronic / Hip Hop', (sel) {
                          setState(() => _selectedMusic = 'Electronic / Hip Hop');
                        }),
                        _buildChoiceChip('Jazz - Classical', _selectedMusic == 'Jazz - Classical', (sel) {
                          setState(() => _selectedMusic = 'Jazz - Classical');
                        }),
                        _buildChoiceChip('Corporate - Easy going', _selectedMusic == 'Corporate - Easy going', (sel) {
                          setState(() => _selectedMusic = 'Corporate - Easy going');
                        }),
                        _buildChoiceChip('No preference', _selectedMusic == 'No preference', (sel) {
                          setState(() => _selectedMusic = 'No preference');
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Elements Checkbox Tray
                    Text(
                      'What elements do you want in your video?',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildCheckboxChip('Intro', _includeIntro, (sel) {
                          setState(() => _includeIntro = sel);
                        }),
                        _buildCheckboxChip('Outro', _includeOutro, (sel) {
                          setState(() => _includeOutro = sel);
                        }),
                        _buildCheckboxChip('Topic card', _includeTopicCard, (sel) {
                          setState(() => _includeTopicCard = sel);
                        }),
                        _buildCheckboxChip('Title cards for speakers', _includeSpeakerCards, (sel) {
                          setState(() => _includeSpeakerCards = sel);
                        }),
                        _buildCheckboxChip('Subtitles', _includeSubtitles, (sel) {
                          setState(() => _includeSubtitles = sel);
                        }),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Bottom Next CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: GestureDetector(
                onTap: widget.onNext,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF147A6D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Next',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool selected, ValueChanged<bool> onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: const Color(0xFF147A6D).withOpacity(0.12),
      checkmarkColor: const Color(0xFF147A6D),
      labelStyle: GoogleFonts.outfit(
        color: selected ? const Color(0xFF147A6D) : Colors.black54,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? const Color(0xFF147A6D) : Colors.transparent,
      ),
    );
  }

  Widget _buildCheckboxChip(String label, bool selected, ValueChanged<bool> onSelected) {
    return InputChip(
      label: Text(label),
      onPressed: () => onSelected(!selected),
      avatar: selected 
          ? const Icon(Icons.check_circle, color: Color(0xFF147A6D), size: 16) 
          : const Icon(Icons.radio_button_unchecked, color: Colors.black26, size: 16),
      backgroundColor: selected ? const Color(0xFF147A6D).withOpacity(0.12) : Colors.white,
      labelStyle: GoogleFonts.outfit(
        color: selected ? const Color(0xFF147A6D) : Colors.black54,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      side: BorderSide(
        color: selected ? const Color(0xFF147A6D) : Colors.transparent,
      ),
    );
  }
}

// ----------------------------------------------------
// WIZARD STEP 2 SCREEN
// ----------------------------------------------------
class WizardStep2Screen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const WizardStep2Screen({
    super.key,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  State<WizardStep2Screen> createState() => _WizardStep2ScreenState();
}

class _WizardStep2ScreenState extends State<WizardStep2Screen> {
  Color _selectedBrandColor = const Color(0xFF142B3F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Step 2 / 2',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            
            // Linear Progress line indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: const LinearProgressIndicator(
                  value: 1.0,
                  backgroundColor: Color(0xFFE5E4DE),
                  color: Color(0xFF147A6D),
                  minHeight: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your brand guidelines',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 24),

                    // Color Palette
                    Text(
                      'Colors',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildColorDot(const Color(0xFF142B3F)),
                        _buildColorDot(const Color(0xFFEF4444)),
                        _buildColorDot(const Color(0xFFF59E0B)),
                        _buildColorDot(const Color(0xFFFBBF24)),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black12, style: BorderStyle.solid),
                              color: Colors.white,
                            ),
                            child: const Icon(Icons.add, color: Colors.black26, size: 14),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Fonts Attachment Card
                    Text(
                      'Fonts',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    _buildAttachmentCard('Lato.otf', '1.2 MB', Icons.text_fields),
                    const SizedBox(height: 28),

                    // Stock footage Card
                    Text(
                      'Your own slides or stock footage',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    _buildAttachmentCard('2020.pdf', '26.4 MB', Icons.picture_as_pdf),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Bottom Submit CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: GestureDetector(
                onTap: widget.onSubmit,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF147A6D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Submit Information',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildColorDot(Color color) {
    bool isSelected = _selectedBrandColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBrandColor = color;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 14),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black87 : Colors.transparent,
            width: isSelected ? 2.5 : 0,
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentCard(String filename, String size, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F2EC),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.black45, size: 16),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(filename, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text(size, style: GoogleFonts.outfit(fontSize: 10, color: Colors.black38)),
                ],
              )
            ],
          ),
          Text(
            'Attach File',
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF147A6D)),
          ),
        ],
      ),
    );
  }
}
