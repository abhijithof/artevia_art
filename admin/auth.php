<?php
session_start();
require_once 'utils/api.php';

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    try {
        $response = makeApiRequest('/admin/login', 'POST', [
            'username' => $_POST['email'],
            'password' => $_POST['password'],
            'grant_type' => 'password'
        ]);
        
        $_SESSION['admin_token'] = $response['access_token'];
        $_SESSION['admin_user'] = $response['user'];
        header("Location: dashboard.php");
        exit();
    } catch (Exception $e) {
        header("Location: login.php?error=" . urlencode($e->getMessage()));
        exit();
    }
}
?> 