"""make_annoyingness_non_nullable_with_default

Revision ID: 658fd905e761
Revises: 7c2832d6b5f4
Create Date: 2025-11-25 22:22:41.154331

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '658fd905e761'
down_revision: Union[str, Sequence[str], None] = '7c2832d6b5f4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # First, update all NULL values to 0
    op.execute("UPDATE todos SET annoyingness = 0 WHERE annoyingness IS NULL")

    # Then, alter the column to be non-nullable with a server default of 0
    op.alter_column('todos', 'annoyingness',
                    existing_type=sa.Integer(),
                    nullable=False,
                    server_default='0')


def downgrade() -> None:
    """Downgrade schema."""
    # Remove the server default and make the column nullable again
    op.alter_column('todos', 'annoyingness',
                    existing_type=sa.Integer(),
                    nullable=True,
                    server_default=None)
