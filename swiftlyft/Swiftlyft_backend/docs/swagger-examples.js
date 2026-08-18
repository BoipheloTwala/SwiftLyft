/**
 * Swagger Documentation Examples for SwiftLyft API
 * This file contains comprehensive JSDoc comments for all API endpoints
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     Location:
 *       type: object
 *       properties:
 *         address:
 *           type: string
 *           example: "123 Main Street, Johannesburg, South Africa"
 *         coordinates:
 *           type: object
 *           properties:
 *             lat:
 *               type: number
 *               example: -26.2041
 *             lng:
 *               type: number
 *               example: 28.0473
 *         type:
 *           type: string
 *           enum: [pickup, dropoff, waypoint]
 *           example: "pickup"
 * 
 *     Pricing:
 *       type: object
 *       properties:
 *         baseFare:
 *           type: number
 *           example: 25.50
 *         distance:
 *           type: number
 *           example: 5.2
 *         duration:
 *           type: number
 *           example: 15
 *         surgeMultiplier:
 *           type: number
 *           example: 1.2
 *         total:
 *           type: number
 *           example: 30.60
 *         breakdown:
 *           type: object
 *           properties:
 *             baseFare:
 *               type: number
 *             distanceFee:
 *               type: number
 *             timeFee:
 *               type: number
 *             surgeFee:
 *               type: number
 *             taxes:
 *               type: number
 * 
 *     PaymentMethod:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           example: "pm_1234567890"
 *         type:
 *           type: string
 *           enum: [card, cash, wallet, corporate]
 *           example: "card"
 *         last4:
 *           type: string
 *           example: "4242"
 *         brand:
 *           type: string
 *           example: "visa"
 *         expiryMonth:
 *           type: number
 *           example: 12
 *         expiryYear:
 *           type: number
 *           example: 2025
 *         isDefault:
 *           type: boolean
 *           example: true
 * 
 *     Notification:
 *       type: object
 *       properties:
 *         _id:
 *           type: string
 *           example: "507f1f77bcf86cd799439011"
 *         userId:
 *           type: string
 *           example: "507f1f77bcf86cd799439011"
 *         type:
 *           type: string
 *           enum: [booking, payment, promotion, system]
 *           example: "booking"
 *         title:
 *           type: string
 *           example: "Booking Confirmed"
 *         message:
 *           type: string
 *           example: "Your ride has been confirmed for 2:30 PM"
 *         data:
 *           type: object
 *         isRead:
 *           type: boolean
 *           example: false
 *         createdAt:
 *           type: string
 *           format: date-time
 * 
 *     Analytics:
 *       type: object
 *       properties:
 *         totalTrips:
 *           type: number
 *           example: 150
 *         totalRevenue:
 *           type: number
 *           example: 3750.00
 *         averageRating:
 *           type: number
 *           example: 4.8
 *         completionRate:
 *           type: number
 *           example: 0.95
 *         popularRoutes:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               route:
 *                 type: string
 *               trips:
 *                 type: number
 *         peakHours:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               hour:
 *                 type: number
 *               trips:
 *                 type: number
 * 
 *     SupportTicket:
 *       type: object
 *       properties:
 *         _id:
 *           type: string
 *           example: "507f1f77bcf86cd799439011"
 *         userId:
 *           type: string
 *           example: "507f1f77bcf86cd799439011"
 *         subject:
 *           type: string
 *           example: "Issue with payment"
 *         description:
 *           type: string
 *           example: "I was charged twice for my last ride"
 *         category:
 *           type: string
 *           enum: [billing, technical, general, complaint]
 *           example: "billing"
 *         priority:
 *           type: string
 *           enum: [low, medium, high, urgent]
 *           example: "medium"
 *         status:
 *           type: string
 *           enum: [open, in_progress, resolved, closed]
 *           example: "open"
 *         responses:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               message:
 *                 type: string
 *               sender:
 *                 type: string
 *                 enum: [user, support]
 *               timestamp:
 *                 type: string
 *                 format: date-time
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 * 
 *     QuoteRequest:
 *       type: object
 *       properties:
 *         _id:
 *           type: string
 *           example: "507f1f77bcf86cd799439011"
 *         userId:
 *           type: string
 *           example: "507f1f77bcf86cd799439011"
 *         pickupLocation:
 *           $ref: '#/components/schemas/Location'
 *         dropoffLocation:
 *           $ref: '#/components/schemas/Location'
 *         vehicleType:
 *           type: string
 *           enum: [sedan, suv, van, luxury]
 *           example: "sedan"
 *         scheduledTime:
 *           type: string
 *           format: date-time
 *         estimatedFare:
 *           type: number
 *           example: 25.50
 *         estimatedDuration:
 *           type: number
 *           example: 15
 *         estimatedDistance:
 *           type: number
 *           example: 5.2
 *         status:
 *           type: string
 *           enum: [pending, accepted, expired]
 *           example: "pending"
 *         expiresAt:
 *           type: string
 *           format: date-time
 *         createdAt:
 *           type: string
 *           format: date-time
 * 
 *   responses:
 *     RateLimitError:
 *       description: Rate limit exceeded
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Error'
 *           example:
 *             success: false
 *             message: "Too many requests from this IP, please try again later"
 * 
 *     ForbiddenError:
 *       description: Access forbidden
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Error'
 *           example:
 *             success: false
 *             message: "Access denied"
 * 
 *     ConflictError:
 *       description: Resource conflict
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Error'
 *           example:
 *             success: false
 *             message: "Resource already exists"
 */

/**
 * @swagger
 * /api/auth/refresh-token:
 *   post:
 *     summary: Refresh access token
 *     tags: [Authentication]
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - refreshToken
 *             properties:
 *               refreshToken:
 *                 type: string
 *                 example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
 *     responses:
 *       200:
 *         description: Token refreshed successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         tokens:
 *                           type: object
 *                           properties:
 *                             accessToken:
 *                               type: string
 *                             refreshToken:
 *                               type: string
 *       401:
 *         description: Invalid or expired refresh token
 */

/**
 * @swagger
 * /api/auth/logout:
 *   post:
 *     summary: Logout user
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               refreshToken:
 *                 type: string
 *                 description: Optional refresh token to logout specific device
 *     responses:
 *       200:
 *         description: Logged out successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */

/**
 * @swagger
 * /api/auth/forgot-password:
 *   post:
 *     summary: Send password reset email
 *     tags: [Authentication]
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 example: user@example.com
 *     responses:
 *       200:
 *         description: Password reset email sent (if account exists)
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       429:
 *         $ref: '#/components/responses/RateLimitError'
 */

/**
 * @swagger
 * /api/auth/me:
 *   get:
 *     summary: Get current user information
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Current user information
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         user:
 *                           $ref: '#/components/schemas/User'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */

/**
 * @swagger
 * /api/auth/logout-all:
 *   post:
 *     summary: Logout from all devices
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Logged out from all devices successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */

