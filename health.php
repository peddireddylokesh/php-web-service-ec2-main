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
<?php
/**
 * Health check endpoint for Kubernetes probes
 */

// Basic service health check
$status = ['status' => 'ok', 'timestamp' => time()];

// Check database connection if needed
$checkDb = false;
if (isset($_GET['check_db']) && $_GET['check_db'] === 'true') {
    $checkDb = true;
}

if ($checkDb) {
    try {
        $host = getenv('DB_HOST') ?: 'mysql-service.database-namespace.svc.cluster.local';
        $dbname = getenv('DB_NAME') ?: 'php_web_service';
        $username = getenv('DB_USER') ?: 'php_user';
        $password = getenv('DB_PASSWORD') ?: 'php_password';

        $dsn = "mysql:host=$host;dbname=$dbname";
        $options = [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ];

        $pdo = new PDO($dsn, $username, $password, $options);
        $stmt = $pdo->query('SELECT 1');

        $status['database'] = 'connected';
    } catch (PDOException $e) {
        $status = [
            'status' => 'error',
            'message' => 'Database connection failed',
            'error' => $e->getMessage(),
            'timestamp' => time()
        ];
        http_response_code(500);
    }
}

// Set appropriate headers
header('Content-Type: application/json');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');

// Output response
echo json_encode($status);
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