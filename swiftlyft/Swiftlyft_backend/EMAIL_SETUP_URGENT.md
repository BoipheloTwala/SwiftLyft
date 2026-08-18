# URGENT: Email Setup for Render

## Problem: Render Blocks Gmail SMTP Connections

Render blocks ALL outgoing SMTP connections to Gmail (ports 587 and 465). This is why you're getting connection timeouts.

## Solution: Use SendGrid (5 minutes setup)

SendGrid works perfectly with Render and offers free tier (100 emails/day).

### Step 1: Sign Up for SendGrid (2 minutes)
1. Go to https://signup.sendgrid.com
2. Sign up with your email
3. Verify your email address

### Step 2: Create an API Key (1 minute)
1. Go to Settings → API Keys
2. Click "Create API Key"
3. Name it "SwiftLyft"
4. Set permission to "Full Access"
5. Copy the API key (you won't see it again!)

### Step 3: Configure Render (2 minutes)
1. Go to your Render service settings
2. Go to Environment tab
3. Add these environment variables:

```
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=apikey
SMTP_PASS=paste-your-sendgrid-api-key-here
FROM_EMAIL=noreply@swiftlyft.co.za
```

4. Click "Save Changes"
5. Render will auto-redeploy

### Step 4: Test
1. Wait for deployment to finish (1-2 minutes)
2. Try password reset again
3. Check your email!

## Alternative: Use Mailtrap (For Testing Only)

If you just want to test:

1. Sign up at https://mailtrap.io (free)
2. Get your credentials from the inbox
3. Use these settings:

```
SMTP_HOST=sandbox.smtp.mailtrap.io
SMTP_PORT=2525
SMTP_SECURE=false
SMTP_USER=your-mailtrap-username
SMTP_PASS=your-mailtrap-password
FROM_EMAIL=noreply@swiftlyft.co.za
```

## Why Gmail Doesn't Work

Render's firewall blocks:
- smtp.gmail.com (all ports)
- googlemail.com (all ports)

This is a Render security policy and cannot be changed.

## SendGrid Free Tier Limits

- 100 emails per day (perfect for testing)
- Unlimited contacts
- Full SMTP access
- Works perfectly with Render

## Done!

After updating environment variables, emails will work immediately.
