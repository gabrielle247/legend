import 'package:intl/intl.dart';
import 'package:legend/app_libs.dart'; 

class AddStudentScreen extends StatelessWidget {
  const AddStudentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final auth = context.read<AuthService>();
        final repo = context.read<StudentRepository>();
        return AddStudentViewModel(repo, auth.activeSchool?.id ?? '');
      },
      child: const _AddStudentContent(),
    );
  }
}

class _AddStudentContent extends StatefulWidget {
  const _AddStudentContent();

  @override
  State<_AddStudentContent> createState() => _AddStudentContentState();
}

class _AddStudentContentState extends State<_AddStudentContent> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _handleSubmit(AddStudentViewModel vm) async {
    if (_formKey.currentState!.validate()) {
      if (vm.selectedGradeName == null) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a Grade Level"), backgroundColor: AppColors.errorRed),
        );
        return;
      }

      if (vm.selectedSubjects.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select at least one subject."), backgroundColor: AppColors.errorRed),
        );
        return;
      }

      final success = await vm.submit();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.studentRegisterSuccess), backgroundColor: AppColors.successGreen),
        );
        context.pop();
      } else if (vm.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(vm.error!), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddStudentViewModel>();

    if (vm.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundBlack,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      );
    }

    if (vm.blockingError != null) {
      return _buildBlockingError(context, vm.blockingError!);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text("NEW ADMISSION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: () => _handleSubmit(vm),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaryBlue.withAlpha(30),
                foregroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.check, size: 18),
              label: const Text(AppStrings.save, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _IdentitySection(vm: vm),
                          const SizedBox(height: 24),
                          _GuardianSection(vm: vm),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          _AcademicSection(vm: vm),
                          const SizedBox(height: 24),
                          _FinancialSection(vm: vm),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _IdentitySection(vm: vm),
                    const SizedBox(height: 24),
                    _AcademicSection(vm: vm),
                    const SizedBox(height: 24),
                    _GuardianSection(vm: vm),
                    const SizedBox(height: 24),
                    _FinancialSection(vm: vm),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBlockingError(BuildContext context, String error) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(backgroundColor: AppColors.backgroundBlack, elevation: 0),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkGrey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.errorRed.withAlpha(50)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block, color: AppColors.errorRed, size: 48),
              const SizedBox(height: 24),
              const Text("Setup Required", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGrey, fontSize: 16)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceLightGrey),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SECTIONS (Strictly using AppStrings)
// -----------------------------------------------------------------------------

