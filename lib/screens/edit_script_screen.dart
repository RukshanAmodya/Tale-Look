import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telelook/models/script.dart';

class EditScriptScreen extends StatefulWidget {
  final TeleprompterScript script;
  final Function(TeleprompterScript) onSave;
  final Function(TeleprompterScript) onStartReading;
  final VoidCallback onCancel;

  const EditScriptScreen({
    super.key,
    required this.script,
    required this.onSave,
    required this.onStartReading,
    required this.onCancel,
  });

  @override
  State<EditScriptScreen> createState() => _EditScriptScreenState();
}

class _EditScriptScreenState extends State<EditScriptScreen> {
  late TeleprompterScript _editedScript;
  late TextEditingController _titleController;
  final List<TextEditingController> _segmentControllers = [];
  int? _activeEditingSegmentIndex;

  @override
  void initState() {
    super.initState();
    _editedScript = widget.script.copyWith();
    _titleController = TextEditingController(text: _editedScript.title);
    for (var seg in _editedScript.segments) {
      _segmentControllers.add(TextEditingController(text: seg.content));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var c in _segmentControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addNewSegment() {
    setState(() {
      _editedScript.segments.add(
        ScriptSegment(
          title: 'New Segment',
          content: '',
          emotions: ['natural'],
        ),
      );
      _segmentControllers.add(TextEditingController());
    });
  }

  void _saveChanges() {
    _editedScript.title = _titleController.text;
    for (int i = 0; i < _editedScript.segments.length; i++) {
      _editedScript.segments[i].content = _segmentControllers[i].text;
    }
    widget.onSave(_editedScript);
  }

  void _startReading() {
    _editedScript.title = _titleController.text;
    for (int i = 0; i < _editedScript.segments.length; i++) {
      _editedScript.segments[i].content = _segmentControllers[i].text;
    }
    widget.onStartReading(_editedScript);
  }

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: widget.onCancel,
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
                    'Edit script',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: _saveChanges,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.black, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            
            // Editable Form
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Welcome speech',
                        hintStyle: TextStyle(color: Colors.black26),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Dec 9 • ${_editedScript.wordCount} words • ${_editedScript.durationString}',
                      style: GoogleFonts.outfit(color: Colors.black38, fontSize: 13),
                    ),
                    const SizedBox(height: 30),
                    
                    // Segments
                    ListView.builder(
                      itemCount: _editedScript.segments.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final segment = _editedScript.segments[index];
                        final controller = _segmentControllers[index];
                        final isEditingThis = _activeEditingSegmentIndex == index;
                        
                        return isEditingThis 
                            ? _buildFullSegmentEditor(index, segment, controller)
                            : _buildCompactSegmentBlock(index, segment, controller);
                      },
                    ),
                    
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: _addNewSegment,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF147A6D).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF147A6D).withOpacity(0.2), width: 1.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, color: Color(0xFF147A6D), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Segment',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF147A6D),
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            
            _buildBottomActionPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSegmentBlock(int index, ScriptSegment segment, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F6F4),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.arrow_right_alt, color: Color(0xFF147A6D), size: 10),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeEditingSegmentIndex = index;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    segment.title,
                    style: GoogleFonts.outfit(
                      color: Colors.black45,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    controller.text.isNotEmpty ? controller.text : 'Tap to write...',
                    style: TextStyle(
                      fontFamily: RegExp(r'[\u0D80-\u0DFF]').hasMatch(controller.text) ? 'SinhalaSangam' : null,
                      color: controller.text.isNotEmpty ? Colors.black87 : Colors.black26,
                      fontSize: 16,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullSegmentEditor(int index, ScriptSegment segment, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF147A6D).withOpacity(0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Editing Segment',
                style: GoogleFonts.outfit(color: Colors.black38, fontSize: 12),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _activeEditingSegmentIndex = null;
                  });
                },
                child: Text(
                  'Done',
                  style: GoogleFonts.outfit(color: const Color(0xFF147A6D), fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: segment.title,
            style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Segment Label',
              labelStyle: TextStyle(color: Colors.black38),
              border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF147A6D))),
            ),
            onChanged: (val) {
              segment.title = val;
            },
          ),
          const SizedBox(height: 15),
          TextField(
            controller: controller,
            maxLines: null,
            style: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.45),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Type script details...',
              hintStyle: TextStyle(color: Colors.black26),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...List.generate(segment.emotions.length, (emoIndex) {
                final emo = segment.emotions[emoIndex];
                return Chip(
                  label: Text(emo, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF147A6D))),
                  backgroundColor: const Color(0xFF147A6D).withOpacity(0.08),
                  side: const BorderSide(color: Colors.transparent),
                  onDeleted: () {
                    setState(() {
                      segment.emotions.removeAt(emoIndex);
                    });
                  },
                  deleteIcon: const Icon(Icons.close, size: 12, color: Color(0xFF147A6D)),
                );
              }),
              GestureDetector(
                onTap: () {
                  _addEmotionTag(segment);
                },
                child: Chip(
                  avatar: const Icon(Icons.add, color: Colors.black38, size: 12),
                  label: Text('Emotion', style: GoogleFonts.outfit(fontSize: 12, color: Colors.black38)),
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: Colors.black26),
                ),
              )
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Simulate voice dictation',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.black38),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    controller.text += " (dictated speech block)";
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF147A6D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 14),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  void _addEmotionTag(ScriptSegment segment) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Add Emotion/Tone Tag', style: GoogleFonts.outfit(color: Colors.black87)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.black87),
            decoration: const InputDecoration(
              hintText: 'e.g. confident, excited, bold',
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF147A6D))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    segment.emotions.add(controller.text.trim());
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF147A6D)),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomActionPanel() {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          )
        ]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _startReading,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF147A6D),
                borderRadius: BorderRadius.circular(27),
              ),
              child: Center(
                child: Text(
                  'Start reading',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _saveChanges,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(27),
                border: Border.all(color: const Color(0xFF147A6D), width: 1.5),
              ),
              child: Center(
                child: Text(
                  'Save & Exit',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF147A6D),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
