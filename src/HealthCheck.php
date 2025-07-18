<?php

namespace App;

class HealthCheck
{
    private const MIN_DISK_SPACE_MB = 50;
    private const MAX_MEMORY_USAGE_MB = 100;
    private const DB_CONNECTION_TIMEOUT = 3;

    private array $checks = [];

    /**
     * Run all health checks
     * 
     * @param string $probeType The type of probe (liveness, readiness, or general)
     * @return array Results and status
     */
    public function runChecks(string $probeType = 'general'): array
    {
        $this->checks = $this->performBasicHealthChecks();

        // Add database check if enabled
        if (getenv('ENABLE_DB_CHECK') === 'true') {
            $this->checks['database'] = $this->performDatabaseHealthCheck();
        }

        // Determine overall status
        $status = 'healthy';
        $statusCode = 200;

        if (in_array(false, $this->checks, true)) {
            $status = 'unhealthy';
            $statusCode = 503;
        }

        return [
            'status' => $status,
            'statusCode' => $statusCode,
            'probe' => $probeType,
            'checks' => $this->checks,
            'timestamp' => date('c')
        ];
    }

    /**
     * Performs basic system health checks
     * @return array
     */
    private function performBasicHealthChecks(): array
    {
        return [
            'php' => true,
            'disk_space' => (disk_free_space('/tmp') > self::MIN_DISK_SPACE_MB * 1024 * 1024),
            'memory' => (memory_get_usage() < self::MAX_MEMORY_USAGE_MB * 1024 * 1024)
        ];
    }

    /**
     * Performs database health check
     * @return bool
     */
    private function performDatabaseHealthCheck(): bool
    {
        if (!extension_loaded('pdo_mysql')) {
            return false;
        }

        try {
            $host = getenv('DB_HOST') ?: 'localhost';
            $dbname = getenv('DB_NAME') ?: 'php_web_service';
            $username = getenv('DB_USERNAME') ?: 'user';
            $password = getenv('DB_PASSWORD') ?: 'password';

            $db = new \PDO(
                "mysql:host={$host};dbname={$dbname};charset=utf8mb4",
                $username,
                $password,
                [
                    \PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION,
                    \PDO::ATTR_TIMEOUT => self::DB_CONNECTION_TIMEOUT
                ]
            );

            $stmt = $db->query('SELECT 1');
            $result = $stmt !== false;
            $db = null; // Clean up connection

            return $result;
        } catch (\PDOException $e) {
            error_log("Database health check failed: " . $e->getMessage());
            return false;
        }
    }
}
