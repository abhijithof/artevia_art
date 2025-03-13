<?php
require_once __DIR__ . '/../config/config.php';

function makeApiRequest($endpoint, $method = 'GET', $data = null, $token = null) {
    $config = require(__DIR__ . '/../config/config.php');
    $curl = curl_init();
    
    // Ensure endpoint starts with '/'
    $endpoint = '/' . ltrim($endpoint, '/');
    $url = $config['api_url'] . $endpoint;
    
    error_log("Making API request to: " . $url);
    
    $headers = ['Accept: application/json'];
    if ($token) {
        $headers[] = 'Authorization: Bearer ' . $token;
        error_log("Using token: " . substr($token, 0, 10) . "...");
    }
    
    $options = [
        CURLOPT_URL => $url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_VERBOSE => true
    ];
    
    if ($method === 'POST' || $method === 'PUT' || $method === 'DELETE') {
        $options[CURLOPT_CUSTOMREQUEST] = $method;
        if ($data) {
            $options[CURLOPT_POSTFIELDS] = json_encode($data);
            $headers[] = 'Content-Type: application/json';
        }
    }
    
    curl_setopt_array($curl, $options);
    
    $response = curl_exec($curl);
    $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
    
    error_log("API Response Code: " . $httpCode);
    error_log("API Response: " . $response);
    
    if (curl_errno($curl)) {
        $error = curl_error($curl);
        error_log("Curl error: " . $error);
        throw new Exception($error);
    }
    
    curl_close($curl);
    
    if ($httpCode >= 400) {
        $error = json_decode($response, true);
        $errorMsg = $error['detail'] ?? 'API request failed';
        error_log("API error: " . $errorMsg);
        throw new Exception($errorMsg);
    }
    
    $decoded = json_decode($response, true);
    if ($decoded === null) {
        error_log("JSON decode error: " . json_last_error_msg());
        throw new Exception("Invalid JSON response");
    }
    
    return $decoded;
}

function checkAuth() {
    if (!isset($_SESSION['admin_token'])) {
        header("Location: login.php");
        exit();
    }
} 