/**
 * @swagger
 * /api/auth/change-password:
 *   post:
 *     summary: Change user password
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - currentPassword
 *               - newPassword
 *             properties:
 *               currentPassword:
 *                 type: string
 *                 example: "CurrentPass123"
 *               newPassword:
 *                 type: string
 *                 minLength: 8
 *                 example: "NewPass123"
 *     responses:
 *       200:
 *         description: Password changed successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */

/**
 * @swagger
 * /api/auth/reset-password/{token}:
 *   post:
 *     summary: Reset password with token
 *     tags: [Authentication]
 *     security: []
 *     parameters:
 *       - in: path
 *         name: token
 *         required: true
 *         schema:
 *           type: string
 *         description: Password reset token
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - password
 *             properties:
 *               password:
 *                 type: string
 *                 minLength: 8
 *                 example: "NewPassword123"
 *     responses:
 *       200:
 *         description: Password reset successful
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 */

/**
 * @swagger
 * /api/auth/verify-email/{token}:
 *   get:
 *     summary: Verify email address (GET for email links)
 *     tags: [Authentication]
 *     security: []
 *     parameters:
 *       - in: path
 *         name: token
 *         required: true
 *         schema:
 *           type: string
 *         description: Email verification token
 *     responses:
 *       200:
 *         description: Email verification page displayed
 *         content:
 *           text/html:
 *             schema:
 *               type: string
 *       400:
 *         description: Invalid or expired verification token
 *         content:
 *           text/html:
 *             schema:
 *               type: string
 */

/**
 * @swagger
 * /api/auth/verify-email/{token}:
 *   post:
 *     summary: Verify email address (POST for API calls)
 *     tags: [Authentication]
 *     security: []
 *     parameters:
 *       - in: path
 *         name: token
 *         required: true
 *         schema:
 *           type: string
 *         description: Email verification token
 *     responses:
 *       200:
 *         description: Email verified successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         user:
 *                           $ref: '#/components/schemas/User'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 */

/**
 * @swagger
 * /api/auth/resend-verification:
 *   post:
 *     summary: Resend email verification
 *     tags: [Authentication]
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 example: user@example.com
 *     responses:
 *       200:
 *         description: Verification email sent (if account exists)
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       429:
 *         $ref: '#/components/responses/RateLimitError'
 */

/**
 * @swagger
 * /api/auth/send-phone-verification:
 *   post:
 *     summary: Send phone verification code
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - phoneNumber
 *             properties:
 *               phoneNumber:
 *                 type: string
 *                 example: "+27123456789"
 *     responses:
 *       200:
 *         description: Verification code sent to email
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         sentTo:
 *                           type: string
 *                           example: "user@example.com"
 *                         expiresIn:
 *                           type: string
 *                           example: "15 minutes"
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       429:
 *         $ref: '#/components/responses/RateLimitError'
 */

/**
 * @swagger
 * /api/auth/verify-phone:
 *   post:
 *     summary: Verify phone number with code
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - verificationCode
 *             properties:
 *               verificationCode:
 *                 type: string
 *                 example: "123456"
 *     responses:
 *       200:
 *         description: Phone number verified successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         user:
 *                           $ref: '#/components/schemas/User'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */

/**
 * @swagger
 * /api/users/profile:
 *   put:
 *     summary: Update user profile
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *                 example: "John Doe"
 *               phoneNumber:
 *                 type: string
 *                 example: "+27123456789"
 *     responses:
 *       200:
 *         description: Profile updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         user:
 *                           $ref: '#/components/schemas/User'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */

/**
 * @swagger
 * /api/users/addresses:
 *   get:
 *     summary: Get user's saved addresses
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Saved addresses retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         addresses:
 *                           type: array
 *                           items:
 *                             type: object
 *                             properties:
 *                               _id:
 *                                 type: string
 *                               label:
 *                                 type: string
 *                               address:
 *                                 type: string
 *                               coordinates:
 *                                 type: object
 *                               isDefault:
 *                                 type: boolean
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */

/**
 * @swagger
 * /api/users/addresses:
 *   post:
 *     summary: Add new saved address
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - label
 *               - address
 *             properties:
 *               label:
 *                 type: string
 *                 example: "Home"
 *               address:
 *                 type: string
 *                 example: "123 Main Street, Johannesburg"
 *               coordinates:
 *                 type: object
 *                 properties:
 *                   latitude:
 *                     type: number
 *                   longitude:
 *                     type: number
 *               isDefault:
 *                 type: boolean
 *                 example: true
 *     responses:
 *       201:
 *         description: Address added successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         addresses:
 *                           type: array
 *                           items:
 *                             type: object
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */

/**
 * @swagger
 * /api/users/addresses/{addressId}:
 *   put:
 *     summary: Update saved address
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: addressId
 *         required: true
 *         schema:
 *           type: string
 *         description: Address ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               label:
 *                 type: string
 *                 example: "Work"
 *               address:
 *                 type: string
 *                 example: "456 Office Street, Johannesburg"
 *               coordinates:
 *                 type: object
 *                 properties:
 *                   latitude:
 *                     type: number
 *                   longitude:
 *                     type: number
 *               isDefault:
 *                 type: boolean
 *                 example: false
 *     responses:
 *       200:
 *         description: Address updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         addresses:
 *                           type: array
 *                           items:
 *                             type: object
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/users/addresses/{addressId}:
 *   delete:
 *     summary: Delete saved address
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: addressId
 *         required: true
 *         schema:
 *           type: string
 *         description: Address ID
 *     responses:
 *       200:
 *         description: Address deleted successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         addresses:
 *                           type: array
 *                           items:
 *                             type: object
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/users/upload-avatar:
 *   post:
 *     summary: Upload profile picture
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - profileImageUrl
 *             properties:
 *               profileImageUrl:
 *                 type: string
 *                 format: uri
 *                 example: "https://example.com/avatar.jpg"
 *     responses:
 *       200:
 *         description: Profile picture updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         user:
 *                           $ref: '#/components/schemas/User'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */

/**
 * @swagger
 * /api/users/loyalty:
 *   get:
 *     summary: Get loyalty program information
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Loyalty information retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         loyaltyTier:
 *                           type: string
 *                         loyaltyPoints:
 *                           type: integer
 *                         pointsToNextTier:
 *                           type: integer
 *                         tierProgress:
 *                           type: number
 *                         tierDiscount:
 *                           type: number
 *                         earnedRewards:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/LoyaltyReward'
 *                         availableRewards:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/LoyaltyReward'
 *                         totalTrips:
 *                           type: integer
 *                         totalSpent:
 *                           type: number
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */

