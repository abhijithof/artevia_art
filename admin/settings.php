<?php
session_start();
if (!isset($_SESSION['admin_token'])) {
    header("Location: login.php");
    exit();
}

// Fetch current settings
$curl = curl_init();
curl_setopt_array($curl, [
    CURLOPT_URL => 'http://localhost:8000/admin/settings',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . $_SESSION['admin_token']
    ]
]);

$response = curl_exec($curl);
$settings = json_decode($response, true);
curl_close($curl);
?>

<!DOCTYPE html>
<html>
<head>
    <title>Admin Settings</title>
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
                <a href="activity.php">Activity Logs</a>
                <a href="settings.php" class="active">Settings</a>
                <a href="logout.php">Logout</a>
            </nav>
        </div>
        
        <div class="main-content">
            <div class="header">
                <h1>System Settings</h1>
            </div>

            <div class="settings-grid">
                <div class="settings-card">
                    <h3>General Settings</h3>
                    <form onsubmit="saveGeneralSettings(event)">
                        <div class="form-group">
                            <label>Site Name</label>
                            <input type="text" name="site_name" value="<?= htmlspecialchars($settings['site_name']) ?>">
                        </div>
                        <div class="form-group">
                            <label>Items Per Page</label>
                            <input type="number" name="items_per_page" value="<?= $settings['items_per_page'] ?>">
                        </div>
                        <div class="form-group">
                            <label>Enable User Registration</label>
                            <input type="checkbox" name="enable_registration" <?= $settings['enable_registration'] ? 'checked' : '' ?>>
                        </div>
                        <button type="submit" class="save-button">Save Changes</button>
                    </form>
                </div>

                <div class="settings-card">
                    <h3>Email Settings</h3>
                    <form onsubmit="saveEmailSettings(event)">
                        <div class="form-group">
                            <label>SMTP Host</label>
                            <input type="text" name="smtp_host" value="<?= htmlspecialchars($settings['smtp_host']) ?>">
                        </div>
                        <div class="form-group">
                            <label>SMTP Port</label>
                            <input type="number" name="smtp_port" value="<?= $settings['smtp_port'] ?>">
                        </div>
                        <div class="form-group">
                            <label>Email From</label>
                            <input type="email" name="email_from" value="<?= htmlspecialchars($settings['email_from']) ?>">
                        </div>
                        <button type="submit" class="save-button">Save Changes</button>
                    </form>
                </div>

                <div class="settings-card">
                    <h3>Security Settings</h3>
                    <form onsubmit="saveSecuritySettings(event)">
                        <div class="form-group">
                            <label>Maximum Login Attempts</label>
                            <input type="number" name="max_login_attempts" value="<?= $settings['max_login_attempts'] ?>">
                        </div>
                        <div class="form-group">
                            <label>Password Expiry Days</label>
                            <input type="number" name="password_expiry_days" value="<?= $settings['password_expiry_days'] ?>">
                        </div>
                        <div class="form-group">
                            <label>Enable Two-Factor Auth</label>
                            <input type="checkbox" name="enable_2fa" <?= $settings['enable_2fa'] ? 'checked' : '' ?>>
                        </div>
                        <button type="submit" class="save-button">Save Changes</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <script>
    async function saveGeneralSettings(event) {
        event.preventDefault();
        const form = event.target;
        const data = {
            site_name: form.site_name.value,
            items_per_page: parseInt(form.items_per_page.value),
            enable_registration: form.enable_registration.checked
        };
        await saveSettings('general', data);
    }

    async function saveEmailSettings(event) {
        event.preventDefault();
        const form = event.target;
        const data = {
            smtp_host: form.smtp_host.value,
            smtp_port: parseInt(form.smtp_port.value),
            email_from: form.email_from.value
        };
        await saveSettings('email', data);
    }

    async function saveSecuritySettings(event) {
        event.preventDefault();
        const form = event.target;
        const data = {
            max_login_attempts: parseInt(form.max_login_attempts.value),
            password_expiry_days: parseInt(form.password_expiry_days.value),
            enable_2fa: form.enable_2fa.checked
        };
        await saveSettings('security', data);
    }

    async function saveSettings(type, data) {
        try {
            const response = await fetch(`http://localhost:8000/admin/settings/${type}`, {
                method: 'POST',
                headers: {
                    'Authorization': 'Bearer <?= $_SESSION['admin_token'] ?>',
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(data)
            });

            if (response.ok) {
                alert('Settings saved successfully!');
            } else {
                alert('Failed to save settings');
            }
        } catch (error) {
            console.error('Error:', error);
            alert('An error occurred');
        }
    }
    </script>
</body>
</html> 