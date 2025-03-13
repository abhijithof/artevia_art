<?php
session_start();
require_once 'utils/api.php';

checkAuth();

try {
    error_log("Making request to admin stats endpoint");
    $stats = makeApiRequest('/admin/stats', 'GET', null, $_SESSION['admin_token']);
    error_log("Stats response: " . print_r($stats, true));
} catch (Exception $e) {
    error_log("Dashboard stats error: " . $e->getMessage());
    $error = $e->getMessage();
    $stats = [
        'total_users' => 0,
        'active_artists' => 0,
        'total_artworks' => 0,
        'total_categories' => 0,
        'activity_labels' => [],
        'new_users_data' => [],
        'category_labels' => [],
        'category_data' => []
    ];
}

// Ensure all stats exist with default values
$stats = array_merge([
    'total_users' => 0,
    'active_artists' => 0,
    'total_artworks' => 0,
    'total_categories' => 0,
    'activity_labels' => [],
    'new_users_data' => [],
    'category_labels' => [],
    'category_data' => []
], $stats ?? []);
?>

<!DOCTYPE html>
<html>
<head>
    <title>Admin Dashboard</title>
    <link rel="stylesheet" href="css/style.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="dashboard-container">
        <div class="sidebar">
            <h2>Admin Panel</h2>
            <nav>
                <a href="dashboard.php" class="active">Dashboard</a>
                <a href="users.php">Users</a>
                <a href="artworks.php">Artworks</a>
                <a href="categories.php">Categories</a>
                <a href="logout.php">Logout</a>
            </nav>
        </div>
        
        <div class="main-content">
            <div class="header">
                <h1>Dashboard Overview</h1>
            </div>

            <div class="stats-grid">
                <div class="stat-card">
                    <h3>Total Users</h3>
                    <p><?= htmlspecialchars($stats['total_users']) ?></p>
                </div>
                <div class="stat-card">
                    <h3>Active Artists</h3>
                    <p><?= htmlspecialchars($stats['active_artists']) ?></p>
                </div>
                <div class="stat-card">
                    <h3>Total Artworks</h3>
                    <p><?= htmlspecialchars($stats['total_artworks']) ?></p>
                </div>
                <div class="stat-card">
                    <h3>Categories</h3>
                    <p><?= htmlspecialchars($stats['total_categories']) ?></p>
                </div>
            </div>

            <div class="charts-container">
                <div class="chart-card">
                    <h3>User Activity</h3>
                    <canvas id="userActivityChart"></canvas>
                </div>
                <div class="chart-card">
                    <h3>Artwork Categories</h3>
                    <canvas id="categoryChart"></canvas>
                </div>
            </div>
        </div>
    </div>

    <script>
    document.addEventListener('DOMContentLoaded', function() {
        // User Activity Chart
        const activityCtx = document.getElementById('userActivityChart').getContext('2d');
        new Chart(activityCtx, {
            type: 'line',
            data: {
                labels: <?= json_encode($stats['activity_labels']) ?>,
                datasets: [{
                    label: 'New Users',
                    data: <?= json_encode($stats['new_users_data']) ?>,
                    borderColor: '#4CAF50',
                    tension: 0.1,
                    fill: false
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            stepSize: 1
                        }
                    }
                }
            }
        });

        // Category Chart
        const categoryCtx = document.getElementById('categoryChart').getContext('2d');
        if (<?= json_encode(!empty($stats['category_labels'])) ?>) {
            new Chart(categoryCtx, {
                type: 'pie',
                data: {
                    labels: <?= json_encode($stats['category_labels']) ?>,
                    datasets: [{
                        data: <?= json_encode($stats['category_data']) ?>,
                        backgroundColor: [
                            '#FF6384', '#36A2EB', '#FFCE56', 
                            '#4BC0C0', '#9966FF', '#FF9F40'
                        ]
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        legend: {
                            position: 'right'
                        }
                    }
                }
            });
        }
    });
    </script>
</body>
</html> 