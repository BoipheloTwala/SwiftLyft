# Email Setup for SwiftLyft Backend

## Problem: Connection Timeout on Render

Render blocks outgoing SMTP connections on port 587. Here's how to fix it.

## Solution 1: Use Port 465 with SSL (Recommended)

1. Go to your Render service settings
2. Add these environment variables:

```
SMTP_HOST=smtp.gmail.com
SMTP_PORT=465
SMTP_SECURE=true
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
FROM_EMAIL=noreply@swiftlyft.co.za
```

3. Save and redeploy

## Solution 2: Use a Different Email Service

If Gmail doesn't work, consider these alternatives:

### Option A: SendGrid (Recommended for Production)

1. Sign up at https://sendgrid.com
2. Create an API Key
3. Use these settings:

```
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=apikey
SMTP_PASS=your-sendgrid-api-key
FROM_EMAIL=noreply@swiftlyft.co.za
```

### Option B: Mailgun

1. Sign up at https://www.mailgun.com
2. Get your SMTP credentials from the dashboard
3. Use these settings:

```
SMTP_HOST=smtp.mailgun.org
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-mailgun-username
SMTP_PASS=your-mailgun-password
FROM_EMAIL=noreply@swiftlyft.co.za
```

### Option C: Mailtrap (For Testing)

For testing purposes, use Mailtrap:

1. Sign up at https://mailtrap.io
2. Get your SMTP settings from the inbox
3. Use these settings:

```
SMTP_HOST=sandbox.smtp.mailtrap.io
SMTP_PORT=2525
SMTP_SECURE=false
SMTP_USER=your-mailtrap-username
SMTP_PASS=your-mailtrap-password
FROM_EMAIL=noreply@swiftlyft.co.za
```

## Gmail App Password Setup

If using Gmail, you need an App Password:

1. Go to https://myaccount.google.com/security
2. Enable 2-Step Verification if not already enabled
3. Go to https://myaccount.google.com/apppasswords
4. Generate a new app password for "Mail"
5. Use the 16-character password as `SMTP_PASS`

## Testing

After setup, try:
1. Request a password reset
2. Check Render logs for email sending status
3. Check your email inbox

## Troubleshooting

### Still getting timeout errors?

1. Make sure `SMTP_SECURE=true` when using port 465
2. Check that your App Password is correct
3. Try using SendGrid or Mailgun instead of Gmail

### Emails going to spam?

1. Set up SPF records for your domain
2. Use a dedicated email service (SendGrid/Mailgun)
3. Avoid using personal Gmail accounts

## Current Configuration

The code now includes:
- Connection timeout settings (10 seconds)
- TLS configuration for Render compatibility
- Detailed error logging
- Test mode fallback when SMTP is not configured
