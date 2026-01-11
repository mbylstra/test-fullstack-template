from __future__ import annotations

from datetime import datetime, timezone, date
from typing import Optional, Dict, Any, List, TypedDict, Literal, TYPE_CHECKING, Union
from sqlalchemy import String, Integer, DateTime, Date, Text, Enum as SQLAEnum, ForeignKey, Boolean, and_, CheckConstraint, Index, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship, Session
from sqlalchemy.sql.expression import ColumnElement
import enum
import time


if TYPE_CHECKING:
    from app.models.user import User

from app.models import Base

# Timer Types ##################################################################

class TimerStartEvent(TypedDict):
    event: Literal['timer_start']
    timestamp: float

class TimerStopEvent(TypedDict):
    event: Literal['timer_stop']
    timestamp: float

class TimeElapsedOverrideEvent(TypedDict):
    event: Literal['time_elapsed_override']
    timestamp: float
    hours: int
    minutes: int

TimerEvent = Union[TimerStartEvent, TimerStopEvent, TimeElapsedOverrideEvent]

# Fields #######################################################################

class TodoStatus(str, enum.Enum):
    TODO = 'todo'
    COMPLETE = 'complete'
    ARCHIVED = 'archived'
    WAITING = 'waiting'


class TodoKind(str, enum.Enum):
    REGULAR = 'regular'
    BREAK_UP = 'break-up'
    HABIT = 'habit'


class TimeEstimate(str, enum.Enum):
    ONE_MIN = '1-min'
    FIVE_MINS = '5-mins'
    FIFTEEN_MINS = '15-mins'
    THIRTY_MINS = '30-mins'
    ONE_HOUR = '1-hour'
    TWO_HOURS = '2-hours'
    HALF_DAY = 'half-day'
    ONE_DAY = 'one-day'
    PROJECT = 'project'


class FrequencyKind(str, enum.Enum):
    SPECIFIC_DAYS_PER_WEEK = 'specific-days-per-week'
    MULTIPLE_DAYS_PER_WEEK = 'multiple-days-per-week'
    SPECIFIC_DAY_OF_MONTH = 'specific-day-of-month'
    MULTIPLE_DAYS_PER_MONTH = 'multiple-days-per-month'

# Models #######################################################################

def _enum_values_list(enum_type: type[enum.Enum]) -> list[str]:
    """Helper function to extract enum values as a list of strings."""
    return [e.value for e in enum_type]  # type: ignore[misc]

