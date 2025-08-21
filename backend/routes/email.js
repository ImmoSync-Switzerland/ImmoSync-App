const express = require('express');
const router = express.Router();
const nodemailer = require('nodemailer');

// Create reusable transporter object using the SMTP transport
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT,
  secure: false, // true for 465, false for other ports
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

// Email service with real nodemailer implementation
class EmailService {
  static async sendEmail(to, subject, htmlContent, textContent = null) {
    console.log('📧 EmailService.sendEmail called with:');
    console.log('📧 To:', to);
    console.log('📧 Subject:', subject);
    console.log('📧 FROM_EMAIL:', process.env.FROM_EMAIL);
    console.log('📧 FROM_NAME:', process.env.FROM_NAME);
    console.log('📧 SMTP_HOST:', process.env.SMTP_HOST);
    console.log('📧 SMTP_PORT:', process.env.SMTP_PORT);
    console.log('📧 SMTP_USER:', process.env.SMTP_USER);
    
    try {
      const mailOptions = {
        from: `${process.env.FROM_NAME} <${process.env.FROM_EMAIL}>`,
        to: to,
        subject: subject,
        html: htmlContent,
        text: textContent || htmlContent.replace(/<[^>]*>/g, '') // Strip HTML for text version
      };

      console.log('📧 Mail options prepared:', JSON.stringify(mailOptions, null, 2));
      console.log('📧 Attempting to send email via transporter...');
      
      const info = await transporter.sendMail(mailOptions);
      console.log('✅ Email sent successfully:', info.messageId);
      console.log('✅ Full email info:', JSON.stringify(info, null, 2));
      
      return { success: true, messageId: info.messageId };
    } catch (error) {
      console.error('❌ Error sending email:', error.message);
      console.error('❌ Full error:', error);
      throw error;
    }
  }

  static async sendRegistrationConfirmation(userEmail, userName) {
    const subject = 'Registration Confirmed - Welcome to ImmoLink!';
    const htmlContent = `
      <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
          <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
            <h1 style="color: #2c5aa0;">Welcome to ImmoLink!</h1>
            <p>Dear ${userName},</p>
            <p>Congratulations! Your ImmoLink account has been successfully created.</p>
            <p>You can now:</p>
            <ul>
              <li>Manage your properties with ease</li>
              <li>Connect with tenants or landlords</li>
              <li>Track payments and maintenance requests</li>
              <li>Generate detailed reports</li>
              <li>Access our mobile app for on-the-go management</li>
            </ul>
            <p>Get started by logging into your account and exploring all the features ImmoLink has to offer.</p>
            <div style="text-align: center; margin: 30px 0;">
              <a href="${process.env.APP_URL}/login" style="background-color: #2c5aa0; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">Login to Your Account</a>
            </div>
            <p>If you have any questions or need assistance, our support team is here to help.</p>
            <p>Best regards,<br>The ImmoLink Team</p>
          </div>
        </body>
      </html>
    `;
    return await this.sendEmail(userEmail, subject, htmlContent);
  }

  static async sendWelcomeEmail(userEmail, userName) {
    const subject = 'Welcome to ImmoLink!';
    const htmlContent = `
      <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
          <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
            <h1 style="color: #2c5aa0;">Welcome to ImmoLink!</h1>
            <p>Dear ${userName},</p>
            <p>Welcome to ImmoLink, your comprehensive property management solution!</p>
            <p>You can now:</p>
            <ul>
              <li>Manage your properties</li>
              <li>Connect with tenants or landlords</li>
              <li>Track payments and maintenance requests</li>
              <li>Generate detailed reports</li>
            </ul>
            <p>Get started by logging into your account and exploring the features.</p>
            <p>If you have any questions, feel free to contact our support team.</p>
            <p>Best regards,<br>The ImmoLink Team</p>
          </div>
        </body>
      </html>
    `;
    return await this.sendEmail(userEmail, subject, htmlContent);
  }

