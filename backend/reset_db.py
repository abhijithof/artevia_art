from app.database import Base, engine, SessionLocal
from app.models import Category, User
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def reset_database():
    print("Dropping all tables...")
    Base.metadata.drop_all(bind=engine)
    print("Creating all tables...")
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    
    # Create predefined admin user
    print("Creating admin user...")
    admin_user = User(
        username="admin",
        email="admin@artevia.com",
        password_hash=pwd_context.hash("admin123"),  # Change this password in production!
        role="admin",
        status="active"
    )
    db.add(admin_user)
    
    # Create predefined categories
    print("Creating predefined categories...")
    categories = [
        Category(name="Street Art", description="Murals, graffiti, and urban artwork"),
        Category(name="Sculpture", description="3D artworks and installations"),
        Category(name="Digital Art", description="Digital projections and interactive art"),
        Category(name="Traditional", description="Paintings, drawings, and traditional media"),
        Category(name="Mixed Media", description="Combination of different art forms"),
        Category(name="Photography", description="Photographic artworks"),
        Category(name="Performance", description="Performance art and temporary installations")
    ]
    
    for category in categories:
        db.add(category)
    
    db.commit()
    db.close()
    print("Database reset complete with predefined admin and categories!")

if __name__ == "__main__":
    reset_database() 