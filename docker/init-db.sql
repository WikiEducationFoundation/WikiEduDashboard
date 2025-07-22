CREATE DATABASE dashboard DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE dashboard_testing DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE USER 'wiki'@'%' IDENTIFIED BY 'wikiedu';
GRANT ALL PRIVILEGES ON dashboard . * TO 'wiki'@'%';
GRANT ALL PRIVILEGES ON dashboard_testing . * TO 'wiki'@'%';