class Todo(Base):
    __tablename__ = 'todos'
    __table_args__ = (
        Index(
            'uq_user_order',
            'user_id', 'order',
            unique=True,
            postgresql_where=text("kind IN ('REGULAR'::todokind, 'BREAK_UP'::todokind)")
        ),
        Index(
            'uq_user_habit_order',
            'user_id', 'order',
            unique=True,
            postgresql_where=text("kind = 'HABIT'::todokind")
        ),
        # Note: days_of_week integer array validation is done at application level
        # (PostgreSQL doesn't allow subqueries in CHECK constraints)
        CheckConstraint(
            "frequency_kind != 'specific-days-per-week' OR days_of_week IS NOT NULL",
            name='ck_specific_days_per_week_requires_days'
        ),
        CheckConstraint(
            "frequency_kind != 'multiple-days-per-week' OR num_times_per_week IS NOT NULL",
            name='ck_multiple_days_per_week_requires_num_times'
        ),
        CheckConstraint(
            "frequency_kind != 'specific-day-of-month' OR day_of_month IS NOT NULL",
            name='ck_specific_day_of_month_requires_day'
        ),
        CheckConstraint(
            "frequency_kind != 'multiple-days-per-month' OR num_times_per_month IS NOT NULL",
            name='ck_multiple_days_per_month_requires_num_times'
        ),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True)
    task: Mapped[str] = mapped_column(Text)
    details: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB, nullable=True)
    status: Mapped[TodoStatus] = mapped_column(SQLAEnum(TodoStatus, name='TodoStatus'), default='todo')
    date_created: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    date_updated: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    user_id: Mapped[str] = mapped_column(String, ForeignKey('users.id'))
    order: Mapped[str] = mapped_column(String)
    importance: Mapped[int] = mapped_column(Integer)
    time_estimate: Mapped[Optional[TimeEstimate]] = mapped_column(SQLAEnum(TimeEstimate, name='TimeEstimate', values_callable=_enum_values_list), nullable=True)
    annoyingness: Mapped[int] = mapped_column(Integer, default=0, server_default='0')
    committed: Mapped[bool] = mapped_column(Boolean, default=False)
    timer_log: Mapped[List[TimerEvent]] = mapped_column(JSONB, nullable=False, default=list, server_default='[]')
    atomic: Mapped[bool] = mapped_column(Boolean, default=False, server_default='false')
    infinitely_divisible: Mapped[bool] = mapped_column(Boolean, default=False, server_default='false')
    kind: Mapped[TodoKind] = mapped_column(SQLAEnum(TodoKind, name='TodoKind'), default=TodoKind.REGULAR)
    parent_id: Mapped[Optional[str]] = mapped_column(String, ForeignKey('todos.id'), nullable=True)
    frequency_kind: Mapped[Optional[FrequencyKind]] = mapped_column(SQLAEnum(FrequencyKind, name='FrequencyKind', values_callable=_enum_values_list), nullable=True)
    days_of_week: Mapped[Optional[List[int]]] = mapped_column(JSONB, nullable=True)
    num_times_per_week: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    num_times_per_month: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    day_of_month: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)

    user: Mapped[User] = relationship("User", back_populates="todos")
    parent: Mapped[Optional[Todo]] = relationship("Todo", remote_side=[id], backref="children")

    def __repr__(self) -> str:
        return f"<Todo(id={self.id}, task={self.task}, status={self.status})>"

    def time_elapsed(self) -> float:
        """
        Calculate total elapsed time from timer_log in seconds.

        Timer events are stored as:
        [
            {"event": "timer_start", "timestamp": 1234567890},
            {"event": "timer_stop", "timestamp": 1234567900},
            {"event": "time_elapsed_override", "timestamp": 1234567910, "hours": 2, "minutes": 30},
            ...
        ]

        The most recent time_elapsed_override event discards all previous events.
        If an override exists, start with that time and only process subsequent events.

        Returns:
            Total elapsed time in seconds. Returns 0 if timer_log is empty.
            If the timer is currently running (last event is timer_start),
            includes time from that start until now.
        """
        if not self.timer_log:
            return 0.0

        # Find the most recent time_elapsed_override event
        override_index = None
        for i in range(len(self.timer_log) - 1, -1, -1):
            if self.timer_log[i].get('event') == 'time_elapsed_override':
                override_index = i
                break

        # If override exists, start with override time and process events after it
        if override_index is not None:
            override_event = self.timer_log[override_index]
            hours = override_event.get('hours', 0)
            minutes = override_event.get('minutes', 0)
            total_elapsed = hours * 3600 + minutes * 60
            events_to_process = self.timer_log[override_index + 1:]
        else:
            total_elapsed = 0.0
            events_to_process = self.timer_log

        # Process timer_start/timer_stop events
        start_time = None
        for event in events_to_process:
            event_type = event.get('event')
            timestamp = event.get('timestamp')

            if event_type == 'timer_start':
                start_time = timestamp
            elif event_type == 'timer_stop' and start_time is not None:
                total_elapsed += timestamp - start_time
                start_time = None

        # If timer is still running (last event was timer_start)
        if start_time is not None:
            current_time = time.time()
            total_elapsed += current_time - start_time

        return total_elapsed


