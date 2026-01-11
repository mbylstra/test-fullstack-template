"""add_habit_to_todokind_enum_and_unique_constraint

Revision ID: 6133287853b2
Revises: 49832d434b59
Create Date: 2025-12-11 09:22:09.697172

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '6133287853b2'
down_revision: Union[str, Sequence[str], None] = '49832d434b59'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Add 'HABIT' to the todokind enum
    # This needs to be done outside of a transaction to avoid the
    # "unsafe use of new value" error
    connection = op.get_bind()
    connection.execute(sa.text("COMMIT"))
    connection.execute(sa.text("ALTER TYPE todokind ADD VALUE 'HABIT'"))

    # Create unique index for habit todos
    op.create_index(
        'uq_user_habit_order',
        'todos',
        ['user_id', 'order'],
        unique=True,
        postgresql_where=sa.text("kind = 'HABIT'::todokind")
    )


def downgrade() -> None:
    """Downgrade schema."""
    # Drop the unique index for habit todos
    op.drop_index(
        'uq_user_habit_order',
        table_name='todos',
        postgresql_where=sa.text("kind = 'HABIT'::todokind")
    )

    # Note: PostgreSQL doesn't support removing enum values directly
    # The enum value 'HABIT' will remain in the database after downgrade
