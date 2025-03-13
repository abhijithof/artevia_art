<?php
session_start();
require_once 'utils/api.php';

checkAuth();

try {
    $artworks = makeApiRequest('/admin/artworks', 'GET', null, $_SESSION['admin_token']);
    $categories = makeApiRequest('/admin/categories', 'GET', null, $_SESSION['admin_token']);
} catch (Exception $e) {
    $error = $e->getMessage();
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Artwork Management</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <div class="dashboard-container">
        <div class="sidebar">
            <h2>Admin Panel</h2>
            <nav>
                <a href="dashboard.php">Dashboard</a>
                <a href="users.php">Users</a>
                <a href="artworks.php" class="active">Artworks</a>
                <a href="categories.php">Categories</a>
                <a href="logout.php">Logout</a>
            </nav>
        </div>
        
        <div class="main-content">
            <div class="header">
                <h1>Artwork Management</h1>
            </div>

            <div class="filters">
                <select id="categoryFilter" onchange="filterArtworks()">
                    <option value="">All Categories</option>
                    <?php foreach ($categories as $category): ?>
                        <?php 
                        $selected = isset($_GET['category']) && $_GET['category'] == $category['id'] ? 'selected' : '';
                        ?>
                        <option value="<?= $category['id'] ?>" <?= $selected ?>>
                            <?= htmlspecialchars($category['name']) ?> (<?= $category['artwork_count'] ?> artworks)
                        </option>
                    <?php endforeach; ?>
                </select>
                <input type="text" id="searchInput" onkeyup="filterArtworks()" placeholder="Search artworks...">
            </div>

            <div class="artwork-grid">
                <?php if ($artworks && is_array($artworks)): ?>
                    <?php foreach ($artworks as $artwork): ?>
                        <div class="artwork-card" data-categories='<?= json_encode(array_map(function($cat) {
                            return [
                                'id' => $cat['id'] ?? 0,
                                'name' => $cat['name'] ?? 'Uncategorized'
                            ];
                        }, $artwork['categories'] ?? [])) ?>'>
                            <?php if (!empty($artwork['image_url'])): ?>
                                <img src="<?= htmlspecialchars('http://localhost:8000' . $artwork['image_url']) ?>" 
                                     alt="<?= htmlspecialchars($artwork['title'] ?? 'Artwork') ?>"
                                     class="artwork-image">
                            <?php else: ?>
                                <div class="no-image-placeholder">No Image Available</div>
                            <?php endif; ?>
                            <div class="artwork-info">
                                <h3><?= htmlspecialchars($artwork['title'] ?? '') ?></h3>
                                <p class="artist">Artist: <?= htmlspecialchars($artwork['artist_name'] ?? 'Unknown') ?></p>
                                <p class="description"><?= htmlspecialchars($artwork['description'] ?? '') ?></p>
                                <p class="categories">Categories: <?= implode(', ', array_map(function($cat) { 
                                    return htmlspecialchars($cat['name'] ?? 'Uncategorized'); 
                                }, $artwork['categories'] ?? [])) ?></p>
                                <p class="status">Status: <?= htmlspecialchars($artwork['status'] ?? 'unknown') ?></p>
                                <p class="date">Created: <?= isset($artwork['created_at']) ? date('Y-m-d', strtotime($artwork['created_at'])) : 'Unknown' ?></p>
                            </div>
                            <div class="artwork-actions">
                                <button onclick="deleteArtwork(<?= $artwork['id'] ?? 0 ?>)" class="delete-btn">Delete</button>
                            </div>
                        </div>
                    <?php endforeach; ?>
                <?php else: ?>
                    <p>No artworks found.</p>
                <?php endif; ?>
            </div>
        </div>
    </div>

    <script>
    function filterArtworks() {
        const categoryId = document.getElementById('categoryFilter').value;
        const search = document.getElementById('searchInput').value.toLowerCase();
        const artworks = document.querySelectorAll('.artwork-card');

        artworks.forEach(artwork => {
            const title = artwork.querySelector('h3').textContent.toLowerCase();
            const description = artwork.querySelector('.description').textContent.toLowerCase();
            const categories = JSON.parse(artwork.dataset.categories);
            
            // Check if the artwork has the selected category ID
            const matchesCategory = !categoryId || categories.some(cat => cat.id === parseInt(categoryId));
            const matchesSearch = !search || 
                title.includes(search) || 
                description.includes(search);
            
            artwork.style.display = matchesCategory && matchesSearch ? 'block' : 'none';
        });
    }

    // Initialize with All Categories on page load
    document.addEventListener('DOMContentLoaded', () => {
        const urlParams = new URLSearchParams(window.location.search);
        const category = urlParams.get('category');
        
        // Set default to "All Categories" if no category specified
        document.getElementById('categoryFilter').value = category || '';
        if (category) {
            filterArtworks();
        }
    });

    async function deleteArtwork(id) {
        if (!confirm('Are you sure you want to delete this artwork?')) return;
        
        try {
            const response = await fetch(`http://localhost:8000/admin/artworks/${id}`, {
                method: 'DELETE',
                headers: {
                    'Authorization': 'Bearer <?= $_SESSION['admin_token'] ?>'
                }
            });
            
            if (response.ok) {
                window.location.reload();
            } else {
                const error = await response.json();
                alert(error.detail || 'Error deleting artwork');
            }
        } catch (error) {
            console.error('Error:', error);
            alert('Error deleting artwork');
        }
    }
    </script>

    <style>
    .main-content {
        padding: 20px;
    }

    .filters {
        margin: 20px 0;
        display: flex;
        gap: 10px;
    }

    .filters select, .filters input {
        padding: 8px;
        border: 1px solid #ddd;
        border-radius: 4px;
    }

    .artwork-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
        gap: 20px;
    }

    .artwork-card {
        border: 1px solid #ddd;
        border-radius: 8px;
        overflow: hidden;
        background: white;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .artwork-card img {
        width: 100%;
        height: 200px;
        object-fit: cover;
        background-color: #f5f5f5;
        border-bottom: 1px solid #eee;
        transition: opacity 0.2s ease-in-out;
    }

    .artwork-card img.error {
        opacity: 0.5;
    }

    .artwork-info {
        padding: 15px;
    }

    .artwork-info h3 {
        margin: 0 0 10px 0;
    }

    .artwork-info p {
        margin: 5px 0;
        color: #666;
    }

    .artwork-actions {
        padding: 15px;
        display: flex;
        gap: 10px;
        border-top: 1px solid #eee;
    }

    .artwork-actions button {
        padding: 8px 15px;
        border-radius: 4px;
        border: none;
        cursor: pointer;
        transition: background-color 0.2s;
    }

    .delete-btn {
        background: #f44336;
        color: white;
    }

    .artwork-actions button:hover {
        opacity: 0.9;
    }

    .no-image-placeholder {
        height: 200px;
        background: #f5f5f5;
        display: flex;
        align-items: center;
        justify-content: center;
        color: #999;
        border-bottom: 1px solid #eee;
    }
    </style>
</body>
</html> 