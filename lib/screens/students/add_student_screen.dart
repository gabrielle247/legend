import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:legend/constants/app_constants.dart';
import 'package:legend/constants/app_strings.dart';
import 'package:legend/screens/utils/subject_selector_field.dart';
import 'package:legend/vmodels/add_student_view_model.dart';

// -----------------------------------------------------------------------------
// SCREEN UI
// -----------------------------------------------------------------------------
class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vm = AddStudentViewModel();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      // -----------------------------------------------------------------------
      // TODO: IMPLEMENT REGISTRATION LOGIC
      // -----------------------------------------------------------------------
      
      // 1. INSERT into legend.students
      // Note: Do NOT send 'admission_number'. Let DB trigger/default handle it.
      
      // 2. INSERT into legend.enrollments
      
      // 3. HANDLE OPENING BALANCE 
      
      // 4. HANDLE IMMEDIATE BILLING

      debugPrint("${AppStrings.savingSubjects} ${_vm.selectedSubjects}");
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.studentRegisterSuccess), backgroundColor: AppColors.successGreen),
      );
      context.pop(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(AppStrings.newAdmission, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _handleSubmit,
            child: const Text(AppStrings.save, style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------------------------
              // 1. IDENTITY SECTION
              // ---------------------------------------------------------------
              _buildSectionHeader(AppStrings.identity),
              _buildCard(
                children: [
                  // Names
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _vm.firstNameCtrl,
                          label: AppStrings.fieldFirstName,//"First Name",
                          icon: Icons.person_outline,
                          validator: (v) => v!.isEmpty ? AppStrings.required : null,//"Required" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _vm.lastNameCtrl,
                          label: AppStrings.fieldLastName,//"Last Name",
                          icon: Icons.person_outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Gender & Type (Moved Type here to fill the gap)
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          value: _vm.selectedGender,
                          items: [AppStrings.genderMale, AppStrings.gendermFemale],
                          label: AppStrings.gender,
                          icon: Icons.wc,
                          onChanged: (val) => setState(() => _vm.selectedGender = val),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdown(
                          value: _vm.selectedStudentType,
                          items: [AppStrings.studentTypeAcademy, AppStrings.studentTypePrivate],
                          label: AppStrings.studentType,
                          icon: Icons.category_outlined,
                          onChanged: (val) => setState(() => _vm.selectedStudentType = val!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ---------------------------------------------------------------
              // 2. ACADEMIC PLACEMENT
              // ---------------------------------------------------------------
              _buildSectionHeader(AppStrings.placement),
              _buildCard(
                children: [
                  // Grade Level (Now Full Width since Type moved up)
                  _buildDropdown(
                    value: _vm.selectedGrade,
                    items: _vm.grades,
                    label: AppStrings.gLevel,
                    icon: Icons.school_outlined,
                    onChanged: (val) => setState(() => _vm.selectedGrade = val),
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.surfaceLightGrey),
                  const SizedBox(height: 16),
                  
                  // Subject Selector
                  SubjectSelectorField(
                    selectedSubjects: _vm.selectedSubjects,
                    onChanged: (list) => setState(() => _vm.selectedSubjects = list),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ---------------------------------------------------------------
              // 3. GUARDIAN CONTACT
              // ---------------------------------------------------------------
              _buildSectionHeader(AppStrings.gContact),
              _buildCard(
                children: [
                  _buildTextField(controller: _vm.guardianNameCtrl, label: AppStrings.gName, icon: Icons.family_restroom),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _vm.guardianPhoneCtrl, label: AppStrings.gPhone, icon: Icons.phone_outlined, inputType: TextInputType.phone),
                ],
              ),
              const SizedBox(height: 24),

              // ---------------------------------------------------------------
              // 4. FINANCIAL ESSENTIALS
              // ---------------------------------------------------------------
              _buildSectionHeader(AppStrings.bEssentials),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withAlpha(200),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryBlue.withAlpha(50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDropdown(
                      value: _vm.selectedBillingCycle,
                      items: _vm.billingTypes,
                      label: AppStrings.bSchedule,
                      icon: Icons.calendar_month_outlined,
                      onChanged: (val) => setState(() => _vm.selectedBillingCycle = val),
                    ),
                    if (_vm.selectedBillingCycle == AppStrings.defaultB) ...[
                      const SizedBox(height: 16),
                      _buildDatePicker(
                        context,
                        label: AppStrings.selectBDate,
                        selectedDate: _vm.customBillingDate,
                        onSelect: (date) => setState(() => _vm.customBillingDate = date),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.surfaceLightGrey),
                    const SizedBox(height: 16),
                    Text(AppStrings.prevTuition, style: TextStyle(color: AppColors.errorRed.withAlpha(200), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(flex: 2, child: _buildTextField(controller: _vm.openingBalanceCtrl, label: AppStrings.amntOwing, icon: Icons.attach_money, inputType: const TextInputType.numberWithOptions(decimal: true), textColor: AppColors.errorRed)),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: _buildTextField(controller: _vm.debtDescriptionCtrl, label: AppStrings.description, icon: Icons.description_outlined)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.surfaceLightGrey),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.successGreen,
                      title: const Text(AppStrings.generateInvoice, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text(AppStrings.standardAction, style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                      value: _vm.generateInvoiceNow,
                      onChanged: (val) => setState(() => _vm.generateInvoiceNow = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textGrey,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(20)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    Color? textColor,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      validator: validator,
      style: TextStyle(color: textColor ?? Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textGrey),
        prefixIcon: Icon(icon, color: AppColors.textGrey, size: 20),
        filled: true,
        fillColor: AppColors.backgroundBlack,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.surfaceLightGrey.withAlpha(30)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      dropdownColor: AppColors.surfaceDarkGrey,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textGrey),
        prefixIcon: Icon(icon, color: AppColors.textGrey, size: 20),
        filled: true,
        fillColor: AppColors.backgroundBlack,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.surfaceLightGrey.withAlpha(30)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, {
    required String label,
    required DateTime? selectedDate,
    required ValueChanged<DateTime> onSelect,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.primaryBlue,
                  onPrimary: Colors.white,
                  surface: AppColors.surfaceDarkGrey,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) onSelect(date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceLightGrey.withAlpha(30)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.textGrey, size: 20),
            const SizedBox(width: 12),
            Text(
              selectedDate != null 
                  ? DateFormat(AppStrings.dateFormat).format(selectedDate) 
                  : label,
              style: TextStyle(
                color: selectedDate != null ? Colors.white : AppColors.textGrey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}