/**
 * @swagger
 * /api/users/referral:
 *   get:
 *     summary: Get referral information
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Referral information retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         referralCode:
 *                           type: string
 *                         referrals:
 *                           type: array
 *                           items:
 *                             type: object
 *                         stats:
 *                           type: object
 *                           properties:
 *                             totalReferrals:
 *                               type: integer
 *                             successfulReferrals:
 *                               type: integer
 *                             pendingReferrals:
 *                               type: integer
 *                             totalEarnings:
 *                               type: number
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */

/**
 * @swagger
 * /api/users/corporate:
 *   get:
 *     summary: Get corporate account information
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Corporate account information retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         corporateAccount:
 *                           $ref: '#/components/schemas/CorporateAccount'
 *                         bulkBookings:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/BulkBooking'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         description: No corporate account found
 */

/**
 * @swagger
 * /api/users/account:
 *   delete:
 *     summary: Delete user account
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - password
 *             properties:
 *               password:
 *                 type: string
 *                 example: "CurrentPassword123"
 *     responses:
 *       200:
 *         description: Account deactivated successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */

/**
 * @swagger
 * /api/users/stats:
 *   get:
 *     summary: Get user statistics
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User statistics retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         totalTrips:
 *                           type: integer
 *                         totalSpent:
 *                           type: number
 *                         loyaltyPoints:
 *                           type: integer
 *                         loyaltyTier:
 *                           type: string
 *                         memberSince:
 *                           type: string
 *                           format: date-time
 *                         lastLogin:
 *                           type: string
 *                           format: date-time
 *                         loginCount:
 *                           type: integer
 *                         isEmailVerified:
 *                           type: boolean
 *                         isPhoneVerified:
 *                           type: boolean
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */

/**
 * @swagger
 * /api/users/{id}:
 *   get:
 *     summary: Get user profile by ID
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *     responses:
 *       200:
 *         description: User profile retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         user:
 *                           $ref: '#/components/schemas/User'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/users/{id}:
 *   put:
 *     summary: Update user information by ID
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *                 example: "John Doe"
 *               phoneNumber:
 *                 type: string
 *                 example: "+27123456789"
 *               profileImageUrl:
 *                 type: string
 *                 format: uri
 *                 example: "https://example.com/avatar.jpg"
 *     responses:
 *       200:
 *         description: User updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         user:
 *                           $ref: '#/components/schemas/User'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/users/{id}/loyalty:
 *   get:
 *     summary: Get loyalty data for specific user
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *     responses:
 *       200:
 *         description: Loyalty data retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         loyaltyTier:
 *                           type: string
 *                         loyaltyPoints:
 *                           type: integer
 *                         pointsToNextTier:
 *                           type: integer
 *                         tierProgress:
 *                           type: number
 *                         tierDiscount:
 *                           type: number
 *                         earnedRewards:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/LoyaltyReward'
 *                         availableRewards:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/LoyaltyReward'
 *                         totalTrips:
 *                           type: integer
 *                         totalSpent:
 *                           type: number
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/users/{id}/rewards:
 *   get:
 *     summary: Get rewards for specific user
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *     responses:
 *       200:
 *         description: Rewards retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         earnedRewards:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/LoyaltyReward'
 *                         availableRewards:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/LoyaltyReward'
 *                         loyaltyPoints:
 *                           type: integer
 *                         loyaltyTier:
 *                           type: string
 *                         totalEarnedRewards:
 *                           type: integer
 *                         totalAvailableRewards:
 *                           type: integer
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/users/{id}/referrals:
 *   get:
 *     summary: Get referral data for specific user
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *     responses:
 *       200:
 *         description: Referral data retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         referralCode:
 *                           type: string
 *                         referredBy:
 *                           type: string
 *                         referrals:
 *                           type: array
 *                           items:
 *                             type: object
 *                         stats:
 *                           type: object
 *                           properties:
 *                             totalReferrals:
 *                               type: integer
 *                             successfulReferrals:
 *                               type: integer
 *                             pendingReferrals:
 *                               type: integer
 *                             cancelledReferrals:
 *                               type: integer
 *                             totalEarnings:
 *                               type: number
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/users/{id}/corporate:
 *   get:
 *     summary: Get corporate account details for specific user
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *     responses:
 *       200:
 *         description: Corporate account details retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         corporateAccount:
 *                           $ref: '#/components/schemas/CorporateAccount'
 *                         isCorporateUser:
 *                           type: boolean
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         description: No corporate account found
 */

/**
 * @swagger
 * /api/users/{id}/bulk-bookings:
 *   get:
 *     summary: Get corporate bulk bookings for specific user
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [draft, pending, confirmed, completed, cancelled]
 *         description: Filter by booking status
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *         description: Number of bookings to return
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *     responses:
 *       200:
 *         description: Bulk bookings retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         bulkBookings:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/BulkBooking'
 *                         pagination:
 *                           type: object
 *                           properties:
 *                             currentPage:
 *                               type: integer
 *                             totalPages:
 *                               type: integer
 *                             totalBookings:
 *                               type: integer
 *                             hasNextPage:
 *                               type: boolean
 *                             hasPrevPage:
 *                               type: boolean
 *                         summary:
 *                           type: object
 *                           properties:
 *                             totalAmount:
 *                               type: number
 *                             totalDiscount:
 *                               type: number
 *                             totalBookings:
 *                               type: integer
 *                             statusCounts:
 *                               type: object
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         description: No corporate account found
 */

/**
 * @swagger
 * /api/bookings/{id}:
 *   get:
 *     summary: Get booking details
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Booking ID
 *     responses:
 *       200:
 *         description: Booking details retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Booking'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/bookings/user/{userId}:
 *   get:
 *     summary: Get user's booking history
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, confirmed, in_progress, completed, cancelled]
 *         description: Filter by booking status
 *       - in: query
 *         name: limit
 *         schema:
 *           type: number
 *           default: 20
 *         description: Number of bookings to return
 *       - in: query
 *         name: page
 *         schema:
 *           type: number
 *           default: 1
 *         description: Page number
 *     responses:
 *       200:
 *         description: User bookings retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/Booking'
 *                     pagination:
 *                       type: object
 *                       properties:
 *                         page:
 *                           type: number
 *                         limit:
 *                           type: number
 *                         total:
 *                           type: number
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/bookings/{id}/rating:
 *   post:
 *     summary: Submit trip rating and review
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Booking ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - rating
 *             properties:
 *               rating:
 *                 type: number
 *                 minimum: 1
 *                 maximum: 5
 *                 example: 5
 *               review:
 *                 type: string
 *                 example: "Great driver, very professional!"
 *               categories:
 *                 type: object
 *                 properties:
 *                   cleanliness:
 *                     type: number
 *                   punctuality:
 *                     type: number
 *                   communication:
 *                     type: number
 *                   driving:
 *                     type: number
 *     responses:
 *       200:
 *         description: Rating submitted successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Booking'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/bookings:
 *   post:
 *     summary: Create a new booking
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - pickupLocation
 *               - dropoffLocation
 *               - scheduledDate
 *             properties:
 *               pickupLocation:
 *                 $ref: '#/components/schemas/Location'
 *               dropoffLocation:
 *                 $ref: '#/components/schemas/Location'
 *               passengerCount:
 *                 type: integer
 *                 example: 2
 *               vehicleType:
 *                 type: string
 *                 enum: [sedan, suv, van, luxury]
 *                 example: "sedan"
 *               scheduledDate:
 *                 type: string
 *                 format: date-time
 *                 example: "2023-12-01T10:00:00Z"
 *               specialRequirements:
 *                 type: string
 *                 example: "Wheelchair accessible"
 *               paymentMethodId:
 *                 type: string
 *                 example: "pm_1234567890"
 *     responses:
 *       201:
 *         description: Booking created successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Booking'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */

