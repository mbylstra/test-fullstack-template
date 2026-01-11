"""Tests for todo filter functions."""
import pytest
from sqlalchemy import create_engine, JSON, String, Integer, DateTime, Text, Enum as SQLAEnum, ForeignKey, Boolean, event
from sqlalchemy.orm import sessionmaker
from sqlalchemy.dialects import postgresql
from app.models import Base
from app.models.todo import (
    Todo,
    TodoStatus,
    TimeEstimate,
    get_max_time_estimate_filter,
    get_weighted_random_required_fields_filter,
    get_chooseable_todos_filter,
)


# Test database setup
@pytest.fixture
def db_session():
    """Create an in-memory SQLite database for testing."""
    engine = create_engine("sqlite:///:memory:")

    # Replace JSONB with JSON for SQLite compatibility
    @event.listens_for(Base.metadata, "before_create")
    def _set_json_type(metadata, conn, **kw):
        for table in metadata.tables.values():
            for column in table.columns:
                if isinstance(column.type, postgresql.JSONB):
                    column.type = JSON()

    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    session = Session()
    yield session
    session.close()


@pytest.fixture
def sample_todos(db_session):
    """Create sample todos with various time estimates."""
    todos = [
        Todo(
            id="1",
            task="Quick task",
            status=TodoStatus.TODO,
            user_id="user1",
            order="a",
            importance=3,
            time_estimate=TimeEstimate.ONE_MIN,
            annoyingness=2,
            committed=False,
        ),
        Todo(
            id="2",
            task="Short task",
            status=TodoStatus.TODO,
            user_id="user1",
            order="b",
            importance=3,
            time_estimate=TimeEstimate.FIVE_MINS,
            annoyingness=2,
            committed=False,
        ),
        Todo(
            id="3",
            task="Medium task",
            status=TodoStatus.TODO,
            user_id="user1",
            order="c",
            importance=3,
            time_estimate=TimeEstimate.THIRTY_MINS,
            annoyingness=2,
            committed=False,
        ),
        Todo(
            id="4",
            task="Long task",
            status=TodoStatus.TODO,
            user_id="user1",
            order="d",
            importance=3,
            time_estimate=TimeEstimate.ONE_HOUR,
            annoyingness=2,
            committed=False,
        ),
        Todo(
            id="5",
            task="Very long task",
            status=TodoStatus.TODO,
            user_id="user1",
            order="e",
            importance=3,
            time_estimate=TimeEstimate.TWO_HOURS,
            annoyingness=2,
            committed=False,
        ),
        Todo(
            id="6",
            task="Project task",
            status=TodoStatus.TODO,
            user_id="user1",
            order="f",
            importance=3,
            time_estimate=TimeEstimate.PROJECT,
            annoyingness=2,
            committed=False,
        ),
        Todo(
            id="7",
            task="No time estimate",
            status=TodoStatus.TODO,
            user_id="user1",
            order="g",
            importance=3,
            time_estimate=None,
            annoyingness=2,
            committed=False,
        ),
    ]
    for todo in todos:
        db_session.add(todo)
    db_session.commit()
    return todos


class TestGetMaxTimeEstimateFilter:
    """Tests for get_max_time_estimate_filter function."""

    def test_filter_30_mins(self, db_session, sample_todos):
        """Test filtering by 30 minutes includes tasks up to 30 minutes."""
        result = (
            db_session.query(Todo)
            .filter(get_max_time_estimate_filter(TimeEstimate.THIRTY_MINS))
            .all()
        )

        task_names = [todo.task for todo in result]

        # Should include: 1-min, 5-mins, 15-mins, 30-mins
        assert "Quick task" in task_names  # 1-min
        assert "Short task" in task_names  # 5-mins
        assert "Medium task" in task_names  # 30-mins

        # Should exclude: 1-hour, 2-hours, project, None
        assert "Long task" not in task_names  # 1-hour
        assert "Very long task" not in task_names  # 2-hours
        assert "Project task" not in task_names  # project
        assert "No time estimate" not in task_names  # None

    def test_filter_1_min(self, db_session, sample_todos):
        """Test filtering by 1 minute only includes 1-min tasks."""
        result = (
            db_session.query(Todo)
            .filter(get_max_time_estimate_filter(TimeEstimate.ONE_MIN))
            .all()
        )

        assert len(result) == 1
        assert result[0].task == "Quick task"

    def test_filter_1_hour(self, db_session, sample_todos):
        """Test filtering by 1 hour includes tasks up to 1 hour."""
        result = (
            db_session.query(Todo)
            .filter(get_max_time_estimate_filter(TimeEstimate.ONE_HOUR))
            .all()
        )

        task_names = [todo.task for todo in result]

        # Should include everything up to 1-hour
        assert "Quick task" in task_names
        assert "Short task" in task_names
        assert "Medium task" in task_names
        assert "Long task" in task_names

        # Should exclude 2-hours and project
        assert "Very long task" not in task_names
        assert "Project task" not in task_names

    def test_filter_project(self, db_session, sample_todos):
        """Test filtering by project includes all time estimates."""
        result = (
            db_session.query(Todo)
            .filter(get_max_time_estimate_filter(TimeEstimate.PROJECT))
            .all()
        )

        task_names = [todo.task for todo in result]

        # Should include all tasks with time estimates
        assert "Quick task" in task_names
        assert "Short task" in task_names
        assert "Medium task" in task_names
        assert "Long task" in task_names
        assert "Very long task" in task_names
        assert "Project task" in task_names

        # Should still exclude None
        assert "No time estimate" not in task_names


