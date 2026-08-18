# Rewards System Integration

## Overview
The rewards system allows users to earn and redeem loyalty rewards based on their activity. Users can view available rewards, their earned rewards, and their loyalty points balance.

## Backend API

### Endpoint
```
GET /api/users/:id/rewards
```

### Response
```json
{
  "success": true,
  "data": {
    "earnedRewards": [
      {
        "id": "reward123",
        "name": "10% Off Next Ride",
        "description": "Get 10% discount on your next booking",
        "type": "discount",
        "pointsCost": 500,
        "discountPercentage": 10,
        "isActive": true,
        "expiresAt": "2025-12-31T23:59:59Z",
        "redeemedAt": null
      }
    ],
    "availableRewards": [
      {
        "id": "reward456",
        "name": "Free Ride",
        "description": "Get one free ride up to R100",
        "type": "free_ride",
        "pointsCost": 2000,
        "discountPercentage": 0,
        "isActive": true,
        "expiresAt": null,
        "redeemedAt": null
      }
    ],
    "loyaltyPoints": 1250,
    "loyaltyTier": "Silver",
    "totalEarnedRewards": 1,
    "totalAvailableRewards": 5
  }
}
```

## Frontend Integration

### 1. Model
The `Reward` and `RewardsInfo` models are defined in `lib/models/reward.dart`.

#### Reward Types
- `discount` - Percentage discount on rides
- `free_ride` - Free ride up to a certain amount
- `upgrade` - Vehicle upgrade (e.g., premium car)
- `priority` - Priority booking/support

### 2. Service
The `UserService` class has a `getRewards()` method:

```dart
final userService = UserService();
final userId = currentUser.id; // Get from authenticated user
final rewardsInfo = await userService.getRewards(userId);
```

### 3. State Management
Access rewards through `AppState`:

```dart
final appState = Provider.of<AppState>(context, listen: false);

// Load rewards
await appState.loadRewards();

// Access rewards data
final rewardsInfo = appState.rewardsInfo;
final isLoading = appState.isLoadingRewards;
final error = appState.rewardsError;
```

### 4. UI Widget
Use the `RewardsCard` widget to display rewards:

```dart
import 'package:swiftlyft/widgets/rewards_card.dart';

// In your widget tree:
RewardsCard()
```

## Usage in Profile Page

The rewards card is already integrated into the Profile page:

```dart
// In profile_screen.dart
import '../widgets/rewards_card.dart';

// Inside the build method:
children: [
  _buildProfileHeader(),
  const SizedBox(height: 24),
  const RewardsCard(), // Replaces the old stats card
  const SizedBox(height: 24),
  _buildProfileActions(),
]
```

The RewardsCard has replaced the old "Your Stats" section on the Profile page.

## Features

### RewardsCard Widget Displays:
1. **Summary Stats**
   - Total available rewards
   - Total earned rewards  
   - Affordable rewards (user has enough points)

2. **Available Rewards**
   - Shows rewards users can redeem
   - Indicates if user has enough points
   - Color-coded by reward type
   - Shows point cost

3. **Earned Rewards**
   - Shows rewards user has earned
   - Displays expiry date if applicable
   - Active/expired status

4. **Empty State**
   - Shown when user has no rewards
   - Encourages completing rides to earn points

## Reward Properties

### Helper Methods
- `isRedeemed` - Check if reward has been redeemed
- `isExpired` - Check if reward has expired
- `isAvailable` - Check if reward is active, not expired, and not redeemed
- `iconName` - Get icon based on reward type
- `typeLabel` - Get user-friendly type label
- `colorValue` - Get color code based on reward type

### RewardsInfo Helper Methods
- `affordableRewards` - Get rewards user can afford with current points
- `expiredRewards` - Get list of expired rewards
- `activeEarnedRewards` - Get active earned rewards (not expired/redeemed)

## Automatic Loading

Rewards are automatically loaded:
- ✅ On app initialization (if user is logged in)
- ✅ After successful login
- ✅ When calling `appState.loadRewards()`

Rewards are automatically cleared:
- ✅ On logout

## Refresh Rewards

To manually refresh rewards data:

```dart
final appState = Provider.of<AppState>(context, listen: false);
await appState.loadRewards();
```

**Recommended refresh triggers:**
- After redeeming a reward
- After earning loyalty points
- When viewing rewards screen
- After completing a booking

## Example Integration

### Profile Page (Current Implementation)
The RewardsCard is already integrated into the Profile page, replacing the old stats card.

### Settings Page (Alternative)
You can also add the rewards card to other pages:
```dart
// Add to your settings page sections
Column(
  children: [
    _buildProfileSection(),
    const SizedBox(height: 20),
    _buildLoyaltySection(),
    const SizedBox(height: 20),
    const RewardsCard(), // Add rewards card here
    const SizedBox(height: 20),
    _buildReferralSection(),
  ],
)
```

### Dedicated Rewards Screen
```dart
class RewardsScreen extends StatefulWidget {
  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh rewards when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.loadRewards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Rewards')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: const RewardsCard(),
      ),
    );
  }
}
```

## Testing

1. **Login as a user** with loyalty points
2. **Navigate to Profile** page
3. **Verify rewards card displays** with available/earned rewards (replaces old stats card)
4. **Check point balance** is correct
5. **Verify "affordable" count** matches points available
6. **Test reward types** display correct icons and colors
7. **Complete a booking** and verify points update
8. **Refresh** and verify rewards reload

## TODO / Future Enhancements

- [ ] Add reward redemption functionality
- [ ] Create dedicated full rewards screen
- [ ] Add reward search/filter
- [ ] Show reward history/transactions
- [ ] Add reward notifications
- [ ] Implement reward expiry warnings
- [ ] Add reward recommendation engine
- [ ] Support reward gifting/sharing