/**
 * @swagger
 * /api/bookings/{id}:
 *   put:
 *     summary: Update booking details
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Booking ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               pickupLocation:
 *                 $ref: '#/components/schemas/Location'
 *               dropoffLocation:
 *                 $ref: '#/components/schemas/Location'
 *               passengerCount:
 *                 type: integer
 *               scheduledDate:
 *                 type: string
 *                 format: date-time
 *               specialRequirements:
 *                 type: string
 *     responses:
 *       200:
 *         description: Booking updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Booking'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/bookings/{id}:
 *   delete:
 *     summary: Cancel booking
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Booking ID
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               cancellationReason:
 *                 type: string
 *                 example: "Change of plans"
 *     responses:
 *       200:
 *         description: Booking cancelled successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Booking'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/bookings/user/{userId}:
 *   get:
 *     summary: Get user's booking history
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, confirmed, driverAssigned, driverEnRoute, driverArrived, inProgress, completed, cancelled, expired, disputed]
 *         description: Filter by booking status
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Number of bookings to return
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *     responses:
 *       200:
 *         description: User bookings retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/Booking'
 *                     pagination:
 *                       type: object
 *                       properties:
 *                         page:
 *                           type: integer
 *                         limit:
 *                           type: integer
 *                         total:
 *                           type: integer
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/bookings/user/{userId}/active:
 *   get:
 *     summary: Get user's active bookings
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *     responses:
 *       200:
 *         description: Active bookings retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/Booking'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/bookings/{id}/assign-driver:
 *   post:
 *     summary: Assign driver to booking (Admin only)
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Booking ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - driverId
 *               - vehicleId
 *             properties:
 *               driverId:
 *                 type: string
 *                 example: "507f1f77bcf86cd799439011"
 *               vehicleId:
 *                 type: string
 *                 example: "507f1f77bcf86cd799439011"
 *     responses:
 *       200:
 *         description: Driver assigned successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Booking'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/bookings/{id}/status:
 *   put:
 *     summary: Update booking status
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Booking ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [pending, confirmed, driverAssigned, driverEnRoute, driverArrived, inProgress, completed, cancelled, expired, disputed]
 *                 example: "inProgress"
 *               notes:
 *                 type: string
 *                 example: "Driver arrived at pickup location"
 *     responses:
 *       200:
 *         description: Booking status updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Booking'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/bookings/stats:
 *   get:
 *     summary: Get booking statistics (Admin only)
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [day, week, month, year]
 *           default: month
 *         description: Time period for statistics
 *     responses:
 *       200:
 *         description: Booking statistics retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         totalBookings:
 *                           type: integer
 *                         completedBookings:
 *                           type: integer
 *                         cancelledBookings:
 *                           type: integer
 *                         totalRevenue:
 *                           type: number
 *                         averageBookingValue:
 *                           type: number
 *                         completionRate:
 *                           type: number
 *                         statusBreakdown:
 *                           type: object
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/bookings/admin/active:
 *   get:
 *     summary: Get all active bookings (Admin only)
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, confirmed, driverAssigned, driverEnRoute, driverArrived, inProgress]
 *         description: Filter by booking status
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 50
 *         description: Number of bookings to return
 *     responses:
 *       200:
 *         description: Active bookings retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/Booking'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/vehicles/available:
 *   get:
 *     summary: Get available vehicles
 *     tags: [Vehicles]
 *     parameters:
 *       - in: query
 *         name: latitude
 *         schema:
 *           type: number
 *         description: User latitude
 *       - in: query
 *         name: longitude
 *         schema:
 *           type: number
 *         description: User longitude
 *       - in: query
 *         name: radius
 *         schema:
 *           type: number
 *           default: 5
 *         description: Search radius in kilometers
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *           enum: [sedan, suv, luxury, van, truck]
 *         description: Vehicle category
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Maximum number of vehicles to return
 *     responses:
 *       200:
 *         description: Available vehicles retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/Vehicle'
 *                     totalCount:
 *                       type: integer
 */

/**
 * @swagger
 * /api/vehicles/categories:
 *   get:
 *     summary: Get vehicle categories
 *     tags: [Vehicles]
 *     responses:
 *       200:
 *         description: Vehicle categories retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           category:
 *                             type: string
 *                           name:
 *                             type: string
 *                           description:
 *                             type: string
 *                           passengerCapacity:
 *                             type: integer
 *                           basePrice:
 *                             type: number
 */

/**
 * @swagger
 * /api/vehicles/search:
 *   get:
 *     summary: Search vehicles by criteria
 *     tags: [Vehicles]
 *     parameters:
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *           enum: [sedan, suv, luxury, van, truck]
 *         description: Vehicle category
 *       - in: query
 *         name: passengerCapacity
 *         schema:
 *           type: integer
 *           minimum: 1
 *         description: Minimum passenger capacity
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [available, busy, offline, maintenance]
 *         description: Vehicle status
 *       - in: query
 *         name: latitude
 *         schema:
 *           type: number
 *         description: User latitude for proximity search
 *       - in: query
 *         name: longitude
 *         schema:
 *           type: number
 *         description: User longitude for proximity search
 *       - in: query
 *         name: radius
 *         schema:
 *           type: number
 *           default: 10
 *         description: Search radius in kilometers
 *     responses:
 *       200:
 *         description: Vehicles found successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/Vehicle'
 *                     totalCount:
 *                       type: integer
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 */

