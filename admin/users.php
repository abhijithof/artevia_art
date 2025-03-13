<?php
session_start();
require_once 'utils/api.php';

checkAuth();

try {
    $users = makeApiRequest('/admin/users', 'GET', null, $_SESSION['admin_token']);
} catch (Exception $e) {
    $error = $e->getMessage();
    $users = [];
}

// Add user management functions
function banUser($userId) {
    try {
        return makeApiRequest("/admin/users/{$userId}/ban", 'PUT', null, $_SESSION['admin_token']);
    } catch (Exception $e) {
        return ['error' => $e->getMessage()];
    }
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
                <?php if (isset($error)): ?>
                    <div class="error-message"><?= htmlspecialchars($error) ?></div>
                <?php endif; ?>
            </div>

            <?php if (!empty($users)): ?>
            <table class="data-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Username</th>
                        <th>Email</th>
                        <th>Role</th>
                        <th>Status</th>
                        <th>Artworks</th>
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
                        <td><?= htmlspecialchars($user['artwork_count'] ?? 0) ?></td>
                        <td class="actions">
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
        if (!confirm('Are you sure you want to ban this user?')) return;
        
        const reason = prompt('Enter ban reason:');
        if (!reason) return;
        
        fetch(`http://localhost:8000/admin/users/${id}/ban`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer <?= $_SESSION['admin_token'] ?>'
            },
            body: JSON.stringify({ reason: reason })
        })
        .then(response => response.json())
        .then(data => {
            if (data.error) {
                alert(data.error);
            } else {
                window.location.reload();
            }
        })
        .catch(error => {
            console.error('Error:', error);
            alert('Error banning user');
        });
    }

    function unbanUser(id) {
        if (!confirm('Are you sure you want to unban this user?')) return;
        
        fetch(`http://localhost:8000/admin/users/${id}/unban`, {
            method: 'PUT',
            headers: {
                'Authorization': 'Bearer <?= $_SESSION['admin_token'] ?>'
            }
        })
        .then(response => response.json())
        .then(data => {
            if (data.error) {
                alert(data.error);
            } else {
                window.location.reload();
            }
        })
        .catch(error => {
            console.error('Error:', error);
            alert('Error unbanning user');
        });
    }

    function deleteUser(id) {
        if (!confirm('Are you sure you want to delete this user? This action cannot be undone.')) return;
        
        fetch(`http://localhost:8000/admin/users/${id}`, {
            method: 'DELETE',
            headers: {
                'Authorization': 'Bearer <?= $_SESSION['admin_token'] ?>'
            }
        })
        .then(response => response.json())
        .then(data => {
            if (data.error) {
                alert(data.error);
            } else {
                window.location.reload();
            }
        })
        .catch(error => {
            console.error('Error:', error);
            alert('Error deleting user');
        });
    }
    </script>
</body>
</html> 