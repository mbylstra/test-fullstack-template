from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


from .user import User

__all__ = ['Base', 'User']
