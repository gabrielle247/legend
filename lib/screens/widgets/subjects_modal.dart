import 'package:legend/app_libs.dart';

class SubjectSelectionModal extends StatefulWidget {
  final List<String> allSubjects;
  final List<String> alreadySelected;
  
  const SubjectSelectionModal({
    super.key, 
    required this.allSubjects, 
    required this.alreadySelected
  });

  @override
  State<SubjectSelectionModal> createState() => _SubjectSelectionModalState();
}

class _SubjectSelectionModalState extends State<SubjectSelectionModal> {
  late List<String> _tempSelected;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    // Clone the list so we don't mutate parent state until "SAVE" is clicked
    _tempSelected = List.from(widget.alreadySelected);
  }

  @override
  Widget build(BuildContext context) {
    // Filter logic
    final visibleSubjects = widget.allSubjects.where((s) {
      return s.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // 85% Height
      decoration: const BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 1. HEADER
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Subjects", 
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _tempSelected), // Return result
                  child: const Text("DONE", style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          
          // 2. SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: AppStrings.search, // "Search"
                hintStyle: TextStyle(color: AppColors.textGrey.withAlpha(100)),
                prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
                filled: true,
                fillColor: AppColors.backgroundBlack,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(height: 10),

          // 3. LIST
          Expanded(
            child: ListView.builder(
              itemCount: visibleSubjects.length,
              itemBuilder: (context, index) {
                final subject = visibleSubjects[index];
                final isSelected = _tempSelected.contains(subject);

                return CheckboxListTile(
                  title: Text(subject, style: const TextStyle(color: Colors.white)),
                  value: isSelected,
                  activeColor: AppColors.primaryBlue,
                  checkColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  onChanged: (bool? checked) {
                    setState(() {
                      if (checked == true) {
                        _tempSelected.add(subject);
                      } else {
                        _tempSelected.remove(subject);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}