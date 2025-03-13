<?php
session_start();
if (!isset($_SESSION['admin_token'])) {
    header("Location: login.php");
    exit();
}

// Fetch stats from FastAPI
$curl = curl_init();
curl_setopt_array($curl, [
    CURLOPT_URL => 'http://localhost:8000/admin/stats',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . $_SESSION['admin_token']
    ]
]);

$response = curl_exec($curl);
$stats = json_decode($response, true);
curl_close($curl);
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
                    <p><?= $stats['total_users'] ?? 0 ?></p>
                </div>
                <div class="stat-card">
                    <h3>Active Artists</h3>
                    <p><?= $stats['active_artists'] ?? 0 ?></p>
                </div>
                <div class="stat-card">
                    <h3>Total Artworks</h3>
                    <p><?= $stats['total_artworks'] ?? 0 ?></p>
                </div>
                <div class="stat-card">
                    <h3>Categories</h3>
                    <p><?= $stats['total_categories'] ?? 0 ?></p>
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
    // User Activity Chart
    const activityLabels = <?= json_encode($stats['activity_labels'] ?? []) ?>;
    const newUsersData = <?= json_encode($stats['new_users_data'] ?? []) ?>;
    
    new Chart(document.getElementById('userActivityChart'), {
        type: 'line',
        data: {
            labels: activityLabels,
            datasets: [{
                label: 'New Users',
                data: newUsersData,
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

    // Category Distribution Chart
    const categoryLabels = <?= json_encode($stats['category_labels'] ?? []) ?>;
    const categoryData = <?= json_encode($stats['category_data'] ?? []) ?>;
    
    if (categoryLabels.length > 0) {
        new Chart(document.getElementById('categoryChart'), {
            type: 'pie',
            data: {
                labels: categoryLabels,
                datasets: [{
                    data: categoryData,
                    backgroundColor: [
                        '#FF6384',
                        '#36A2EB',
                        '#FFCE56',
                        '#4BC0C0',
                        '#9966FF'
                    ]
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'right',
                        display: true
                    }
                }
            }
        });
    } else {
        document.getElementById('categoryChart').parentElement.innerHTML += '<p class="no-data">No categories available</p>';
    }
    </script>
</body>
</html> 