/**
 * @swagger
 * /api/vehicles/stats:
 *   get:
 *     summary: Get vehicle statistics (Admin only)
 *     tags: [Vehicles]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Vehicle statistics retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         totalVehicles:
 *                           type: integer
 *                         availableVehicles:
 *                           type: integer
 *                         busyVehicles:
 *                           type: integer
 *                         offlineVehicles:
 *                           type: integer
 *                         maintenanceVehicles:
 *                           type: integer
 *                         fleetUtilization:
 *                           type: number
 *                         categoryBreakdown:
 *                           type: object
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/vehicles/driver/{driverId}:
 *   get:
 *     summary: Get vehicles assigned to driver
 *     tags: [Vehicles]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: driverId
 *         required: true
 *         schema:
 *           type: string
 *         description: Driver ID
 *     responses:
 *       200:
 *         description: Driver vehicles retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/Vehicle'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/vehicles/{id}:
 *   get:
 *     summary: Get vehicle details
 *     tags: [Vehicles]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Vehicle ID
 *     responses:
 *       200:
 *         description: Vehicle details retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Vehicle'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/vehicles/{id}/availability:
 *   get:
 *     summary: Check vehicle availability
 *     tags: [Vehicles]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Vehicle ID
 *       - in: query
 *         name: date
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Check availability for specific date/time
 *     responses:
 *       200:
 *         description: Vehicle availability checked successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         vehicleId:
 *                           type: string
 *                         isAvailable:
 *                           type: boolean
 *                         status:
 *                           type: string
 *                         nextAvailableTime:
 *                           type: string
 *                           format: date-time
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/vehicles/{id}/status:
 *   put:
 *     summary: Update vehicle status (Admin/Driver only)
 *     tags: [Vehicles]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Vehicle ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [available, busy, offline, maintenance]
 *                 example: "available"
 *               location:
 *                 type: object
 *                 properties:
 *                   latitude:
 *                     type: number
 *                   longitude:
 *                     type: number
 *     responses:
 *       200:
 *         description: Vehicle status updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Vehicle'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/vehicles:
 *   post:
 *     summary: Create new vehicle (Admin only)
 *     tags: [Vehicles]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - vehicleId
 *               - name
 *               - make
 *               - model
 *               - year
 *               - category
 *             properties:
 *               vehicleId:
 *                 type: string
 *                 example: "VHC001"
 *               name:
 *                 type: string
 *                 example: "Toyota Camry"
 *               make:
 *                 type: string
 *                 example: "Toyota"
 *               model:
 *                 type: string
 *                 example: "Camry"
 *               year:
 *                 type: number
 *                 example: 2022
 *               category:
 *                 type: string
 *                 enum: [sedan, suv, luxury, van, truck]
 *                 example: "sedan"
 *               passengerCapacity:
 *                 type: number
 *                 example: 4
 *               status:
 *                 type: string
 *                 enum: [available, busy, offline, maintenance]
 *                 example: "available"
 *               pricing:
 *                 $ref: '#/components/schemas/Pricing'
 *     responses:
 *       201:
 *         description: Vehicle created successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Vehicle'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/vehicles/{id}:
 *   put:
 *     summary: Update vehicle information (Admin only)
 *     tags: [Vehicles]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Vehicle ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               make:
 *                 type: string
 *               model:
 *                 type: string
 *               year:
 *                 type: number
 *               category:
 *                 type: string
 *                 enum: [sedan, suv, luxury, van, truck]
 *               passengerCapacity:
 *                 type: number
 *               status:
 *                 type: string
 *                 enum: [available, busy, offline, maintenance]
 *               pricing:
 *                 $ref: '#/components/schemas/Pricing'
 *     responses:
 *       200:
 *         description: Vehicle updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Vehicle'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/quotes:
 *   post:
 *     summary: Request a quote for a ride
 *     tags: [Quotes]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - pickupLocation
 *               - dropoffLocation
 *               - vehicleType
 *             properties:
 *               pickupLocation:
 *                 $ref: '#/components/schemas/Location'
 *               dropoffLocation:
 *                 $ref: '#/components/schemas/Location'
 *               vehicleType:
 *                 type: string
 *                 enum: [sedan, suv, van, luxury]
 *                 example: "sedan"
 *               scheduledTime:
 *                 type: string
 *                 format: date-time
 *               passengerCount:
 *                 type: number
 *                 example: 2
 *               specialRequirements:
 *                 type: string
 *                 example: "Wheelchair accessible"
 *     responses:
 *       201:
 *         description: Quote request created successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Quote'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */

/**
 * @swagger
 * /api/quotes/{id}:
 *   get:
 *     summary: Get quote details
 *     tags: [Quotes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Quote ID
 *     responses:
 *       200:
 *         description: Quote details retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Quote'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/quotes/{id}:
 *   put:
 *     summary: Update quote
 *     tags: [Quotes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Quote ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [pending, accepted, expired]
 *                 example: "accepted"
 *               notes:
 *                 type: string
 *                 example: "Quote accepted by customer"
 *     responses:
 *       200:
 *         description: Quote updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Quote'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/quotes/user/{userId}:
 *   get:
 *     summary: Get user's quotes
 *     tags: [Quotes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, accepted, expired]
 *         description: Filter by quote status
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Number of quotes to return
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *     responses:
 *       200:
 *         description: User quotes retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/Quote'
 *                     pagination:
 *                       type: object
 *                       properties:
 *                         page:
 *                           type: integer
 *                         limit:
 *                           type: integer
 *                         total:
 *                           type: integer
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/quotes/estimate:
 *   post:
 *     summary: Get fare estimate
 *     tags: [Quotes]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - pickupLocation
 *               - dropoffLocation
 *             properties:
 *               pickupLocation:
 *                 $ref: '#/components/schemas/Location'
 *               dropoffLocation:
 *                 $ref: '#/components/schemas/Location'
 *               vehicleType:
 *                 type: string
 *                 enum: [sedan, suv, van, luxury]
 *                 example: "sedan"
 *               scheduledTime:
 *                 type: string
 *                 format: date-time
 *               passengerCount:
 *                 type: integer
 *                 example: 2
 *     responses:
 *       200:
 *         description: Fare estimate calculated successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         estimatedFare:
 *                           type: number
 *                         estimatedDuration:
 *                           type: number
 *                         estimatedDistance:
 *                           type: number
 *                         currency:
 *                           type: string
 *                         breakdown:
 *                           type: object
 *                           properties:
 *                             baseFare:
 *                               type: number
 *                             distanceFee:
 *                               type: number
 *                             timeFee:
 *                               type: number
 *                             surgeMultiplier:
 *                               type: number
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 */

/**
 * @swagger
 * /api/quotes/{id}:
 *   delete:
 *     summary: Delete quote (Admin only)
 *     tags: [Quotes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Quote ID
 *     responses:
 *       200:
 *         description: Quote deleted successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/payments/methods:
 *   get:
 *     summary: Get user's payment methods
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Payment methods retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/PaymentMethod'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */

/**
 * @swagger
 * /api/payments/process:
 *   post:
 *     summary: Process a payment
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - bookingId
 *               - paymentMethodId
 *               - amount
 *             properties:
 *               bookingId:
 *                 type: string
 *                 example: "507f1f77bcf86cd799439011"
 *               paymentMethodId:
 *                 type: string
 *                 example: "pm_1234567890"
 *               amount:
 *                 type: number
 *                 example: 25.50
 *               currency:
 *                 type: string
 *                 example: "ZAR"
 *               description:
 *                 type: string
 *                 example: "SwiftLyft ride payment"
 *     responses:
 *       200:
 *         description: Payment processed successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         paymentId:
 *                           type: string
 *                         status:
 *                           type: string
 *                         amount:
 *                           type: number
 *                         currency:
 *                           type: string
 *                         transactionId:
 *                           type: string
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       402:
 *         description: Payment failed
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */

