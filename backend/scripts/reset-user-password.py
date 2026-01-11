#!/usr/bin/env python3
"""
Password Reset Script

This script allows you to reset a user's password in the database.
Useful after database migrations or when users forget their passwords.

Usage:
    python reset-user-password.py <email> <new_password>

Example:
    python reset-user-password.py user@example.com newpassword123
"""

import sys
import os

# Add the parent directory to the path so we can import from app
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime, timezone

from app.database import SessionLocal, engine
from app.models.user import User
from pwdlib import PasswordHash

def reset_password(email: str, new_password: str):
    """Reset a user's password."""

    # Create password hash
    password_hash = PasswordHash.recommended()
    hashed_password = password_hash.hash(new_password)

    # Get database session
    db = SessionLocal()

    try:
        # Find user by email
        user = db.query(User).filter(User.email == email).first()

        if not user:
            print(f"❌ Error: User with email '{email}' not found")
            return False

        # Update password and timestamp
        user.hashed_password = hashed_password
        user.date_updated = datetime.now(timezone.utc)
        db.commit()

        print(f"✅ Password successfully updated for user: {email}")
        print(f"   User ID: {user.id}")
        return True

    except Exception as e:
        db.rollback()
        print(f"❌ Error updating password: {e}")
        return False

    finally:
        db.close()

def main():
    if len(sys.argv) != 3:
        print("Usage: python reset-user-password.py <email> <new_password>")
        print("\nExample:")
        print("  python reset-user-password.py user@example.com newpassword123")
        sys.exit(1)

    email = sys.argv[1]
    new_password = sys.argv[2]

    print(f"🔄 Resetting password for: {email}")
    print()

    success = reset_password(email, new_password)

    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