class HabitLog(Base):
    __tablename__ = 'habit_logs'

    id: Mapped[str] = mapped_column(String, primary_key=True)
    habit_id: Mapped[str] = mapped_column(String, ForeignKey('todos.id'))
    when: Mapped[date] = mapped_column(Date)
    date_created: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    habit: Mapped[Todo] = relationship("Todo", backref="habit_logs")

    def __repr__(self) -> str:
        return f"<HabitLog(id={self.id}, habit_id={self.habit_id}, when={self.when})>"

# Helper functions #############################################################

time_estimates_order: Dict[TimeEstimate, int] = {
    TimeEstimate.ONE_MIN: 0,
    TimeEstimate.FIVE_MINS: 1,
    TimeEstimate.FIFTEEN_MINS: 2,
    TimeEstimate.THIRTY_MINS: 3,
    TimeEstimate.ONE_HOUR: 4,
    TimeEstimate.TWO_HOURS: 5,
    TimeEstimate.HALF_DAY: 6,
    TimeEstimate.ONE_DAY: 7,
    TimeEstimate.PROJECT: 8,
}

def get_chooseable_todos_filter() -> ColumnElement[bool]:
    """
    Get a SQLAlchemy filter for chooseable todos.

    A todo is chooseable if it is NOT:
    - Completed (status = COMPLETE)
    - Waiting (status = WAITING)
    - Archived (status = ARCHIVED)
    - Committed (committed = True)

    Returns:
        SQLAlchemy filter condition that can be used with .filter()
    """
    return and_(
        Todo.status != TodoStatus.COMPLETE,
        Todo.status != TodoStatus.WAITING,
        Todo.status != TodoStatus.ARCHIVED,
        Todo.committed == False
    )


def get_weighted_random_required_fields_filter() -> ColumnElement[bool]:
    """
    Get a SQLAlchemy filter for todos that have required fields for weighted random selection.

    A todo must have:
    - time_estimate (not None)

    Returns:
        SQLAlchemy filter condition that can be used with .filter()
    """
    return Todo.time_estimate.isnot(None)


def get_max_time_estimate_filter(max_time_estimate: TimeEstimate) -> ColumnElement[bool]:
    """
    Get a SQLAlchemy filter for todos with time estimates <= max_time_estimate.

    Args:
        max_time_estimate: Maximum time estimate threshold

    Returns:
        SQLAlchemy filter condition that can be used with .filter()
    """
    max_time_order = time_estimates_order[max_time_estimate]
    # Get all time estimates that are <= max_time_estimate (as string values)
    valid_time_estimates = [
        te.value for te, order in time_estimates_order.items()
        if order <= max_time_order
    ]
    return Todo.time_estimate.in_(valid_time_estimates)


def annotate_integer_order(todos: list['Todo']) -> 'TodoOrderDict':
    """
    Annotate todos with their integer position in the list.

    Args:
        todos: List of Todo instances

    Returns:
        Dictionary mapping todo_id to integer_order (0-based position in the list)
    """
    return {todo.id: i for i, todo in enumerate(todos)}

TodoOrderDict = Dict[str, int]


def is_parent_todo(todo: 'Todo', all_todos: List['Todo']) -> bool:
    """
    Check if a todo is a parent (has children).

    Args:
        todo: The todo to check
        all_todos: List of all todos to search for children

    Returns:
        True if the todo has any children, False otherwise
    """
    return any(t.parent_id == todo.id for t in all_todos)


def get_order_before_todo(todo: 'Todo', all_todos: List['Todo']) -> str:
    """
    Calculate a fractional index order that places a new todo just before (higher priority than)
    the specified todo.

    This uses fractional indexing to generate an order value between the previous todo
    and the target todo, following the same algorithm as the frontend's reorderTodos.

    Args:
        todo: The todo that the new order should be placed before
        all_todos: List of all todos sorted by order

    Returns:
        A fractional index string that places a todo just before the specified todo
    """
    from fractional_indexing import generate_key_between  # type: ignore[import-untyped]

    # Find the index of the target todo
    todo_index = next((i for i, t in enumerate(all_todos) if t.id == todo.id), None)

    # Calculate the new order to place item just before the target
    if todo_index is None:
        # If not found in list, use the todo's order as fallback
        return todo.order
    elif todo_index == 0:
        # Target is at the start, place new item before it
        return generate_key_between(None, all_todos[0].order)
    else:
        # Place new item between the previous todo and the target
        prev_order = all_todos[todo_index - 1].order
        return generate_key_between(prev_order, todo.order)


