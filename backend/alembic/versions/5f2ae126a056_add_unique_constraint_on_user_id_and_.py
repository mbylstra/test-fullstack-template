"""add unique constraint on user_id and order

Revision ID: 5f2ae126a056
Revises: 6489c3340586
Create Date: 2025-12-03 12:56:09.000646

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '5f2ae126a056'
down_revision: Union[str, Sequence[str], None] = '6489c3340586'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # First, fix duplicate order values by reassigning them using fractional indexing
    # We'll use a SQL script to handle this
    connection = op.get_bind()

    # Get all duplicates grouped by user_id and order
    result = connection.execute(sa.text("""
        SELECT user_id, "order", array_agg(id ORDER BY date_created) as todo_ids
        FROM todos
        GROUP BY user_id, "order"
        HAVING COUNT(*) > 1
    """))

    duplicates = result.fetchall()

    # For each group of duplicates, keep the first one and reassign the others
    for user_id, order, todo_ids in duplicates:
        # Keep the first todo with the original order
        # For the rest, append a suffix to make them unique
        for i, todo_id in enumerate(todo_ids[1:], start=1):
            new_order = f"{order}{chr(96 + i)}"  # append 'a', 'b', 'c', etc.
            connection.execute(
                sa.text('UPDATE todos SET "order" = :new_order WHERE id = :todo_id'),
                {"new_order": new_order, "todo_id": todo_id}
            )

    # Now add the unique constraint
    op.create_unique_constraint('uq_user_order', 'todos', ['user_id', 'order'])


def downgrade() -> None:
    """Downgrade schema."""
    # Remove the unique constraint
    op.drop_constraint('uq_user_order', 'todos', type_='unique')
