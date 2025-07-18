<?php

namespace Tests;

use App\HealthCheck;
use PHPUnit\Framework\TestCase;

class HealthCheckTest extends TestCase
{
    private HealthCheck $healthCheck;

    protected function setUp(): void
    {
        $this->healthCheck = new HealthCheck();
    }

    public function testRunChecksReturnsExpectedKeys(): void
    {
        $result = $this->healthCheck->runChecks();

        $this->assertArrayHasKey('status', $result);
        $this->assertArrayHasKey('checks', $result);
        $this->assertArrayHasKey('probe', $result);
        $this->assertArrayHasKey('timestamp', $result);
    }

    public function testRunChecksIncludesProbeType(): void
    {
        $probeType = 'liveness';
        $result = $this->healthCheck->runChecks($probeType);

        $this->assertEquals($probeType, $result['probe']);
    }

    public function testRunChecksIncludesBasicChecks(): void
    {
        $result = $this->healthCheck->runChecks();

        $this->assertArrayHasKey('php', $result['checks']);
        $this->assertArrayHasKey('disk_space', $result['checks']);
        $this->assertArrayHasKey('memory', $result['checks']);
    }
}
