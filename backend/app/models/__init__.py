from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


from .user import User
from .note import Note

__all__ = ['Base', 'User', 'Note']
