import 'package:flutter/material.dart';
import 'package:legend/constants/app_strings.dart';

class AddStudentViewModel {
  // Dropdown Data Sources
  final List<String> grades = AppStrings.grades;
  final List<String> billingTypes = AppStrings.billingTypes;
  
  // Form Controllers
  final TextEditingController firstNameCtrl = TextEditingController();
  final TextEditingController lastNameCtrl = TextEditingController();
  // Removed admNumberCtrl (Auto-generated)
  final TextEditingController guardianNameCtrl = TextEditingController();
  final TextEditingController guardianPhoneCtrl = TextEditingController();
  
  // Financial Controllers
  final TextEditingController openingBalanceCtrl = TextEditingController();
  final TextEditingController debtDescriptionCtrl = TextEditingController(text: AppStrings.balBroughtDown);

  // Form State
  String? selectedGrade;
  String? selectedGender;
  String selectedStudentType = AppStrings.studentTypeAcademy; 
  String? selectedBillingCycle;
  bool generateInvoiceNow = true;
  DateTime? customBillingDate;
  
  // Subject List
  List<String> selectedSubjects = []; 

  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    // admNumberCtrl.dispose(); 
    guardianNameCtrl.dispose();
    guardianPhoneCtrl.dispose();
    openingBalanceCtrl.dispose();
    debtDescriptionCtrl.dispose();
  }
}
