<?php
session_start();

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $email = $_POST['email'];
    $password = $_POST['password'];
    
    // Call FastAPI backend
    $curl = curl_init();
    curl_setopt_array($curl, [
        CURLOPT_URL => 'http://localhost:8000/auth/admin/login',
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => http_build_query([
            'username' => $email,
            'password' => $password,
        ])
    ]);
    
    $response = curl_exec($curl);
    $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
    curl_close($curl);
    
    if ($httpCode === 200) {
        $data = json_decode($response, true);
        if ($data['role'] !== 'admin') {
            header("Location: login.php?error=Not authorized. Admin access only.");
            exit();
        }
        $_SESSION['admin_token'] = $data['access_token'];
        header("Location: dashboard.php");
        exit();
    } else {
        header("Location: login.php?error=Invalid credentials");
        exit();
    }
}
?> 