<?php
$host = 'localhost';
$dbname = 'admin_panel';
$username = 'root';     // Change this to your MySQL username
$password = '';         // Change this to your MySQL password

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    echo "Connection failed: " . $e->getMessage();
    exit();
}
?> 