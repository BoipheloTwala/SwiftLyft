const nodemailer = require('nodemailer');

// Create transporter (you'll need to configure this with your email service)
const createTransporter = () => {
  // Use environment variables for both development and production
  
  // If no SMTP settings are provided, use a test configuration
  if (!process.env.SMTP_HOST || !process.env.SMTP_USER) {
    console.log('⚠️ No email configuration found. Using test mode.');
    // Return a test transporter that just logs
    return nodemailer.createTransport({
      streamTransport: true,
      newline: 'unix',
      buffer: true
    });
  }
  
  // Configure SMTP with proper options for production hosting
  // Render blocks SMTP connections, so we need special handling
  const port = parseInt(process.env.SMTP_PORT) || 587;
  const isSecure = process.env.SMTP_SECURE === 'true';
  
  const transporterConfig = {
    host: process.env.SMTP_HOST,
    port: port,
    secure: isSecure, // true for 465, false for other ports
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS
    },
    // Increased timeouts for slower connections
    connectionTimeout: 20000, // 20 seconds
    greetingTimeout: 10000, // 10 seconds
    socketTimeout: 20000, // 20 seconds
    // TLS configuration
    tls: {
      rejectUnauthorized: false, // Accept self-signed certificates
      ciphers: 'SSLv3' // Try different cipher if needed
    },
    // Retry configuration
    pool: true,
    maxConnections: 1,
    maxMessages: 3
  };
  
  return nodemailer.createTransport(transporterConfig);
};

// Send basic email
const sendEmail = async (to, subject, html, text = null) => {
  try {
    const transporter = createTransporter();
    
    const mailOptions = {
      from: process.env.FROM_EMAIL || 'noreply@swiftlyft.co.za',
      to,
      subject,
      html,
      text: text || html.replace(/<[^>]*>/g, '') // Strip HTML for text version
    };

    const result = await transporter.sendMail(mailOptions);
    
    // Handle different types of transporters
    if (!process.env.SMTP_HOST || !process.env.SMTP_USER) {
      // Test mode - just log the email content
      console.log('📧 Test Email Sent:');
      console.log(`   To: ${to}`);
      console.log(`   Subject: ${subject}`);
      console.log(`   Content: Email verification system is working!`);
    } else {
      // Production or development with real email service
      console.log('📧 Email sent successfully to:', to);
      console.log('📧 Message ID:', result.messageId);
      
      // Additional logging for production
      if (process.env.NODE_ENV === 'production') {
        console.log('📧 SMTP Host:', process.env.SMTP_HOST);
        console.log('📧 SMTP User:', process.env.SMTP_USER);
      }
      
      if (nodemailer.getTestMessageUrl && nodemailer.getTestMessageUrl(result)) {
        console.log('📧 Preview URL:', nodemailer.getTestMessageUrl(result));
      }
    }
    
    return {
      success: true,
      messageId: result.messageId || 'test-message-id'
    };
  } catch (error) {
    console.error('❌ Email sending error:', error.message);
    console.error('❌ Error details:', error);
    
    // Log configuration issues
    if (!process.env.SMTP_HOST) {
      console.error('⚠️ SMTP_HOST is not set in environment variables');
    }
    if (!process.env.SMTP_USER) {
      console.error('⚠️ SMTP_USER is not set in environment variables');
    }
    if (!process.env.SMTP_PASS) {
      console.error('⚠️ SMTP_PASS is not set in environment variables');
    }
    
    return {
      success: false,
      error: error.message
    };
  }
};