/**
 * @swagger
 * /api/payments/users/{userId}/payment-methods:
 *   get:
 *     summary: Get payment methods for specific user (Admin only)
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *     responses:
 *       200:
 *         description: Payment methods retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/PaymentMethod'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/payments/users/{userId}/payment-methods:
 *   post:
 *     summary: Add payment method for user
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - type
 *               - token
 *             properties:
 *               type:
 *                 type: string
 *                 enum: [card, bank_account]
 *                 example: "card"
 *               token:
 *                 type: string
 *                 description: Payment provider token
 *                 example: "tok_visa"
 *               isDefault:
 *                 type: boolean
 *                 example: true
 *     responses:
 *       201:
 *         description: Payment method added successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/PaymentMethod'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/payments/payment-methods/{id}:
 *   delete:
 *     summary: Delete payment method
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Payment method ID
 *     responses:
 *       200:
 *         description: Payment method deleted successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/payments/users/{userId}/payments:
 *   get:
 *     summary: Get payment history for user
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, completed, failed, refunded, cancelled]
 *         description: Filter by payment status
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Number of payments to return
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *     responses:
 *       200:
 *         description: Payment history retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           _id:
 *                             type: string
 *                           bookingId:
 *                             type: string
 *                           amount:
 *                             type: number
 *                           currency:
 *                             type: string
 *                           status:
 *                             type: string
 *                           paymentMethod:
 *                             type: string
 *                           transactionId:
 *                             type: string
 *                           createdAt:
 *                             type: string
 *                             format: date-time
 *                     pagination:
 *                       type: object
 *                       properties:
 *                         page:
 *                           type: integer
 *                         limit:
 *                           type: integer
 *                         total:
 *                           type: integer
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/payments/{id}/refund:
 *   post:
 *     summary: Process refund for payment (Admin only)
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Payment ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - amount
 *             properties:
 *               amount:
 *                 type: number
 *                 example: 25.50
 *               reason:
 *                 type: string
 *                 example: "Customer requested cancellation"
 *     responses:
 *       200:
 *         description: Refund processed successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         refundId:
 *                           type: string
 *                         amount:
 *                           type: number
 *                         status:
 *                           type: string
 *                         transactionId:
 *                           type: string
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/payments/{id}/status:
 *   get:
 *     summary: Get payment status
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Payment ID
 *     responses:
 *       200:
 *         description: Payment status retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         paymentId:
 *                           type: string
 *                         status:
 *                           type: string
 *                         amount:
 *                           type: number
 *                         currency:
 *                           type: string
 *                         transactionId:
 *                           type: string
 *                         updatedAt:
 *                           type: string
 *                           format: date-time
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/location/geocode:
 *   post:
 *     summary: Geocode an address to coordinates
 *     tags: [Location]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - address
 *             properties:
 *               address:
 *                 type: string
 *                 example: "123 Main Street, Johannesburg, South Africa"
 *     responses:
 *       200:
 *         description: Address geocoded successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         coordinates:
 *                           type: object
 *                           properties:
 *                             lat:
 *                               type: number
 *                             lng:
 *                               type: number
 *                         formattedAddress:
 *                           type: string
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */

/**
 * @swagger
 * /api/location/reverse-geocode:
 *   post:
 *     summary: Reverse geocode coordinates to address
 *     tags: [Location]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - latitude
 *               - longitude
 *             properties:
 *               latitude:
 *                 type: number
 *                 example: -26.2041
 *               longitude:
 *                 type: number
 *                 example: 28.0473
 *     responses:
 *       200:
 *         description: Coordinates reverse geocoded successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         address:
 *                           type: string
 *                         coordinates:
 *                           type: object
 *                           properties:
 *                             lat:
 *                               type: number
 *                             lng:
 *                               type: number
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 */

/**
 * @swagger
 * /api/location/route:
 *   post:
 *     summary: Calculate route between two points
 *     tags: [Location]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - origin
 *               - destination
 *             properties:
 *               origin:
 *                 type: object
 *                 properties:
 *                   latitude:
 *                     type: number
 *                     example: -26.2041
 *                   longitude:
 *                     type: number
 *                     example: 28.0473
 *               destination:
 *                 type: object
 *                 properties:
 *                   latitude:
 *                     type: number
 *                     example: -26.1952
 *                   longitude:
 *                     type: number
 *                     example: 28.0341
 *               waypoints:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     latitude:
 *                       type: number
 *                     longitude:
 *                       type: number
 *     responses:
 *       200:
 *         description: Route calculated successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         distance:
 *                           type: object
 *                           properties:
 *                             value:
 *                               type: number
 *                             text:
 *                               type: string
 *                         duration:
 *                           type: object
 *                           properties:
 *                             value:
 *                               type: number
 *                             text:
 *                               type: string
 *                         polyline:
 *                           type: string
 *                         bounds:
 *                           type: object
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 */

/**
 * @swagger
 * /api/location/places/search:
 *   get:
 *     summary: Search for places
 *     tags: [Location]
 *     parameters:
 *       - in: query
 *         name: query
 *         required: true
 *         schema:
 *           type: string
 *         description: Search query
 *       - in: query
 *         name: latitude
 *         schema:
 *           type: number
 *         description: Latitude for location bias
 *       - in: query
 *         name: longitude
 *         schema:
 *           type: number
 *         description: Longitude for location bias
 *       - in: query
 *         name: radius
 *         schema:
 *           type: number
 *           default: 1000
 *         description: Search radius in meters
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *           enum: [establishment, geocode, address]
 *         description: Place type filter
 *     responses:
 *       200:
 *         description: Places search completed successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           placeId:
 *                             type: string
 *                           name:
 *                             type: string
 *                           address:
 *                             type: string
 *                           coordinates:
 *                             type: object
 *                             properties:
 *                               lat:
 *                                 type: number
 *                               lng:
 *                                 type: number
 *                           types:
 *                             type: array
 *                             items:
 *                               type: string
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 */

/**
 * @swagger
 * /api/location/places/nearby:
 *   get:
 *     summary: Find nearby places
 *     tags: [Location]
 *     parameters:
 *       - in: query
 *         name: latitude
 *         required: true
 *         schema:
 *           type: number
 *         description: Latitude
 *       - in: query
 *         name: longitude
 *         required: true
 *         schema:
 *           type: number
 *         description: Longitude
 *       - in: query
 *         name: radius
 *         schema:
 *           type: number
 *           default: 1500
 *         description: Search radius in meters
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *         description: Place type (e.g., restaurant, hotel, gas_station)
 *     responses:
 *       200:
 *         description: Nearby places found successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           placeId:
 *                             type: string
 *                           name:
 *                             type: string
 *                           vicinity:
 *                             type: string
 *                           coordinates:
 *                             type: object
 *                             properties:
 *                               lat:
 *                                 type: number
 *                               lng:
 *                                 type: number
 *                           rating:
 *                             type: number
 *                           types:
 *                             type: array
 *                             items:
 *                               type: string
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 */

