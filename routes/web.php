<?php

use Illuminate\Support\Facades\Route;

// 发送500测试用
Route::get('/test-error', function () {
    abort(500, 'Test 500 Error');
});

Route::get('/', function () {
    // 打印特定的环境变量（例如 APP_NAME 或自定义的）
    $envVar = env('DISPLAY_ENV_VAR', env('APP_NAME', 'Laravel'));
    
    return response()->json([
        'message' => 'Laravel 11 Application on ECS Fargate',
        'environment_variable' => $envVar,
        'php_version' => PHP_VERSION,
        'timestamp' => now()->toIso8601String(),
    ]);
});

