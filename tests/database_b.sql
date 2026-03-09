-- ============================================================================
-- DB Compare - Test Database B (Target / Stripped-Down / Different)
-- ============================================================================
-- This database is intentionally different from Database A to exercise
-- every comparison feature of the DB Compare tool:
--
--   1. MISSING TABLES:      tags, product_tags, settings exist only in A
--                            coupons, wishlists exist only in B
--   2. COLUMN DIFFERENCES:  Type changes, nullable changes, default changes,
--                            extra changes, missing columns, extra columns
--   3. INDEX DIFFERENCES:   Missing indexes, extra indexes, different indexes
--   4. FK DIFFERENCES:      Missing FKs, extra FKs
--
-- Usage:
--   mysql -u root < database_b.sql
-- ============================================================================

DROP DATABASE IF EXISTS `test_db_b`;
CREATE DATABASE `test_db_b` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `test_db_b`;

-- ============================================================================
-- TABLE 1: all_data_types
-- Differences from A:
--   - MISSING columns: binary_val, varbinary_val, tinyblob_val, mediumblob_val,
--                       longblob_val, flags
--   - EXTRA columns:   uuid_val, geometry_val
--   - TYPE changes:    decimal_val (12,4 -> 10,2), varchar_val (255 -> 500),
--                      char_val (10 -> 20)
--   - NULLABLE change: tiny_val (NOT NULL -> NULL)
--   - DEFAULT change:  status ENUM has different options
--   - EXTRA change:    (none, but AUTO_INCREMENT stays same)
-- ============================================================================
CREATE TABLE `all_data_types` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tiny_val`          TINYINT DEFAULT NULL,
    `small_val`         SMALLINT NOT NULL DEFAULT 0,
    `medium_val`        MEDIUMINT NOT NULL DEFAULT 0,
    `int_val`           INT NOT NULL DEFAULT 0,
    `big_val`           BIGINT NOT NULL DEFAULT 0,

    `decimal_val`       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `float_val`         FLOAT(8,2) DEFAULT NULL,
    `double_val`        DOUBLE(16,4) DEFAULT NULL,

    `char_val`          CHAR(20) NOT NULL DEFAULT '',
    `varchar_val`       VARCHAR(500) NOT NULL DEFAULT '',
    `tinytext_val`      TINYTEXT,
    `text_val`          TEXT,
    `mediumtext_val`    MEDIUMTEXT,
    `longtext_val`      LONGTEXT,

    `blob_val`          BLOB,

    `date_val`          DATE DEFAULT NULL,
    `datetime_val`      DATETIME DEFAULT NULL,
    `timestamp_val`     TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `time_val`          TIME DEFAULT NULL,
    `year_val`          YEAR DEFAULT NULL,

    `status`            ENUM('active','inactive','pending','archived','deleted') NOT NULL DEFAULT 'active',
    `tags`              SET('urgent','important','normal','low','critical') DEFAULT 'normal',

    `json_data`         JSON DEFAULT NULL,

    `is_active`         BOOLEAN NOT NULL DEFAULT TRUE,
    `is_deleted`        BOOLEAN NOT NULL DEFAULT FALSE,

    -- Extra columns not in A
    `uuid_val`          CHAR(36) DEFAULT NULL,

    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE 2: users
-- Differences from A:
--   - MISSING columns: phone, avatar_url, bio, is_premium, balance
--   - EXTRA columns:   timezone, language, two_factor_enabled
--   - TYPE change:     email (VARCHAR(150) -> VARCHAR(100))
--   - ENUM change:     role has fewer options (no super_admin, moderator)
--   - ENUM change:     status has different options
--   - DEFAULT change:  login_count default 0 -> 1
--   - MISSING indexes: idx_name, idx_premium_status
--   - EXTRA indexes:   idx_language
--   - MISSING FK:      (none here, users has no FK in A either)
-- ============================================================================
CREATE TABLE `users` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid`              CHAR(36) NOT NULL,
    `username`          VARCHAR(50) NOT NULL,
    `email`             VARCHAR(100) NOT NULL,
    `password_hash`     VARCHAR(255) NOT NULL,
    `first_name`        VARCHAR(100) DEFAULT NULL,
    `last_name`         VARCHAR(100) DEFAULT NULL,
    `role`              ENUM('admin','editor','user','guest') NOT NULL DEFAULT 'user',
    `status`            ENUM('active','inactive','banned') NOT NULL DEFAULT 'active',
    `email_verified_at` DATETIME DEFAULT NULL,
    `last_login_at`     DATETIME DEFAULT NULL,
    `login_count`       INT UNSIGNED NOT NULL DEFAULT 1,
    `preferences`       JSON DEFAULT NULL,
    `timezone`          VARCHAR(50) DEFAULT 'UTC',
    `language`          CHAR(5) DEFAULT 'en',
    `two_factor_enabled` BOOLEAN NOT NULL DEFAULT FALSE,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_uuid` (`uuid`),
    UNIQUE KEY `uk_username` (`username`),
    UNIQUE KEY `uk_email` (`email`),
    INDEX `idx_role` (`role`),
    INDEX `idx_status` (`status`),
    INDEX `idx_created_at` (`created_at`),
    INDEX `idx_language` (`language`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE 3: categories
-- Differences from A:
--   - MISSING columns: icon, meta_title, meta_description
--   - EXTRA columns:   image_url, badge_text
--   - TYPE change:     name (VARCHAR(100) -> VARCHAR(150))
--   - NULLABLE change: description (NULL -> NOT NULL with default '')
--   - MISSING index:   idx_sort
--   - MISSING FK:      fk_category_parent (no self-referencing FK)
-- ============================================================================
CREATE TABLE `categories` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `parent_id`         INT UNSIGNED DEFAULT NULL,
    `name`              VARCHAR(150) NOT NULL,
    `slug`              VARCHAR(120) NOT NULL,
    `description`       TEXT NOT NULL,
    `image_url`         VARCHAR(500) DEFAULT NULL,
    `badge_text`        VARCHAR(30) DEFAULT NULL,
    `sort_order`        INT NOT NULL DEFAULT 0,
    `is_visible`        BOOLEAN NOT NULL DEFAULT TRUE,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_slug` (`slug`),
    INDEX `idx_parent` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE 4: products
