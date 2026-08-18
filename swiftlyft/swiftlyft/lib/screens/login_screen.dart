import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import '../utils/validators.dart';
import '../providers/app_state.dart';
import '../widgets/error_handler.dart';
import '../utils/constants.dart';
import '../utils/phone_input_formatter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _referralCodeController = TextEditingController();
  
  // Corporate registration fields
  final _companyNameController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _budgetController = TextEditingController(text: '50000'); // Default budget
  
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isCorporateRegistration = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _referralCodeController.dispose();
    _companyNameController.dispose();
    _companyEmailController.dispose();
    _contactPersonController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // Show validation errors
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in the form'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);

    try {
      bool success;
      if (_isLogin) {
        success = await appState.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        // Additional validation for registration
        if (_nameController.text.trim().isEmpty) {
          throw Exception('Please enter your full name');
        }
        
        if (_phoneController.text.trim().isEmpty) {
          throw Exception('Please enter your phone number');
        }
        
        final normalizedPhone = normalizeToZaPhone(_phoneController.text.trim());
        final referralCode = _referralCodeController.text.trim();
        success = await appState.signUp(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
          normalizedPhone,
          referralCode: referralCode.isNotEmpty ? referralCode : null,
          isCorporate: _isCorporateRegistration,
          companyName: _isCorporateRegistration ? _companyNameController.text.trim() : null,
          companyEmail: _isCorporateRegistration ? _companyEmailController.text.trim() : null,
          contactPerson: _isCorporateRegistration ? _contactPersonController.text.trim() : null,
          monthlyBudget: _isCorporateRegistration 
              ? (double.tryParse(_budgetController.text.trim()) ?? 50000.0)
              : null,
        );
      }

      if (mounted && success) {
        // Initialize all user data in the background (don't await to avoid blocking navigation)
        final app = Provider.of<AppState>(context, listen: false);
        app.onSignIn(); // Fire and forget - loads loyalty, stats, referral, corporate, etc.
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else if (mounted && !success) {
        final err = appState.error ?? 'Invalid email or password';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _submitForm,
            ),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final form = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            _buildHeader(),
            const SizedBox(height: 40),
            _buildFormFields(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
            const SizedBox(height: 24),
            _buildToggleButton(),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: SwiftLyftTheme.lightGray,
      body: SafeArea(
        child: SwiftLyftTheme.isWeb
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: form,
                ),
              )
            : form,
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [SwiftLyftTheme.primaryBlue, SwiftLyftTheme.accentPurple],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.local_taxi,
            size: 50,
            color: SwiftLyftTheme.pureWhite,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _isLogin ? 'Welcome Back' : 'Create Account',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: SwiftLyftTheme.deepCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin 
            ? 'Sign in to continue your journey'
            : 'Join SwiftLyft for premium transportation',
          style: const TextStyle(
            fontSize: 16,
            color: SwiftLyftTheme.mediumGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        if (!_isLogin) ...[
          // Name field (only for registration)
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
              hintText: 'Enter your full name',
            ),
            validator: (value) {
                      if (!_isLogin) {
          return Validators.validateName(value);
        }
        return null;
            },
            onChanged: (value) {
              // Real-time validation feedback
              if (value.isNotEmpty && value.length < 2) {
                setState(() {
                  // Update UI to show validation state
                });
              }
            },
          ),
          const SizedBox(height: 16),
          
          // Phone field (only for registration)
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined),
              hintText: 'Enter your phone number',
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [SouthAfricaPhoneFormatter()],
            validator: (value) {
              if (!_isLogin) {
                return Validators.validatePhoneNumber(value);
              }
              return null;
            },
            onChanged: (value) {
              // Real-time validation feedback
              if (value.isNotEmpty) {
                setState(() {
                  // Update UI to show validation state
                });
              }
            },
          ),
          const SizedBox(height: 16),
          
          // Referral code field (optional, only for registration)
          TextFormField(
            controller: _referralCodeController,
            decoration: const InputDecoration(
              labelText: 'Referral Code (Optional)',
              prefixIcon: Icon(Icons.card_giftcard),
              hintText: 'Enter a referral code',
            ),
            onChanged: (value) {
              setState(() {
                // Update UI
              });
            },
          ),
          const SizedBox(height: 24),
          
          // Corporate Registration Toggle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SwiftLyftTheme.lightGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isCorporateRegistration 
                    ? SwiftLyftTheme.warmOrange 
                    : SwiftLyftTheme.mediumGray.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.business,
                  color: _isCorporateRegistration 
                      ? SwiftLyftTheme.warmOrange 
                      : SwiftLyftTheme.mediumGray,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Register as Corporate Account',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isCorporateRegistration 
                              ? SwiftLyftTheme.warmOrange 
                              : SwiftLyftTheme.darkGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Get corporate discounts and bulk booking features',
                        style: TextStyle(
                          fontSize: 12,
                          color: SwiftLyftTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isCorporateRegistration,
                  onChanged: (value) {
                    setState(() {
                      _isCorporateRegistration = value;
                    });
                  },
                  activeColor: SwiftLyftTheme.warmOrange,
                ),
              ],
            ),
          ),
          
          // Corporate fields (shown when corporate registration is enabled)
          if (_isCorporateRegistration) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: 'Company Name',
                prefixIcon: Icon(Icons.business_outlined),
                hintText: 'Enter company name',
              ),
              validator: (value) {
                if (_isCorporateRegistration && (value == null || value.trim().isEmpty)) {
                  return 'Company name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyEmailController,
              decoration: const InputDecoration(
                labelText: 'Company Email',
                prefixIcon: Icon(Icons.email_outlined),
                hintText: 'Enter company email',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (_isCorporateRegistration) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Company email is required';
                  }
                  return Validators.validateEmail(value);
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactPersonController,
              decoration: const InputDecoration(
                labelText: 'Contact Person',
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'Enter contact person name',
              ),
              validator: (value) {
                if (_isCorporateRegistration && (value == null || value.trim().isEmpty)) {
                  return 'Contact person is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _budgetController,
              decoration: const InputDecoration(
                labelText: 'Monthly Budget (R)',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                hintText: 'Enter monthly budget',
                helperText: 'Default: R50,000',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (_isCorporateRegistration) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Monthly budget is required';
                  }
                  final budget = double.tryParse(value.trim());
                  if (budget == null) {
                    return 'Please enter a valid number';
                  }
                  if (budget < 10000) {
                    return 'Minimum budget is R10,000';
                  }
                  if (budget > 10000000) {
                    return 'Maximum budget is R10,000,000';
                  }
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 16),
        ],
        
        // Email field
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined),
            hintText: 'Enter your email address',
          ),
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
          onChanged: (value) {
            // Real-time validation feedback
            if (value.isNotEmpty) {
              setState(() {
                // Update UI to show validation state
              });
            }
          },
        ),
        const SizedBox(height: 16),
        
        // Password field
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            hintText: 'Enter your password',
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          obscureText: _obscurePassword,
          validator: (value) {
            if (_isLogin) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            } else {
              return Validators.validatePassword(value);
            }
          },
          onChanged: (value) {
            // Real-time validation feedback
            if (value.isNotEmpty) {
              setState(() {
                // Update UI to show validation state
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return ElevatedButton(
          onPressed: appState.isLoading ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: appState.isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(SwiftLyftTheme.pureWhite),
              ),
            )
          : Text(
              _isLogin ? 'Sign In' : 'Create Account',
              style: const TextStyle(fontSize: 16),
            ),
        );
      },
    );
  }


  Widget _buildToggleButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? 'Don\'t have an account? ' : 'Already have an account? ',
          style: const TextStyle(
            color: SwiftLyftTheme.mediumGray,
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isLogin = !_isLogin;
            });
          },
          child: Text(
            _isLogin ? 'Sign Up' : 'Sign In',
            style: const TextStyle(
              color: SwiftLyftTheme.primaryBlue,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

} 