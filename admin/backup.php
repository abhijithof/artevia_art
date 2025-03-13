<?php
session_start();
if (!isset($_SESSION['admin_token'])) {
    header("Location: login.php");
    exit();
}

// Fetch backup history
$curl = curl_init();
curl_setopt_array($curl, [
    CURLOPT_URL => 'http://localhost:8000/admin/backups',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . $_SESSION['admin_token']
    ]
]);

$response = curl_exec($curl);
$backups = json_decode($response, true);
curl_close($curl);
?>

<!DOCTYPE html>
<html>
<head>
    <title>Backup Management</title>
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
                <a href="backup.php" class="active">Backups</a>
                <a href="logout.php">Logout</a>
            </nav>
        </div>
        
        <div class="main-content">
            <div class="header">
                <h1>Backup Management</h1>
                <button onclick="createBackup()" class="add-button">Create New Backup</button>
            </div>

            <div class="backup-container">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Date</th>
                            <th>Size</th>
                            <th>Type</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($backups as $backup): ?>
                        <tr>
                            <td><?= htmlspecialchars($backup['created_at']) ?></td>
                            <td><?= htmlspecialchars($backup['size']) ?></td>
                            <td><?= htmlspecialchars($backup['type']) ?></td>
                            <td>
                                <span class="status-badge <?= $backup['status'] ?>">
                                    <?= htmlspecialchars($backup['status']) ?>
                                </span>
                            </td>
                            <td>
                                <button onclick="downloadBackup('<?= $backup['id'] ?>')" class="download-button">Download</button>
                                <button onclick="deleteBackup('<?= $backup['id'] ?>')" class="delete-button">Delete</button>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <script>
    async function createBackup() {
        if (confirm('Create a new backup? This might take a few minutes.')) {
            try {
                const response = await fetch('http://localhost:8000/admin/backups', {
                    method: 'POST',
                    headers: {
                        'Authorization': 'Bearer <?= $_SESSION['admin_token'] ?>'
                    }
                });

                if (response.ok) {
                    alert('Backup started successfully!');
                    window.location.reload();
                }
            } catch (error) {
                console.error('Error:', error);
                alert('Failed to create backup');
            }
        }
    }

    function downloadBackup(id) {
        window.location.href = `http://localhost:8000/admin/backups/${id}/download`;
    }

    async function deleteBackup(id) {
        if (confirm('Are you sure you want to delete this backup?')) {
            try {
                const response = await fetch(`http://localhost:8000/admin/backups/${id}`, {
                    method: 'DELETE',
                    headers: {
                        'Authorization': 'Bearer <?= $_SESSION['admin_token'] ?>'
                    }
                });

                if (response.ok) {
                    window.location.reload();
                }
            } catch (error) {
                console.error('Error:', error);
                alert('Failed to delete backup');
            }
        }
    }
    </script>
</body>
</html> 