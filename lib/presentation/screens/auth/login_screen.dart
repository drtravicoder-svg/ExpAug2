import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/storage_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../business_logic/providers/auth_providers.dart';
import '../../../business_logic/services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showPhoneLogin = false;
  bool _showOTPField = false;
  bool _biometricAvailable = false;
  bool _rememberMe = false;

  String? _verificationId;
  EnhancedAuthService? _authService;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    try {
      _authService = EnhancedAuthService();

      // Check if biometric authentication is available
      final isAvailable = await _authService!.isBiometricAvailable();

      // Check if user has enabled biometric auth
      final storage = StorageService();
      final biometricEnabled = await storage.isBiometricEnabled();

      if (mounted) {
        setState(() {
          _biometricAvailable = isAvailable && biometricEnabled;
        });
      }

      // Auto-login with biometrics if enabled and user was previously logged in
      final userId = await storage.getUserId();
      if (userId != null && _biometricAvailable) {
        _handleBiometricLogin();
      }
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Login Init');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_authService == null) {
        throw Exception('Authentication service not initialized');
      }

      final user = await _authService!.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Store remember me preference
      if (_rememberMe) {
        final storage = StorageService();
        await storage.setUserEmail(_emailController.text.trim());
      }

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(ErrorHandler.getUserMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePhoneLogin() async {
    if (_phoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your phone number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_authService == null) {
        throw Exception('Authentication service not initialized');
      }

      await _authService!.signInWithPhoneNumber(
        phoneNumber: _phoneController.text.trim(),
        onCodeSent: (verificationId) {
          setState(() {
            _verificationId = verificationId;
            _showOTPField = true;
            _isLoading = false;
          });
          _showSuccessSnackBar('OTP sent to your phone');
        },
        onError: (error) {
          setState(() => _isLoading = false);
          _showErrorSnackBar(error);
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar(ErrorHandler.getUserMessage(e));
      }
    }
  }

  Future<void> _handleOTPVerification() async {
    if (_otpController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter the OTP');
      return;
    }

    if (_verificationId == null) {
      _showErrorSnackBar('Verification ID not found. Please try again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_authService == null) {
        throw Exception('Authentication service not initialized');
      }

      final user = await _authService!.verifyOTPCode(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar(ErrorHandler.getUserMessage(e));
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    try {
      if (_authService == null) return;

      final isAuthenticated = await _authService!.authenticateWithBiometrics(
        reason: 'Please authenticate to access your account',
      );

      if (isAuthenticated && mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Biometric authentication failed');
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your email address');
      return;
    }

    try {
      if (_authService == null) {
        throw Exception('Authentication service not initialized');
      }

      await _authService!.sendPasswordResetEmail(_emailController.text.trim());
      _showSuccessSnackBar('Password reset email sent');
    } catch (e) {
      _showErrorSnackBar(ErrorHandler.getUserMessage(e));
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo and Title
                const Icon(
                  Icons.account_balance_wallet,
                  size: 80,
                  color: DesignTokens.primaryBlue,
                ),
                const SizedBox(height: 24),
                Text(
                  'Group Trip\nExpense Splitter',
                  style: DesignTokens.header.copyWith(
                    fontSize: 28,
                    color: DesignTokens.primaryBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Admin Login',
                  style: DesignTokens.subtitle.copyWith(
                    color: DesignTokens.inactiveGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  validator: Validators.password,
                  onFieldSubmitted: (_) => _handleLogin(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.borderRadius),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Forgot Password
                TextButton(
                  onPressed: () {
                    // TODO: Implement forgot password
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Forgot password feature coming soon'),
                      ),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: DesignTokens.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: DesignTokens.subtitle,
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Implement sign up navigation
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sign up feature coming soon'),
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: DesignTokens.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
