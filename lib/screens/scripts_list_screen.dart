import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telelook/models/script.dart';

class ScriptsListScreen extends StatelessWidget {
  final List<TeleprompterScript> scripts;
  final Function(int) onSelectScript;
  final Function(int) onEditScript;
  final VoidCallback onCreateScript;

  const ScriptsListScreen({
    super.key,
    required this.scripts,
    required this.onSelectScript,
    required this.onEditScript,
    required this.onCreateScript,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                    ),
                  ),
                  Text(
                    'Scripts',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search, color: Colors.black, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              // Scrollable list of cards
              Expanded(
                child: ListView.builder(
                  itemCount: scripts.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final script = scripts[index];
                        
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF147A6D).withOpacity(0.08), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Dec 9 • ${script.wordCount} words • ${script.durationString}',
                                style: GoogleFonts.outfit(
                                  color: Colors.black38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => onEditScript(index),
                                child: Text(
                                  'Edit',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF147A6D),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 18),
                          
                          Text(
                            script.title,
                            style: GoogleFonts.outfit(
                              color: Colors.black87,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            script.segments.first.content,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: RegExp(r'[\u0D80-\u0DFF]').hasMatch(script.segments.first.content) ? 'SinhalaSangam' : null,
                              color: Colors.black54,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF147A6D).withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.auto_awesome, 
                                  color: Color(0xFF147A6D), 
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => onSelectScript(index),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      color: const Color(0xFF147A6D),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Start reading',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: onCreateScript,
        backgroundColor: const Color(0xFF147A6D),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