  static async sendPasswordChangeNotification(userEmail, userName) {
    const subject = 'Password Changed - ImmoLink';
    const htmlContent = `
      <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
          <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
            <h1 style="color: #2c5aa0;">Password Changed</h1>
            <p>Dear ${userName},</p>
            <p>Your ImmoLink account password has been successfully changed.</p>
            <p>If you did not make this change, please contact our support team immediately.</p>
            <p>For security reasons, you may need to log in again on your devices.</p>
            <p>Best regards,<br>The ImmoLink Team</p>
          </div>
        </body>
      </html>
    `;
    return await this.sendEmail(userEmail, subject, htmlContent);
  }

  static async send2FAEnabledNotification(userEmail, userName, maskedPhone) {
    const subject = '2FA Enabled - ImmoLink';
    const htmlContent = `
      <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
          <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
            <h1 style="color: #2c5aa0;">Two-Factor Authentication Enabled</h1>
            <p>Dear ${userName},</p>
            <p>Two-factor authentication has been successfully enabled for your ImmoLink account.</p>
            <p>Your registered phone number: ${maskedPhone}</p>
            <p>This adds an extra layer of security to your account. You'll now receive SMS codes when logging in.</p>
            <p>If you did not enable this feature, please contact our support team immediately.</p>
            <p>Best regards,<br>The ImmoLink Team</p>
          </div>
        </body>
      </html>
    `;
    return await this.sendEmail(userEmail, subject, htmlContent);
  }

  static async sendPaymentReminder(userEmail, userName, propertyAddress, amount, dueDate) {
    const subject = 'Payment Reminder - ImmoLink';
    const htmlContent = `
      <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
          <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
            <h1 style="color: #2c5aa0;">Payment Reminder</h1>
            <p>Dear ${userName},</p>
            <p>This is a friendly reminder about your upcoming payment:</p>
            <div style="background-color: #f8f9fa; padding: 15px; border-radius: 8px; margin: 20px 0;">
              <p><strong>Property:</strong> ${propertyAddress}</p>
              <p><strong>Amount Due:</strong> ${amount}</p>
              <p><strong>Due Date:</strong> ${dueDate}</p>
            </div>
            <p>Please ensure your payment is made by the due date to avoid any late fees.</p>
            <p>You can make payments through the ImmoLink app or contact your landlord for alternative payment methods.</p>
            <p>Best regards,<br>The ImmoLink Team</p>
          </div>
        </body>
      </html>
    `;
    return await this.sendEmail(userEmail, subject, htmlContent);
  }

  static async sendMaintenanceRequestUpdate(userEmail, userName, requestId, status, propertyAddress) {
    const subject = `Maintenance Request Update - ImmoLink`;
    const htmlContent = `
      <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
          <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
            <h1 style="color: #2c5aa0;">Maintenance Request Update</h1>
            <p>Dear ${userName},</p>
            <p>Your maintenance request has been updated:</p>
            <div style="background-color: #f8f9fa; padding: 15px; border-radius: 8px; margin: 20px 0;">
              <p><strong>Request ID:</strong> ${requestId}</p>
              <p><strong>Property:</strong> ${propertyAddress}</p>
              <p><strong>Status:</strong> ${status}</p>
            </div>
            <p>You can view the full details in the ImmoLink app.</p>
            <p>Best regards,<br>The ImmoLink Team</p>
          </div>
        </body>
      </html>
    `;
    return await this.sendEmail(userEmail, subject, htmlContent);
  }

