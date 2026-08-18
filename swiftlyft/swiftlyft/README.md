# swiftlyft

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


# SwiftLyft_Frontend


🚘 SwiftLyft: Comprehensive Frontend Design
🎨 Design Principles

Luxury Aesthetic: Clean, modern design with a color palette of gold (#FFD700), jet black (#000000), platinum white (#FFFFFF), and deep sapphire blue (#1A2A44) for depth and contrast.
Simplicity & Usability: Streamlined navigation and interactions for browsing vehicles, requesting quotes, and booking rides.
Accessibility: High-contrast text, alt text for images, and keyboard navigation support for inclusivity.
Performance: Optimized for smooth animations and fast load times on mobile devices.


🧭 1. Onboarding & Welcome
Splash Screen

Animation: A sleek luxury car drives across a stylized skyline of Johannesburg and Cape Town, with the SwiftLyft logo fading in.
Tagline: "Your Journey, Elevated with SwiftLyft" in gold text on a black background.
Accessibility: Skippable animation for users with motion sensitivity.

Onboarding Slides (2 Slides)

Slide 1: Image of a luxury vehicle with "Luxury Travel, Tailored for You".
Slide 2: Booking interface illustration with "Book with Ease in Johannesburg & Cape Town".
Controls: "Next" and "Skip" buttons on each slide.
Localization: Language selection (English, Afrikaans, isiZulu) at the bottom.


🏠 2. Home Screen
Header

Personalized Greeting: "Good Morning, [User Name]" (dynamic based on time).
Location Selector: Auto-detects city (e.g., 🏙️ Johannesburg or 🌄 Cape Town) with manual override.

Main Sections

Search Box: "Where would you like to go?" with predictive text and voice input.
Vehicle Categories Carousel:
3D card carousel with tilt animations.
Each card includes:
High-quality vehicle image.
Name (e.g., Mercedes S-Class).
Features (e.g., "Seats 4, Leather Interior").
Buttons: "View Details" and "Request Quote".


Filters: Sort by price, seating, or popularity.


Promotions Banner: Rotating offers (e.g., "10% off your first ride!") with countdown timers.
CTA: Sticky "Book Your Luxury Ride" button at the bottom.


🚙 3. Vehicle Listing Screen

Tabbed Navigation: 
Tabs: Johannesburg, Cape Town, All Cities.
Active tab highlighted with a gold underline.


Vehicle Cards:
Image: Consistent high-quality photo.
Details: Name, seating capacity, badges (e.g., "Top Choice").
Actions: "View Details", "Request Quote", "Compare".


Accessibility: Touch-friendly with alt text.


🔍 4. Vehicle Details Screen

Image Gallery: Swipeable high-res images with pinch-to-zoom or 360° view.
Description: Concise luxury highlights (e.g., "Plush leather seats, Wi-Fi").
Features List: Animated icons (e.g., USB port, reclining seat).
Trust Signals: Badges like "Certified Chauffeurs".
CTAs: 
"Request Quote" (opens form).
"Book Now" (instant booking).




📋 5. Quote Request Form

Form Fields:
Pickup Location: Auto-filled via geolocation, with suggestions.
Dropoff Location: Predictive text with recent destinations.
Date & Time: Calendar and time slider.
Passenger Count: Dropdown or stepper.
Advanced Options (collapsible): Special notes, Close Protection Officer toggle.


Real-Time Feedback: Estimated price range (e.g., "~R1,200–R1,500").
Confirmation Screen: Booking summary, map preview, and options to share or add extras.


🏢 6. About Us Screen

Interactive Timeline: Scrollable history of SwiftLyft.
Team Highlights: Cards for key members with photos and bios.
Video: 30-second clip of chauffeurs and testimonials.


📣 7. Special Offers Screen

Personalized Deals: Based on behavior (e.g., "15% off airport rides").
Urgency: Countdown timers.
Loyalty Points: Progress bar for points and rewards.


💬 8. Contact & Communication

Primary Contact: WhatsApp button for instant chat.
Secondary Options: Email and phone.
Chatbot: AI assistant for quick queries.


📬 9. Subscribe to Newsletter

Incentive: "5% off your first ride".
Placement: Pop-up after booking confirmation.
Privacy Note: "Unsubscribe anytime."


⚙️ 10. Settings / Profile

Profile Section: Photo upload, loyalty status, saved payments.
Booking History: Timeline with downloadable receipts.
Notifications: Toggle preferences (email, push, WhatsApp).


🎨 UI/UX Style Guide

Color Palette:
Primary: Gold (#FFD700), Jet Black (#000000), Platinum White (#FFFFFF).
Secondary: Deep Sapphire Blue (#1A2A44).
Accessibility: WCAG 2.1 contrast ratios (e.g., gold on black ≥ 4.5:1).


Typography:
Headings: Poppins (bold, modern).
Body Text: Roboto (readable).
CTA Buttons: 18px, bold.


Imagery: High-res photos with a consistent filter (e.g., sepia).
Animations: Smooth transitions and micro-interactions, optimized for 60fps.


⚙️ Technical Notes

Framework: Flutter for cross-platform development.
Integrations: Google Maps, Paystack/Yoco payments, OneSignal notifications, WhatsApp API.


This design delivers a luxurious, user-friendly experience for SwiftLyft, with a focus on simplicity, elegance, and modern features tailored to Johannesburg and Cape Town users.



