/* ===========================================================
   Pawfect Finds – FULL DATABASE SCHEMA
   =========================================================== */

CREATE DATABASE IF NOT EXISTS pawfect_findsdatabase
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pawfect_findsdatabase;

/* ------------------ USERS ------------------ */
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    address TEXT NOT NULL,
    country VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    id_picture VARCHAR(255),
    role ENUM('user','seller','admin','rider') DEFAULT 'user',
    status ENUM('active','inactive','banned') DEFAULT 'active',
    latitude DECIMAL(10,8) DEFAULT 14.5995,
    longitude DECIMAL(11,8) DEFAULT 120.9842,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_role(role),
    INDEX idx_status(status),
    INDEX idx_email(email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ CATEGORIES ------------------ */
CREATE TABLE IF NOT EXISTS categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    image_url VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_active(is_active),
    INDEX idx_name(name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ SELLER REQUESTS ------------------ */
CREATE TABLE IF NOT EXISTS seller_requests (
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
    INDEX idx_status(status),
    INDEX idx_user(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ PRODUCTS ------------------ */
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    seller_id INT NOT NULL,
    category_id INT NOT NULL,
    name VARCHAR(200) NOT NULL,
    slug VARCHAR(255),
    sku VARCHAR(100),
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    sale_price DECIMAL(10,2),
    sale_start_date DATETIME,
    sale_end_date DATETIME,
    stock_quantity INT DEFAULT 0,
    low_stock_threshold INT DEFAULT 10,
    is_low_stock BOOLEAN GENERATED ALWAYS AS (stock_quantity <= low_stock_threshold) STORED,
    seller_latitude DECIMAL(10,8) DEFAULT 14.5995,
    seller_longitude DECIMAL(11,8) DEFAULT 120.9842,
    image_url VARCHAR(255),
    meta_title VARCHAR(200),
    meta_description TEXT,
    meta_keywords VARCHAR(255),
    status ENUM('active','inactive','out_of_stock','draft') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (seller_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT,
    INDEX idx_seller(seller_id),
    INDEX idx_category(category_id),
    INDEX idx_status(status),
    INDEX idx_name(name),
    INDEX idx_price(price),
    INDEX idx_slug(slug),
    INDEX idx_sale_dates(sale_start_date, sale_end_date),
    INDEX idx_category_status(category_id, status),
    INDEX idx_seller_category(seller_id, category_id),
    INDEX idx_low_stock(is_low_stock),
    FULLTEXT idx_search(name, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ CART ------------------ */
CREATE TABLE IF NOT EXISTS cart (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_product(user_id, product_id),
    INDEX idx_user(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ ORDERS ------------------ */
CREATE TABLE IF NOT EXISTS orders (
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
    status ENUM('pending','confirmed','preparing','shipped','assigned_to_rider','picked_up','on_the_way','delivered','cancelled') DEFAULT 'pending',
    shipping_address TEXT NOT NULL,
    payment_method ENUM('cod','online') DEFAULT 'cod',
    payment_status ENUM('pending','paid','refunded') DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (seller_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (rider_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user(user_id),
    INDEX idx_seller(seller_id),
    INDEX idx_rider(rider_id),
    INDEX idx_status(status),
    INDEX idx_payment(payment_status),
    INDEX idx_created(created_at),
    INDEX idx_tracking_number(tracking_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ DELIVERIES ------------------ */
CREATE TABLE IF NOT EXISTS deliveries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    rider_id INT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    picked_up_at TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,
    delivery_notes TEXT,
    status ENUM('assigned','picked_up','in_transit','delivered','failed') DEFAULT 'assigned',
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (rider_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_order_rider(order_id, rider_id),
    INDEX idx_rider(rider_id),
    INDEX idx_status(status),
    INDEX idx_assigned(assigned_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ ORDER ITEMS ------------------ */
CREATE TABLE IF NOT EXISTS order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    price_at_time DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_order(order_id),
    INDEX idx_product(product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ REVIEWS ------------------ */
CREATE TABLE IF NOT EXISTS reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_product_review(user_id, product_id),
    INDEX idx_product(product_id),
    INDEX idx_rating(rating)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ PRODUCT VARIANTS ------------------ */
CREATE TABLE IF NOT EXISTS product_variants (
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    INDEX idx_product_id(product_id),
    INDEX idx_status(status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ PRODUCT BUNDLES / ITEMS ------------------ */
CREATE TABLE IF NOT EXISTS product_bundles (
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

CREATE TABLE IF NOT EXISTS bundle_items (
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
    INDEX idx_product_id(product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ SHIPPING PROVIDERS ------------------ */
CREATE TABLE IF NOT EXISTS shipping_providers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    base_fee DECIMAL(10,2) NOT NULL DEFAULT 50.00,
    per_km_rate DECIMAL(10,2) NOT NULL DEFAULT 5.00,
    estimated_delivery_days INT NOT NULL DEFAULT 3,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO shipping_providers (name, base_fee, per_km_rate, estimated_delivery_days) VALUES
('J&T Express', 50.00, 5.00, 3),
('Ninja Van', 60.00, 6.00, 2),
('Lalamove', 70.00, 7.00, 1),
('LBC', 55.00, 5.50, 3),
('JRS Express', 45.00, 4.50, 4);

/* ------------------ RIDER APPLICATIONS + SUPPORT TABLES ------------------ */
CREATE TABLE IF NOT EXISTS rider_applications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    vehicle_type VARCHAR(50) NOT NULL,
    vehicle_plate_number VARCHAR(20),
    vehicle_model VARCHAR(100),
    government_id VARCHAR(255),
    vehicle_registration VARCHAR(255),
    profile_photo VARCHAR(255),
    clearance VARCHAR(255),
    status ENUM('pending','under_review','approved','rejected') DEFAULT 'pending',
    admin_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id(user_id),
    INDEX idx_status(status),
    INDEX idx_created_at(created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS rider_training (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    status ENUM('not_started','in_progress','completed') DEFAULT 'not_started',
    completed_at TIMESTAMP NULL,
    training_score INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id(user_id),
    INDEX idx_status(status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS rider_availability (
    id INT AUTO_INCREMENT PRIMARY KEY,
    rider_id INT NOT NULL UNIQUE,
    is_online BOOLEAN DEFAULT FALSE,
    is_available BOOLEAN DEFAULT FALSE,
    current_latitude DECIMAL(10,8),
    current_longitude DECIMAL(11,8),
    last_online TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (rider_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_rider_id(rider_id),
    INDEX idx_is_online(is_online),
    INDEX idx_is_available(is_available)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS rider_documents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    rider_id INT NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    document_path VARCHAR(255) NOT NULL,
    status ENUM('pending','verified','rejected') DEFAULT 'pending',
    expiry_date DATE,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_at TIMESTAMP NULL,
    notes TEXT,
    FOREIGN KEY (rider_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_rider_id(rider_id),
    INDEX idx_document_type(document_type),
    INDEX idx_status(status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS rider_performance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    rider_id INT NOT NULL,
    total_deliveries INT DEFAULT 0,
    completed_deliveries INT DEFAULT 0,
    cancelled_deliveries INT DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    total_earnings DECIMAL(10,2) DEFAULT 0.00,
    on_time_delivery_rate DECIMAL(5,2) DEFAULT 0.00,
    last_delivery_date TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (rider_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_rider_id(rider_id),
    INDEX idx_average_rating(average_rating)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ RETURN REQUESTS ------------------ */
CREATE TABLE IF NOT EXISTS return_requests (
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
    INDEX idx_user_id(user_id),
    INDEX idx_order_id(order_id),
    INDEX idx_status(status),
    INDEX idx_created_at(created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ INVENTORY TRANSACTIONS ------------------ */
CREATE TABLE IF NOT EXISTS inventory_transactions (
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

/* ------------------ LOW STOCK ALERTS ------------------ */
CREATE TABLE IF NOT EXISTS low_stock_alerts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    seller_id INT NOT NULL,
    threshold_quantity INT NOT NULL DEFAULT 10,
    current_stock INT NOT NULL,
    alert_sent BOOLEAN DEFAULT FALSE,
    alert_sent_at TIMESTAMP NULL,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (seller_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_product_id(product_id),
    INDEX idx_seller_id(seller_id),
    INDEX idx_alert_sent(alert_sent)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ ORDER TRACKING ------------------ */
CREATE TABLE IF NOT EXISTS order_tracking (
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
    INDEX idx_tracking_number(tracking_number),
    INDEX idx_created_at(created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* ------------------ PRODUCT VIEWS ------------------ */
CREATE TABLE IF NOT EXISTS product_views (
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

/* ------------------ SALES ANALYTICS ------------------ */
CREATE TABLE IF NOT EXISTS sales_analytics (
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

/* ------------------ CACHE ENTRIES (Redis fallback) ------------------ */
CREATE TABLE IF NOT EXISTS cache_entries (
    cache_key VARCHAR(255) PRIMARY KEY,
    cache_value LONGTEXT NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_expires_at(expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* Extend wishlist (if table exists in your DB) */
ALTER TABLE wishlist
    ADD COLUMN IF NOT EXISTS notes TEXT,
    ADD COLUMN IF NOT EXISTS priority ENUM('low','medium','high') DEFAULT 'medium',
    ADD COLUMN IF NOT EXISTS notified_when_available BOOLEAN DEFAULT FALSE;

/* ---------- TRIGGER for inventory + low stock alerts ---------- */
DELIMITER $$
CREATE TRIGGER IF NOT EXISTS after_order_item_insert
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
        ON DUPLICATE KEY UPDATE current_stock = VALUES(current_stock), alert_sent = FALSE;
    END IF;
END$$
DELIMITER ;

/* ------------------ VIEWS ------------------ */
CREATE OR REPLACE VIEW sales_summary AS
SELECT DATE(o.created_at) AS order_date,
       COUNT(o.id) AS total_orders,
       SUM(o.total_amount) AS total_revenue,
       AVG(o.total_amount) AS avg_order_value
FROM orders o
WHERE o.status <> 'cancelled'
GROUP BY DATE(o.created_at)
ORDER BY order_date DESC;

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

/* ------------------ PROCEDURES ------------------ */
DELIMITER //
CREATE PROCEDURE GetCartTotal(IN p_user_id INT, OUT cart_total DECIMAL(10,2))
BEGIN
    SELECT COALESCE(SUM(p.price * c.quantity),0)
    INTO cart_total
    FROM cart c
    JOIN products p ON c.product_id = p.id
    WHERE c.user_id = p_user_id;
END//
CREATE PROCEDURE UpdateProductStock(IN p_product_id INT, IN quantity_sold INT)
BEGIN
    UPDATE products
    SET stock_quantity = stock_quantity - quantity_sold,
        status = CASE WHEN (stock_quantity - quantity_sold) <= 0 THEN 'out_of_stock' ELSE status END
    WHERE id = p_product_id;
END//
DELIMITER ;

/* ------------------ SAMPLE DATA (optional) ------------------ */
INSERT INTO categories (name, description, image_url) VALUES
('Dog Food & Treats','Premium dog food and treats',NULL),
('Cat Litter & Accessories','Cat litter, boxes, toys',NULL),
('Aquariums & Fish Supplies','Aquarium gear and supplies',NULL),
('Bird Feeders & Food','Cages, feeders, food',NULL),
('Pet Grooming Products','Shampoo, brushes, etc.',NULL),
('Pet Health & Wellness','Vitamins, supplements',NULL);

INSERT INTO users (username, email, password_hash, first_name, last_name, phone, address, role)
VALUES
('admin','admin@pawfectfinds.com','pbkdf2:sha256:260000$EPldXnXRcXdYhNUt$6831a3a1a46e6595478cf13fa05d85cd7fe3849ff25d1719f83cbbde066d0412','Admin','User','1234567890','123 Admin Street','admin'),
('petstore1','seller1@petstore.com','pbkdf2:sha256:260000$KnEmmkNgxtEkRu7l$49fa90c5d97e8612334c7318d3587f3b182d9df0075f3b965d65a6f3c5ce5fa8','John','Smith','5551234567','456 Pet Avenue','seller'),
('happypaws','seller2@happypaws.com','pbkdf2:sha256:260000$KnEmmkNgxtEkRu7l$49fa90c5d97e8612334c7318d3587f3b182d9df0075f3b965d65a6f3c5ce5fa8','Sarah','Johnson','5559876543','789 Happy Lane','seller'),
('petlover1','customer1@example.com','pbkdf2:sha256:260000$18tvDaa7LzYBXBGi$d17817193edf01a10b34cec8cdff09ae73cc448fcafab65545e188a0d59c121e','Mike','Davis','5552468135','321 Customer Road','user'),
('doglover','customer2@example.com','pbkdf2:sha256:260000$18tvDaa7LzYBXBGi$d17817193edf01a10b34cec8cdff09ae73cc448fcafab65545e188a0d59c121e','Emily','Wilson','5558642097','654 Dog Street','user'),
('rider1','rider1@delivery.com','pbkdf2:sha256:260000$YSgQh7tIWyOYTKvz$ca05767ef5ae8c616d10f3302ad29cf2afbe83f848d5c3c878b263382c8b9dc3','Alex','Rider','5551112223','123 Delivery HQ','rider'),
('rider2','rider2@delivery.com','pbkdf2:sha256:260000$YSgQh7tIWyOYTKvz$ca05767ef5ae8c616d10f3302ad29cf2afbe83f848d5c3c878b263382c8b9dc3','Jordan','Swift','5553334445','456 Fast Lane','rider');


SELECT 'Database setup completed successfully!' AS Status;