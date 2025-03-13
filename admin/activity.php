<?php
session_start();
if (!isset($_SESSION['admin_token'])) {
    header("Location: login.php");
    exit();
}

// Fetch activity logs from FastAPI
$curl = curl_init();
curl_setopt_array($curl, [
    CURLOPT_URL => 'http://localhost:8000/admin/activity-logs',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . $_SESSION['admin_token']
    ]
]);

$response = curl_exec($curl);
$logs = json_decode($response, true);
curl_close($curl);
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
            <div class="header">
                <h1>Activity Logs</h1>
                <div class="filter-section">
                    <select id="actionFilter" onchange="filterLogs()">
                        <option value="">All Actions</option>
                        <option value="login">Login</option>
                        <option value="create">Create</option>
                        <option value="update">Update</option>
                        <option value="delete">Delete</option>
                    </select>
                    <input type="date" id="dateFilter" onchange="filterLogs()">
                </div>
            </div>

            <div class="logs-container">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Time</th>
                            <th>User</th>
                            <th>Action</th>
                            <th>Details</th>
                            <th>IP Address</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($logs as $log): ?>
                        <tr class="log-entry" 
                            data-action="<?= $log['action'] ?>" 
                            data-timestamp="<?= $log['timestamp'] ?>">
                            <td><?= htmlspecialchars($log['timestamp']) ?></td>
                            <td><?= htmlspecialchars($log['user_email']) ?></td>
                            <td>
                                <span class="action-badge <?= strtolower($log['action']) ?>">
                                    <?= htmlspecialchars(ucfirst($log['action'])) ?>
                                </span>
                            </td>
                            <td>
                                <span class="log-level <?= strtolower($log['level']) ?>">
                                    <?= $log['level'] ?>
                                </span>
                                <?= htmlspecialchars($log['details']) ?>
                            </td>
                            <td><?= htmlspecialchars($log['ip_address']) ?></td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <style>
    .action-badge {
        padding: 4px 8px;
        border-radius: 4px;
        font-size: 12px;
        font-weight: bold;
    }

    .action-badge.login { background: #4CAF50; color: white; }
    .action-badge.create { background: #2196F3; color: white; }
    .action-badge.update { background: #FF9800; color: white; }
    .action-badge.delete { background: #f44336; color: white; }

    .log-level {
        padding: 2px 6px;
        border-radius: 3px;
        font-size: 11px;
        margin-right: 8px;
    }

    .log-level.info { background: #E3F2FD; color: #1976D2; }
    .log-level.warning { background: #FFF3E0; color: #F57C00; }
    .log-level.error { background: #FFEBEE; color: #D32F2F; }
    </style>

    <script>
    function filterLogs() {
        const actionFilter = document.getElementById('actionFilter').value;
        const dateFilter = document.getElementById('dateFilter').value;
        const logs = document.querySelectorAll('.log-entry');
        
        logs.forEach(log => {
            const action = log.dataset.action;
            const timestamp = log.dataset.timestamp.split(' ')[0]; // Get just the date part
            
            const matchesAction = !actionFilter || action === actionFilter;
            const matchesDate = !dateFilter || timestamp === dateFilter;
            
            log.style.display = matchesAction && matchesDate ? 'table-row' : 'none';
        });
    }

    // Initialize date filter with today's date
    document.addEventListener('DOMContentLoaded', () => {
        const today = new Date().toISOString().split('T')[0];
        document.getElementById('dateFilter').value = today;
    });
    </script>
</body>
</html> 