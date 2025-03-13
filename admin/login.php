<!DOCTYPE html>
<html>
<head>
    <title>Admin Login</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <div class="login-container">
        <form action="auth.php" method="POST" class="login-form">
            <h2>Admin Login</h2>
            <?php if (isset($_GET['error'])) { ?>
                <div class="error"><?php echo $_GET['error']; ?></div>
            <?php } ?>
            <div class="form-group">
                <label>Email</label>
                <input type="email" name="email" required>
            </div>
            <div class="form-group">
                <label>Password</label>
                <input type="password" name="password" required>
            </div>
            <button type="submit">Login</button>
        </form>
    </div>
</body>
</html> 