  static async sendPasswordResetEmail(userEmail, resetToken) {
    console.log('🔐 Creating password reset email for:', userEmail);
    console.log('🔗 Reset token:', resetToken);
    
    // Use the dedicated ImmoLink reset password page
    const resetLink = `${process.env.APP_URL}/immolink-reset-password?token=${resetToken}`;
    console.log('🔗 Final reset link:', resetLink);
    
    const subject = 'Password Reset - ImmoLink';
    const htmlContent = `
      <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
          <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="text-align: center; margin-bottom: 30px;">
              <h1 style="color: #2c5aa0; margin: 0;">ImmoLink</h1>
              <p style="color: #666; margin: 5px 0;">Property Management Made Simple</p>
            </div>
            
            <h2 style="color: #2c5aa0;">Password Reset Request</h2>
            <p>You have requested a password reset for your ImmoLink account.</p>
            <p>Click the button below to create a new password:</p>
            
            <div style="text-align: center; margin: 30px 0;">
              <a href="${resetLink}" style="background-color: #2c5aa0; color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; display: inline-block; font-weight: bold; font-size: 16px;">Reset My Password</a>
            </div>
            
            <div style="background-color: #f8f9fa; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #2c5aa0;">
              <p style="margin: 0;"><strong>Security Information:</strong></p>
              <ul style="margin: 10px 0; padding-left: 20px;">
                <li>This link will expire in 1 hour for security reasons</li>
                <li>The link can only be used once</li>
                <li>If you didn't request this reset, please ignore this email</li>
              </ul>
            </div>
            
            <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
            <p style="word-break: break-all; background-color: #f8f9fa; padding: 10px; border-radius: 5px; font-family: monospace; font-size: 12px;">${resetLink}</p>
            
            <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
            
            <p style="color: #666; font-size: 14px;">
              If you have any questions or need assistance, please contact our support team.<br>
              <strong>The ImmoLink Team</strong>
            </p>
          </div>
        </body>
      </html>
    `;
    
    console.log('📧 Generated email HTML content for ImmoLink reset');
    return await this.sendEmail(userEmail, subject, htmlContent);
  }
}

// Send welcome email
router.post('/send-welcome', async (req, res) => {
  try {
    const { userEmail, userName } = req.body;

    if (!userEmail || !userName) {
      return res.status(400).json({
        error: 'User email and name are required'
      });
    }

    const result = await EmailService.sendWelcomeEmail(userEmail, userName);

    res.json({
      success: true,
      message: 'Welcome email sent successfully',
      messageId: result.messageId
    });

  } catch (error) {
    console.error('Error sending welcome email:', error);
    res.status(500).json({
      error: 'Failed to send welcome email',
      details: error.message
    });
  }
});

// Send password change notification
router.post('/send-password-change', async (req, res) => {
  try {
    const { userEmail, userName } = req.body;

    if (!userEmail || !userName) {
      return res.status(400).json({
        error: 'User email and name are required'
      });
    }

    const result = await EmailService.sendPasswordChangeNotification(userEmail, userName);

    res.json({
      success: true,
      message: 'Password change notification sent successfully',
      messageId: result.messageId
    });

  } catch (error) {
    console.error('Error sending password change notification:', error);
    res.status(500).json({
      error: 'Failed to send password change notification',
      details: error.message
    });
  }
});

// Send 2FA enabled notification
router.post('/send-2fa-enabled', async (req, res) => {
  try {
    const { userEmail, userName, maskedPhone } = req.body;

    if (!userEmail || !userName || !maskedPhone) {
      return res.status(400).json({
        error: 'User email, name, and masked phone are required'
      });
    }

    const result = await EmailService.send2FAEnabledNotification(userEmail, userName, maskedPhone);

    res.json({
      success: true,
      message: '2FA enabled notification sent successfully',
      messageId: result.messageId
    });

  } catch (error) {
    console.error('Error sending 2FA enabled notification:', error);
    res.status(500).json({
      error: 'Failed to send 2FA enabled notification',
      details: error.message
    });
  }
});

// Send payment reminder
router.post('/send-payment-reminder', async (req, res) => {
  try {
    const { userEmail, userName, propertyAddress, amount, dueDate } = req.body;

    if (!userEmail || !userName || !propertyAddress || !amount || !dueDate) {
      return res.status(400).json({
        error: 'All fields are required: userEmail, userName, propertyAddress, amount, dueDate'
      });
    }

    const result = await EmailService.sendPaymentReminder(userEmail, userName, propertyAddress, amount, dueDate);

    res.json({
      success: true,
      message: 'Payment reminder sent successfully',
      messageId: result.messageId
    });

  } catch (error) {
    console.error('Error sending payment reminder:', error);
    res.status(500).json({
      error: 'Failed to send payment reminder',
      details: error.message
    });
  }
});

