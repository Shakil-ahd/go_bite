import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import 'bloc/auth_bloc.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+880 ');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onSignup() {
    if (!_formKey.currentState!.validate()) return;

    final profile = UserProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      deliveryAddress: _addressController.text.trim(),
    );

    context.read<AuthBloc>().add(SignupRequested(
          profile: profile,
          method: AuthMethod.phone, 
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSignupSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully! Please login.')),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade50, Colors.white, Colors.orange.shade50.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: CustomScrollView(
                slivers: [
                  // App Bar / Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: Column(
                        children: [
                          const Text(
                            'GoBite',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create Your Account',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fast, secure, and ready to deliver',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Form Fields
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // First Name & Last Name row
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  controller: _firstNameController,
                                  label: 'First Name *',
                                  hint: 'John',
                                  icon: Icons.person,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildInputField(
                                  controller: _lastNameController,
                                  label: 'Last Name (Optional)',
                                  hint: 'Doe',
                                  icon: Icons.person_outline,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Phone (Mandatory)
                          _buildInputField(
                            controller: _phoneController,
                            label: 'Phone Number *',
                            hint: '+880 1XXXXXXXXX',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty || v.trim() == '+880') return 'Phone is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Email (Optional but good to have)
                          _buildInputField(
                            controller: _emailController,
                            label: 'Email Address (Optional)',
                            hint: 'example@email.com',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          
                          // Password (Mandatory)
                          _buildInputField(
                            controller: _passwordController,
                            label: 'Password *',
                            hint: 'Enter your password',
                            icon: Icons.lock,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password is required';
                              if (v.length < 6) return 'At least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Address Section
                          const Text(
                            'Delivery Location *',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your full delivery address manually',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 12),
                          
                          _buildInputField(
                            controller: _addressController,
                            label: 'Full Address',
                            hint: 'House No, Road, Area, City',
                            icon: Icons.home,
                            maxLines: 3,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                          ),

                          const SizedBox(height: 40),

                          // Submit Button
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _onSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 4,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.rocket_launch, size: 22, color: Colors.white),
                                  SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      'Create Account 🚀',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Login Redirect
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Already have an account? ', style: TextStyle(color: Colors.grey.shade700)),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  );
                                },
                                child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          obscureText: obscureText,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: maxLines > 1 
                ? Padding(padding: const EdgeInsets.only(bottom: 40), child: Icon(icon, color: AppTheme.primary))
                : Icon(icon, color: AppTheme.primary),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
