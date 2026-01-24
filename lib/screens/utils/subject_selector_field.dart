import 'package:flutter/material.dart';
import 'package:legend/data/constants/app_constants.dart';
import '../../data/constants/subjects.dart'; // Ensure this points to your ZimsecSubject model

class SubjectSelectorField extends StatefulWidget {
  final List<String> selectedSubjects;
  final ValueChanged<List<String>> onChanged;

  const SubjectSelectorField({
    super.key,
    required this.selectedSubjects,
    required this.onChanged,
  });

  @override
  State<SubjectSelectorField> createState() => _SubjectSelectorFieldState();
}

class _SubjectSelectorFieldState extends State<SubjectSelectorField> {
  void _openSearchModal() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true, // Critical for full height
      backgroundColor: Colors.transparent,
      builder: (context) => _SubjectSearchModal(
        initialSelection: widget.selectedSubjects,
        allSubjects: ZimsecSubject.allNames, 
      ),
    );

    if (result != null) {
      widget.onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. THE TRIGGER BUTTON
        InkWell(
          onTap: _openSearchModal,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.backgroundBlack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(30)),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book_outlined, color: AppColors.textGrey, size: 20),
                const SizedBox(width: 12),
                Text(
                  widget.selectedSubjects.isEmpty 
                      ? "Select Subjects..." 
                      : "${widget.selectedSubjects.length} Subjects Selected",
                  style: TextStyle(
                    color: widget.selectedSubjects.isEmpty ? AppColors.textGrey : Colors.white,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: AppColors.textGrey),
              ],
            ),
          ),
        ),

        // 2. THE CHIP DISPLAY (If items selected)
        if (widget.selectedSubjects.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedSubjects.map((subject) {
              return Chip(
                label: Text(
                  subject, 
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                backgroundColor: AppColors.primaryBlue.withAlpha(40),
                deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white70),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onDeleted: () {
                  final newList = List<String>.from(widget.selectedSubjects);
                  newList.remove(subject);
                  widget.onChanged(newList);
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// INTERNAL MODAL WIDGET (With Custom Adder)
// -----------------------------------------------------------------------------
class _SubjectSearchModal extends StatefulWidget {
  final List<String> initialSelection;
  final List<String> allSubjects;

  const _SubjectSearchModal({
    required this.initialSelection,
    required this.allSubjects,
  });

  @override
  State<_SubjectSearchModal> createState() => _SubjectSearchModalState();
}

class _SubjectSearchModalState extends State<_SubjectSearchModal> {
  late List<String> _selected;
  late List<String> _filteredList;
  final TextEditingController _searchCtrl = TextEditingController();
  
  // Custom Subject Helper State
  String? _customSubjectCandidate;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelection);
    _filteredList = List.from(widget.allSubjects);
    
    // Ensure existing custom subjects (not in the static list) are visible
    for (var s in _selected) {
      if (!_filteredList.contains(s)) {
        _filteredList.add(s);
      }
    }
    
    _sortList();
  }

  void _sortList() {
    _filteredList.sort((a, b) {
      final aSelected = _selected.contains(a);
      final bSelected = _selected.contains(b);
      if (aSelected && !bSelected) return -1;
      if (!aSelected && bSelected) return 1;
      return a.compareTo(b);
    });
  }

  void _filter(String query) {
    setState(() {
      final cleanQuery = query.trim();
      
      if (cleanQuery.isEmpty) {
        _filteredList = List.from(widget.allSubjects);
        // Re-add selected custom ones if any
        for (var s in _selected) {
          if (!_filteredList.contains(s)) _filteredList.add(s);
        }
        _customSubjectCandidate = null;
      } else {
        // Standard Filter
        _filteredList = widget.allSubjects
            .where((s) => s.toLowerCase().contains(cleanQuery.toLowerCase()))
            .toList();
        
        // Check if exact match exists
        final exactMatch = _filteredList.any((s) => s.toLowerCase() == cleanQuery.toLowerCase());
        
        // If no exact match, propose adding it
        if (!exactMatch && cleanQuery.isNotEmpty) {
          _customSubjectCandidate = cleanQuery;
        } else {
          _customSubjectCandidate = null;
        }
      }
      _sortList();
    });
  }

  void _toggleItem(String subject) {
    setState(() {
      if (_selected.contains(subject)) {
        _selected.remove(subject);
      } else {
        _selected.add(subject);
      }
      _searchCtrl.clear();
      _filter(''); // Reset filter to show selection
    });
  }

  void _addCustomSubject() {
    if (_customSubjectCandidate != null) {
      // Capitalize first letter for neatness
      final formatted = toBeginningOfSentenceCase(_customSubjectCandidate!) ?? _customSubjectCandidate!;
      
      setState(() {
        if (!_filteredList.contains(formatted)) {
          _filteredList.insert(0, formatted); // Add to local list view
        }
        if (!_selected.contains(formatted)) {
          _selected.add(formatted);
        }
        _searchCtrl.clear();
        _customSubjectCandidate = null;
        _filter(''); // Reset view
      });
    }
  }
  
  // Helper for capitalization since intl might not be everywhere
  String? toBeginningOfSentenceCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85, 
      decoration: const BoxDecoration(
        color: AppColors.backgroundBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 1. DRAG HANDLE & TITLE
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceLightGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              "Manage Enrollment",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // 2. SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filter,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search or add custom...",
                hintStyle: const TextStyle(color: AppColors.textGrey),
                prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
                filled: true,
                fillColor: AppColors.surfaceDarkGrey,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. LIST VIEW
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // A. CUSTOM ADDER TILE (Only if candidate exists)
                if (_customSubjectCandidate != null) ...[
                  ListTile(
                    onTap: _addCustomSubject,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add, color: AppColors.successGreen, size: 20),
                    ),
                    title: RichText(
                      text: TextSpan(
                        text: "Add custom: ",
                        style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                        children: [
                          TextSpan(
                            text: '"$_customSubjectCandidate"',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: AppColors.surfaceLightGrey, height: 24),
                ],

                // B. STANDARD LIST
                ..._filteredList.map((subject) {
                  final isSelected = _selected.contains(subject);
                  return Column(
                    children: [
                      ListTile(
                        onTap: () => _toggleItem(subject),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          subject,
                          style: TextStyle(
                            color: isSelected ? AppColors.primaryBlueLight : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppColors.primaryBlue)
                            : const Icon(Icons.circle_outlined, color: AppColors.textGrey),
                      ),
                      const Divider(color: AppColors.surfaceDarkGrey, height: 1),
                    ],
                  );
                }),
              ],
            ),
          ),

          // 4. DONE BUTTON
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Done (${_selected.length})", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}