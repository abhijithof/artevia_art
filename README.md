# Artevia Art Platform

A full-stack web application for managing and showcasing artworks with an admin panel and backend API.

## Project Structure

```
artevia_art/
├── admin/              # PHP Admin Panel
│   ├── auth.php
│   ├── config/
│   ├── css/
│   └── utils/
├── backend/           # Python FastAPI Backend
│   ├── app/
│   ├── uploads/
│   ├── static/
│   ├── requirements.txt
│   └── sql_app.db
```

## Prerequisites

- Python 3.7+
- PHP 7.4+
- Web server (Apache/Nginx) or PHP's built-in server
- pip (Python package manager)
- Composer (PHP package manager) - optional

## Installation & Setup

### Backend (FastAPI)

#### Windows
```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the server
uvicorn app.main:app --reload --port 8000
```

#### macOS/Linux
```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run the server
uvicorn app.main:app --reload --port 8000
```

### Admin Panel

#### Windows (Using XAMPP)
1. Install XAMPP
2. Copy the `admin` folder to `C:\xampp\htdocs\artevia_art`
3. Start Apache from XAMPP Control Panel
4. Access at `http://localhost/artevia_art/admin`

#### macOS/Linux (Using built-in PHP server)
```bash
cd admin
php -S localhost:8080
```

## Accessing the Application

### Backend API
- Main API: `http://localhost:8000`
- API Documentation: `http://localhost:8000/docs`
- Admin API: `http://localhost:8000/admin`

### Admin Panel
- URL: `http://localhost:8080` (or your configured port)
- Default Admin Credentials:
  - Username: admin@art.com
  - Password: 123

## Features

- Artwork Management
- User Management
- Category Management
- Activity Tracking
- File Upload System
- Admin Dashboard
- Authentication System

## Database

The application uses SQLite database (`sql_app.db`) for data storage. No additional database setup is required.

## API Endpoints

### Public Endpoints
- `GET /artworks` - List all artworks
- `GET /artworks/{id}` - Get artwork details
- `GET /categories` - List all categories

### Admin Endpoints
- `POST /admin/login` - Admin authentication
- `GET /admin/dashboard` - Dashboard statistics
- `POST /admin/artworks` - Create artwork
- `PUT /admin/artworks/{id}` - Update artwork
- `DELETE /admin/artworks/{id}` - Delete artwork

## File Structure

### Backend
- `app/` - Main application code
- `uploads/` - Uploaded files storage
- `static/` - Static files
- `requirements.txt` - Python dependencies

### Admin Panel
- `auth.php` - Authentication handling
- `config/` - Configuration files
- `utils/` - Utility functions
- `css/` - Stylesheets

## Security Notes

- Change default admin credentials in production
- Secure file upload paths
- Configure proper CORS settings
- Use environment variables for sensitive data
- Implement rate limiting

## Development

To contribute to the project:
1. Fork the repository
2. Create a feature branch
3. Commit changes
4. Submit pull request

## Troubleshooting

### Common Issues

1. Port already in use:
   - Change the port number in the server command
   - Kill the process using the port

2. Database errors:
   - Check file permissions
   - Ensure SQLite is installed
   - Verify database file exists

3. Upload issues:
   - Check folder permissions
   - Verify upload size limits
   - Ensure correct file paths

## License

[Add your license information here]

## Support

For support and questions, please [create an issue](link-to-issues) or contact [your-email].
```

</rewritten_file>