/**
 * @swagger
 * /api/location/service-area:
 *   post:
 *     summary: Check if location is within service area
 *     tags: [Location]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - latitude
 *               - longitude
 *             properties:
 *               latitude:
 *                 type: number
 *                 example: -26.2041
 *               longitude:
 *                 type: number
 *                 example: 28.0473
 *     responses:
 *       200:
 *         description: Service area check completed
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         inServiceArea:
 *                           type: boolean
 *                         distance:
 *                           type: number
 *                         nearestServicePoint:
 *                           type: object
 *                           properties:
 *                             name:
 *                               type: string
 *                             coordinates:
 *                               type: object
 *                             distance:
 *                               type: number
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 */

/**
 * @swagger
 * /api/location/drivers/{id}/location:
 *   get:
 *     summary: Get driver current location
 *     tags: [Location]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Driver ID
 *     responses:
 *       200:
 *         description: Driver location retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         driverId:
 *                           type: string
 *                         coordinates:
 *                           type: object
 *                           properties:
 *                             lat:
 *                               type: number
 *                             lng:
 *                               type: number
 *                         lastUpdated:
 *                           type: string
 *                           format: date-time
 *                         status:
 *                           type: string
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/location/history:
 *   get:
 *     summary: Get user's location history
 *     tags: [Location]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 50
 *         description: Number of locations to return
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Start date for history
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date-time
 *         description: End date for history
 *     responses:
 *       200:
 *         description: Location history retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           coordinates:
 *                             type: object
 *                             properties:
 *                               lat:
 *                                 type: number
 *                               lng:
 *                                 type: number
 *                           timestamp:
 *                             type: string
 *                             format: date-time
 *                           activity:
 *                             type: string
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */

/**
 * @swagger
 * /api/notifications:
 *   get:
 *     summary: Get user notifications
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: unread
 *         schema:
 *           type: boolean
 *         description: Filter for unread notifications only
 *       - in: query
 *         name: limit
 *         schema:
 *           type: number
 *           default: 20
 *         description: Number of notifications to return
 *       - in: query
 *         name: page
 *         schema:
 *           type: number
 *           default: 1
 *         description: Page number
 *     responses:
 *       200:
 *         description: Notifications retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/Notification'
 *                     pagination:
 *                       type: object
 *                       properties:
 *                         page:
 *                           type: number
 *                         limit:
 *                           type: number
 *                         total:
 *                           type: number
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */

/**
 * @swagger
 * /api/notifications/send:
 *   post:
 *     summary: Send notification (Admin only)
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *               - message
 *             properties:
 *               title:
 *                 type: string
 *                 example: "System Maintenance"
 *               message:
 *                 type: string
 *                 example: "The system will be under maintenance tonight from 10 PM to 2 AM"
 *               type:
 *                 type: string
 *                 enum: [booking, payment, promotion, system]
 *                 example: "system"
 *               userId:
 *                 type: string
 *                 description: Specific user ID, or omit for broadcast
 *               data:
 *                 type: object
 *                 description: Additional notification data
 *     responses:
 *       200:
 *         description: Notification sent successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/notifications/user/{userId}:
 *   get:
 *     summary: Get notifications for specific user (Admin only)
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *       - in: query
 *         name: unread
 *         schema:
 *           type: boolean
 *         description: Filter for unread notifications only
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Number of notifications to return
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *     responses:
 *       200:
 *         description: User notifications retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/Notification'
 *                     pagination:
 *                       type: object
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/notifications/user/{userId}/{notificationId}/read:
 *   put:
 *     summary: Mark notification as read
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *       - in: path
 *         name: notificationId
 *         required: true
 *         schema:
 *           type: string
 *         description: Notification ID
 *     responses:
 *       200:
 *         description: Notification marked as read
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/notifications/user/{userId}/mark-all-read:
 *   put:
 *     summary: Mark all user notifications as read
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *     responses:
 *       200:
 *         description: All notifications marked as read
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/notifications/user/{userId}/settings:
 *   get:
 *     summary: Get notification settings
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *     responses:
 *       200:
 *         description: Notification settings retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         emailNotifications:
 *                           type: boolean
 *                         pushNotifications:
 *                           type: boolean
 *                         smsNotifications:
 *                           type: boolean
 *                         bookingUpdates:
 *                           type: boolean
 *                         promotionalOffers:
 *                           type: boolean
 *                         systemUpdates:
 *                           type: boolean
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/notifications/user/{userId}/settings:
 *   put:
 *     summary: Update notification settings
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               emailNotifications:
 *                 type: boolean
 *                 example: true
 *               pushNotifications:
 *                 type: boolean
 *                 example: true
 *               smsNotifications:
 *                 type: boolean
 *                 example: false
 *               bookingUpdates:
 *                 type: boolean
 *                 example: true
 *               promotionalOffers:
 *                 type: boolean
 *                 example: false
 *               systemUpdates:
 *                 type: boolean
 *                 example: true
 *     responses:
 *       200:
 *         description: Notification settings updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/notifications/user/{userId}/fcm-token:
 *   post:
 *     summary: Register FCM token for push notifications
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - token
 *             properties:
 *               token:
 *                 type: string
 *                 description: FCM registration token
 *                 example: "eA1B2cD3eF4gH5iJ6kL7mN8oP9qR0sT1uV2wX3yZ4"
 *               platform:
 *                 type: string
 *                 enum: [ios, android, web]
 *                 example: "android"
 *     responses:
 *       200:
 *         description: FCM token registered successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/notifications/sms:
 *   post:
 *     summary: Send SMS notification (Admin only)
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - phoneNumber
 *               - message
 *             properties:
 *               phoneNumber:
 *                 type: string
 *                 example: "+27123456789"
 *               message:
 *                 type: string
 *                 example: "Your SwiftLyft driver is arriving in 5 minutes"
 *               userId:
 *                 type: string
 *                 description: Associated user ID for tracking
 *     responses:
 *       200:
 *         description: SMS sent successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         messageId:
 *                           type: string
 *                         status:
 *                           type: string
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/notifications/user/{userId}/{notificationId}:
 *   delete:
 *     summary: Delete notification
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *       - in: path
 *         name: notificationId
 *         required: true
 *         schema:
 *           type: string
 *         description: Notification ID
 *     responses:
 *       200:
 *         description: Notification deleted successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/analytics/dashboard:
 *   get:
 *     summary: Get analytics dashboard data
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [day, week, month, year]
 *           default: month
 *         description: Time period for analytics
 *     responses:
 *       200:
 *         description: Analytics data retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Analytics'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/analytics/users/{userId}:
 *   get:
 *     summary: Get user analytics (Admin only)
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [day, week, month, year]
 *           default: month
 *         description: Time period for analytics
 *     responses:
 *       200:
 *         description: User analytics retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         totalBookings:
 *                           type: integer
 *                         totalSpent:
 *                           type: number
 *                         averageRating:
 *                           type: number
 *                         favoriteRoutes:
 *                           type: array
 *                         bookingFrequency:
 *                           type: object
 *                         loyaltyTier:
 *                           type: string
 *                         pointsEarned:
 *                           type: integer
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/analytics/bookings:
 *   get:
 *     summary: Get booking analytics (Admin only)
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [day, week, month, year]
 *           default: month
 *         description: Time period for analytics
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Start date for analytics
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date
 *         description: End date for analytics
 *     responses:
 *       200:
 *         description: Booking analytics retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         totalBookings:
 *                           type: integer
 *                         completedBookings:
 *                           type: integer
 *                         cancelledBookings:
 *                           type: integer
 *                         totalRevenue:
 *                           type: number
 *                         averageBookingValue:
 *                           type: number
 *                         completionRate:
 *                           type: number
 *                         popularRoutes:
 *                           type: array
 *                         peakHours:
 *                           type: array
 *                         statusBreakdown:
 *                           type: object
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/analytics/revenue:
 *   get:
 *     summary: Get revenue analytics (Admin only)
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [day, week, month, year]
 *           default: month
 *         description: Time period for analytics
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Start date for analytics
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date
 *         description: End date for analytics
 *     responses:
 *       200:
 *         description: Revenue analytics retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         totalRevenue:
 *                           type: number
 *                         dailyRevenue:
 *                           type: array
 *                         monthlyRevenue:
 *                           type: array
 *                         paymentMethodBreakdown:
 *                           type: object
 *                         averageTransactionValue:
 *                           type: number
 *                         revenueGrowth:
 *                           type: number
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/analytics/drivers:
 *   get:
 *     summary: Get driver analytics (Admin only)
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [day, week, month, year]
 *           default: month
 *         description: Time period for analytics
 *     responses:
 *       200:
 *         description: Driver analytics retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         totalDrivers:
 *                           type: integer
 *                         activeDrivers:
 *                           type: integer
 *                         averageRating:
 *                           type: number
 *                         totalTrips:
 *                           type: integer
 *                         totalEarnings:
 *                           type: number
 *                         utilizationRate:
 *                           type: number
 *                         driverPerformance:
 *                           type: array
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/analytics/events:
 *   post:
 *     summary: Track user events for analytics
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - eventType
 *             properties:
 *               eventType:
 *                 type: string
 *                 enum: [app_open, booking_started, booking_completed, payment_success, rating_submitted]
 *                 example: "booking_started"
 *               eventData:
 *                 type: object
 *                 description: Additional event data
 *                 example: { "vehicleType": "sedan", "pickupLocation": "Sandton" }
 *               timestamp:
 *                 type: string
 *                 format: date-time
 *                 description: Event timestamp (defaults to now)
 *     responses:
 *       200:
 *         description: Event tracked successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       429:
 *         description: Too many events
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */

