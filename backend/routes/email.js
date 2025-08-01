const express = require('express');
const router = express.Router();

// Mock Email service - in production, integrate with services like SendGrid, AWS SES, Nodemailer, etc.
class EmailService {
  static async sendEmail(to, subject, htmlContent, textContent = null) {
    // Mock implementation - replace with actual email service
    console.log(`
=== EMAIL SENT ===
To: ${to}
Subject: ${subject}
Content: ${textContent || htmlContent}
==================
    `);
    return { success: true, messageId: `email_${Date.now()}` };
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

module.exports = router;