-- Differences from A:
--   - MISSING columns: compare_price, cost_price, weight, dimensions,
--                       is_digital, tax_class, metadata, published_at
--   - EXTRA columns:   brand, color, rating_avg, review_count
--   - TYPE change:     price (DECIMAL(12,2) -> DECIMAL(10,2))
--   - TYPE change:     short_description (VARCHAR(500) -> TEXT)
--   - ENUM change:     status has different values
--   - MISSING indexes: idx_price, idx_featured, idx_published, idx_name_status
--   - EXTRA indexes:   idx_brand, idx_rating
--   - FK same:         fk_product_category exists in both
-- ============================================================================
CREATE TABLE `products` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `category_id`       INT UNSIGNED DEFAULT NULL,
    `sku`               VARCHAR(50) NOT NULL,
    `name`              VARCHAR(200) NOT NULL,
    `slug`              VARCHAR(220) NOT NULL,
    `description`       TEXT,
    `short_description` TEXT,
    `price`             DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `quantity`          INT NOT NULL DEFAULT 0,
    `brand`             VARCHAR(100) DEFAULT NULL,
    `color`             VARCHAR(30) DEFAULT NULL,
    `is_featured`       BOOLEAN NOT NULL DEFAULT FALSE,
    `status`            ENUM('draft','active','paused','discontinued') NOT NULL DEFAULT 'draft',
    `rating_avg`        DECIMAL(3,2) DEFAULT 0.00,
    `review_count`      INT UNSIGNED NOT NULL DEFAULT 0,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_sku` (`sku`),
    UNIQUE KEY `uk_slug` (`slug`),
    INDEX `idx_category` (`category_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_brand` (`brand`),
    INDEX `idx_rating` (`rating_avg`),
    CONSTRAINT `fk_product_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE 5: product_images
-- Differences from A:
--   - MISSING columns: alt_text, file_size, mime_type, width, height
--   - EXTRA columns:   caption, blurhash
--   - MISSING index:   idx_primary
--   - MISSING FK:      fk_image_product (FK removed in B)
-- ============================================================================
CREATE TABLE `product_images` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id`        INT UNSIGNED NOT NULL,
    `url`               VARCHAR(1000) NOT NULL,
    `caption`           VARCHAR(300) DEFAULT NULL,
    `blurhash`          VARCHAR(100) DEFAULT NULL,
    `sort_order`        INT NOT NULL DEFAULT 0,
    `is_primary`        BOOLEAN NOT NULL DEFAULT FALSE,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    INDEX `idx_product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE 6: orders