class _IdentitySection extends StatelessWidget {
  final AddStudentViewModel vm;
  const _IdentitySection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: AppStrings.identity.toUpperCase(),
      icon: Icons.fingerprint,
      children: [
        Row(
          children: [
            Expanded(
              child: _CompactTextField(
                controller: vm.firstNameCtrl,
                label: AppStrings.fieldFirstName,
                validator: (v) => v!.isEmpty ? AppStrings.required : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CompactTextField(
                controller: vm.lastNameCtrl,
                label: AppStrings.fieldLastName,
                validator: (v) => v!.isEmpty ? AppStrings.required : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _CompactDropdown(
                value: vm.selectedGender,
                items: const [AppStrings.genderMale, AppStrings.genderFemale],
                label: AppStrings.gender,
                onChanged: (val) => vm.selectedGender = val,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CompactDropdown(
                value: vm.selectedStudentType,
                items: const [AppStrings.studentTypeAcademy, AppStrings.studentTypePrivate],
                label: AppStrings.studentType,
                onChanged: (val) => vm.selectedStudentType = val,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GuardianSection extends StatelessWidget {
  final AddStudentViewModel vm;
  const _GuardianSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: AppStrings.gContact.toUpperCase(),
      icon: Icons.family_restroom,
      children: [
        _CompactTextField(
          controller: vm.guardianNameCtrl,
          label: AppStrings.gName,
          icon: Icons.person_outline,
          validator: (v) => v!.isEmpty ? AppStrings.required : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _CompactTextField(
                controller: vm.guardianPhoneCtrl,
                label: AppStrings.gPhone,
                icon: Icons.phone,
                inputType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: _CompactTextField(
                controller: vm.guardianEmailCtrl,
                label: "Email (Optional)",
                icon: Icons.email_outlined,
                inputType: TextInputType.emailAddress,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AcademicSection extends StatelessWidget {
  final AddStudentViewModel vm;
  const _AcademicSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: AppStrings.placement.toUpperCase(),
      icon: Icons.school,
      children: [
        // 1. Grade Dropdown (Using DropdownMenu for searchability)
        Text(AppStrings.gLevel, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return DropdownMenu<String>(
              width: constraints.maxWidth,
              initialSelection: vm.selectedGradeName,
              hintText: "Select Class",
              textStyle: const TextStyle(color: Colors.white),
              menuStyle: MenuStyle(backgroundColor: MaterialStateProperty.all(AppColors.surfaceDarkGrey)),
              inputDecorationTheme: InputDecorationTheme(
                 filled: true,
                 fillColor: AppColors.backgroundBlack,
                 contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.surfaceLightGrey.withAlpha(30))),
              ),
              dropdownMenuEntries: vm.grades.map<DropdownMenuEntry<String>>((String value) {
                return DropdownMenuEntry<String>(
                  value: value, 
                  label: value,
                  style: ButtonStyle(foregroundColor: MaterialStateProperty.all(Colors.white)),
                );
              }).toList(),
              onSelected: (String? value) {
                vm.selectedGradeName = value;
              },
            );
          }
        ),
        
        const SizedBox(height: 24),
        
        // 2. AWESOME SUBJECT MODAL TRIGGER
        Text(
          AppStrings.secSubjects.toUpperCase(),
          style: const TextStyle(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        
        InkWell(
          onTap: () async {
            // Open the Awesome Modal
            final List<String>? result = await showModalBottomSheet<List<String>>(
              context: context,
              isScrollControlled: true, // Full height capability
              backgroundColor: Colors.transparent,
              builder: (context) => SubjectSelectionModal(
                allSubjects: vm.availableSubjects,
                alreadySelected: vm.selectedSubjects,
              ),
            );

            // Update VM if result returned
            if (result != null) {
              // We manually update the list in the VM using a loop to ensure notification
              // This is safer than replacing the list directly if there's no specific setter
              // First, clear everything
              final toRemove = List<String>.from(vm.selectedSubjects);
              for (var s in toRemove) {
                vm.toggleSubject(s); // Toggle OFF
              }
              // Then add new ones
              for (var s in result) {
                vm.toggleSubject(s); // Toggle ON
              }
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundBlack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: vm.selectedSubjects.isEmpty
                    ? const Text("Tap to select subjects...", style: TextStyle(color: AppColors.textGrey, fontStyle: FontStyle.italic))
                    : Text(
                        "${vm.selectedSubjects.length} Subjects Selected",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                ),
                const Icon(Icons.arrow_forward_ios, color: AppColors.textGrey, size: 14),
              ],
            ),
          ),
        ),

        // 3. Selected Chips Display (Read Only)
        if (vm.selectedSubjects.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, 
            runSpacing: 8,
            children: vm.selectedSubjects.map((s) => Chip(
              label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 11)),
              backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            )).toList(),
          ),
        ]
      ],
    );
  }
}

class _FinancialSection extends StatelessWidget {
  final AddStudentViewModel vm;
  const _FinancialSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: AppStrings.bEssentials.toUpperCase(),
      icon: Icons.attach_money,
      accentColor: AppColors.primaryBlue.withAlpha(20),
      children: [
        Row(
          children: [
            Expanded(
              child: _CompactDropdown(
                value: vm.selectedBillingCycle,
                items: vm.billingTypes,
                label: AppStrings.bSchedule,
                onChanged: (val) => vm.selectedBillingCycle = val,
              ),
            ),
            if (vm.selectedBillingCycle == "Monthly (Custom Date)") ...[
              const SizedBox(width: 12),
              Expanded(
                child: _CompactDatePicker(
                  label: AppStrings.selectBDate,
                  selectedDate: vm.customBillingDate,
                  onSelect: (date) => vm.customBillingDate = date,
                ),
              ),
            ]
          ],
        ),
        const SizedBox(height: 20),
        const Divider(color: AppColors.surfaceLightGrey),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _CompactTextField(
                controller: vm.openingBalanceCtrl,
                label: AppStrings.amntOwing,
                icon: Icons.money_off,
                inputType: const TextInputType.numberWithOptions(decimal: true),
                textColor: AppColors.errorRed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: _CompactTextField(
                controller: vm.debtDescriptionCtrl,
                label: AppStrings.description,
                placeholder: "e.g. Term 1 Balance",
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.successGreen.withAlpha(50)),
          ),
          child: Row(
            children: [
              const Icon(Icons.receipt_long, color: AppColors.successGreen, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.generateInvoice, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(AppStrings.standardAction, style: TextStyle(color: AppColors.textGrey, fontSize: 11)),
                  ],
                ),
              ),
              Switch(
                value: vm.generateInvoiceNow,
                activeThumbColor: AppColors.successGreen,
                activeTrackColor: AppColors.successGreen.withAlpha(100),
                onChanged: (val) => vm.generateInvoiceNow = val,
              ),
            ],
          ),
        )
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// REUSABLE WIDGETS
// -----------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color? accentColor;

  const _SectionCard({required this.title, required this.icon, required this.children, this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accentColor ?? AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.textGrey),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceLightGrey),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }
}

class _CompactTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? placeholder;
  final IconData? icon;
  final TextInputType inputType;
  final Color? textColor;
  final String? Function(String?)? validator;

  const _CompactTextField({
    required this.controller,
    required this.label,
    this.placeholder,
    this.icon,
    this.inputType = TextInputType.text,
    this.textColor,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          validator: validator,
          style: TextStyle(color: textColor ?? Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: AppColors.textGrey.withAlpha(100)),
            prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.textGrey) : null,
            filled: true,
            fillColor: AppColors.backgroundBlack,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.surfaceLightGrey.withAlpha(30))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.errorRed)),
          ),
        ),
      ],
    );
  }
}

