import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import '../widgets/unified_navigation.dart';
import '../widgets/corporate_account_card.dart';
import '../providers/app_state.dart';
import '../services/location_api_service.dart';
import '../services/auth_service.dart';
import '../utils/phone_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
	bool _locationEnabled = true;

	SharedPreferences? _prefs;
	final LocationService _locationService = LocationService();

	@override
	void initState() {
		super.initState();
		_initSettings();
		// Schedule referral data refresh after the build phase
		WidgetsBinding.instance.addPostFrameCallback((_) {
			_refreshReferralData();
		});
	}

	Future<void> _refreshReferralData() async {
		// Force refresh referral data when settings screen opens
		if (mounted) {
			final appState = Provider.of<AppState>(context, listen: false);
			await appState.loadReferral();
		}
	}

	Future<void> _initSettings() async {
		_prefs = await SharedPreferences.getInstance();
		setState(() {
			_locationEnabled = _prefs?.getBool('locationEnabled') ?? true;
		});
	}

	Future<void> _persistBool(String key, bool value) async {
		try {
			await _prefs?.setBool(key, value);
		} catch (e) {
			debugPrint('Failed to persist setting $key: $e');
		}
	}


  @override
  Widget build(BuildContext context) {
		final content = SingleChildScrollView(
			padding: const EdgeInsets.all(24),
      child: WebContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(),
						const SizedBox(height: 24),
            _buildCorporateSection(),
            _buildReferralSection(),
            const SizedBox(height: 24),
            _buildLocationSection(),
						const SizedBox(height: 24),
            _buildSupportSection(),
          ],
        ),
      ),
    );

		return UnifiedNavigation.buildScaffold(
			context: context,
			currentRoute: AppRoutes.settings,
			appBar: UnifiedAppBar.buildResponsive(
				context: context,
				title: 'Settings',
				subtitle: 'Manage your preferences',
				showBackButton: true,
			),
			body: content,
    );
  }

  Widget _buildCorporateSection() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        // Only show corporate section if user has a corporate account
        if (appState.isCorporateUser) {
          return Column(
            children: [
              const CorporateAccountCard(),
              const SizedBox(height: 24),
            ],
          );
        }
        return const SizedBox.shrink(); // Hide if not corporate user
      },
    );
  }

  Widget _buildReferralSection() {
    return Consumer<AppState>(
      builder: (context, app, _) {
        if (app.isLoadingReferral) {
          return const Center(child: CircularProgressIndicator());
        }
        final r = app.referralInfo;
        if (r == null) {
          // Load on first view
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Provider.of<AppState>(context, listen: false).loadReferral();
          });
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: SwiftLyftTheme.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SwiftLyftTheme.lightGray),
            ),
            child: const Row(
              children: [
                SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading referrals...'),
              ],
            ),
          );
        }

        final code = r.referralCode ?? '—';
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SwiftLyftTheme.pureWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SwiftLyftTheme.lightGray),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Referrals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: SwiftLyftTheme.lightGray.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Your code: $code',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Referral code copied')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final message = 'Join me on SwiftLyft! Use my referral code: $code';
                      await Share.share(message, subject: 'SwiftLyft Referral');
                    },
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Share'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _statChip('Total', r.stats.totalReferrals.toString(), Icons.group),
                  _statChip('Successful', r.stats.successfulReferrals.toString(), Icons.check_circle),
                  _statChip('Pending', r.stats.pendingReferrals.toString(), Icons.hourglass_bottom),
                  _statChip('Points Earned', r.stats.totalEarnings.toInt().toString(), Icons.stars),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SwiftLyftTheme.lightGray),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: SwiftLyftTheme.primaryBlue),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: SwiftLyftTheme.mediumGray)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Profile image and info
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.person,
                  size: 40,
                  color: SwiftLyftTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Consumer<AppState>(
                  builder: (context, appState, _) {
                    final user = appState.currentUser;
                    final displayName = (user?.name?.isNotEmpty ?? false) ? user!.name! : (user?.email ?? 'Guest');
                    final email = user?.email ?? '';
                    final tier = user?.loyaltyTier ?? '';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: SwiftLyftTheme.mediumGray,
                            ),
                          ),
                        const SizedBox(height: 4),
                        if (tier.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: SwiftLyftTheme.warmOrange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$tier Member',
                              style: const TextStyle(
                                color: SwiftLyftTheme.pureWhite,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final l = appState.loyaltyInfo;
                            if (appState.isLoadingLoyalty) {
                              return const SizedBox(
                                height: 8,
                                child: LinearProgressIndicator(minHeight: 8),
                              );
                            }
                            if (l == null) {
                              // Trigger load once if missing
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                Provider.of<AppState>(context, listen: false).loadLoyalty();
                              });
                              return const SizedBox(
                                height: 8,
                                child: LinearProgressIndicator(minHeight: 8),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                      begin: 0.0,
                                      end: l.tierProgress.clamp(0.0, 1.0),
                                    ),
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, _) {
                                      return LinearProgressIndicator(
                                        value: value,
                                        minHeight: 8,
                                        backgroundColor: SwiftLyftTheme.lightGray,
                                        valueColor: const AlwaysStoppedAnimation(SwiftLyftTheme.warmOrange),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${l.loyaltyPoints} pts • ${l.pointsToNextTier} to ${user?.nextTier ?? 'next tier'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: SwiftLyftTheme.mediumGray,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              IconButton(
								onPressed: _showEditProfileDialog,
                icon: const Icon(Icons.edit),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Stats - Using real data from userStats with fallbacks
          Consumer<AppState>(
            builder: (context, appState, _) {
              final stats = appState.userStats;
              final isLoading = appState.isLoadingStats;
              
              if (isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              // Get data with fallbacks to user/loyalty info
              final loyalty = appState.loyaltyInfo;
              
              final loyaltyPoints = loyalty?.loyaltyPoints ?? stats?.loyaltyPoints ?? 0;
              
              return Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Loyalty Points',
                      '$loyaltyPoints',
                      Icons.stars,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Member Since',
                      stats?.membershipDuration ?? 'N/A',
                      Icons.calendar_today,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Logins',
                      '${stats?.loginCount ?? 0}',
                      Icons.login,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: SwiftLyftTheme.primaryBlue,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: SwiftLyftTheme.mediumGray,
          ),
        ),
      ],
    );
  }

	Widget _buildLocationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
							'Location Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: SwiftLyftTheme.deepCharcoal,
              ),
            ),
          ),
					SettingsItem(
						icon: Icons.location_on,
						title: 'Location',
						subtitle: _locationEnabled ? 'On' : 'Off',
						onTap: () async {
							if (!_locationEnabled) {
								final ok = await _locationService.checkLocationPermission();
								setState(() => _locationEnabled = ok);
								await _persistBool('locationEnabled', _locationEnabled);
							} else {
								await showDialog<void>(
									context: context,
									builder: (context) => AlertDialog(
										title: const Text('Disable Location'),
										content: const Text('To disable location access, please turn it off in your device settings.'),
										actions: [
											TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
										],
									),
								);
							}
						},
					),
				],
			),
		);
	}




  Widget _buildSupportSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SwiftLyftTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Support & Legal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: SwiftLyftTheme.deepCharcoal,
              ),
            ),
          ),
          SettingsItem(
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'Get help and support',
            onTap: () => _showHelpCenterDialog(),
          ),
          SettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () => _showPrivacyPolicyDialog(),
          ),
          SettingsItem(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'Read our terms of service',
            onTap: () => _showTermsOfServiceDialog(),
          ),
          SettingsItem(
            icon: Icons.info_outline,
            title: 'About App',
            subtitle: 'Version 1.0.0',
            onTap: () => _showAboutAppDialog(),
          ),
          SettingsItem(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Log out of your account',
            onTap: () async {
              final navigator = Navigator.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign out?'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out')),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                // Call signOut and clear all user data
                final appState = Provider.of<AppState>(context, listen: false);
                await appState.signOut();
                await appState.onSignOut(); // Clear all cached data
                navigator.pushReplacementNamed(AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.currentUser;
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final phoneController = TextEditingController(text: user?.phoneNumber ?? '');
		
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
				content: SingleChildScrollView(
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							// Profile picture
							Center(
								child: Stack(
									children: [
										CircleAvatar(
											radius: 50,
											backgroundColor: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.1),
											child: const Icon(
												Icons.person,
												size: 50,
												color: SwiftLyftTheme.primaryBlue,
											),
										),
										Positioned(
											bottom: 0,
											right: 0,
											child: Container(
												padding: const EdgeInsets.all(4),
												decoration: const BoxDecoration(
													color: SwiftLyftTheme.primaryBlue,
													shape: BoxShape.circle,
												),
												child: const Icon(
													Icons.camera_alt,
													color: SwiftLyftTheme.pureWhite,
													size: 16,
												),
											),
										),
									],
								),
							),
							const SizedBox(height: 20),
							
							// Name field
							TextFormField(
								controller: nameController,
								decoration: const InputDecoration(
									labelText: 'Full Name',
									prefixIcon: Icon(Icons.person_outline),
								),
							),
							const SizedBox(height: 16),
							
              // Email field (read-only; backend does not support changing email yet)
							TextFormField(
								controller: emailController,
                readOnly: true,
                decoration: const InputDecoration(
									labelText: 'Email Address',
									prefixIcon: Icon(Icons.email_outlined),
                  helperText: 'Contact support to change email',
								),
								keyboardType: TextInputType.emailAddress,
							),
							const SizedBox(height: 16),
							
							// Phone field
							TextFormField(
								controller: phoneController,
								decoration: const InputDecoration(
									labelText: 'Phone Number',
									prefixIcon: Icon(Icons.phone_outlined),
								),
								keyboardType: TextInputType.phone,
                inputFormatters: [SouthAfricaPhoneFormatter()],
							),
						],
					),
				),
        actions: [
					TextButton(
						onPressed: () => Navigator.pop(context),
						child: const Text('Cancel'),
					),
					ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final newName = nameController.text.trim();
              final newPhone = phoneController.text.trim();
              // Email update is not supported by current backend endpoints
              try {
                final normalizedPhone = newPhone.isNotEmpty ? normalizeToZaPhone(newPhone) : null;
                final updated = await AuthService().updateUserProfile(
                  name: newName.isNotEmpty ? newName : null,
                  phoneNumber: normalizedPhone,
                );
                if (!mounted) return;
                // Update in-memory user for UI via AuthState helper (triggers AppState listeners)
                Provider.of<AppState>(context, listen: false).auth.setTestUser(updated!);
                navigator.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update profile: $e')),
                );
              }
            },
						child: const Text('Save Changes'),
					),
        ],
      ),
    );
  }


  void _showHelpCenterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help Center'),
				content: SizedBox(
					width: 400.0,
					height: 500.0,
					child: SingleChildScrollView(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								// Search
								const TextField(
									decoration: InputDecoration(
										hintText: 'Search help topics...',
										prefixIcon: Icon(Icons.search),
										border: OutlineInputBorder(
											borderRadius: BorderRadius.all(Radius.circular(12)),
										),
									),
								),
								const SizedBox(height: 20),
								
							// Quick actions
							const Text(
								'Quick Actions',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							const SizedBox(height: 12),
								ListTile(
									leading: const Icon(Icons.phone_outlined),
									title: const Text('Call Support'),
									subtitle: const Text('+27 11 123 4567'),
									onTap: () {
										Navigator.pop(context);
										// Handle phone call
									},
								),
								ListTile(
									leading: const Icon(Icons.email_outlined),
									title: const Text('Email Support'),
									subtitle: const Text('support@swiftlyft.co.za'),
									onTap: () {
										Navigator.pop(context);
										// Handle email
									},
								),
								const SizedBox(height: 20),
								
							// FAQ
							const Text(
								'Frequently Asked Questions',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							const SizedBox(height: 12),
							const ExpansionTile(
								title: Text('How do I book a vehicle?'),
								children: [
									Padding(
										padding: EdgeInsets.all(16),
										child: Text(
											'To book a vehicle, go to the Vehicles section, select your preferred vehicle, and click "Request Quote". Fill in your trip details and submit your request.',
										),
									),
								],
							),
							const ExpansionTile(
								title: Text('What payment methods do you accept?'),
								children: [
									Padding(
										padding: EdgeInsets.all(16),
										child: Text(
											'We accept all major credit cards, debit cards, and mobile payment methods including Apple Pay and Google Pay.',
										),
									),
								],
							),
							const ExpansionTile(
								title: Text('Can I cancel my booking?'),
								children: [
									Padding(
										padding: EdgeInsets.all(16),
										child: Text(
											'Yes, you can cancel your booking up to 24 hours before your scheduled pickup time. Cancellations made within 24 hours may incur a cancellation fee.',
										),
									),
								],
							),
							const ExpansionTile(
								title: Text('What if my driver is late?'),
								children: [
									Padding(
										padding: EdgeInsets.all(16),
										child: Text(
											'If your driver is running late, you will receive real-time updates via the app. For delays over 15 minutes, please contact our support team.',
										),
									),
								],
							),
							],
						),
					),
				),
        actions: [
					TextButton(
						onPressed: () => Navigator.pop(context),
						child: const Text('Close'),
					),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
		showDialog(
			context: context,
		builder: (context) => AlertDialog(
			title: const Text('Privacy Policy'),
			content: const SizedBox(
				width: 500,
				height: 600,
				child: SingleChildScrollView(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									'Last updated: December 2024',
									style: TextStyle(
										fontSize: 12,
										color: Colors.grey,
									),
								),
							SizedBox(height: 20),
							
							Text(
								'1. Information We Collect',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							SizedBox(height: 8),
							Text(
									'We collect information you provide directly to us, such as when you create an account, make a booking, or contact our support team. This includes:\n'
									'• Personal information (name, email, phone number)\n'
									'• Payment information\n'
									'• Trip details and preferences\n'
									'• Location data (with your consent)\n'
									'• Device information and usage data',
								),
							SizedBox(height: 16),
							
							Text(
								'2. How We Use Your Information',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							SizedBox(height: 8),
							Text(
									'We use the information we collect to:\n'
									'• Provide and improve our services\n'
									'• Process bookings and payments\n'
									'• Send you updates and notifications\n'
									'• Provide customer support\n'
									'• Ensure safety and security\n'
									'• Comply with legal obligations',
								),
							SizedBox(height: 16),
							
							Text(
								'3. Information Sharing',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							SizedBox(height: 8),
							Text(
									'We do not sell your personal information. We may share your information with:\n'
									'• Service providers (drivers, payment processors)\n'
									'• Legal authorities when required by law\n'
									'• Business partners with your consent',
								),
							SizedBox(height: 16),
							
							Text(
								'4. Data Security',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							SizedBox(height: 8),
							Text(
									'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
								),
							SizedBox(height: 16),
							
							Text(
								'5. Your Rights',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							SizedBox(height: 8),
							Text(
									'You have the right to:\n'
									'• Access your personal information\n'
									'• Correct inaccurate information\n'
									'• Delete your account\n'
									'• Opt out of marketing communications\n'
									'• Request data portability',
								),
							SizedBox(height: 16),
							
							Text(
								'6. Contact Us',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							SizedBox(height: 8),
							Text(
									'If you have questions about this Privacy Policy, please contact us at:\n'
									'Email: privacy@swiftlyft.co.za\n'
									'Phone: +27 11 123 4567\n'
									'Address: 123 Main Street, Johannesburg, South Africa',
								),
							],
						),
					),
				),
        actions: [
				TextButton(
					onPressed: () => Navigator.pop(context),
					child: const Text('Close'),
				),
        ],
      ),
    );
  }

	void _showTermsOfServiceDialog() {
		showDialog(
			context: context,
		builder: (context) => AlertDialog(
			title: const Text('Terms of Service'),
			content: const SizedBox(
				width: 500,
				height: 600,
				child: SingleChildScrollView(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									'Last updated: December 2024',
									style: TextStyle(
										fontSize: 12,
										color: Colors.grey,
									),
								),
							SizedBox(height: 20),
							
							Text(
								'1. Acceptance of Terms',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							SizedBox(height: 8),
							Text(
								'By using the SwiftLyft app and services, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.',
							),
							SizedBox(height: 16),
							
							Text(
								'2. Service Description',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							SizedBox(height: 8),
							Text(
								'SwiftLyft provides premium transportation services through our mobile application. We connect users with professional drivers and luxury vehicles for various transportation needs.',
							),
							SizedBox(height: 16),
							
							Text(
								'3. User Responsibilities',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							SizedBox(height: 8),
							Text(
									'As a user, you agree to:\n'
									'• Provide accurate and complete information\n'
									'• Be respectful to drivers and other users\n'
									'• Pay for services as agreed\n'
									'• Follow all applicable laws and regulations\n'
									'• Not use our services for illegal purposes',
								),
							SizedBox(height: 16),
							
							Text(
								'4. Booking and Cancellation',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							SizedBox(height: 8),
							Text(
									'• Bookings are confirmed upon payment\n'
									'• Cancellations must be made 24 hours in advance\n'
									'• Late cancellations may incur fees\n'
									'• No-shows will be charged the full fare',
								),
							SizedBox(height: 16),
							
							Text(
								'5. Payment Terms',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							SizedBox(height: 8),
							Text(
									'• All fares are in South African Rand (ZAR)\n'
									'• Payment is processed securely\n'
									'• Tips are appreciated but not required\n'
									'• Refunds are processed within 5-7 business days',
								),
							SizedBox(height: 16),
							
							Text(
								'6. Safety and Liability',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							SizedBox(height: 8),
							Text(
									'• We prioritize your safety\n'
									'• All drivers are licensed and insured\n'
									'• Vehicles are regularly inspected\n'
									'• We are not liable for delays due to traffic or weather',
								),
							SizedBox(height: 16),
							
							Text(
								'7. Privacy and Data',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							SizedBox(height: 8),
							Text(
								'Your privacy is important to us. Please review our Privacy Policy for details on how we collect, use, and protect your information.',
							),
							SizedBox(height: 16),
							
							Text(
								'8. Termination',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							SizedBox(height: 8),
							Text(
								'We may terminate or suspend your account at any time for violations of these terms. You may also terminate your account at any time.',
							),
							SizedBox(height: 16),
							
							Text(
								'9. Changes to Terms',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							SizedBox(height: 8),
							Text(
								'We may update these terms from time to time. We will notify you of any material changes via email or in-app notification.',
							),
							SizedBox(height: 16),
							
							Text(
								'10. Contact Information',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							SizedBox(height: 8),
							Text(
								'For questions about these Terms of Service, contact us at:\n'
								'Email: legal@swiftlyft.co.za\n'
								'Phone: +27 11 123 4567',
							),
							],
						),
					),
				),
        actions: [
				TextButton(
					onPressed: () => Navigator.pop(context),
					child: const Text('Close'),
				),
        ],
      ),
    );
  }

  void _showAboutAppDialog() {
    showDialog(
      context: context,
			builder: (context) => AlertDialog(
				title: const Text('About SwiftLyft'),
				content: SizedBox(
					width: 400.0,
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							// App logo
							Container(
								width: 80,
								height: 80,
								decoration: BoxDecoration(
									gradient: const LinearGradient(
										colors: [SwiftLyftTheme.primaryBlue, SwiftLyftTheme.accentPurple],
									),
									borderRadius: BorderRadius.circular(20.0),
								),
								child: const Icon(
									Icons.local_taxi,
									color: SwiftLyftTheme.pureWhite,
									size: 40,
								),
							),
							const SizedBox(height: 16),
							
							// App name and version
							const Text(
								'SwiftLyft',
								style: TextStyle(
									fontSize: 24,
									fontWeight: FontWeight.bold,
								),
							),
							const SizedBox(height: 4),
							const Text(
								'Version 1.0.0',
								style: TextStyle(
									fontSize: 14,
									color: Colors.grey,
								),
							),
							const SizedBox(height: 20),
							
							// App description
							const Text(
								'Premium transportation services at your fingertips. Experience luxury travel with professional drivers and high-end vehicles.',
								textAlign: TextAlign.center,
								style: TextStyle(
									fontSize: 14,
									height: 1.5,
								),
							),
							const SizedBox(height: 20),
							
							// Features
							const Text(
								'Features:',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							const SizedBox(height: 8),
							const Text(
								'• Luxury vehicle booking\n'
								'• Real-time tracking\n'
								'• Secure payments\n'
								'• 24/7 support\n'
								'• Loyalty rewards',
								style: TextStyle(fontSize: 14),
							),
							const SizedBox(height: 20),
							
							// Team information
							const Text(
								'Development Team',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							const SizedBox(height: 8),
							const Text(
								'Built with ❤️ by the SwiftLyft team\n'
								'Using Flutter & Dart',
								textAlign: TextAlign.center,
								style: TextStyle(fontSize: 14),
							),
							const SizedBox(height: 20),
							
							// Contact information
							const Text(
								'Contact Us',
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.bold,
								),
							),
							const SizedBox(height: 8),
							const Text(
								'Email: info@swiftlyft.co.za\n'
								'Phone: +27 11 123 4567\n'
								'Website: www.swiftlyft.co.za',
								textAlign: TextAlign.center,
								style: TextStyle(fontSize: 14),
							),
							const SizedBox(height: 20),
							
							// Copyright
							const Text(
								'© 2024 SwiftLyft. All rights reserved.',
								textAlign: TextAlign.center,
								style: TextStyle(
									fontSize: 12,
									color: Colors.grey,
								),
							),
						],
					),
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context),
						child: const Text('Close'),
					),
				],
			),
		);
	}




}

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: SwiftLyftTheme.primaryBlue,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}