import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedLanguage = 'English';

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Luxury Travel, Tailored for You',
      description: 'Experience premium transportation with our fleet of luxury vehicles, designed for comfort and style.',
      image: Icons.directions_car,
      backgroundColor: SwiftLyftTheme.primaryBlue,
    ),
    OnboardingSlide(
      title: 'Book with Ease in Johannesburg & Cape Town',
      description: 'Seamless booking experience with instant quotes, real-time tracking, and professional chauffeurs.',
      image: Icons.phone_android,
      backgroundColor: SwiftLyftTheme.secondaryTeal,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  void _skipOnboarding() {
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: SwiftLyftTheme.pureWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SwiftLyftTheme.primaryBlue.withValues(alpha: 0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    icon: const Icon(
                      Icons.language,
                      color: SwiftLyftTheme.primaryBlue,
                      size: 20,
                    ),
                    style: const TextStyle(
                      color: SwiftLyftTheme.deepCharcoal,
                      fontSize: 14,
                    ),
                    items: ['English', 'Afrikaans', 'isiZulu'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedLanguage = newValue!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return _buildSlide(_slides[index]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? SwiftLyftTheme.primaryBlue
                          : SwiftLyftTheme.mediumGray.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: SwiftLyftTheme.primaryBlue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(
                      _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: SwiftLyftTheme.lightGray,
      body: SafeArea(
        child: SwiftLyftTheme.isWeb
            ? WebContainer(child: content)
            : content,
      ),
    );
  }

  Widget _buildSlide(OnboardingSlide slide) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image/Icon with modern design
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  slide.backgroundColor,
                  slide.backgroundColor.withValues(alpha: 0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: slide.backgroundColor.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              slide.image,
              size: 100,
              color: SwiftLyftTheme.pureWhite,
            ),
          ),
          
          const SizedBox(height: 60),
          
          // Title
          Text(
            slide.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: SwiftLyftTheme.deepCharcoal,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          // Description
          Text(
            slide.description,
            style: const TextStyle(
              fontSize: 16,
              color: SwiftLyftTheme.mediumGray,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final IconData image;
  final Color backgroundColor;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.image,
    required this.backgroundColor,
  });
} 