class TestGetWeightedRandomRequiredFieldsFilter:
    """Tests for get_weighted_random_required_fields_filter function."""

    def test_filters_out_missing_time_estimate(self, db_session, sample_todos):
        """Test that todos without time_estimate are filtered out."""
        result = (
            db_session.query(Todo)
            .filter(get_weighted_random_required_fields_filter())
            .all()
        )

        task_names = [todo.task for todo in result]
        assert "No time estimate" not in task_names

    def test_includes_todos_with_required_fields(self, db_session, sample_todos):
        """Test that todos with required fields are included."""
        result = (
            db_session.query(Todo)
            .filter(get_weighted_random_required_fields_filter())
            .all()
        )

        task_names = [todo.task for todo in result]

        # Should include all tasks that have time_estimate
        assert "Quick task" in task_names
        assert "Short task" in task_names
        assert "Medium task" in task_names

        # Count should exclude only the todo without time_estimate
        assert len(result) == 6


class TestGetChooseableTodosFilter:
    """Tests for get_chooseable_todos_filter function."""

    def test_excludes_completed_todos(self, db_session):
        """Test that completed todos are filtered out."""
        completed_todo = Todo(
            id="c1",
            task="Completed task",
            status=TodoStatus.COMPLETE,
            user_id="user1",
            order="z",
            importance=3,
            time_estimate=TimeEstimate.FIVE_MINS,
            annoyingness=2,
            committed=False,
        )
        db_session.add(completed_todo)
        db_session.commit()

        result = (
            db_session.query(Todo)
            .filter(get_chooseable_todos_filter())
            .all()
        )

        task_names = [todo.task for todo in result]
        assert "Completed task" not in task_names

    def test_excludes_waiting_todos(self, db_session):
        """Test that waiting todos are filtered out."""
        waiting_todo = Todo(
            id="w1",
            task="Waiting task",
            status=TodoStatus.WAITING,
            user_id="user1",
            order="z",
            importance=3,
            time_estimate=TimeEstimate.FIVE_MINS,
            annoyingness=2,
            committed=False,
        )
        db_session.add(waiting_todo)
        db_session.commit()

        result = (
            db_session.query(Todo)
            .filter(get_chooseable_todos_filter())
            .all()
        )

        task_names = [todo.task for todo in result]
        assert "Waiting task" not in task_names

    def test_excludes_committed_todos(self, db_session):
        """Test that committed todos are filtered out."""
        committed_todo = Todo(
            id="co1",
            task="Committed task",
            status=TodoStatus.TODO,
            user_id="user1",
            order="z",
            importance=3,
            time_estimate=TimeEstimate.FIVE_MINS,
            annoyingness=2,
            committed=True,
        )
        db_session.add(committed_todo)
        db_session.commit()

        result = (
            db_session.query(Todo)
            .filter(get_chooseable_todos_filter())
            .all()
        )

        task_names = [todo.task for todo in result]
        assert "Committed task" not in task_names

    def test_excludes_archived_todos(self, db_session):
        """Test that archived todos are filtered out."""
        archived_todo = Todo(
            id="a1",
            task="Archived task",
            status=TodoStatus.ARCHIVED,
            user_id="user1",
            order="z",
            importance=3,
            time_estimate=TimeEstimate.FIVE_MINS,
            annoyingness=2,
            committed=False,
        )
        db_session.add(archived_todo)
        db_session.commit()

        result = (
            db_session.query(Todo)
            .filter(get_chooseable_todos_filter())
            .all()
        )

        task_names = [todo.task for todo in result]
        assert "Archived task" not in task_names

    def test_includes_todo_status_todos(self, db_session):
        """Test that regular TODO status todos are included."""
        regular_todo = Todo(
            id="r1",
            task="Regular task",
            status=TodoStatus.TODO,
            user_id="user1",
            order="z",
            importance=3,
            time_estimate=TimeEstimate.FIVE_MINS,
            annoyingness=2,
            committed=False,
        )
        db_session.add(regular_todo)
        db_session.commit()

        result = (
            db_session.query(Todo)
            .filter(get_chooseable_todos_filter())
            .all()
        )

        task_names = [todo.task for todo in result]
        assert "Regular task" in task_names
