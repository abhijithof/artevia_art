<?php
session_start();
if (!isset($_SESSION['admin_token'])) {
    header("Location: login.php");
    exit();
}

// Fetch categories from FastAPI
$curl = curl_init();
curl_setopt_array($curl, [
    CURLOPT_URL => 'http://localhost:8000/admin/categories',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . $_SESSION['admin_token']
    ]
]);

$response = curl_exec($curl);
$categories = json_decode($response, true);
curl_close($curl);

// Check if categories were fetched successfully
if ($categories === null) {
    $error = "Error fetching categories";
    $categories = []; // Initialize as empty array to avoid foreach error
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Category Management</title>
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
                <a href="categories.php" class="active">Categories</a>
                <a href="logout.php">Logout</a>
            </nav>
        </div>
        
        <div class="main-content">
            <div class="header">
                <h1>Category Management</h1>
                <button onclick="showAddCategoryModal()" class="add-button">Add Category</button>
            </div>

            <div class="category-grid">
                <?php foreach ($categories as $category): ?>
                <div class="category-card">
                    <div class="category-info">
                        <h3><?= htmlspecialchars($category['name']) ?></h3>
                        <p><?= htmlspecialchars($category['description'] ?? '') ?></p>
                        <p class="artwork-count">
                            <?= $category['artwork_count'] ?> artwork(s) -
                            <a href="artworks.php?category=<?= $category['id'] ?>">
                                View artworks in this category
                            </a>
                        </p>
                    </div>
                    <div class="category-actions">
                        <button onclick="editCategory(<?= $category['id'] ?>)" class="edit-btn">Edit</button>
                        <button onclick="deleteCategory(<?= $category['id'] ?>)" class="delete-btn">Delete</button>
                    </div>
                </div>
                <?php endforeach; ?>
            </div>
        </div>
    </div>

    <!-- Add Category Modal -->
    <div id="addCategoryModal" class="modal">
        <div class="modal-content">
            <h2>Add New Category</h2>
            <form id="addCategoryForm" onsubmit="submitCategory(event)">
                <div class="form-group">
                    <label>Name</label>
                    <input type="text" name="name" required>
                </div>
                <div class="form-group">
                    <label>Description</label>
                    <textarea name="description" required></textarea>
                </div>
                <button type="submit" class="add-button">Add Category</button>
                <button type="button" onclick="closeModal()" class="cancel-button">Cancel</button>
            </form>
        </div>
    </div>

    <!-- Edit Category Modal -->
    <div id="editCategoryModal" class="modal">
        <div class="modal-content">
            <h2>Edit Category</h2>
            <form id="editCategoryForm" onsubmit="updateCategory(event)">
                <input type="hidden" name="category_id" id="edit_category_id">
                <div class="form-group">
                    <label>Name</label>
                    <input type="text" name="name" id="edit_name" required>
                </div>
                <div class="form-group">
                    <label>Description</label>
                    <textarea name="description" id="edit_description" required></textarea>
                </div>
                <button type="submit" class="edit-button">Update Category</button>
                <button type="button" onclick="closeModal()" class="cancel-button">Cancel</button>
            </form>
        </div>
    </div>

    <script>
    function showAddCategoryModal() {
        document.getElementById('addCategoryModal').style.display = 'block';
    }

    function closeModal() {
        document.getElementById('addCategoryModal').style.display = 'none';
        document.getElementById('editCategoryModal').style.display = 'none';
    }

    async function submitCategory(event) {
        event.preventDefault();
        const form = event.target;
        const data = {
            name: form.name.value,
            description: form.description.value
        };

        try {
            const response = await fetch('http://localhost:8000/categories', {
                method: 'POST',
                headers: {
                    'Authorization': 'Bearer <?= $_SESSION['admin_token'] ?>',
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(data)
            });

            if (response.ok) {
                window.location.reload();
            } else {
                const error = await response.json();
                alert(error.detail || 'Failed to create category');
            }
        } catch (error) {
            console.error('Error:', error);
            alert('Failed to create category');
        }
    }

    async function editCategory(id) {
        try {
            const response = await fetch(`http://localhost:8000/categories/${id}`, {
                headers: {
                    'Authorization': 'Bearer <?= $_SESSION['admin_token'] ?>'
                }
            });
            const category = await response.json();
            
            document.getElementById('edit_category_id').value = id;
            document.getElementById('edit_name').value = category.name;
            document.getElementById('edit_description').value = category.description || '';
            document.getElementById('editCategoryModal').style.display = 'block';
        } catch (error) {
            console.error('Error:', error);
            alert('Failed to load category details');
        }
    }

    async function updateCategory(event) {
        event.preventDefault();
        const form = event.target;
        const id = form.category_id.value;
        const data = {
            name: form.name.value,
            description: form.description.value
        };

        try {
            const response = await fetch(`http://localhost:8000/categories/${id}`, {
                method: 'PUT',
                headers: {
                    'Authorization': 'Bearer <?= $_SESSION['admin_token'] ?>',
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(data)
            });

            if (response.ok) {
                window.location.reload();
            } else {
                const error = await response.json();
                alert(error.detail || 'Failed to update category');
            }
        } catch (error) {
            console.error('Error:', error);
            alert('Failed to update category');
        }
    }

    async function deleteCategory(id) {
        if (confirm('Are you sure you want to delete this category?')) {
            try {
                const response = await fetch(`http://localhost:8000/categories/${id}`, {
                    method: 'DELETE',
                    headers: {
                        'Authorization': 'Bearer <?= $_SESSION['admin_token'] ?>'
                    }
                });

                if (response.ok) {
                    window.location.reload();
                } else {
                    const error = await response.json();
                    alert(error.detail || 'Failed to delete category');
                }
            } catch (error) {
                console.error('Error:', error);
                alert('Failed to delete category');
            }
        }
    }
    </script>
</body>
</html> 