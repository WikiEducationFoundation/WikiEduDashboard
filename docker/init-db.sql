CREATE DATABASE dashboard DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci;
CREATE DATABASE dashboard_testing DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci;
CREATE USER 'wiki'@'%' IDENTIFIED BY 'wikiedu';
-- The `dashboard%` pattern also covers the numbered test databases
-- (dashboard_testing2, ...) that parallel_tests creates from TEST_ENV_NUMBER.
GRANT ALL PRIVILEGES ON `dashboard%`.* TO 'wiki'@'%';
