-- Bootstrap script for the MySQL container.
--
-- This file only provisions databases and grants. Table structure and seed data
-- are owned exclusively by Rails (`db/migrate/*` and `db/seeds.rb`); defining
-- them here as well produced a schema that silently diverged from schema.rb.

CREATE DATABASE IF NOT EXISTS expense_system_development
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- The MySQL image only grants MYSQL_USER rights on MYSQL_DATABASE, so the test
-- database has to be created and granted explicitly for `bundle exec rspec`.
CREATE DATABASE IF NOT EXISTS expense_system_test
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

GRANT ALL PRIVILEGES ON expense_system_development.* TO 'expense_user'@'%';
GRANT ALL PRIVILEGES ON expense_system_test.* TO 'expense_user'@'%';

FLUSH PRIVILEGES;