-- Differences from A:
--   - MISSING columns: payment_status, payment_method, shipping_amount,
--                       discount_amount, shipping_name, shipping_address,
--                       shipping_city, shipping_state, shipping_zip,
--                       shipping_country, notes, ip_address, user_agent,
--                       shipped_at, delivered_at
--   - EXTRA columns:   coupon_code, tracking_number, estimated_delivery
--   - TYPE change:     currency (CHAR(3) -> VARCHAR(10))
--   - ENUM change:     status has fewer options
--   - MISSING indexes: idx_payment_status, idx_user_status
--   - EXTRA indexes:   idx_tracking
--   - FK same:         fk_order_user exists in both
-- ============================================================================
CREATE TABLE `orders` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `order_number`      VARCHAR(30) NOT NULL,
    `user_id`           INT UNSIGNED NOT NULL,
    `status`            ENUM('pending','confirmed','processing','shipped','delivered','cancelled') NOT NULL DEFAULT 'pending',
    `subtotal`          DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `tax_amount`        DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `total_amount`      DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `currency`          VARCHAR(10) NOT NULL DEFAULT 'USD',
    `coupon_code`       VARCHAR(50) DEFAULT NULL,
    `tracking_number`   VARCHAR(100) DEFAULT NULL,
    `estimated_delivery` DATE DEFAULT NULL,
    `ordered_at`        DATETIME NOT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_order_number` (`order_number`),
    INDEX `idx_user` (`user_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_ordered_at` (`ordered_at`),
    INDEX `idx_tracking` (`tracking_number`),
    CONSTRAINT `fk_order_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE 7: order_items
