"""fix_timeestimate_enum_values

Revision ID: 7c2832d6b5f4
Revises: 9ea13a584c49
Create Date: 2025-11-24 21:56:59.748924

"""
from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = '7c2832d6b5f4'
down_revision: Union[str, Sequence[str], None] = '9ea13a584c49'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema to fix TimeEstimate enum values."""
    # Create new enum with correct values
    op.execute("""
        CREATE TYPE timeestimate_new AS ENUM (
            '1-min',
            '5-mins',
            '15-mins',
            '30-mins',
            '1-hour',
            '2-hours',
            'half-day',
            'one-day',
            'project'
        )
    """)

    # Add temporary column with new type
    op.execute("""
        ALTER TABLE todos
        ADD COLUMN time_estimate_new timeestimate_new
    """)

    # Migrate data from old to new column with mapping
    op.execute("""
        UPDATE todos
        SET time_estimate_new = CASE time_estimate
            WHEN 'ONE_MIN' THEN '1-min'::timeestimate_new
            WHEN 'FIVE_MINS' THEN '5-mins'::timeestimate_new
            WHEN 'THIRTY_MINS' THEN '30-mins'::timeestimate_new
            WHEN 'ONE_HOUR' THEN '1-hour'::timeestimate_new
            WHEN 'TWO_HOURS' THEN '2-hours'::timeestimate_new
            WHEN 'HALF_DAY' THEN 'half-day'::timeestimate_new
            WHEN 'ONE_DAY' THEN 'one-day'::timeestimate_new
            WHEN 'PROJECT' THEN 'project'::timeestimate_new
            ELSE NULL
        END
        WHERE time_estimate IS NOT NULL
    """)

    # Drop old column
    op.execute("ALTER TABLE todos DROP COLUMN time_estimate")

    # Rename new column to old name
    op.execute("ALTER TABLE todos RENAME COLUMN time_estimate_new TO time_estimate")

    # Drop old enum type
    op.execute("DROP TYPE timeestimate")

    # Rename new enum type to old name
    op.execute("ALTER TYPE timeestimate_new RENAME TO timeestimate")


def downgrade() -> None:
    """Downgrade schema to restore old TimeEstimate enum values."""
    # Create old enum type
    op.execute("""
        CREATE TYPE timeestimate_old AS ENUM (
            'ONE_MIN',
            'FIVE_MINS',
            'THIRTY_MINS',
            'ONE_HOUR',
            'TWO_HOURS',
            'HALF_DAY',
            'ONE_DAY',
            'PROJECT'
        )
    """)

    # Add temporary column with old type
    op.execute("""
        ALTER TABLE todos
        ADD COLUMN time_estimate_old timeestimate_old
    """)

    # Migrate data back
    op.execute("""
        UPDATE todos
        SET time_estimate_old = CASE time_estimate
            WHEN '1-min' THEN 'ONE_MIN'::timeestimate_old
            WHEN '5-mins' THEN 'FIVE_MINS'::timeestimate_old
            WHEN '15-mins' THEN 'THIRTY_MINS'::timeestimate_old
            WHEN '30-mins' THEN 'THIRTY_MINS'::timeestimate_old
            WHEN '1-hour' THEN 'ONE_HOUR'::timeestimate_old
            WHEN '2-hours' THEN 'TWO_HOURS'::timeestimate_old
            WHEN 'half-day' THEN 'HALF_DAY'::timeestimate_old
            WHEN 'one-day' THEN 'ONE_DAY'::timeestimate_old
            WHEN 'project' THEN 'PROJECT'::timeestimate_old
            ELSE NULL
        END
        WHERE time_estimate IS NOT NULL
    """)

    # Drop new column
    op.execute("ALTER TABLE todos DROP COLUMN time_estimate")

    # Rename old column back
    op.execute("ALTER TABLE todos RENAME COLUMN time_estimate_old TO time_estimate")

    # Drop new enum type
    op.execute("DROP TYPE timeestimate")

    # Rename old enum type back
    op.execute("ALTER TYPE timeestimate_old RENAME TO timeestimate")
