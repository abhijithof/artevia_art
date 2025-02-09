from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime, Text, Table, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime

from .database import Base

# Association tables
artwork_categories = Table('artwork_categories', Base.metadata,
    Column('artwork_id', Integer, ForeignKey('artworks.id')),
    Column('category_id', Integer, ForeignKey('categories.id'))
)

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    username = Column(String, unique=True, index=True)
    password = Column(String)
    role = Column(String, default="user")
    is_active = Column(Boolean, default=True)
    status = Column(String, default="active")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    profile_picture = Column(String, nullable=True)
    bio = Column(Text, nullable=True)
    website = Column(String, nullable=True)
    location = Column(String, nullable=True)
    social_links = Column(String, nullable=True)
    ban_reason = Column(String, nullable=True)

    # Existing relationships
    artworks = relationship("Artwork", back_populates="artist")
    discoveries = relationship("Discovery", back_populates="user")
    likes = relationship("Like", back_populates="user")
    comments = relationship("Comment", back_populates="user")

    # Relationships
    profile = relationship("Profile", back_populates="user", uselist=False)

class Profile(Base):
    __tablename__ = "profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    bio = Column(Text, nullable=True)
    website = Column(String, nullable=True)
    location = Column(String, nullable=True)
    profile_picture = Column(String, nullable=True)
    social_links = Column(JSON, default=dict)  # JSON string

    # Relationships
    user = relationship("User", back_populates="profile")

class Artwork(Base):
    __tablename__ = "artworks"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(Text)
    image_url = Column(String, nullable=True)
    latitude = Column(Float)
    longitude = Column(Float)
    status = Column(String, default="active")
    is_featured = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    artist_id = Column(Integer, ForeignKey("users.id"))

    # Relationships
    artist = relationship("User", back_populates="artworks")
    categories = relationship("Category", secondary=artwork_categories, back_populates="artworks")
    discoveries = relationship("Discovery", back_populates="artwork")
    likes = relationship("Like", back_populates="artwork")
    comments = relationship("Comment", back_populates="artwork")

    # Add to Artwork model
    moderation_reason = Column(String, nullable=True)

class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    description = Column(Text)

    # Relationships
    artworks = relationship("Artwork", secondary=artwork_categories, back_populates="categories")

class Discovery(Base):
    __tablename__ = "discoveries"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    artwork_id = Column(Integer, ForeignKey("artworks.id"))
    discovered_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="discoveries")
    artwork = relationship("Artwork", back_populates="discoveries")

class Like(Base):
    __tablename__ = "likes"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    artwork_id = Column(Integer, ForeignKey("artworks.id"))
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="likes")
    artwork = relationship("Artwork", back_populates="likes")

class Comment(Base):
    __tablename__ = "comments"

    id = Column(Integer, primary_key=True, index=True)
    text = Column(Text)
    user_id = Column(Integer, ForeignKey("users.id"))
    artwork_id = Column(Integer, ForeignKey("artworks.id"))
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="comments")
    artwork = relationship("Artwork", back_populates="comments")

    # Add to Comment model
    status = Column(String, default="active")
    moderation_reason = Column(String, nullable=True)

class ModerationLog(Base):
    __tablename__ = "moderation_logs"

    id = Column(Integer, primary_key=True, index=True)
    admin_id = Column(Integer, ForeignKey("users.id"))
    action = Column(String)  # "ban_user", "unban_user", "hide_artwork", etc.
    target_type = Column(String)  # "user", "artwork", "comment"
    target_id = Column(Integer)
    reason = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationship with admin
    admin = relationship("User")
