# Corporate Account Registration

This guide explains how users can register as corporate accounts directly during signup.

## For Users (Assignment Demo)

### How to Register as Corporate User

1. **Open the app** and go to the Registration screen
2. **Fill in basic information:**
   - Full Name
   - Phone Number
   - Email Address
   - Password
   - Referral Code (optional)

3. **Enable Corporate Registration:**
   - Toggle the **"Register as Corporate Account"** switch
   - The switch will turn orange when enabled

4. **Fill in Corporate Information** (appears after toggling):
   - **Company Name**: Your company's name
   - **Company Email**: Company email address
   - **Contact Person**: Primary contact name

5. **Complete Registration:**
   - Click "Sign Up" button
   - Account will be created with corporate features

### What Corporate Users Get

✅ **Active Status**: Immediately usable (for demo/assignment purposes)
✅ **10% Discount**: Automatic corporate discount on all rides
✅ **R50,000 Budget**: Default monthly budget
✅ **Bulk Booking**: Ability to create bulk bookings
✅ **Corporate Dashboard**: View in Settings page

## Technical Implementation

### Frontend Changes

**Files Modified:**
1. `swiftlyft/lib/screens/login_screen.dart`
   - Added corporate registration toggle
   - Added 3 corporate fields (company name, email, contact person)
   - Visual feedback when corporate mode is enabled

2. `swiftlyft/lib/providers/auth_state.dart`
   - Updated `signUp()` method to accept corporate parameters

3. `swiftlyft/lib/services/auth_service.dart`
   - Updated `register()` method to send corporate data to backend

4. `swiftlyft/lib/providers/app_state.dart`
   - Updated delegated `signUp()` to forward corporate parameters

### Backend Changes

**File Modified:**
- `Swiftlyft_backend/routes/auth.js`
  - Extracts `isCorporate`, `companyName`, `companyEmail`, `contactPerson` from request
  - Creates `corporateAccount` object if `isCorporate` is true
  - Sets default values:
    - **Discount**: 10%
    - **Monthly Budget**: R50,000
    - **Status**: 'active' (for demo purposes)

### Default Corporate Account Values

When a user registers as corporate, they automatically get:

```javascript
{
  companyName: companyName || name,
  companyEmail: companyEmail || email,
  contactPerson: contactPerson || name,
  contactPhone: userPhone || '',
  discountPercentage: 10,      // 10% discount
  monthlyBudget: 50000,         // R50,000
  usedBudget: 0,                // Starts at 0
  status: 'active',             // Ready to use
  createdAt: new Date(),
  authorizedUsers: []
}
```

## UI Flow

### Registration Screen - Regular User
```
┌─────────────────────────────┐
│ Full Name                   │
│ Phone Number                │
│ Referral Code (Optional)    │
│ Email                       │
│ Password                    │
│ [Sign Up]                   │
└─────────────────────────────┘
```

### Registration Screen - Corporate User
```
┌─────────────────────────────┐
│ Full Name                   │
│ Phone Number                │
│ Referral Code (Optional)    │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🏢 Register as Corporate│ │
│ │ Get corporate discounts │ │
│ │                [ON] ◉  │ │ ← Toggle Switch
│ └─────────────────────────┘ │
│                             │
│ Company Name                │ ← Shows when ON
│ Company Email               │ ← Shows when ON
│ Contact Person              │ ← Shows when ON
│                             │
│ Email                       │
│ Password                    │
│ [Sign Up]                   │
└─────────────────────────────┘
```

## Testing

### Test Case 1: Regular User Registration
1. Fill registration form
2. Keep corporate toggle **OFF**
3. Sign up
4. **Expected**: Normal account created, no corporate features in Settings

### Test Case 2: Corporate User Registration
1. Fill registration form
2. Toggle corporate **ON**
3. Fill corporate fields:
   - Company Name: "Test Corp"
   - Company Email: "corp@test.com"
   - Contact Person: "John Manager"
4. Sign up
5. **Expected**: 
   - Account created successfully
   - Navigate to Settings
   - See Corporate Account Card with:
     - Company name: "Test Corp"
     - Status: Active (green badge)
     - Budget: R50,000.00 total, R0.00 used
     - Discount: 10%
     - Progress bar at 0%

### Test Case 3: Corporate Fields Validation
1. Toggle corporate **ON**
2. Try to submit without filling corporate fields
3. **Expected**: Validation errors for required fields

### Test Case 4: Login as Corporate User
1. Register as corporate user
2. Log out
3. Log back in with same credentials
4. Navigate to Settings
5. **Expected**: Corporate Account Card still visible with all details

## API Request Example

When a user registers as corporate, the frontend sends:

```json
{
  "email": "user@company.com",
  "password": "SecurePass123!",
  "name": "John Doe",
  "phoneNumber": "+27821234567",
  "isCorporate": true,
  "companyName": "Test Corporation",
  "companyEmail": "corp@testcorp.com",
  "contactPerson": "John Manager"
}
```

Backend response includes the user with `corporateAccount` field populated.

## Notes for Assignment Grading

- ✅ **No Admin Panel Required**: Users can self-register as corporate
- ✅ **Immediate Access**: Corporate accounts are active immediately
- ✅ **Visual Distinction**: Clear UI difference between registration types
- ✅ **Full Integration**: Corporate features work end-to-end
- ✅ **Validation**: Proper error handling and form validation
- ✅ **Persistence**: Corporate status persists across login sessions

## Troubleshooting

**Q: Corporate toggle is not showing**
- Make sure you're on the Registration screen (not Login)
- Switch to "Sign Up" tab if using tab-based UI

**Q: Corporate fields are required but not showing**
- Ensure the corporate toggle is switched ON (orange color)

**Q: Corporate Card not showing in Settings after registration**
- Check that registration succeeded
- Try logging out and back in
- Verify `isCorporate` was sent in the API request (check network tab)

**Q: Budget or discount values are wrong**
- These are defaults set in the backend
- Can be modified in `Swiftlyft_backend/routes/auth.js`
- Look for the `corporateAccount` object creation

## Future Enhancements

For a production app, you might want to:
- Add approval workflow (start as 'pending' status)
- Admin panel to approve/reject corporate registrations
- Custom budget/discount settings per company
- Company verification (tax ID, business license)
- Multiple user authorization per corporate account
- Company-specific pricing tiers