/**
 * @swagger
 * /api/support/tickets:
 *   post:
 *     summary: Create a support ticket
 *     tags: [Support]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - subject
 *               - description
 *               - category
 *             properties:
 *               subject:
 *                 type: string
 *                 example: "Issue with payment"
 *               description:
 *                 type: string
 *                 example: "I was charged twice for my last ride"
 *               category:
 *                 type: string
 *                 enum: [billing, technical, general, complaint]
 *                 example: "billing"
 *               priority:
 *                 type: string
 *                 enum: [low, medium, high, urgent]
 *                 example: "medium"
 *               bookingId:
 *                 type: string
 *                 description: Related booking ID if applicable
 *     responses:
 *       201:
 *         description: Support ticket created successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/SupportTicket'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */

/**
 * @swagger
 * /api/support/user/{userId}/tickets:
 *   get:
 *     summary: Get user's support tickets
 *     tags: [Support]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [open, in_progress, resolved, closed]
 *         description: Filter by ticket status
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Number of tickets to return
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *     responses:
 *       200:
 *         description: Support tickets retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/SupportTicket'
 *                     pagination:
 *                       type: object
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */

/**
 * @swagger
 * /api/support/tickets/{ticketId}:
 *   get:
 *     summary: Get support ticket details
 *     tags: [Support]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: ticketId
 *         required: true
 *         schema:
 *           type: string
 *         description: Support ticket ID
 *     responses:
 *       200:
 *         description: Support ticket details retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/SupportTicket'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/support/tickets/{ticketId}/messages:
 *   post:
 *     summary: Add message to support ticket
 *     tags: [Support]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: ticketId
 *         required: true
 *         schema:
 *           type: string
 *         description: Support ticket ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - message
 *             properties:
 *               message:
 *                 type: string
 *                 example: "I need help with my recent booking"
 *     responses:
 *       200:
 *         description: Message added successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/SupportTicket'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/support/tickets/{ticketId}/status:
 *   put:
 *     summary: Update support ticket status (Admin/Support only)
 *     tags: [Support]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: ticketId
 *         required: true
 *         schema:
 *           type: string
 *         description: Support ticket ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [open, in_progress, resolved, closed]
 *                 example: "in_progress"
 *               notes:
 *                 type: string
 *                 example: "Working on resolving the issue"
 *     responses:
 *       200:
 *         description: Ticket status updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/SupportTicket'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */

/**
 * @swagger
 * /api/support/faq:
 *   get:
 *     summary: Get FAQ list
 *     tags: [Support]
 *     responses:
 *       200:
 *         description: FAQ list retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           _id:
 *                             type: string
 *                           question:
 *                             type: string
 *                           answer:
 *                             type: string
 *                           category:
 *                             type: string
 *                           helpful:
 *                             type: integer
 *                           totalViews:
 *                             type: integer
 */

/**
 * @swagger
 * /api/support/faq/categories:
 *   get:
 *     summary: Get FAQ categories
 *     tags: [Support]
 *     responses:
 *       200:
 *         description: FAQ categories retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           category:
 *                             type: string
 *                           name:
 *                             type: string
 *                           description:
 *                             type: string
 *                           faqCount:
 *                             type: integer
 */

/**
 * @swagger
 * /api/support/contact:
 *   get:
 *     summary: Get contact information
 *     tags: [Support]
 *     responses:
 *       200:
 *         description: Contact information retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         email:
 *                           type: string
 *                         phone:
 *                           type: string
 *                         whatsapp:
 *                           type: string
 *                         businessHours:
 *                           type: string
 *                         responseTime:
 *                           type: string
 */