-- Differences from A:
--   - MISSING columns: product_name, sku, discount, tax, metadata
--   - EXTRA columns:   variant_id, variant_name
--   - TYPE change:     quantity (INT UNSIGNED -> SMALLINT UNSIGNED)
--   - MISSING index:   idx_sku
--   - EXTRA index:     idx_variant
--   - MISSING FK:      fk_item_product (FK to products removed)
--   - EXTRA FK:        (none)
-- ============================================================================
CREATE TABLE `order_items` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `order_id`          BIGINT UNSIGNED NOT NULL,
    `product_id`        INT UNSIGNED NOT NULL,
    `variant_id`        INT UNSIGNED DEFAULT NULL,
    `variant_name`      VARCHAR(100) DEFAULT NULL,
    `quantity`          SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `unit_price`        DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `total`             DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    INDEX `idx_order` (`order_id`),
    INDEX `idx_product` (`product_id`),
    INDEX `idx_variant` (`variant_id`),
    CONSTRAINT `fk_item_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE 8: reviews
-- Differences from A:
--   - MISSING columns: pros, cons, is_verified, helpful_count
--   - EXTRA columns:   images_json, reply_text, reply_at
--   - TYPE change:     rating (TINYINT UNSIGNED -> SMALLINT)
--   - NULLABLE change: title (NULL -> NOT NULL)
--   - MISSING index:   idx_product_rating, idx_approved
--   - MISSING unique:  uk_user_product (removed)
--   - EXTRA index:     idx_created
--   - FK difference:   fk_review_user exists in both, fk_review_product exists in both
-- ============================================================================
CREATE TABLE `reviews` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id`        INT UNSIGNED NOT NULL,
    `user_id`           INT UNSIGNED NOT NULL,
    `rating`            SMALLINT NOT NULL,
    `title`             VARCHAR(200) NOT NULL DEFAULT '',
    `body`              TEXT,
    `images_json`       JSON DEFAULT NULL,
    `reply_text`        TEXT,
    `reply_at`          DATETIME DEFAULT NULL,
    `is_approved`       BOOLEAN NOT NULL DEFAULT FALSE,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    INDEX `idx_product` (`product_id`),
    INDEX `idx_user` (`user_id`),
    INDEX `idx_rating` (`rating`),
    INDEX `idx_created` (`created_at`),
    CONSTRAINT `fk_review_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_review_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE 9: audit_logs
-- Differences from A:
--   - MISSING columns: user_agent, session_id, request_url, severity
--   - EXTRA columns:   browser, os, country_code
--   - TYPE change:     entity_type (VARCHAR(100) -> VARCHAR(50))
--   - MISSING indexes: idx_severity, idx_session
--   - EXTRA indexes:   idx_country
--   - MISSING FK:      fk_audit_user (FK removed in B)
-- ============================================================================
CREATE TABLE `audit_logs` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`           INT UNSIGNED DEFAULT NULL,
    `action`            VARCHAR(50) NOT NULL,
    `entity_type`       VARCHAR(50) NOT NULL,
    `entity_id`         BIGINT UNSIGNED DEFAULT NULL,
    `old_values`        JSON DEFAULT NULL,
    `new_values`        JSON DEFAULT NULL,
    `ip_address`        VARCHAR(45) DEFAULT NULL,
    `browser`           VARCHAR(100) DEFAULT NULL,
    `os`                VARCHAR(50) DEFAULT NULL,
    `country_code`      CHAR(2) DEFAULT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    INDEX `idx_user` (`user_id`),
    INDEX `idx_action` (`action`),
    INDEX `idx_entity` (`entity_type`, `entity_id`),
    INDEX `idx_created` (`created_at`),
    INDEX `idx_country` (`country_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE 10: notifications
-- Differences from A:
--   - MISSING columns: data, channel, priority, sent_at, expires_at
--   - EXTRA columns:   action_url, icon, category
--   - TYPE change:     message (TEXT -> VARCHAR(1000))
--   - MISSING indexes: idx_channel, idx_priority, idx_expires
--   - EXTRA indexes:   idx_category
--   - MISSING FK:      fk_notification_user (FK removed in B)
-- ============================================================================
CREATE TABLE `notifications` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`           INT UNSIGNED NOT NULL,
    `type`              VARCHAR(100) NOT NULL,
    `title`             VARCHAR(200) NOT NULL,
    `message`           VARCHAR(1000) NOT NULL,
    `action_url`        VARCHAR(500) DEFAULT NULL,
    `icon`              VARCHAR(50) DEFAULT NULL,
    `category`          VARCHAR(50) DEFAULT 'general',
    `is_read`           BOOLEAN NOT NULL DEFAULT FALSE,
    `read_at`           DATETIME DEFAULT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    INDEX `idx_user` (`user_id`),
    INDEX `idx_type` (`type`),
    INDEX `idx_user_read` (`user_id`, `is_read`),
    INDEX `idx_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE 11: media_files
-- Differences from A:
--   - MISSING columns: thumbnail_path, checksum, width, height, duration,
--                       disk, visibility, metadata
--   - EXTRA columns:   folder, tags_json, download_count
--   - TYPE change:     file_size (BIGINT UNSIGNED -> INT UNSIGNED)
--   - MISSING indexes: idx_mime, idx_disk, idx_checksum
--   - EXTRA indexes:   idx_folder
--   - MISSING FK:      fk_media_user (FK removed in B)
-- ============================================================================
CREATE TABLE `media_files` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`           INT UNSIGNED DEFAULT NULL,
    `filename`          VARCHAR(255) NOT NULL,
    `original_name`     VARCHAR(255) NOT NULL,
    `mime_type`         VARCHAR(100) NOT NULL,
    `file_size`         INT UNSIGNED NOT NULL DEFAULT 0,
    `storage_path`      VARCHAR(1000) NOT NULL,
    `folder`            VARCHAR(200) DEFAULT '/',
    `tags_json`         JSON DEFAULT NULL,
    `download_count`    INT UNSIGNED NOT NULL DEFAULT 0,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    INDEX `idx_user` (`user_id`),
    INDEX `idx_folder` (`folder`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE 12: coupons (exists ONLY in DB B)
-- Purpose: Tests "missing in A" detection
-- ============================================================================
CREATE TABLE `coupons` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`              VARCHAR(30) NOT NULL,
    `description`       VARCHAR(200) DEFAULT NULL,
    `type`              ENUM('percentage','fixed','free_shipping') NOT NULL DEFAULT 'percentage',
    `value`             DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `min_order_amount`  DECIMAL(10,2) DEFAULT NULL,
    `max_uses`          INT UNSIGNED DEFAULT NULL,
    `used_count`        INT UNSIGNED NOT NULL DEFAULT 0,
    `is_active`         BOOLEAN NOT NULL DEFAULT TRUE,
    `starts_at`         DATETIME DEFAULT NULL,
    `expires_at`        DATETIME DEFAULT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_code` (`code`),
    INDEX `idx_active` (`is_active`),
    INDEX `idx_dates` (`starts_at`, `expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE 13: wishlists (exists ONLY in DB B)
-- Purpose: Tests "missing in A" with FK
-- ============================================================================
CREATE TABLE `wishlists` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`           INT UNSIGNED NOT NULL,
    `product_id`        INT UNSIGNED NOT NULL,
    `priority`          TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `notes`             VARCHAR(500) DEFAULT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_product` (`user_id`, `product_id`),
    INDEX `idx_user` (`user_id`),
    INDEX `idx_product` (`product_id`),
    CONSTRAINT `fk_wishlist_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_wishlist_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