// Send maintenance request update
router.post('/send-maintenance-update', async (req, res) => {
  try {
    const { userEmail, userName, requestId, status, propertyAddress } = req.body;

    if (!userEmail || !userName || !requestId || !status || !propertyAddress) {
      return res.status(400).json({
        error: 'All fields are required: userEmail, userName, requestId, status, propertyAddress'
      });
    }

    const result = await EmailService.sendMaintenanceRequestUpdate(userEmail, userName, requestId, status, propertyAddress);

    res.json({
      success: true,
      message: 'Maintenance update notification sent successfully',
      messageId: result.messageId
    });

  } catch (error) {
    console.error('Error sending maintenance update notification:', error);
    res.status(500).json({
      error: 'Failed to send maintenance update notification',
      details: error.message
    });
  }
});

// Bulk send payment reminders
router.post('/send-bulk-payment-reminders', async (req, res) => {
  try {
    const { reminders } = req.body; // Array of reminder objects

    if (!reminders || !Array.isArray(reminders)) {
      return res.status(400).json({
        error: 'Reminders array is required'
      });
    }

    const results = [];
    
    for (const reminder of reminders) {
      try {
        const result = await EmailService.sendPaymentReminder(
          reminder.userEmail,
          reminder.userName,
          reminder.propertyAddress,
          reminder.amount,
          reminder.dueDate
        );
        results.push({ success: true, email: reminder.userEmail, messageId: result.messageId });
      } catch (error) {
        results.push({ success: false, email: reminder.userEmail, error: error.message });
      }
    }

    const successCount = results.filter(r => r.success).length;

    res.json({
      success: true,
      message: `Sent ${successCount} of ${reminders.length} payment reminders`,
      results: results
    });

  } catch (error) {
    console.error('Error sending bulk payment reminders:', error);
    res.status(500).json({
      error: 'Failed to send bulk payment reminders',
      details: error.message
    });
  }
});

// Send registration confirmation email
router.post('/send-registration-confirmation', async (req, res) => {
  try {
    const { userEmail, userName } = req.body;

    if (!userEmail || !userName) {
      return res.status(400).json({
        error: 'User email and name are required'
      });
    }

    const result = await EmailService.sendRegistrationConfirmation(userEmail, userName);

    res.json({
      success: true,
      message: 'Registration confirmation email sent successfully',
      messageId: result.messageId
    });

  } catch (error) {
    console.error('Error sending registration confirmation email:', error);
    res.status(500).json({
      error: 'Failed to send registration confirmation email',
      details: error.message
    });
  }
});

// Send password reset email
router.post('/send-password-reset', async (req, res) => {
  console.log('🔐 Password reset email endpoint called');
  console.log('📨 Request body:', JSON.stringify(req.body, null, 2));
  console.log('📨 Request headers:', JSON.stringify(req.headers, null, 2));
  
  try {
    const { userEmail, resetToken, resetLink } = req.body;

    console.log('📧 Extracted userEmail:', userEmail);
    console.log('🔗 Extracted resetToken:', resetToken);
    console.log('🔗 Extracted resetLink (legacy):', resetLink);

    // Support both new token format and legacy link format for backward compatibility
    const tokenToUse = resetToken || (resetLink ? resetLink.split('token=')[1] : null);

    if (!userEmail || !tokenToUse) {
      console.error('❌ Missing required fields');
      console.error('❌ userEmail present:', !!userEmail);
      console.error('❌ resetToken present:', !!resetToken);
      console.error('❌ resetLink present:', !!resetLink);
      console.error('❌ tokenToUse derived:', tokenToUse);
      
      return res.status(400).json({
        error: 'User email and reset token are required',
        received: {
          userEmail: !!userEmail,
          resetToken: !!resetToken,
          resetLink: !!resetLink,
          tokenToUse: !!tokenToUse,
          actualBody: req.body
        }
      });
    }

    console.log('✅ All required fields present, sending password reset email...');
    const result = await EmailService.sendPasswordResetEmail(userEmail, tokenToUse);
    console.log('✅ Password reset email sent successfully:', result.messageId);

    res.json({
      success: true,
      message: 'Password reset email sent successfully',
      messageId: result.messageId
    });

  } catch (error) {
    console.error('❌ Error sending password reset email:', error.message);
    console.error('❌ Full error:', error);
    res.status(500).json({
      error: 'Failed to send password reset email',
      details: error.message,
      stack: error.stack
    });
  }
});

module.exports = router;