class _CompactDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final String label;
  final ValueChanged<String?> onChanged;

  const _CompactDropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveValue = items.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: effectiveValue,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          dropdownColor: AppColors.surfaceDarkGrey,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.backgroundBlack,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.surfaceLightGrey.withAlpha(30))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue)),
          ),
        ),
      ],
    );
  }
}

class _CompactDatePicker extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelect;

  const _CompactDatePicker({required this.label, required this.selectedDate, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder: (ctx, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(primary: AppColors.primaryBlue, onPrimary: Colors.white, surface: AppColors.surfaceDarkGrey),
                ),
                child: child!,
              ),
            );
            if (date != null) onSelect(date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.backgroundBlack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(30)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.textGrey),
                const SizedBox(width: 8),
                Text(
                  selectedDate != null ? DateFormat("MMM dd, yyyy").format(selectedDate!) : "Select Date",
                  style: TextStyle(color: selectedDate != null ? Colors.white : AppColors.textGrey, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// THE AWESOME SUBJECT MODAL (Internal Class)
// -----------------------------------------------------------------------------

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
    // Clone list so we don't mutate parent until save
    _tempSelected = List.from(widget.alreadySelected);
  }

  @override
  Widget build(BuildContext context) {
    final visibleSubjects = widget.allSubjects.where((s) {
      return s.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85, 
      decoration: const BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // HEADER
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
                  onPressed: () => Navigator.pop(context, _tempSelected), 
                  child: const Text("DONE", style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          
          // SEARCH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: AppStrings.search, 
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

          // LIST
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