def create_break_up_todo(todo_to_break_up: 'Todo', all_todos: List['Todo']) -> 'Todo':
    """
    Create a meta todo for breaking up a larger task.

    This function creates a new "break-up" todo that prompts the user to manually
    split a large task into smaller subtasks. The break-up todo is positioned with
    slightly higher priority (appears just before) the todo being broken up.

    Args:
        todo_to_break_up: The Todo instance that needs to be broken up
        all_todos: List of all todos sorted by order (to calculate new position)

    Returns:
        A new Todo instance with kind='break-up' that is a child of the original todo
    """
    import uuid

    # Generate a new ID for the break-up todo
    breakup_id = str(uuid.uuid4())

    # Calculate the new order to place the break-up todo just before the parent
    new_order = get_order_before_todo(todo_to_break_up, all_todos)

    # Create the break-up todo with title referencing the parent task
    breakup_todo = Todo(
        id=breakup_id,
        task=f'break up "{todo_to_break_up.task}"',
        kind=TodoKind.BREAK_UP,
        parent_id=todo_to_break_up.id,
        time_estimate=TimeEstimate.FIVE_MINS,
        user_id=todo_to_break_up.user_id,
        status=TodoStatus.TODO,
        order=new_order,
        importance=todo_to_break_up.importance,
        annoyingness=0,
        committed=False,
        atomic=False,
        infinitely_divisible=False,
    )

    return breakup_todo


def generate_break_up_todos(db: Session, user_id: str) -> List['Todo']:
    """
    Generate break-up todos for all tasks that meet the criteria.

    Creates a meta "break-up" todo for any task that:
    - Has a time estimate greater than 30 minutes
    - Is not already a parent (has no children)
    - Does not have a parent (parent_id is null)
    - Is not complete, waiting, or committed

    Args:
        db: Database session
        user_id: User ID to filter todos

    Returns:
        List of new break-up Todo instances to be added to the database
    """
    # Fetch ALL todos for the user to calculate correct order positions
    # We need all todos (including completed, waiting, committed, etc.) to avoid
    # order collisions when creating new break-up todos
    all_todos_for_ordering = db.query(Todo).filter(
        Todo.user_id == user_id
    ).order_by(Todo.order).all()

    # Fetch todos that are candidates for breaking up (with filters)
    candidate_todos = db.query(Todo).filter(
        Todo.user_id == user_id,
        Todo.status != TodoStatus.COMPLETE,
        Todo.status != TodoStatus.WAITING,
        Todo.status != TodoStatus.ARCHIVED,
        Todo.committed == False,
        Todo.atomic == False,
        Todo.infinitely_divisible == False
    ).order_by(Todo.order).all()

    break_up_todos: List[Todo] = []

    # Convert to list so we can modify it as we create new todos
    all_todos_list = list(all_todos_for_ordering)

    for todo in candidate_todos:
        # Check if todo meets all criteria
        if (
            todo.time_estimate is not None
            and time_estimates_order[todo.time_estimate] > time_estimates_order[TimeEstimate.THIRTY_MINS]
            and not is_parent_todo(todo, all_todos_list)
            and todo.parent_id is None
        ):
            # Create a break-up todo for this task
            break_up_todo = create_break_up_todo(todo, all_todos_list)
            break_up_todos.append(break_up_todo)

            # Add the newly created break-up todo to all_todos_list so that
            # subsequent break-up todos are aware of it and don't get duplicate order values
            all_todos_list.append(break_up_todo)
            # Keep the list sorted by order to maintain correct positioning
            all_todos_list.sort(key=lambda t: t.order)

    return break_up_todos