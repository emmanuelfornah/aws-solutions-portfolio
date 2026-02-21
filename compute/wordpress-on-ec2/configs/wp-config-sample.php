<?php
/**
 * WordPress Configuration File - Sample Template
 * 
 * This file contains the database configuration and WordPress settings.
 * Copy this file to wp-config.php and update with your actual credentials.
 * 
 * SECURITY WARNING: This file contains sensitive credentials.
 * Ensure proper file permissions (600) and never commit to version control.
 */

// ** Database Settings ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'wordpress_db' );

/** Database username */
define( 'DB_USER', 'wordpress_user' );

/** Database password */
define( 'DB_PASSWORD', 'wordpress_password_change_me' );

/** Database hostname (use 'localhost' for same-server database) */
define( 'DB_HOST', 'localhost' );

/** Database charset to use in creating database tables */
define( 'DB_CHARSET', 'utf8mb4' );

/** The database collate type (leave blank for default) */
define( 'DB_COLLATE', '' );

/**
 * Authentication Unique Keys and Salts
 * 
 * Generate unique keys using: https://api.wordpress.org/secret-key/1.1/salt/
 * These should be changed to random, unique values for security.
 */
define('AUTH_KEY',         'put your unique phrase here');
define('SECURE_AUTH_KEY',  'put your unique phrase here');
define('LOGGED_IN_KEY',    'put your unique phrase here');
define('NONCE_KEY',        'put your unique phrase here');
define('AUTH_SALT',        'put your unique phrase here');
define('SECURE_AUTH_SALT', 'put your unique phrase here');
define('LOGGED_IN_SALT',   'put your unique phrase here');
define('NONCE_SALT',       'put your unique phrase here');

/**
 * WordPress Database Table Prefix
 * 
 * Change this to use a different prefix for your database tables.
 * Using a non-default prefix adds a small layer of security.
 */
$table_prefix = 'wp_';

/**
 * WordPress Debugging Mode
 * 
 * Enable WP_DEBUG for development environments to see errors and warnings.
 * Disable in production to prevent information disclosure.
 */
define( 'WP_DEBUG', false );
define( 'WP_DEBUG_LOG', false );
define( 'WP_DEBUG_DISPLAY', false );

/**
 * WordPress Memory Limits
 * 
 * Increase memory limits for better performance with plugins and themes.
 */
define( 'WP_MEMORY_LIMIT', '256M' );
define( 'WP_MAX_MEMORY_LIMIT', '512M' );

/**
 * WordPress Auto-Updates
 * 
 * Control automatic updates for WordPress core.
 * Options: true (all updates), false (no updates), 'minor' (security updates only)
 */
define( 'WP_AUTO_UPDATE_CORE', 'minor' );

/**
 * WordPress File System Method
 * 
 * Force direct file system access for plugin/theme installation.
 * Only use if file permissions are properly configured.
 */
// define( 'FS_METHOD', 'direct' );

/**
 * WordPress Site URLs
 * 
 * Uncomment and set these if you need to override the site URL.
 * Useful when moving WordPress or using a load balancer.
 */
// define( 'WP_HOME', 'https://your-domain.com' );
// define( 'WP_SITEURL', 'https://your-domain.com' );

/**
 * Force SSL for Admin and Login
 * 
 * Uncomment to force HTTPS for admin area and login pages.
 */
// define( 'FORCE_SSL_ADMIN', true );

/**
 * Disable File Editing
 * 
 * Uncomment to disable the plugin and theme file editor in WordPress admin.
 * Recommended for production environments.
 */
// define( 'DISALLOW_FILE_EDIT', true );

/**
 * WordPress Post Revisions
 * 
 * Limit the number of post revisions to save database space.
 */
// define( 'WP_POST_REVISIONS', 5 );

/**
 * WordPress Trash Auto-Empty
 * 
 * Number of days before WordPress permanently deletes trashed items.
 */
// define( 'EMPTY_TRASH_DAYS', 30 );

/**
 * WordPress Cron
 * 
 * Disable WordPress cron if using system cron for better performance.
 */
// define( 'DISABLE_WP_CRON', true );

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
