<?php
session_start();
require_once 'utils/api.php';

checkAuth();
?>

<!DOCTYPE html>
<html>
<head>
    <title>Activity Logs</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <div class="dashboard-container">
        <div class="sidebar">
            <h2>Admin Panel</h2>
            <nav>
                <a href="dashboard.php">Dashboard</a>
                <a href="users.php">Users</a>
                <a href="artworks.php">Artworks</a>
                <a href="categories.php">Categories</a>
                <a href="activity.php" class="active">Activity Logs</a>
                <a href="logout.php">Logout</a>
            </nav>
        </div>
        
        <div class="main-content">
            <h1>Activity Logs</h1>
            <p>Activity logging is currently disabled.</p>
        </div>
    </div>
</body>
</html> 