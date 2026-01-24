import 'package:legend/app_libs.dart';

class CreateSchoolScreen extends StatefulWidget {
  const CreateSchoolScreen({super.key});

  @override
  State<CreateSchoolScreen> createState() => _CreateSchoolScreenState();
}

class _CreateSchoolScreenState extends State<CreateSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _currencyController = TextEditingController(text: 'USD');
  final _logoUrlController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _currencyController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  Future<void> _createSchool() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthService>().user?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to create a school.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        context.go(AppRoutes.login);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final schoolRepo = context.read<SchoolRepository>();
      final authService = context.read<AuthService>();

      final config = await schoolRepo.createSchool(
        ownerId: userId,
        schoolName: _nameController.text.trim(),
        currency: _currencyController.text.trim().isEmpty
            ? 'USD'
            : _currencyController.text.trim().toUpperCase(),
        address: _addressController.text.trim(),
        logoUrl: _logoUrlController.text.trim(),
      );

      await authService.completeSchoolSetup(config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('School "${config.name}" created.'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating school: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('Create School'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Let's set up your school.",
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter the basics to start using KwaLegend.',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _Field(
                    label: 'School name',
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'School name is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _Field(
                    label: 'Address (optional)',
                    controller: _addressController,
                  ),
                  const SizedBox(height: 16),
                  _Field(
                    label: 'Currency',
                    controller: _currencyController,
                    hintText: 'USD',
                  ),
                  const SizedBox(height: 16),
                  _Field(
                    label: 'Logo URL (optional)',
                    controller: _logoUrlController,
                    hintText: 'https://...',
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createSchool,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Create School'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.controller,
    this.hintText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceDarkGrey,
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.textGrey),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.surfaceLightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryBlue),
            ),
          ),
        ),
      ],
    );
  }
}
