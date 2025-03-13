<?php
session_start();
if (!isset($_SESSION['admin_token'])) {
    header("Location: login.php");
    exit();
}

// Fetch users from FastAPI
$curl = curl_init();
curl_setopt_array($curl, [
    CURLOPT_URL => 'http://localhost:8000/admin/users',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . $_SESSION['admin_token']
    ]
]);

$response = curl_exec($curl);
$users = json_decode($response, true);
curl_close($curl);

$error = null;
if ($users === null) {
    $error = "Error fetching users";
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>User Management</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <div class="dashboard-container">
        <div class="sidebar">
            <h2>Admin Panel</h2>
            <nav>
                <a href="dashboard.php">Dashboard</a>
                <a href="users.php" class="active">Users</a>
                <a href="artworks.php">Artworks</a>
                <a href="categories.php">Categories</a>
                <a href="logout.php">Logout</a>
            </nav>
        </div>
        
        <div class="main-content">
            <div class="header">
                <h1>User Management</h1>
                <?php if ($error): ?>
                    <div class="error-message"><?= htmlspecialchars($error) ?></div>
                <?php endif; ?>
            </div>

            <?php if (!$error): ?>
            <table class="data-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Username</th>
                        <th>Email</th>
                        <th>Role</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($users as $user): ?>
                    <tr>
                        <td><?= htmlspecialchars($user['id']) ?></td>
                        <td><?= htmlspecialchars($user['username']) ?></td>
                        <td><?= htmlspecialchars($user['email']) ?></td>
                        <td><?= htmlspecialchars($user['role']) ?></td>
                        <td><?= htmlspecialchars($user['status']) ?></td>
                        <td>
                            <?php if ($user['status'] === 'banned'): ?>
                                <button class="unban-button" onclick="unbanUser(<?= $user['id'] ?>)">Unban</button>
                            <?php else: ?>
                                <button class="ban-button" onclick="banUser(<?= $user['id'] ?>)">Ban</button>
                            <?php endif; ?>
                            <button class="delete-button" onclick="deleteUser(<?= $user['id'] ?>)">Delete</button>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
            <?php endif; ?>
        </div>
    </div>

    <script>
    function banUser(id) {
        const reason = prompt('Enter ban reason:');
        if (reason) {
            fetch(`http://localhost:8000/admin/users/${id}/ban`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer <?= $_SESSION['admin_token'] ?>'
                },
                body: JSON.stringify({ reason: reason })
            }).then(async response => {
                if (response.ok) {
                    window.location.reload();
                } else {
                    const error = await response.json();
                    alert('Error banning user: ' + error.detail);
                }
            }).catch(error => {
                console.error('Error:', error);
                alert('Error banning user');
            });
        }
    }

    function unbanUser(id) {
        if (confirm('Are you sure you want to unban this user?')) {
            fetch(`http://localhost:8000/admin/users/${id}/unban`, {
                method: 'PUT',
                headers: {
                    'Authorization': 'Bearer <?= $_SESSION['admin_token'] ?>'
                }
            }).then(response => {
                if (response.ok) {
                    window.location.reload();
                } else {
                    alert('Error unbanning user');
                }
            }).catch(error => {
                console.error('Error:', error);
                alert('Error unbanning user');
            });
        }
    }

    function deleteUser(id) {
        if (confirm('Are you sure you want to delete this user?')) {
            fetch(`http://localhost:8000/admin/users/${id}`, {
                method: 'DELETE',
                headers: {
                    'Authorization': 'Bearer <?= $_SESSION['admin_token'] ?>'
                }
            }).then(response => {
                if (response.ok) {
                    window.location.reload();
                } else {
                    alert('Error deleting user');
                }
            }).catch(error => {
                console.error('Error:', error);
                alert('Error deleting user');
            });
        }
    }
    </script>
</body>
</html> 