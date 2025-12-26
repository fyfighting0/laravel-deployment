<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class LogRequests
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $startTime = microtime(true);
        
        $response = $next($request);
        
        $duration = round((microtime(true) - $startTime) * 1000, 2);
        
        // 获取 X-Amzn-Trace-Id
        $traceId = $request->header('X-Amzn-Trace-Id', 'N/A');
        
        // 构建 JSON 格式的日志
        $logData = [
            'time' => now()->toIso8601String(),
            'method' => $request->method(),
            'uri' => $request->fullUrl(),
            'path' => $request->path(),
            'status' => $response->getStatusCode(),
            'response_time_ms' => $duration,
            'memory_usage_mb' => round(memory_get_usage(true) / 1024 / 1024, 2),
            'x_amzn_trace_id' => $traceId,
            'ip' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ];
        
        // 记录到 CloudWatch（通过标准输出，由 CloudWatch Logs Agent 收集）
        Log::channel('cloudwatch')->info('HTTP Request', $logData);
        
        return $response;
    }
}