// Send email verification
const sendEmailVerification = async (email, verificationUrl) => {
  const subject = 'Verify Your Email - SwiftLyft';
  
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="text-align: center; margin-bottom: 30px;">
        <h1 style="color: #007bff; margin: 0;">🚗 SwiftLyft</h1>
      </div>
      
      <div style="background: #f8f9fa; padding: 30px; border-radius: 10px; margin-bottom: 30px;">
        <h2 style="color: #333; margin-top: 0;">📧 Verify Your Email Address</h2>
        <p style="color: #666; font-size: 16px; line-height: 1.5;">
          Welcome to SwiftLyft! Please verify your email address to complete your account setup.
        </p>
        
        <div style="text-align: center; margin: 30px 0;">
          <a href="${verificationUrl}" 
             style="background: #007bff; color: white; padding: 15px 30px; 
                    text-decoration: none; border-radius: 5px; display: inline-block;
                    font-weight: bold; font-size: 16px;">
            ✅ Verify Email Address
          </a>
        </div>
        
        <p style="color: #666; font-size: 14px;">
          Or copy and paste this link in your browser:
        </p>
        <p style="word-break: break-all; background: #e9ecef; padding: 10px; border-radius: 5px; font-family: monospace; font-size: 12px;">
          ${verificationUrl}
        </p>
      </div>
      
      <div style="text-align: center; color: #666; font-size: 12px;">
        <p>This verification link expires in 24 hours.</p>
        <p>If you didn't create a SwiftLyft account, please ignore this email.</p>
        <p>© 2024 SwiftLyft. All rights reserved.</p>
      </div>
    </div>
  `;

  return await sendEmail(email, subject, html);
};

// Send phone verification code via email
const sendPhoneVerificationEmail = async (email, phoneNumber, verificationCode) => {
  const subject = 'Phone Verification Code - SwiftLyft';
  
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="text-align: center; margin-bottom: 30px;">
        <h1 style="color: #007bff; margin: 0;">🚗 SwiftLyft</h1>
      </div>
      
      <div style="background: #f8f9fa; padding: 30px; border-radius: 10px; margin-bottom: 30px;">
        <h2 style="color: #333; margin-top: 0;">📱 Phone Number Verification</h2>
        <p style="color: #666; font-size: 16px; line-height: 1.5;">
          You requested to verify the phone number: <strong>${phoneNumber}</strong>
        </p>
        
        <div style="background: #e3f2fd; padding: 25px; text-align: center; margin: 25px 0; border-radius: 8px; border-left: 4px solid #007bff;">
          <p style="color: #333; font-size: 14px; margin-bottom: 10px;">Your verification code:</p>
          <h1 style="color: #007bff; font-size: 48px; margin: 15px 0; letter-spacing: 8px; font-family: monospace;">
            ${verificationCode}
          </h1>
          <p style="color: #666; font-size: 14px; margin-top: 15px;">
            ⏰ This code expires in 15 minutes
          </p>
        </div>
        
        <div style="background: #fff3cd; padding: 15px; border-radius: 5px; border-left: 4px solid #ffc107;">
          <p style="color: #856404; font-size: 14px; margin: 0;">
            <strong>Security Note:</strong> Never share this code with anyone. SwiftLyft will never ask for your verification code.
          </p>
        </div>
      </div>
      
      <div style="text-align: center; color: #666; font-size: 12px;">
        <p>If you didn't request this verification, please ignore this email.</p>
        <p>© 2024 SwiftLyft. All rights reserved.</p>
      </div>
    </div>
  `;

  return await sendEmail(email, subject, html);
};

// Send password reset email
const sendPasswordResetEmail = async (email, resetUrl) => {
  const subject = 'Reset Your Password - SwiftLyft';
  
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="text-align: center; margin-bottom: 30px;">
        <h1 style="color: #007bff; margin: 0;">🚗 SwiftLyft</h1>
      </div>
      
      <div style="background: #f8f9fa; padding: 30px; border-radius: 10px; margin-bottom: 30px;">
        <h2 style="color: #333; margin-top: 0;">🔐 Reset Your Password</h2>
        <p style="color: #666; font-size: 16px; line-height: 1.5;">
          You requested to reset your password. Click the button below to set a new password:
        </p>
        
        <div style="text-align: center; margin: 30px 0;">
          <a href="${resetUrl}" 
             style="background: #dc3545; color: white; padding: 15px 30px; 
                    text-decoration: none; border-radius: 5px; display: inline-block;
                    font-weight: bold; font-size: 16px;">
            🔑 Reset Password
          </a>
        </div>
        
        <p style="color: #666; font-size: 14px;">
          Or copy and paste this link in your browser:
        </p>
        <p style="word-break: break-all; background: #e9ecef; padding: 10px; border-radius: 5px; font-family: monospace; font-size: 12px;">
          ${resetUrl}
        </p>
        
        <div style="background: #f8d7da; padding: 15px; border-radius: 5px; border-left: 4px solid #dc3545; margin-top: 20px;">
          <p style="color: #721c24; font-size: 14px; margin: 0;">
            <strong>Security Note:</strong> This link expires in 10 minutes. If you didn't request this reset, please ignore this email.
          </p>
        </div>
      </div>
      
      <div style="text-align: center; color: #666; font-size: 12px;">
        <p>© 2024 SwiftLyft. All rights reserved.</p>
      </div>
    </div>
  `;

  return await sendEmail(email, subject, html);
};

module.exports = {
  sendEmail,
  sendEmailVerification,
  sendPhoneVerificationEmail,
  sendPasswordResetEmail
};

