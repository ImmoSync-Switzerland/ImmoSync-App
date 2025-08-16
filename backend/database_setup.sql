-- ImmoLink Complete Database Setup
-- This script creates all necessary tables for the ImmoLink application
-- It includes checks for existing databases and tables

-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS immolink_db 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE immolink_db;

-- Enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- =============================================
-- 1. USERS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS users (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    role ENUM('landlord', 'tenant', 'admin') NOT NULL,
    profile_image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    email_verified BOOLEAN DEFAULT FALSE,
    email_verification_token VARCHAR(255),
    password_reset_token VARCHAR(255),
    password_reset_expires DATETIME,
    password_changed_at DATETIME,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(255),
    two_factor_backup_codes JSON,
    last_login DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_created_at (created_at)
);

-- =============================================
-- 2. ADDRESSES TABLE (for normalized address storage)
-- =============================================
CREATE TABLE IF NOT EXISTS addresses (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    street VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) DEFAULT 'Switzerland',
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_city (city),
    INDEX idx_postal_code (postal_code),
    INDEX idx_coordinates (latitude, longitude)
);

-- =============================================
-- 3. PROPERTIES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS properties (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    landlord_id CHAR(36) NOT NULL,
    address_id CHAR(36) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    property_type ENUM('apartment', 'house', 'studio', 'commercial', 'other') NOT NULL,
    bedrooms INT DEFAULT 0,
    bathrooms INT DEFAULT 0,
    size_sqm DECIMAL(8,2),
    rent_amount DECIMAL(10,2) NOT NULL,
    deposit_amount DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'CHF',
    status ENUM('available', 'rented', 'maintenance', 'unavailable') DEFAULT 'available',
    availability_date DATE,
    lease_start_date DATE,
    lease_end_date DATE,
    utilities_included BOOLEAN DEFAULT FALSE,
    pets_allowed BOOLEAN DEFAULT FALSE,
    smoking_allowed BOOLEAN DEFAULT FALSE,
    furnished BOOLEAN DEFAULT FALSE,
    parking_available BOOLEAN DEFAULT FALSE,
    balcony BOOLEAN DEFAULT FALSE,
    garden BOOLEAN DEFAULT FALSE,
    elevator BOOLEAN DEFAULT FALSE,
    outstanding_payments DECIMAL(10,2) DEFAULT 0.00,
    image_urls JSON,
    amenities JSON,
    house_rules TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (landlord_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (address_id) REFERENCES addresses(id) ON DELETE RESTRICT,
    INDEX idx_landlord (landlord_id),
    INDEX idx_status (status),
    INDEX idx_rent_amount (rent_amount),
    INDEX idx_property_type (property_type),
    INDEX idx_availability_date (availability_date)
);

-- =============================================
-- 4. PROPERTY_TENANTS TABLE (Many-to-Many relationship)
-- =============================================
CREATE TABLE IF NOT EXISTS property_tenants (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    property_id CHAR(36) NOT NULL,
    tenant_id CHAR(36) NOT NULL,
    lease_start_date DATE NOT NULL,
    lease_end_date DATE,
    rent_amount DECIMAL(10,2) NOT NULL,
    deposit_paid DECIMAL(10,2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    move_in_date DATE,
    move_out_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE,
    FOREIGN KEY (tenant_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_active_tenant_property (property_id, tenant_id, is_active),
    INDEX idx_property_tenant (property_id, tenant_id),
    INDEX idx_lease_dates (lease_start_date, lease_end_date)
);

-- =============================================
-- 5. PAYMENTS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS payments (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    property_id CHAR(36) NOT NULL,
    tenant_id CHAR(36) NOT NULL,
    landlord_id CHAR(36) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'CHF',
    type ENUM('rent', 'deposit', 'utilities', 'late_fee', 'maintenance', 'other') NOT NULL,
    payment_method ENUM('stripe', 'bank_transfer', 'cash', 'check', 'pending') DEFAULT 'pending',
    status ENUM('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded') DEFAULT 'pending',
    due_date DATE,
    payment_date DATETIME,
    completed_at DATETIME,
    cancelled_at DATETIME,
    notes TEXT,
    is_recurring BOOLEAN DEFAULT FALSE,
    recurring_interval ENUM('weekly', 'monthly', 'quarterly', 'yearly'),
    parent_payment_id CHAR(36), -- For recurring payments
    
    -- Stripe integration fields
    stripe_payment_intent_id VARCHAR(255),
    stripe_customer_id VARCHAR(255),
    stripe_metadata JSON,
    
    -- Bank transfer fields
    bank_transfer_reference VARCHAR(255),
    bank_account_info JSON,
    bank_verification_status ENUM('pending', 'verified', 'rejected') DEFAULT 'pending',
    bank_verification_date DATETIME,
    
    -- Receipt and documentation
    receipt_url TEXT,
    receipt_number VARCHAR(100),
    
    failure_reason TEXT,
    cancellation_reason TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE,
    FOREIGN KEY (tenant_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (landlord_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_payment_id) REFERENCES payments(id) ON DELETE SET NULL,
    
    INDEX idx_property_payments (property_id),
    INDEX idx_tenant_payments (tenant_id),
    INDEX idx_landlord_payments (landlord_id),
    INDEX idx_payment_status (status),
    INDEX idx_payment_date (payment_date),
    INDEX idx_due_date (due_date),
    INDEX idx_stripe_intent (stripe_payment_intent_id),
    INDEX idx_recurring (is_recurring, recurring_interval)
);

-- =============================================
-- 6. MAINTENANCE_REQUESTS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS maintenance_requests (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    property_id CHAR(36) NOT NULL,
    tenant_id CHAR(36),
    landlord_id CHAR(36) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category ENUM('plumbing', 'electrical', 'heating', 'appliances', 'structural', 'pest_control', 'cleaning', 'other') NOT NULL,
    priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
    status ENUM('open', 'in_progress', 'waiting_parts', 'completed', 'cancelled') DEFAULT 'open',
    urgency_level INT DEFAULT 3, -- 1-5 scale
    estimated_cost DECIMAL(10,2),
    actual_cost DECIMAL(10,2),
    scheduled_date DATETIME,
    completion_date DATETIME,
    contractor_id CHAR(36),
    contractor_name VARCHAR(255),
    contractor_contact VARCHAR(255),
    images JSON, -- Array of image URLs
    documents JSON, -- Array of document URLs
    notes TEXT,
    tenant_access_instructions TEXT,
    landlord_notes TEXT,
    resolution_notes TEXT,
    satisfaction_rating INT, -- 1-5 rating from tenant
    satisfaction_feedback TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE,
    FOREIGN KEY (tenant_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (landlord_id) REFERENCES users(id) ON DELETE CASCADE,
    
    INDEX idx_property_maintenance (property_id),
    INDEX idx_tenant_maintenance (tenant_id),
    INDEX idx_landlord_maintenance (landlord_id),
    INDEX idx_status (status),
    INDEX idx_priority (priority),
    INDEX idx_category (category),
    INDEX idx_scheduled_date (scheduled_date),
    INDEX idx_created_at (created_at)
);

-- =============================================
-- 7. CONVERSATIONS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS conversations (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    participants JSON NOT NULL, -- Array of user IDs
    last_message TEXT,
    last_message_sender_id CHAR(36),
    last_message_time DATETIME,
    is_active BOOLEAN DEFAULT TRUE,
    conversation_type ENUM('direct', 'group', 'support') DEFAULT 'direct',
    title VARCHAR(255), -- For group conversations
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (last_message_sender_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_last_message_time (last_message_time),
    INDEX idx_participants (participants(255)), -- MySQL JSON index
    INDEX idx_active (is_active)
);

-- =============================================
-- 8. MESSAGES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS messages (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    conversation_id CHAR(36) NOT NULL,
    sender_id CHAR(36) NOT NULL,
    receiver_id CHAR(36),
    content TEXT NOT NULL,
    message_type ENUM('text', 'image', 'document', 'system') DEFAULT 'text',
    file_url TEXT,
    file_name VARCHAR(255),
    file_size BIGINT,
    file_type VARCHAR(100),
    is_read BOOLEAN DEFAULT FALSE,
    read_at DATETIME,
    is_edited BOOLEAN DEFAULT FALSE,
    edited_at DATETIME,
    reply_to_message_id CHAR(36),
    metadata JSON,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (reply_to_message_id) REFERENCES messages(id) ON DELETE SET NULL,
    
    INDEX idx_conversation_messages (conversation_id, timestamp),
    INDEX idx_sender_messages (sender_id),
    INDEX idx_receiver_messages (receiver_id),
    INDEX idx_read_status (is_read),
    INDEX idx_message_type (message_type)
);

-- =============================================
-- 9. INVITATIONS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS invitations (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    sender_id CHAR(36) NOT NULL,
    receiver_id CHAR(36),
    receiver_email VARCHAR(255) NOT NULL,
    property_id CHAR(36),
    invitation_type ENUM('tenant_invitation', 'landlord_connection', 'property_viewing') NOT NULL,
    status ENUM('pending', 'accepted', 'declined', 'expired') DEFAULT 'pending',
    message TEXT,
    invitation_token VARCHAR(255) UNIQUE,
    expires_at DATETIME NOT NULL,
    accepted_at DATETIME,
    declined_at DATETIME,
    lease_terms JSON, -- For tenant invitations
    viewing_slots JSON, -- For property viewing invitations
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE,
    
    INDEX idx_sender_invitations (sender_id),
    INDEX idx_receiver_invitations (receiver_id),
    INDEX idx_receiver_email (receiver_email),
    INDEX idx_property_invitations (property_id),
    INDEX idx_status (status),
    INDEX idx_invitation_token (invitation_token),
    INDEX idx_expires_at (expires_at)
);

-- =============================================
-- 10. ACTIVITIES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS activities (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id CHAR(36) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    type ENUM('payment', 'maintenance', 'message', 'property', 'tenant', 'login', 'system', 'invitation') NOT NULL,
    related_id CHAR(36), -- Generic reference to related entity
    related_property_id CHAR(36),
    metadata JSON,
    is_read BOOLEAN DEFAULT FALSE,
    read_at DATETIME,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (related_property_id) REFERENCES properties(id) ON DELETE SET NULL,
    
    INDEX idx_user_activities (user_id, timestamp DESC),
    INDEX idx_activity_type (type),
    INDEX idx_read_status (is_read),
    INDEX idx_related_property (related_property_id),
    INDEX idx_timestamp (timestamp)
);

-- =============================================
-- 11. SERVICES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS services (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    landlord_id CHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category ENUM('maintenance', 'cleaning', 'security', 'utilities', 'internet', 'other') NOT NULL,
    provider_name VARCHAR(255),
    provider_contact VARCHAR(255),
    provider_email VARCHAR(255),
    cost DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'CHF',
    billing_frequency ENUM('one_time', 'monthly', 'quarterly', 'yearly') DEFAULT 'one_time',
    is_active BOOLEAN DEFAULT TRUE,
    contract_start_date DATE,
    contract_end_date DATE,
    auto_renewal BOOLEAN DEFAULT FALSE,
    notes TEXT,
    documents JSON, -- Array of document URLs
    service_areas JSON, -- Array of property IDs or areas covered
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (landlord_id) REFERENCES users(id) ON DELETE CASCADE,
    
    INDEX idx_landlord_services (landlord_id),
    INDEX idx_category (category),
    INDEX idx_active (is_active),
    INDEX idx_provider (provider_name),
    INDEX idx_contract_dates (contract_start_date, contract_end_date)
);

-- =============================================
-- 12. TICKETS/SUPPORT TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS tickets (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id CHAR(36) NOT NULL,
    property_id CHAR(36),
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category ENUM('technical_support', 'billing', 'maintenance', 'general_inquiry', 'complaint', 'feature_request') NOT NULL,
    priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
    status ENUM('open', 'in_progress', 'waiting_response', 'resolved', 'closed') DEFAULT 'open',
    assigned_to CHAR(36), -- Admin/support user ID
    resolution TEXT,
    resolved_at DATETIME,
    closed_at DATETIME,
    satisfaction_rating INT, -- 1-5 rating
    satisfaction_feedback TEXT,
    attachments JSON, -- Array of file URLs
    internal_notes TEXT, -- For admin use
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_user_tickets (user_id),
    INDEX idx_property_tickets (property_id),
    INDEX idx_assigned_tickets (assigned_to),
    INDEX idx_status (status),
    INDEX idx_priority (priority),
    INDEX idx_category (category),
    INDEX idx_created_at (created_at)
);

-- =============================================
-- 13. NOTIFICATIONS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS notifications (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id CHAR(36) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('info', 'warning', 'success', 'error', 'payment', 'maintenance', 'message', 'system') NOT NULL,
    related_id CHAR(36), -- Reference to related entity
    related_type VARCHAR(100), -- Type of related entity (payment, maintenance, etc.)
    is_read BOOLEAN DEFAULT FALSE,
    read_at DATETIME,
    action_url TEXT, -- URL to navigate when notification is clicked
    action_label VARCHAR(100), -- Label for action button
    push_notification_sent BOOLEAN DEFAULT FALSE,
    email_notification_sent BOOLEAN DEFAULT FALSE,
    sms_notification_sent BOOLEAN DEFAULT FALSE,
    expires_at DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    
    INDEX idx_user_notifications (user_id, created_at DESC),
    INDEX idx_read_status (is_read),
    INDEX idx_notification_type (type),
    INDEX idx_expires_at (expires_at)
);

-- =============================================
-- 14. FILES/UPLOADS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS file_uploads (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id CHAR(36) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    stored_filename VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_type ENUM('image', 'document', 'video', 'audio', 'other') NOT NULL,
    related_type VARCHAR(100), -- property, maintenance, message, etc.
    related_id CHAR(36), -- ID of related entity
    is_public BOOLEAN DEFAULT FALSE,
    checksum VARCHAR(255), -- For file integrity
    upload_status ENUM('uploading', 'completed', 'failed', 'deleted') DEFAULT 'completed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    
    INDEX idx_user_files (user_id),
    INDEX idx_related_entity (related_type, related_id),
    INDEX idx_file_type (file_type),
    INDEX idx_upload_status (upload_status),
    INDEX idx_created_at (created_at)
);

-- =============================================
-- 15. USER_PREFERENCES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS user_preferences (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id CHAR(36) NOT NULL UNIQUE,
    language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(100) DEFAULT 'Europe/Zurich',
    currency VARCHAR(3) DEFAULT 'CHF',
    date_format VARCHAR(20) DEFAULT 'DD/MM/YYYY',
    time_format VARCHAR(10) DEFAULT '24h',
    
    -- Notification preferences
    email_notifications BOOLEAN DEFAULT TRUE,
    sms_notifications BOOLEAN DEFAULT FALSE,
    push_notifications BOOLEAN DEFAULT TRUE,
    marketing_emails BOOLEAN DEFAULT FALSE,
    
    -- Specific notification types
    payment_reminders BOOLEAN DEFAULT TRUE,
    maintenance_updates BOOLEAN DEFAULT TRUE,
    message_notifications BOOLEAN DEFAULT TRUE,
    rental_updates BOOLEAN DEFAULT TRUE,
    
    theme VARCHAR(20) DEFAULT 'light',
    auto_logout_minutes INT DEFAULT 60,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- =============================================
-- 16. AUDIT_LOG TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS audit_log (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id CHAR(36),
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    record_id CHAR(36),
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_user_audit (user_id),
    INDEX idx_action (action),
    INDEX idx_table_record (table_name, record_id),
    INDEX idx_timestamp (timestamp)
);

-- =============================================
-- CREATE VIEWS FOR COMMON QUERIES
-- =============================================

-- View for active property listings with full address
CREATE OR REPLACE VIEW property_listings AS
SELECT 
    p.id,
    p.title,
    p.description,
    p.property_type,
    p.bedrooms,
    p.bathrooms,
    p.size_sqm,
    p.rent_amount,
    p.currency,
    p.status,
    p.utilities_included,
    p.pets_allowed,
    p.furnished,
    CONCAT(a.street, ', ', a.city, ', ', a.postal_code) as full_address,
    a.city,
    a.postal_code,
    a.latitude,
    a.longitude,
    u.full_name as landlord_name,
    u.email as landlord_email,
    u.phone as landlord_phone,
    p.created_at,
    p.updated_at
FROM properties p
JOIN addresses a ON p.address_id = a.id
JOIN users u ON p.landlord_id = u.id
WHERE p.status = 'available' AND u.is_active = TRUE;

-- View for payment summaries by property
CREATE OR REPLACE VIEW payment_summaries AS
SELECT 
    p.id as property_id,
    p.title as property_title,
    CONCAT(a.street, ', ', a.city) as property_address,
    COUNT(pay.id) as total_payments,
    SUM(CASE WHEN pay.status = 'completed' THEN pay.amount ELSE 0 END) as total_paid,
    SUM(CASE WHEN pay.status = 'pending' THEN pay.amount ELSE 0 END) as total_pending,
    SUM(CASE WHEN pay.status = 'failed' THEN pay.amount ELSE 0 END) as total_failed,
    MAX(pay.payment_date) as last_payment_date
FROM properties p
LEFT JOIN addresses a ON p.address_id = a.id
LEFT JOIN payments pay ON p.id = pay.property_id
GROUP BY p.id, p.title, property_address;

-- =============================================
-- INSERT DEFAULT DATA
-- =============================================

-- Insert default admin user (password should be changed immediately)
INSERT IGNORE INTO users (id, email, password, full_name, role, is_active, email_verified) 
VALUES (
    UUID(),
    'admin@immolink.com',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- password: 'password'
    'System Administrator',
    'admin',
    TRUE,
    TRUE
);

-- Insert sample addresses for testing
INSERT IGNORE INTO addresses (id, street, city, postal_code, country, latitude, longitude) VALUES
(UUID(), 'Bahnhofstrasse 1', 'Zurich', '8001', 'Switzerland', 47.3769, 8.5417),
(UUID(), 'Rue du Rhône 10', 'Geneva', '1204', 'Switzerland', 46.2044, 6.1432),
(UUID(), 'Freie Strasse 25', 'Basel', '4001', 'Switzerland', 47.5596, 7.5886);

-- =============================================
-- CREATE STORED PROCEDURES
-- =============================================

DELIMITER //

-- Procedure to create a complete tenant invitation
CREATE PROCEDURE IF NOT EXISTS CreateTenantInvitation(
    IN p_sender_id CHAR(36),
    IN p_receiver_email VARCHAR(255),
    IN p_property_id CHAR(36),
    IN p_message TEXT,
    IN p_lease_start DATE,
    IN p_lease_end DATE,
    IN p_rent_amount DECIMAL(10,2)
)
BEGIN
    DECLARE invitation_id CHAR(36);
    DECLARE token VARCHAR(255);
    
    SET invitation_id = UUID();
    SET token = SHA2(CONCAT(invitation_id, NOW(), RAND()), 256);
    
    INSERT INTO invitations (
        id, sender_id, receiver_email, property_id, 
        invitation_type, message, invitation_token, 
        expires_at, lease_terms
    ) VALUES (
        invitation_id, p_sender_id, p_receiver_email, p_property_id,
        'tenant_invitation', p_message, token,
        DATE_ADD(NOW(), INTERVAL 7 DAY),
        JSON_OBJECT(
            'lease_start', p_lease_start,
            'lease_end', p_lease_end,
            'rent_amount', p_rent_amount
        )
    );
    
    SELECT invitation_id as id, token as invitation_token;
END //

-- Procedure to process recurring payments
CREATE PROCEDURE IF NOT EXISTS ProcessRecurringPayments()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE payment_id CHAR(36);
    DECLARE property_id CHAR(36);
    DECLARE tenant_id CHAR(36);
    DECLARE landlord_id CHAR(36);
    DECLARE amount DECIMAL(10,2);
    DECLARE payment_type VARCHAR(50);
    DECLARE recurring_interval VARCHAR(20);
    
    DECLARE payment_cursor CURSOR FOR
        SELECT id, property_id, tenant_id, landlord_id, amount, type, recurring_interval
        FROM payments 
        WHERE is_recurring = TRUE 
        AND status = 'completed'
        AND (
            (recurring_interval = 'monthly' AND DATE_ADD(completed_at, INTERVAL 1 MONTH) <= NOW()) OR
            (recurring_interval = 'quarterly' AND DATE_ADD(completed_at, INTERVAL 3 MONTH) <= NOW()) OR
            (recurring_interval = 'yearly' AND DATE_ADD(completed_at, INTERVAL 1 YEAR) <= NOW())
        );
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN payment_cursor;
    
    payment_loop: LOOP
        FETCH payment_cursor INTO payment_id, property_id, tenant_id, landlord_id, amount, payment_type, recurring_interval;
        
        IF done THEN
            LEAVE payment_loop;
        END IF;
        
        -- Create new recurring payment
        INSERT INTO payments (
            id, property_id, tenant_id, landlord_id, amount, type,
            payment_method, status, due_date, is_recurring, recurring_interval,
            parent_payment_id, created_at
        ) VALUES (
            UUID(), property_id, tenant_id, landlord_id, amount, payment_type,
            'pending', 'pending', 
            CASE 
                WHEN recurring_interval = 'monthly' THEN DATE_ADD(CURDATE(), INTERVAL 1 MONTH)
                WHEN recurring_interval = 'quarterly' THEN DATE_ADD(CURDATE(), INTERVAL 3 MONTH)
                WHEN recurring_interval = 'yearly' THEN DATE_ADD(CURDATE(), INTERVAL 1 YEAR)
            END,
            TRUE, recurring_interval, payment_id, NOW()
        );
        
    END LOOP;
    
    CLOSE payment_cursor;
END //

DELIMITER ;

-- =============================================
-- CREATE TRIGGERS
-- =============================================

DELIMITER //

-- Trigger to update property outstanding payments
CREATE TRIGGER IF NOT EXISTS update_property_outstanding_payments
AFTER UPDATE ON payments
FOR EACH ROW
BEGIN
    IF NEW.status != OLD.status THEN
        UPDATE properties 
        SET outstanding_payments = (
            SELECT COALESCE(SUM(amount), 0) 
            FROM payments 
            WHERE property_id = NEW.property_id 
            AND status IN ('pending', 'overdue')
        )
        WHERE id = NEW.property_id;
    END IF;
END //

-- Trigger to create activity when payment status changes
CREATE TRIGGER IF NOT EXISTS payment_activity_trigger
AFTER UPDATE ON payments
FOR EACH ROW
BEGIN
    IF NEW.status != OLD.status THEN
        INSERT INTO activities (
            id, user_id, title, description, type, related_id, 
            related_property_id, timestamp
        ) VALUES (
            UUID(), NEW.tenant_id,
            CONCAT('Payment ', NEW.status),
            CONCAT('Payment of ', NEW.amount, ' ', NEW.currency, ' for ', NEW.type, ' is now ', NEW.status),
            'payment', NEW.id, NEW.property_id, NOW()
        );
        
        -- Also create activity for landlord
        INSERT INTO activities (
            id, user_id, title, description, type, related_id,
            related_property_id, timestamp
        ) VALUES (
            UUID(), NEW.landlord_id,
            CONCAT('Payment ', NEW.status),
            CONCAT('Payment of ', NEW.amount, ' ', NEW.currency, ' from tenant is now ', NEW.status),
            'payment', NEW.id, NEW.property_id, NOW()
        );
    END IF;
END //

-- Trigger to create activity when maintenance request is created/updated
CREATE TRIGGER IF NOT EXISTS maintenance_activity_trigger
AFTER UPDATE ON maintenance_requests
FOR EACH ROW
BEGIN
    IF NEW.status != OLD.status THEN
        INSERT INTO activities (
            id, user_id, title, description, type, related_id,
            related_property_id, timestamp
        ) VALUES (
            UUID(), NEW.tenant_id,
            CONCAT('Maintenance request ', NEW.status),
            CONCAT('Your maintenance request "', NEW.title, '" is now ', NEW.status),
            'maintenance', NEW.id, NEW.property_id, NOW()
        );
        
        -- Also for landlord
        INSERT INTO activities (
            id, user_id, title, description, type, related_id,
            related_property_id, timestamp
        ) VALUES (
            UUID(), NEW.landlord_id,
            CONCAT('Maintenance request ', NEW.status),
            CONCAT('Maintenance request "', NEW.title, '" is now ', NEW.status),
            'maintenance', NEW.id, NEW.property_id, NOW()
        );
    END IF;
END //

DELIMITER ;

-- =============================================
-- CREATE INDEXES FOR PERFORMANCE
-- =============================================

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_property_status_rent ON properties(status, rent_amount);
CREATE INDEX IF NOT EXISTS idx_payment_property_status ON payments(property_id, status, due_date);
CREATE INDEX IF NOT EXISTS idx_maintenance_property_status ON maintenance_requests(property_id, status, priority);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_time ON conversations(participants(100), last_message_time);
CREATE INDEX IF NOT EXISTS idx_message_conversation_time ON messages(conversation_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_activity_user_type_time ON activities(user_id, type, timestamp DESC);

-- Full-text search indexes
ALTER TABLE properties ADD FULLTEXT(title, description);
ALTER TABLE maintenance_requests ADD FULLTEXT(title, description);
ALTER TABLE messages ADD FULLTEXT(content);

-- =============================================
-- GRANT PERMISSIONS (adjust as needed)
-- =============================================

-- Create application user with limited permissions
CREATE USER IF NOT EXISTS 'immolink_app'@'localhost' IDENTIFIED BY 'secure_password_here';
GRANT SELECT, INSERT, UPDATE, DELETE ON immolink_db.* TO 'immolink_app'@'localhost';
GRANT EXECUTE ON immolink_db.* TO 'immolink_app'@'localhost';
FLUSH PRIVILEGES;

-- =============================================
-- COMPLETION MESSAGE
-- =============================================

SELECT 'ImmoLink database setup completed successfully!' as message,
       COUNT(*) as tables_created 
FROM information_schema.tables 
WHERE table_schema = 'immolink_db';

-- Show all created tables
SELECT table_name, table_rows, data_length, index_length 
FROM information_schema.tables 
WHERE table_schema = 'immolink_db' 
ORDER BY table_name;
