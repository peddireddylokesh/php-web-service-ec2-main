<?php
// Simple health check endpoint for Kubernetes probes
header('Content-Type: application/json');

// Constants
define('MIN_DISK_SPACE_MB', 50);
define('MAX_MEMORY_USAGE_MB', 100);
define('DB_CONNECTION_TIMEOUT', 3);

/**
 * Performs basic system health checks
 * @return array
 */
function performBasicHealthChecks() {
    return [
        'php' => true,
        'disk_space' => (disk_free_space('/tmp') > MIN_DISK_SPACE_MB * 1024 * 1024),
        'memory' => (memory_get_usage() < MAX_MEMORY_USAGE_MB * 1024 * 1024)
    ];
}

/**
 * Performs database health check
 * @return bool
 */
function performDatabaseHealthCheck() {
    if (!extension_loaded('pdo_mysql')) {
        return false;
    }

    try {
        $host = getenv('DB_HOST') ?: 'localhost';
        $dbname = getenv('DB_NAME') ?: 'php_web_service';
        $username = getenv('DB_USERNAME') ?: 'user';
        $password = getenv('DB_PASSWORD') ?: 'password';

        $db = new PDO(
            "mysql:host={$host};dbname={$dbname};charset=utf8mb4",
            $username,
            $password,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_TIMEOUT => DB_CONNECTION_TIMEOUT
            ]
        );

        $stmt = $db->query('SELECT 1');
        $result = $stmt !== false;
        $db = null; // Clean up connection

        return $result;
    } catch (PDOException $e) {
        error_log("Database health check failed: " . $e->getMessage());
        return false;
    }
}

$status = 'healthy';
$statusCode = 200;

// Get probe type from query parameter
$probeType = isset($_GET['probe']) ? $_GET['probe'] : 'general';

// Perform basic checks
$checks = performBasicHealthChecks();

// Add database check if enabled
if (getenv('ENABLE_DB_CHECK') === 'true') {
    $checks['database'] = performDatabaseHealthCheck();
}

// Determine overall status
if (in_array(false, $checks, true)) {
    $status = 'unhealthy';
    $statusCode = 503;
}

// Return response
http_response_code($statusCode);
echo json_encode([
    'status' => $status,
    'probe' => $probeType,
    'checks' => $checks,
    'timestamp' => date('c')
]);