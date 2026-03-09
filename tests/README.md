# Test Databases for DB Compare

These SQL files create two test databases designed to exercise **every feature** of the DB Compare tool. They are split into three steps to avoid dependency errors.

## Quick Start

Run the files in order. Each step depends on the previous one.

```bash
# Step 1: Create both empty databases
mysql -u root -p < 01_create_databases.sql

# Step 2: Create tables inside test_db_a
mysql -u root -p test_db_a < 02_tables_db_a.sql

# Step 3: Create tables inside test_db_b
mysql -u root -p test_db_b < 03_tables_db_b.sql
```

Then open DB Compare and compare `test_db_a` against `test_db_b`.

## File Structure

| File | Purpose |
|---|---|
| `01_create_databases.sql` | Creates (or recreates) the two empty databases |
| `02_tables_db_a.sql` | Creates all 14 tables inside `test_db_a` in FK dependency order |
| `03_tables_db_b.sql` | Creates all 13 tables inside `test_db_b` in FK dependency order |

Tables within each file are ordered so that referenced tables are created before the tables that reference them. This prevents `Failed to open the referenced table` errors.

## Difference Coverage Matrix

The table below summarizes every type of schema difference covered by these test databases.

| Feature Category | Difference Type | Where It Occurs |
|---|---|---|
| **Missing Tables** | Tables only in Database A | `tags`, `product_tags`, `settings` |
| **Missing Tables** | Tables only in Database B | `coupons`, `wishlists` |
| **Column Diffs** | Column missing in B | `users.phone`, `users.avatar_url`, `users.bio`, `products.weight`, etc. |
| **Column Diffs** | Column missing in A | `users.timezone`, `users.language`, `products.brand`, `products.color`, etc. |
| **Column Diffs** | Data type change | `users.email` (VARCHAR 150 vs 100), `products.price` (DECIMAL 12,2 vs 10,2), `all_data_types.decimal_val`, `all_data_types.char_val`, `all_data_types.varchar_val` |
| **Column Diffs** | ENUM value change | `users.role`, `users.status`, `products.status`, `orders.status`, `all_data_types.status` |
| **Column Diffs** | SET value change | `all_data_types.tags` |
| **Column Diffs** | Nullable change | `all_data_types.tiny_val`, `reviews.title`, `categories.description` |
| **Column Diffs** | Default value change | `users.login_count` (0 vs 1), `reviews.title` (NULL vs '') |
| **Index Diffs** | Index missing in B | `users.idx_name`, `users.idx_premium_status`, `products.idx_price`, `products.idx_featured`, etc. |
| **Index Diffs** | Index missing in A | `users.idx_language`, `products.idx_brand`, `products.idx_rating`, `orders.idx_tracking`, etc. |
| **Index Diffs** | Unique key missing in B | `reviews.uk_user_product` |
| **FK Diffs** | FK missing in B | `categories.fk_category_parent`, `product_images.fk_image_product`, `order_items.fk_item_product`, `audit_logs.fk_audit_user`, `notifications.fk_notification_user`, `media_files.fk_media_user` |
| **FK Diffs** | FK missing in A | (covered by B-only tables `wishlists` with FKs) |

## Data Types Covered

Database A's `all_data_types` table includes columns for every major MySQL data type category.

| Category | Types Included |
|---|---|
| Integer | TINYINT, SMALLINT, MEDIUMINT, INT, BIGINT, BIGINT UNSIGNED |
| Decimal | DECIMAL, FLOAT, DOUBLE |
| String | CHAR, VARCHAR, TINYTEXT, TEXT, MEDIUMTEXT, LONGTEXT |
| Binary | BINARY, VARBINARY, TINYBLOB, BLOB, MEDIUMBLOB, LONGBLOB |
| Date/Time | DATE, DATETIME, TIMESTAMP, TIME, YEAR |
| Enum/Set | ENUM, SET |
| JSON | JSON |
| Boolean | BOOLEAN (TINYINT(1)) |
| Bit | BIT(8) |

## Table Count Summary

| | Database A | Database B |
|---|---|---|
| Total tables | 14 | 13 |
| Common tables | 11 | 11 |
| Unique tables | 3 (`tags`, `product_tags`, `settings`) | 2 (`coupons`, `wishlists`) |
