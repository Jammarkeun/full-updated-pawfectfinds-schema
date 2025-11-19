/* ===========================================================
   Pawfect Finds – Clean Database Schema
   =========================================================== */
DROP DATABASE IF EXISTS pawfect_findsdatabase;
CREATE DATABASE pawfect_findsdatabase CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pawfect_findsdatabase;

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

/* ------------------ PROCEDURES ------------------ */
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE GetCartTotal(IN p_user_id INT, OUT cart_total DECIMAL(10,2))
BEGIN
    SELECT COALESCE(SUM(p.price * c.quantity), 0)
    INTO cart_total
    FROM cart c
    JOIN products p ON c.product_id = p.id
    WHERE c.user_id = p_user_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE UpdateProductStock(IN p_product_id INT, IN quantity_sold INT)
BEGIN
    UPDATE products
    SET stock_quantity = stock_quantity - quantity_sold,
        status = CASE WHEN (stock_quantity - quantity_sold) <= 0 THEN 'out_of_stock' ELSE status END
    WHERE id = p_product_id;
END$$
DELIMITER ;

/* ------------------ TABLES ------------------ */
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    address TEXT NOT NULL,
    house_number VARCHAR(50),
    street VARCHAR(150),
    barangay VARCHAR(100),
    country VARCHAR(100) DEFAULT 'Philippines',
    city VARCHAR(100) DEFAULT 'Manila',
    province VARCHAR(100),
    postal_code VARCHAR(20),
    id_picture VARCHAR(255),
    profile_image VARCHAR(255),
    role ENUM('user','seller','admin','rider') DEFAULT 'user',
    status ENUM('active','inactive','banned') DEFAULT 'active',
    latitude DECIMAL(10,8) DEFAULT 14.5995,
    longitude DECIMAL(11,8) DEFAULT 120.9842,
    is_verified TINYINT(1) DEFAULT 0,
    verified_at TIMESTAMP NULL,
    verification_level ENUM('none','basic','premium','elite') DEFAULT 'none',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_role (role),
    INDEX idx_status (status),
    INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    image_url VARCHAR(255),
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_active (is_active),
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE seller_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    business_name VARCHAR(100) NOT NULL,
    business_description TEXT,
    business_address TEXT NOT NULL,
    business_phone VARCHAR(20) NOT NULL,
    tax_id VARCHAR(50),
    business_permit VARCHAR(255),
    status ENUM('pending','approved','rejected') DEFAULT 'pending',
    admin_notes TEXT,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_status (status),
    INDEX idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    seller_id INT NOT NULL,
    category_id INT NOT NULL,
    name VARCHAR(200) NOT NULL,
    slug VARCHAR(255),
    sku VARCHAR(50),
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    sale_price DECIMAL(10,2),
    sale_start_date DATETIME,
    sale_end_date DATETIME,
    stock_quantity INT DEFAULT 0,
    low_stock_threshold INT DEFAULT 10,
    is_low_stock TINYINT(1) GENERATED ALWAYS AS (stock_quantity <= low_stock_threshold) STORED,
    seller_latitude DECIMAL(10,8) DEFAULT 14.5995,
    seller_longitude DECIMAL(11,8) DEFAULT 120.9842,
    image_url VARCHAR(255),
    meta_title VARCHAR(200),
    meta_description TEXT,
    meta_keywords VARCHAR(255),
    weight DECIMAL(8,2),
    dimensions VARCHAR(50),
    brand VARCHAR(100),
    age_group ENUM('puppy','adult','senior','all_ages') DEFAULT 'all_ages',
    pet_type ENUM('dog','cat','fish','bird','other') NOT NULL DEFAULT 'dog',
    featured TINYINT(1) DEFAULT 0,
    cost_price DECIMAL(10,2),
    status ENUM('active','inactive','out_of_stock','draft') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (seller_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT,
    INDEX idx_seller (seller_id),
    INDEX idx_category (category_id),
    INDEX idx_status (status),
    INDEX idx_name (name),
    INDEX idx_price (price),
    INDEX idx_slug (slug),
    INDEX idx_sale_dates (sale_start_date, sale_end_date),
    INDEX idx_category_status (category_id, status),
    INDEX idx_seller_category (seller_id, category_id),
    INDEX idx_low_stock (is_low_stock),
    INDEX idx_products_price_range (price, status),
    FULLTEXT idx_search (name, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE cart (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_product (user_id, product_id),
    INDEX idx_user (user_id),
    INDEX idx_product (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    seller_id INT NOT NULL,
    rider_id INT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    shipping_fee DECIMAL(10,2) DEFAULT 0.00,
    shipping_provider VARCHAR(50) DEFAULT 'J&T Express',
    tracking_number VARCHAR(100),
    carrier VARCHAR(100) DEFAULT 'Standard Delivery',
    estimated_delivery_date DATE,
    shipping_address TEXT NOT NULL,
    shipping_city VARCHAR(100),
    shipping_province VARCHAR(100),
    shipping_postal_code VARCHAR(20),
    payment_method ENUM('cod','online') DEFAULT 'cod',
    payment_status ENUM('pending','paid','refunded') DEFAULT 'pending',
    status ENUM('pending','confirmed','preparing','shipped','assigned_to_rider','picked_up','on_the_way','delivered','cancelled') DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    delivered_at DATETIME NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (seller_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (rider_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user (user_id),
    INDEX idx_seller (seller_id),
    INDEX idx_rider (rider_id),
    INDEX idx_status (status),
    INDEX idx_payment (payment_status),
    INDEX idx_created (created_at),
    INDEX idx_tracking (tracking_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE deliveries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    rider_id INT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    picked_up_at TIMESTAMP NULL,
    on_the_way_at DATETIME NULL,
    delivered_at TIMESTAMP NULL,
    failed_at DATETIME NULL,
    delivery_notes TEXT,
    proof_photo_url VARCHAR(255),
    signature_url VARCHAR(255),
    recipient_name VARCHAR(150),
    cod_collected DECIMAL(10,2),
    delivered_lat DECIMAL(10,8),
    delivered_lng DECIMAL(11,8),
    pod_submitted_at DATETIME NULL,
    failure_reason TEXT,
    status ENUM('assigned','picked_up','on_the_way','delivered','failed') DEFAULT 'assigned',
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (rider_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_order_rider (order_id, rider_id),
    INDEX idx_rider (rider_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    price_at_time DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_order (order_id),
    INDEX idx_product (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_product_review (user_id, product_id),
    INDEX idx_product (product_id),
    INDEX idx_rating (rating)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE shipping_providers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    base_fee DECIMAL(10,2) NOT NULL DEFAULT 50.00,
    per_km_rate DECIMAL(10,2) NOT NULL DEFAULT 5.00,
    estimated_delivery_days INT DEFAULT 3,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ PRODUCT ENHANCEMENTS ------------------ */
CREATE TABLE product_variants (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    sku VARCHAR(100) UNIQUE,
    price DECIMAL(10,2) NOT NULL,
    sale_price DECIMAL(10,2),
    stock_quantity INT DEFAULT 0,
    image_url VARCHAR(255),
    attributes JSON,
    display_order INT DEFAULT 0,
    status ENUM('active','inactive') DEFAULT 'active',
    cost_price DECIMAL(10,2),
    low_stock_threshold INT DEFAULT 5,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    INDEX idx_product_id(product_id),
    INDEX idx_status(status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE product_bundles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    seller_id INT NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    bundle_price DECIMAL(10,2) NOT NULL,
    discount_percentage DECIMAL(5,2),
    image_url VARCHAR(255),
    status ENUM('active','inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (seller_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_seller_id(seller_id),
    INDEX idx_status(status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE bundle_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    bundle_id INT NOT NULL,
    product_id INT NOT NULL,
    variant_id INT NULL,
    quantity INT DEFAULT 1,
    display_order INT DEFAULT 0,
    FOREIGN KEY (bundle_id) REFERENCES product_bundles(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE SET NULL,
    INDEX idx_bundle_id(bundle_id),
    INDEX idx_product_id(product_id),
    INDEX idx_variant_id(variant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ CHAT / SUPPORT ------------------ */
CREATE TABLE chat_rooms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    subject VARCHAR(255) NOT NULL DEFAULT 'Support Request',
    status ENUM('active','closed','archived') DEFAULT 'active',
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_status(status),
    INDEX idx_updated_at(updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE chat_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    room_id INT NOT NULL,
    user_id INT NOT NULL,
    message TEXT NOT NULL,
    is_support TINYINT(1) DEFAULT 0,
    is_read TINYINT(1) DEFAULT 0,
    created_at DATETIME NOT NULL,
    FOREIGN KEY (room_id) REFERENCES chat_rooms(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_is_read(is_read),
    INDEX idx_created_at(created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ NOTIFICATIONS / LOGS ------------------ */
CREATE TABLE notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    type ENUM('order_status','seller_application','product_review','delivery_update','general') NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    is_read TINYINT(1) DEFAULT 0,
    related_id INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    role ENUM('admin','seller','user','rider') DEFAULT 'user',
    data JSON,
    FOREIGN KEY (user_id) REFERENCES users(id),
    INDEX idx_user_role (user_id, role, is_read, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE system_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(100) NOT NULL,
    details TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE system_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    setting_type VARCHAR(50) DEFAULT 'string',
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE website_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    description TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ CACHE & ANALYTICS ------------------ */
CREATE TABLE cache_entries (
    cache_key VARCHAR(255) PRIMARY KEY,
    cache_value LONGTEXT NOT NULL,
    expires_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_expires_at(expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE product_views (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    user_id INT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_product_id(product_id),
    INDEX idx_user_id(user_id),
    INDEX idx_viewed_at(viewed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sales_analytics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL,
    seller_id INT,
    total_orders INT DEFAULT 0,
    total_revenue DECIMAL(12,2) DEFAULT 0.00,
    total_items_sold INT DEFAULT 0,
    avg_order_value DECIMAL(10,2) DEFAULT 0.00,
    new_customers INT DEFAULT 0,
    returning_customers INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (seller_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_date_seller(date, seller_id),
    INDEX idx_date(date),
    INDEX idx_seller_id(seller_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ RETURNS & INVENTORY ------------------ */
CREATE TABLE inventory_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    transaction_type ENUM('purchase','sale','return','adjustment','restock') NOT NULL,
    quantity INT NOT NULL,
    previous_stock INT NOT NULL,
    new_stock INT NOT NULL,
    reference_type ENUM('order','return_request','manual') NOT NULL,
    reference_id INT,
    notes TEXT,
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_product_id(product_id),
    INDEX idx_transaction_type(transaction_type),
    INDEX idx_created_at(created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE return_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    order_item_id INT NOT NULL,
    user_id INT NOT NULL,
    reason ENUM('defective','wrong_item','not_as_described','changed_mind','other') NOT NULL,
    description TEXT,
    images TEXT,
    status ENUM('pending','processing','approved','rejected','cancelled') DEFAULT 'pending',
    admin_notes TEXT,
    refund_amount DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (order_item_id) REFERENCES order_items(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_order_id(order_id),
    INDEX idx_order_item(order_item_id),
    INDEX idx_user_id(user_id),
    INDEX idx_status(status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE low_stock_alerts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    seller_id INT NOT NULL,
    threshold_quantity INT DEFAULT 10,
    current_stock INT NOT NULL,
    alert_sent TINYINT(1) DEFAULT 0,
    alert_sent_at TIMESTAMP NULL,
    acknowledged TINYINT(1) DEFAULT 0,
    acknowledged_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (seller_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_product_id(product_id),
    INDEX idx_seller_id(seller_id),
    INDEX idx_alert_sent(alert_sent)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ ORDER TRACKING ------------------ */
CREATE TABLE order_tracking (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    status VARCHAR(50) NOT NULL,
    location VARCHAR(255),
    tracking_number VARCHAR(100),
    carrier VARCHAR(100),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    INDEX idx_order_id(order_id),
    INDEX idx_tracking_number(tracking_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ NOTIFICATION SUPPORT TABLES ------------------ */
CREATE TABLE wishlist (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    notes TEXT,
    priority ENUM('low','medium','high') DEFAULT 'medium',
    notified_when_available TINYINT(1) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_product_wish (user_id, product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ RIDER EARNINGS/PERFORMANCE ------------------ */
CREATE TABLE rider_earnings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    rider_id INT NOT NULL,
    order_id INT NOT NULL,
    base_fee DECIMAL(8,2) NOT NULL,
    distance_fee DECIMAL(8,2) DEFAULT 0,
    tip_amount DECIMAL(8,2) DEFAULT 0,
    total_earning DECIMAL(8,2) NOT NULL,
    status ENUM('pending','paid') DEFAULT 'pending',
    paid_at DATETIME NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (rider_id) REFERENCES users(id),
    FOREIGN KEY (order_id) REFERENCES orders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE rider_performance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    rider_id INT NOT NULL,
    order_id INT NOT NULL,
    rating INT,
    feedback TEXT,
    delivery_time_minutes INT,
    rated_by INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (rider_id) REFERENCES users(id),
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (rated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ ADDITIONAL APP TABLES ------------------ */
CREATE TABLE notifications_history LIKE notifications; -- optional archival example

/* ------------------ VIEWS ------------------ */
CREATE OR REPLACE VIEW product_performance AS
SELECT p.id,
       p.name,
       p.price,
       p.stock_quantity,
       COALESCE(SUM(oi.quantity),0) AS total_sold,
       COALESCE(SUM(oi.quantity * oi.price_at_time),0) AS total_revenue,
       COALESCE(AVG(r.rating),0) AS avg_rating,
       COUNT(r.id) AS review_count
FROM products p
LEFT JOIN order_items oi ON p.id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.id AND o.status <> 'cancelled'
LEFT JOIN reviews r ON p.id = r.product_id
GROUP BY p.id, p.name, p.price, p.stock_quantity
ORDER BY total_sold DESC;

CREATE OR REPLACE VIEW sales_summary AS
SELECT DATE(o.created_at) AS order_date,
       COUNT(o.id) AS total_orders,
       SUM(o.total_amount) AS total_revenue,
       AVG(o.total_amount) AS avg_order_value
FROM orders o
WHERE o.status <> 'cancelled'
GROUP BY DATE(o.created_at)
ORDER BY order_date DESC;

/* ------------------ TRIGGERS ------------------ */
DELIMITER $$
CREATE TRIGGER after_order_item_insert
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    DECLARE prev_stock INT;
    SELECT stock_quantity INTO prev_stock FROM products WHERE id = NEW.product_id;

    INSERT INTO inventory_transactions (
        product_id, transaction_type, quantity,
        previous_stock, new_stock, reference_type, reference_id
    ) VALUES (
        NEW.product_id, 'sale', NEW.quantity,
        prev_stock, prev_stock - NEW.quantity, 'order', NEW.order_id
    );

    IF (prev_stock - NEW.quantity) <= (SELECT low_stock_threshold FROM products WHERE id = NEW.product_id) THEN
        INSERT INTO low_stock_alerts (product_id, seller_id, threshold_quantity, current_stock)
        SELECT id, seller_id, low_stock_threshold, stock_quantity
        FROM products WHERE id = NEW.product_id
        ON DUPLICATE KEY UPDATE
            current_stock = VALUES(current_stock),
            alert_sent = FALSE;
    END IF;
END$$
DELIMITER ;

   
