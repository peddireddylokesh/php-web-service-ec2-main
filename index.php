<?php
// Main entry point for the PHP web service
require_once __DIR__ . '/vendor/autoload.php';

// For now, just display a simple welcome message
header('Content-Type: application/json');
echo json_encode([
    'service' => 'PHP Web Service',
    'status' => 'running',
    'timestamp' => date('c'),
    'version' => '1.0.0',
    'endpoints' => [
        '/health' => 'Health check endpoint for Kubernetes probes',
    ]
]);