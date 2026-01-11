"""update_zero_importance_to_one

Revision ID: 846bb0e38268
Revises: 5f2ae126a056
Create Date: 2025-12-09 11:40:38.990006

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '846bb0e38268'
down_revision: Union[str, Sequence[str], None] = '5f2ae126a056'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Update all todos with importance=0 to importance=1
    op.execute("UPDATE todos SET importance = 1 WHERE importance = 0")


def downgrade() -> None:
    """Downgrade schema."""
    # Revert all todos with importance=1 back to importance=0
    # Note: This will affect ALL todos with importance=1, not just the ones we updated
    # This is a limitation of this migration approach
    op.execute("UPDATE todos SET importance = 0 WHERE importance = 1")
