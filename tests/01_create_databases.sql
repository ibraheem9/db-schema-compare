-- ============================================================================
-- STEP 1: Create the two test databases
-- ============================================================================
-- Run this file FIRST to create both empty databases.
--
-- Usage:
--   mysql -u root -p < 01_create_databases.sql
-- ============================================================================

DROP DATABASE IF EXISTS `test_db_a`;
CREATE DATABASE `test_db_a` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

DROP DATABASE IF EXISTS `test_db_b`;
CREATE DATABASE `test_db_b` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
