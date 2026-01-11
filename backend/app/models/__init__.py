from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


from .todo import Todo
from .user import User
from .fun import Fun

__all__ = ['Base', 'Todo', 'User', 'Fun']
