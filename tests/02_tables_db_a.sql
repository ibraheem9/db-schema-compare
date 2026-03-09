-- ============================================================================
-- STEP 2: Create tables for test_db_a (Source / Full-Featured)
-- ============================================================================
-- Run AFTER 01_create_databases.sql
-- Tables are ordered by foreign key dependencies.
--
-- Usage:
--   mysql -u root -p test_db_a < 02_tables_db_a.sql
-- ============================================================================

-- ============================================================================
-- TABLE: all_data_types
-- Covers every major MySQL data type category (no FK dependencies)
-- ============================================================================
CREATE TABLE `all_data_types` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tiny_val`          TINYINT NOT NULL DEFAULT 0,
    `small_val`         SMALLINT NOT NULL DEFAULT 0,
    `medium_val`        MEDIUMINT NOT NULL DEFAULT 0,
    `int_val`           INT NOT NULL DEFAULT 0,
    `big_val`           BIGINT NOT NULL DEFAULT 0,
    `decimal_val`       DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
    `float_val`         FLOAT(8,2) DEFAULT NULL,
    `double_val`        DOUBLE(16,4) DEFAULT NULL,
    `char_val`          CHAR(10) NOT NULL DEFAULT '',
    `varchar_val`       VARCHAR(255) NOT NULL DEFAULT '',
    `tinytext_val`      TINYTEXT,
    `text_val`          TEXT,
    `mediumtext_val`    MEDIUMTEXT,
    `longtext_val`      LONGTEXT,
    `binary_val`        BINARY(16) DEFAULT NULL,
    `varbinary_val`     VARBINARY(256) DEFAULT NULL,
    `tinyblob_val`      TINYBLOB,
    `blob_val`          BLOB,
    `mediumblob_val`    MEDIUMBLOB,
    `longblob_val`      LONGBLOB,
    `date_val`          DATE DEFAULT NULL,
    `datetime_val`      DATETIME DEFAULT NULL,
    `timestamp_val`     TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `time_val`          TIME DEFAULT NULL,
    `year_val`          YEAR DEFAULT NULL,
    `status`            ENUM('active','inactive','pending','archived') NOT NULL DEFAULT 'active',
    `tags`              SET('urgent','important','normal','low') DEFAULT 'normal',
    `json_data`         JSON DEFAULT NULL,
    `is_active`         BOOLEAN NOT NULL DEFAULT TRUE,
    `is_deleted`        BOOLEAN NOT NULL DEFAULT FALSE,
    `flags`             BIT(8) DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE: users (no FK dependencies)
-- ============================================================================
CREATE TABLE `users` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid`              CHAR(36) NOT NULL,
    `username`          VARCHAR(50) NOT NULL,
    `email`             VARCHAR(150) NOT NULL,
    `password_hash`     VARCHAR(255) NOT NULL,
    `first_name`        VARCHAR(100) DEFAULT NULL,
    `last_name`         VARCHAR(100) DEFAULT NULL,
    `phone`             VARCHAR(20) DEFAULT NULL,
    `avatar_url`        VARCHAR(500) DEFAULT NULL,
    `bio`               TEXT,
    `role`              ENUM('super_admin','admin','editor','moderator','user','guest') NOT NULL DEFAULT 'user',
    `status`            ENUM('active','inactive','banned','suspended') NOT NULL DEFAULT 'active',
    `email_verified_at` DATETIME DEFAULT NULL,
    `last_login_at`     DATETIME DEFAULT NULL,
    `login_count`       INT UNSIGNED NOT NULL DEFAULT 0,
    `preferences`       JSON DEFAULT NULL,
    `is_premium`        BOOLEAN NOT NULL DEFAULT FALSE,
    `balance`           DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_uuid` (`uuid`),
    UNIQUE KEY `uk_username` (`username`),
    UNIQUE KEY `uk_email` (`email`),
    INDEX `idx_role` (`role`),
    INDEX `idx_status` (`status`),
    INDEX `idx_created_at` (`created_at`),
    INDEX `idx_name` (`first_name`, `last_name`),
    INDEX `idx_premium_status` (`is_premium`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE: settings (no FK dependencies)
-- ============================================================================
CREATE TABLE `settings` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `group_name`        VARCHAR(50) NOT NULL DEFAULT 'general',
    `setting_key`       VARCHAR(100) NOT NULL,
    `setting_value`     TEXT,
    `setting_type`      ENUM('string','integer','boolean','json','file') NOT NULL DEFAULT 'string',
    `is_public`         BOOLEAN NOT NULL DEFAULT FALSE,
    `description`       VARCHAR(500) DEFAULT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_group_key` (`group_name`, `setting_key`),
    INDEX `idx_group` (`group_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE: tags (no FK dependencies)
-- ============================================================================
CREATE TABLE `tags` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`              VARCHAR(50) NOT NULL,
    `slug`              VARCHAR(60) NOT NULL,
    `color`             CHAR(7) DEFAULT '#000000',
    `usage_count`       INT UNSIGNED NOT NULL DEFAULT 0,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_name` (`name`),
    UNIQUE KEY `uk_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE: categories (self-referencing FK to itself)
-- Depends on: nothing external (self-reference is fine)
-- ============================================================================
CREATE TABLE `categories` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `parent_id`         INT UNSIGNED DEFAULT NULL,
    `name`              VARCHAR(100) NOT NULL,
    `slug`              VARCHAR(120) NOT NULL,
    `description`       TEXT,
    `icon`              VARCHAR(50) DEFAULT NULL,
    `sort_order`        INT NOT NULL DEFAULT 0,
    `is_visible`        BOOLEAN NOT NULL DEFAULT TRUE,
    `meta_title`        VARCHAR(200) DEFAULT NULL,
    `meta_description`  VARCHAR(500) DEFAULT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_slug` (`slug`),
    INDEX `idx_parent` (`parent_id`),
    INDEX `idx_sort` (`sort_order`),
    CONSTRAINT `fk_category_parent` FOREIGN KEY (`parent_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE: products (depends on: categories)
-- ============================================================================
CREATE TABLE `products` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `category_id`       INT UNSIGNED DEFAULT NULL,
    `sku`               VARCHAR(50) NOT NULL,
    `name`              VARCHAR(200) NOT NULL,
    `slug`              VARCHAR(220) NOT NULL,
    `description`       TEXT,
    `short_description` VARCHAR(500) DEFAULT NULL,
    `price`             DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `compare_price`     DECIMAL(12,2) DEFAULT NULL,
    `cost_price`        DECIMAL(12,2) DEFAULT NULL,
    `quantity`          INT NOT NULL DEFAULT 0,
    `weight`            DECIMAL(8,2) DEFAULT NULL,
    `dimensions`        VARCHAR(50) DEFAULT NULL,
    `is_featured`       BOOLEAN NOT NULL DEFAULT FALSE,
    `is_digital`        BOOLEAN NOT NULL DEFAULT FALSE,
    `status`            ENUM('draft','active','discontinued','out_of_stock') NOT NULL DEFAULT 'draft',
    `tax_class`         ENUM('standard','reduced','zero','exempt') NOT NULL DEFAULT 'standard',
    `metadata`          JSON DEFAULT NULL,
    `published_at`      DATETIME DEFAULT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_sku` (`sku`),
    UNIQUE KEY `uk_slug` (`slug`),
    INDEX `idx_category` (`category_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_price` (`price`),
    INDEX `idx_featured` (`is_featured`),
    INDEX `idx_published` (`published_at`),
    INDEX `idx_name_status` (`name`(100), `status`),
    CONSTRAINT `fk_product_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE: product_images (depends on: products)
-- ============================================================================
CREATE TABLE `product_images` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id`        INT UNSIGNED NOT NULL,
    `url`               VARCHAR(1000) NOT NULL,
    `alt_text`          VARCHAR(255) DEFAULT NULL,
    `sort_order`        INT NOT NULL DEFAULT 0,
    `is_primary`        BOOLEAN NOT NULL DEFAULT FALSE,
    `file_size`         INT UNSIGNED DEFAULT NULL,
    `mime_type`         VARCHAR(50) DEFAULT NULL,
    `width`             SMALLINT UNSIGNED DEFAULT NULL,
    `height`            SMALLINT UNSIGNED DEFAULT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_product` (`product_id`),
    INDEX `idx_primary` (`product_id`, `is_primary`),
    CONSTRAINT `fk_image_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE: product_tags (depends on: products, tags)
-- ============================================================================
CREATE TABLE `product_tags` (
    `product_id`        INT UNSIGNED NOT NULL,
    `tag_id`            INT UNSIGNED NOT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`product_id`, `tag_id`),
    INDEX `idx_tag` (`tag_id`),
    CONSTRAINT `fk_pt_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_pt_tag` FOREIGN KEY (`tag_id`) REFERENCES `tags` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE: orders (depends on: users)
-- ============================================================================
CREATE TABLE `orders` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `order_number`      VARCHAR(30) NOT NULL,
    `user_id`           INT UNSIGNED NOT NULL,
    `status`            ENUM('pending','confirmed','processing','shipped','delivered','cancelled','refunded') NOT NULL DEFAULT 'pending',
    `payment_status`    ENUM('unpaid','paid','partial','refunded','failed') NOT NULL DEFAULT 'unpaid',
    `payment_method`    VARCHAR(50) DEFAULT NULL,
    `subtotal`          DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `tax_amount`        DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `shipping_amount`   DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `discount_amount`   DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `total_amount`      DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `currency`          CHAR(3) NOT NULL DEFAULT 'USD',
    `shipping_name`     VARCHAR(200) DEFAULT NULL,
    `shipping_address`  TEXT,
    `shipping_city`     VARCHAR(100) DEFAULT NULL,
    `shipping_state`    VARCHAR(100) DEFAULT NULL,
    `shipping_zip`      VARCHAR(20) DEFAULT NULL,
    `shipping_country`  CHAR(2) DEFAULT NULL,
    `notes`             TEXT,
    `ip_address`        VARCHAR(45) DEFAULT NULL,
    `user_agent`        VARCHAR(500) DEFAULT NULL,
    `ordered_at`        DATETIME NOT NULL,
    `shipped_at`        DATETIME DEFAULT NULL,
    `delivered_at`      DATETIME DEFAULT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_order_number` (`order_number`),
    INDEX `idx_user` (`user_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_payment_status` (`payment_status`),
    INDEX `idx_ordered_at` (`ordered_at`),
    INDEX `idx_user_status` (`user_id`, `status`),
    CONSTRAINT `fk_order_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE: order_items (depends on: orders, products)
-- ============================================================================
CREATE TABLE `order_items` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `order_id`          BIGINT UNSIGNED NOT NULL,
    `product_id`        INT UNSIGNED NOT NULL,
    `product_name`      VARCHAR(200) NOT NULL,
    `sku`               VARCHAR(50) NOT NULL,
    `quantity`          INT UNSIGNED NOT NULL DEFAULT 1,
    `unit_price`        DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `discount`          DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `tax`               DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `total`             DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `metadata`          JSON DEFAULT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_order` (`order_id`),
    INDEX `idx_product` (`product_id`),
    INDEX `idx_sku` (`sku`),
    CONSTRAINT `fk_item_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_item_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE: reviews (depends on: products, users)
-- ============================================================================
CREATE TABLE `reviews` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id`        INT UNSIGNED NOT NULL,
    `user_id`           INT UNSIGNED NOT NULL,
    `rating`            TINYINT UNSIGNED NOT NULL,
    `title`             VARCHAR(200) DEFAULT NULL,
    `body`              TEXT,
    `pros`              TEXT,
    `cons`              TEXT,
    `is_verified`       BOOLEAN NOT NULL DEFAULT FALSE,
    `is_approved`       BOOLEAN NOT NULL DEFAULT FALSE,
    `helpful_count`     INT UNSIGNED NOT NULL DEFAULT 0,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_product` (`product_id`),
    INDEX `idx_user` (`user_id`),
    INDEX `idx_rating` (`rating`),
    INDEX `idx_product_rating` (`product_id`, `rating`),
    INDEX `idx_approved` (`is_approved`, `created_at`),
    UNIQUE KEY `uk_user_product` (`user_id`, `product_id`),
    CONSTRAINT `fk_review_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_review_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE: audit_logs (depends on: users)
-- ============================================================================
CREATE TABLE `audit_logs` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`           INT UNSIGNED DEFAULT NULL,
    `action`            VARCHAR(50) NOT NULL,
    `entity_type`       VARCHAR(100) NOT NULL,
    `entity_id`         BIGINT UNSIGNED DEFAULT NULL,
    `old_values`        JSON DEFAULT NULL,
    `new_values`        JSON DEFAULT NULL,
    `ip_address`        VARCHAR(45) DEFAULT NULL,
    `user_agent`        VARCHAR(500) DEFAULT NULL,
    `session_id`        VARCHAR(128) DEFAULT NULL,
    `request_url`       VARCHAR(2000) DEFAULT NULL,
    `severity`          ENUM('info','warning','error','critical') NOT NULL DEFAULT 'info',
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_user` (`user_id`),
    INDEX `idx_action` (`action`),
    INDEX `idx_entity` (`entity_type`, `entity_id`),
    INDEX `idx_severity` (`severity`),
    INDEX `idx_created` (`created_at`),
    INDEX `idx_session` (`session_id`),
    CONSTRAINT `fk_audit_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE: notifications (depends on: users)
-- ============================================================================
CREATE TABLE `notifications` (
    `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`           INT UNSIGNED NOT NULL,
    `type`              VARCHAR(100) NOT NULL,
    `title`             VARCHAR(200) NOT NULL,
    `message`           TEXT NOT NULL,
    `data`              JSON DEFAULT NULL,
    `channel`           ENUM('email','sms','push','in_app') NOT NULL DEFAULT 'in_app',
    `priority`          ENUM('low','normal','high','urgent') NOT NULL DEFAULT 'normal',
    `is_read`           BOOLEAN NOT NULL DEFAULT FALSE,
    `read_at`           DATETIME DEFAULT NULL,
    `sent_at`           DATETIME DEFAULT NULL,
    `expires_at`        DATETIME DEFAULT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_user` (`user_id`),
    INDEX `idx_type` (`type`),
    INDEX `idx_user_read` (`user_id`, `is_read`),
    INDEX `idx_channel` (`channel`),
    INDEX `idx_priority` (`priority`),
    INDEX `idx_expires` (`expires_at`),
    CONSTRAINT `fk_notification_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- TABLE: media_files (depends on: users)
-- ============================================================================
CREATE TABLE `media_files` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`           INT UNSIGNED DEFAULT NULL,
    `filename`          VARCHAR(255) NOT NULL,
    `original_name`     VARCHAR(255) NOT NULL,
    `mime_type`         VARCHAR(100) NOT NULL,
    `file_size`         BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `storage_path`      VARCHAR(1000) NOT NULL,
    `thumbnail_path`    VARCHAR(1000) DEFAULT NULL,
    `checksum`          CHAR(64) DEFAULT NULL,
    `width`             INT UNSIGNED DEFAULT NULL,
    `height`            INT UNSIGNED DEFAULT NULL,
    `duration`          INT UNSIGNED DEFAULT NULL,
    `disk`              ENUM('local','s3','gcs','azure') NOT NULL DEFAULT 'local',
    `visibility`        ENUM('public','private','signed') NOT NULL DEFAULT 'private',
    `metadata`          JSON DEFAULT NULL,
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_user` (`user_id`),
    INDEX `idx_mime` (`mime_type`),
    INDEX `idx_disk` (`disk`),
    INDEX `idx_checksum` (`checksum`),
    CONSTRAINT `fk_media_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
