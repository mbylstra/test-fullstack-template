import "@typespec/http";
import "@typespec/openapi3";

using TypeSpec.Http;

@service(#{ title: "Fllstck Tmplt API" })
@server("http://localhost:8000", "Development server")
@useAuth(BearerAuth)
namespace FllstckTmpltAPI;

/**
 * Importance level (0-5)
 */
@minValue(0)
@maxValue(5)
scalar Importance extends int32;

/**
 * Annoyingness level (0-4)
 */
@minValue(0)
@maxValue(4)
scalar Annoyingness extends int32;

/**
 * Status of a todo item
 */
enum TodoStatus {
  todo: "todo",
  complete: "complete",
  archived: "archived",
  waiting: "waiting",
}

/**
 * Time estimate for completing a todo
 */
enum TimeEstimate {
  oneMin: "1-min",
  fiveMins: "5-mins",
  fifteenMins: "15-mins",
  thirtyMins: "30-mins",
  oneHour: "1-hour",
  twoHours: "2-hours",
  halfDay: "half-day",
  oneDay: "one-day",
  project: "project",
}

/**
 * Frequency kind for recurring todos
 */
enum FrequencyKind {
  specificDaysPerWeek: "specific-days-per-week",
  multipleDaysPerWeek: "multiple-days-per-week",
  specificDayOfMonth: "specific-day-of-month",
  multipleDaysPerMonth: "multiple-days-per-month",
}

/**
 * Insert at the top of the list
 */
model PositionTop {
  type: "top";
}

/**
 * Insert at the bottom of the list
 */
model PositionBottom {
  type: "bottom";
}

/**
 * Insert after a specific todo
 */
model PositionAfter {
  type: "after";

  /**
   * ID of the todo to insert after
   */
  id: string;
}

/**
 * Position for inserting a new todo
 */
union TodoPosition {
  PositionTop,
  PositionBottom,
  PositionAfter,
}

/**
 * A todo item
 */
model Todo {
  /**
   * Unique identifier for the todo
   */
  id: string;

  /**
   * The task description
   */
  task: string;

  /**
   * Additional details stored as JSON
   */
  details?: {};

  /**
   * Current status of the todo
   */
  status: TodoStatus;

  /**
   * When the todo was created
   */
  @encodedName("application/json", "date_created")
  dateCreated: utcDateTime;

  /**
   * When the todo was last updated
   */
  @encodedName("application/json", "date_updated")
  dateUpdated: utcDateTime;

  /**
   * ID of the user who owns this todo
   */
  @encodedName("application/json", "user_id")
  userId: string;

  /**
   * Order/position of the todo in the list
   */
  order: string;

  /**
   * Integer priority position (0-based index in the ordered list)
   */
  priority?: int32;

  /**
   * Calculated desirability score for weighted random selection
   */
  desirability?: float32;

  /**
   * Importance level (0-5)
   */
  importance?: Importance;

  /**
   * Estimated time to complete
   */
  @encodedName("application/json", "time_estimate")
  timeEstimate?: TimeEstimate;

  /**
   * Annoyingness level (0-4)
   */
  annoyingness: Annoyingness;

  /**
   * Whether the todo is committed
   */
  committed: boolean;

  /**
   * Elapsed time in seconds for timer
   */
  elapsedTimeSeconds: int32;

  /**
   * Whether the todo is atomic (cannot be broken down)
   */
  atomic: boolean;

  /**
   * Whether the todo is infinitely divisible
   */
  @encodedName("application/json", "infinitely_divisible")
  infinitelyDivisible: boolean;
}

/**
 * Request body for creating a new todo
 */
model CreateTodoRequest {
  /**
   * The task description
   */
  task: string;

  /**
   * Additional details stored as JSON
   */
  details?: {};

  /**
   * Current status of the todo (defaults to 'todo')
   */
  status?: TodoStatus;

  /**
   * Where to insert the todo (defaults to top)
   */
  position?: TodoPosition;

  /**
   * Importance level (0-5)
   */
  importance?: Importance;

  /**
   * Estimated time to complete
   */
  @encodedName("application/json", "time_estimate")
  timeEstimate?: TimeEstimate;

  /**
   * Annoyingness level (0-4)
   */
  annoyingness?: Annoyingness;

  /**
   * Whether the todo is committed (defaults to false)
   */
  committed?: boolean;

  /**
   * Whether the todo is atomic (defaults to false)
   */
  atomic?: boolean;

  /**
   * Whether the todo is infinitely divisible (defaults to false)
   */
  @encodedName("application/json", "infinitely_divisible")
  infinitelyDivisible?: boolean;
}

/**
 * Request body for overriding elapsed time
 */
model OverrideElapsedTimeRequest {
  /**
   * Hours component of elapsed time
   */
  hours: int32;

  /**
   * Minutes component of elapsed time
   */
  minutes: int32;
}

/**
 * Request body for reordering a todo
 */
model ReorderTodoRequest {
  /**
   * New position for the todo
   */
  position: TodoPosition;
}

/**
 * Request body for updating a todo
 */
model UpdateTodoRequest {
  /**
   * The task description
   */
  task?: string;

  /**
   * Additional details stored as JSON
   */
  details?: {};

  /**
   * Current status of the todo
   */
  status?: TodoStatus;

  /**
   * Importance level (0-5)
   */
  importance?: Importance;

  /**
   * Estimated time to complete
   */
  @encodedName("application/json", "time_estimate")
  timeEstimate?: TimeEstimate;

  /**
   * Annoyingness level (0-4)
   */
  annoyingness?: Annoyingness;

  /**
   * Whether the todo is committed
   */
  committed?: boolean;

  /**
   * Whether the todo is atomic
   */
  atomic?: boolean;

  /**
   * Whether the todo is infinitely divisible
   */
  @encodedName("application/json", "infinitely_divisible")
  infinitelyDivisible?: boolean;
}

/**
 * A habit item
 */
model Habit {
  /**
   * Unique identifier for the habit
   */
  id: string;

  /**
   * The habit description
   */
  task: string;

  /**
   * Additional details stored as JSON
   */
  details?: {};

  /**
   * Current status of the habit
   */
  status: TodoStatus;

  /**
   * When the habit was created
   */
  @encodedName("application/json", "date_created")
  dateCreated: utcDateTime;

  /**
   * When the habit was last updated
   */
  @encodedName("application/json", "date_updated")
  dateUpdated: utcDateTime;

  /**
   * ID of the user who owns this habit
   */
  @encodedName("application/json", "user_id")
  userId: string;

  /**
   * Order/position of the habit in the list
   */
  order: string;

  /**
   * Integer priority position (0-based index in the ordered list)
   */
  priority?: int32;

  /**
   * Calculated desirability score for weighted random selection
   */
  desirability?: float32;

  /**
   * Importance level (0-5)
   */
  importance?: Importance;

  /**
   * Estimated time to complete
   */
  @encodedName("application/json", "time_estimate")
  timeEstimate?: TimeEstimate;

  /**
   * Annoyingness level (0-4)
   */
  annoyingness: Annoyingness;

  /**
   * Whether the habit is committed
   */
  committed: boolean;

  /**
   * Elapsed time in seconds for timer
   */
  elapsedTimeSeconds: int32;

  /**
   * Whether the habit is atomic (cannot be broken down)
   */
  atomic: boolean;

  /**
   * Whether the habit is infinitely divisible
   */
  @encodedName("application/json", "infinitely_divisible")
  infinitelyDivisible: boolean;

  /**
   * Frequency kind for recurring habits
   * Constraints:
   * - If 'specific-days-per-week', daysOfWeek must be provided
   * - If 'multiple-days-per-week', numTimesPerWeek must be provided
   * - If 'specific-day-of-month', dayOfMonth must be provided
   * - If 'multiple-days-per-month', numTimesPerMonth must be provided
   */
  @encodedName("application/json", "frequency_kind")
  frequencyKind: FrequencyKind;

  /**
   * Days of the week (0-6, where 0=Monday, 6=Sunday)
   * Required when frequencyKind is 'specific-days-per-week'
   */
  @encodedName("application/json", "days_of_week")
  daysOfWeek?: int32[];

  /**
   * Number of times per week
   * Required when frequencyKind is 'multiple-days-per-week'
   */
  @encodedName("application/json", "num_times_per_week")
  numTimesPerWeek?: int32;

  /**
   * Number of times per month
   * Required when frequencyKind is 'multiple-days-per-month'
   */
  @encodedName("application/json", "num_times_per_month")
  numTimesPerMonth?: int32;

  /**
   * Day of the month (1-31)
   * Required when frequencyKind is 'specific-day-of-month'
   */
  @encodedName("application/json", "day_of_month")
  dayOfMonth?: int32;

  /**
   * Days of the week when habit was completed this week (0-6, where 0=Monday, 6=Sunday)
   */
  @encodedName("application/json", "done_this_week")
  doneThisWeek: int32[];
}

/**
 * Request body for creating a new habit
 */
model CreateHabitRequest {
  /**
   * The habit description
   */
  task: string;

  /**
   * Additional details stored as JSON
   */
  details?: {};

  /**
   * Current status of the habit (defaults to 'todo')
   */
  status?: TodoStatus;

  /**
   * Where to insert the habit (defaults to top)
   */
  position?: TodoPosition;

  /**
   * Importance level (0-5)
   */
  importance?: Importance;

  /**
   * Estimated time to complete
   */
  @encodedName("application/json", "time_estimate")
  timeEstimate?: TimeEstimate;

  /**
   * Annoyingness level (0-4)
   */
  annoyingness?: Annoyingness;

  /**
   * Whether the habit is committed (defaults to false)
   */
  committed?: boolean;

  /**
   * Whether the habit is atomic (defaults to false)
   */
  atomic?: boolean;

  /**
   * Whether the habit is infinitely divisible (defaults to false)
   */
  @encodedName("application/json", "infinitely_divisible")
  infinitelyDivisible?: boolean;

  /**
   * Frequency kind for recurring habits
   * Constraints:
   * - If 'specific-days-per-week', daysOfWeek must be provided
   * - If 'multiple-days-per-week', numTimesPerWeek must be provided
   * - If 'specific-day-of-month', dayOfMonth must be provided
   * - If 'multiple-days-per-month', numTimesPerMonth must be provided
   */
  @encodedName("application/json", "frequency_kind")
  frequencyKind: FrequencyKind;

  /**
   * Days of the week (0-6, where 0=Monday, 6=Sunday)
   * Required when frequencyKind is 'specific-days-per-week'
   */
  @encodedName("application/json", "days_of_week")
  daysOfWeek?: int32[];

  /**
   * Number of times per week
   * Required when frequencyKind is 'multiple-days-per-week'
   */
  @encodedName("application/json", "num_times_per_week")
  numTimesPerWeek?: int32;

  /**
   * Number of times per month
   * Required when frequencyKind is 'multiple-days-per-month'
   */
  @encodedName("application/json", "num_times_per_month")
  numTimesPerMonth?: int32;

  /**
   * Day of the month (1-31)
   * Required when frequencyKind is 'specific-day-of-month'
   */
  @encodedName("application/json", "day_of_month")
  dayOfMonth?: int32;
}

/**
 * Request body for updating a habit
 */
model UpdateHabitRequest {
  /**
   * The habit description
   */
  task?: string;

  /**
   * Additional details stored as JSON
   */
  details?: {};

  /**
   * Current status of the habit
   */
  status?: TodoStatus;

  /**
   * Importance level (0-5)
   */
  importance?: Importance;

  /**
   * Estimated time to complete
   */
  @encodedName("application/json", "time_estimate")
  timeEstimate?: TimeEstimate;

  /**
   * Annoyingness level (0-4)
   */
  annoyingness?: Annoyingness;

  /**
   * Whether the habit is committed
   */
  committed?: boolean;

  /**
   * Whether the habit is atomic
   */
  atomic?: boolean;

  /**
   * Whether the habit is infinitely divisible
   */
  @encodedName("application/json", "infinitely_divisible")
  infinitelyDivisible?: boolean;

  /**
   * Frequency kind for recurring habits
   * Constraints:
   * - If 'specific-days-per-week', daysOfWeek must be provided
   * - If 'multiple-days-per-week', numTimesPerWeek must be provided
   * - If 'specific-day-of-month', dayOfMonth must be provided
   * - If 'multiple-days-per-month', numTimesPerMonth must be provided
   */
  @encodedName("application/json", "frequency_kind")
  frequencyKind?: FrequencyKind;

  /**
   * Days of the week (0-6, where 0=Monday, 6=Sunday)
   * Required when frequencyKind is 'specific-days-per-week'
   */
  @encodedName("application/json", "days_of_week")
  daysOfWeek?: int32[];

  /**
   * Number of times per week
   * Required when frequencyKind is 'multiple-days-per-week'
   */
  @encodedName("application/json", "num_times_per_week")
  numTimesPerWeek?: int32;

  /**
   * Number of times per month
   * Required when frequencyKind is 'multiple-days-per-month'
   */
  @encodedName("application/json", "num_times_per_month")
  numTimesPerMonth?: int32;

  /**
   * Day of the month (1-31)
   * Required when frequencyKind is 'specific-day-of-month'
   */
  @encodedName("application/json", "day_of_month")
  dayOfMonth?: int32;
}

/**
 * Request body for logging a habit completion
 */
model LogHabitRequest {
  /**
   * The date when the habit was completed (YYYY-MM-DD format)
   */
  when: plainDate;
}

/**
 * A fun item
 */
model Fun {
  /**
   * Unique identifier for the fun
   */
  id: string;

  /**
   * The fun title
   */
  title: string;

  /**
   * ID of the user who owns this fun
   */
  @encodedName("application/json", "user_id")
  userId: string;

  /**
   * Order/position of the fun in the list
   */
  order: string;

  /**
   * When the fun was created
   */
  @encodedName("application/json", "date_created")
  dateCreated: utcDateTime;

  /**
   * When the fun was last updated
   */
  @encodedName("application/json", "date_updated")
  dateUpdated: utcDateTime;
}

/**
 * Request body for creating a new fun
 */
model CreateFunRequest {
  /**
   * The fun title
   */
  title: string;

  /**
   * Where to insert the fun (defaults to top)
   */
  position?: TodoPosition;
}

/**
 * Request body for updating a fun
 */
model UpdateFunRequest {
  /**
   * The fun title
   */
  title?: string;
}

/**
 * Error response
 */
model ErrorResponse {
  /**
   * Error message
   */
  message: string;

  /**
   * Error code
   */
  code?: string;
}

/**
 * User model
 */
model User {
  /**
   * Unique identifier for the user
   */
  id: string;

  /**
   * User's email address
   */
  email: string;

  /**
   * Whether the user account is active
   */
  @encodedName("application/json", "is_active")
  isActive: boolean;

  /**
   * When the user was created
   */
  @encodedName("application/json", "date_created")
  dateCreated: utcDateTime;

  /**
   * When the user was last updated
   */
  @encodedName("application/json", "date_updated")
  dateUpdated: utcDateTime;
}

/**
 * Request body for user registration
 */
model UserRegisterRequest {
  /**
   * User's email address
   */
  email: string;

  /**
   * User's password
   */
  password: string;
}

/**
 * Request body for user login
 */
model UserLoginRequest {
  /**
   * User's email address
   */
  email: string;

  /**
   * User's password
   */
  password: string;
}

/**
 * JWT token response
 */
model Token {
  /**
   * JWT access token
   */
  @encodedName("application/json", "access_token")
  accessToken: string;

  /**
   * Token type (always 'bearer')
   */
  @encodedName("application/json", "token_type")
  tokenType: string;
}

@route("/api/todos")
@tag("Todos")
interface Todos {
  /**
   * List all todos for the authenticated user
   */
  @get
  list(): {
    @statusCode statusCode: 200;
    @body todos: Todo[];
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Create a new todo
   */
  @post
  create(@body todo: CreateTodoRequest): {
    @statusCode statusCode: 201;
    @body todo: Todo;
  } | {
    @statusCode statusCode: 400;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Get a specific todo by ID
   */
  @get
  @route("/{id}")
  get(@path id: string): {
    @statusCode statusCode: 200;
    @body todo: Todo;
  } | {
    @statusCode statusCode: 404;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Update a todo
   */
  @patch(#{ implicitOptionality: true })
  @route("/{id}")
  update(@path id: string, @body todo: UpdateTodoRequest):
    | {
        @statusCode statusCode: 200;
        @body todo: Todo;
      }
    | {
        @statusCode statusCode: 400;
        @body error: ErrorResponse;
      }
    | {
        @statusCode statusCode: 404;
        @body error: ErrorResponse;
      }
    | {
        @statusCode statusCode: 500;
        @body error: ErrorResponse;
      };

  /**
   * Delete a todo
   */
  @delete
  @route("/{id}")
  delete(@path id: string): {
    @statusCode statusCode: 204;
  } | {
    @statusCode statusCode: 404;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Reorder a todo
   */
  @post
  @route("/{id}/reorder")
  reorder(@path id: string, @body request: ReorderTodoRequest):
    | {
        @statusCode statusCode: 200;
        @body todo: Todo;
      }
    | {
        @statusCode statusCode: 400;
        @body error: ErrorResponse;
      }
    | {
        @statusCode statusCode: 404;
        @body error: ErrorResponse;
      }
    | {
        @statusCode statusCode: 500;
        @body error: ErrorResponse;
      };

  /**
   * Start a timer for a todo
   */
  @post
  @route("/{id}/start-timer")
  startTimer(@path id: string): {
    @statusCode statusCode: 200;
  } | {
    @statusCode statusCode: 404;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Stop a timer for a todo
   */
  @post
  @route("/{id}/stop-timer")
  stopTimer(@path id: string): {
    @statusCode statusCode: 200;
  } | {
    @statusCode statusCode: 404;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Override elapsed time for a todo
   */
  @post
  @route("/{id}/time-elapsed-override")
  overrideElapsedTime(
    @path id: string,
    @body request: OverrideElapsedTimeRequest,
  ): {
    @statusCode statusCode: 200;
  } | {
    @statusCode statusCode: 404;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Generate break-up todos across all todos
   */
  @post
  @route("/generate-break-up-todos")
  generateBreakUpTodos(): {
    @statusCode statusCode: 200;
    @body todos: Todo[];
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };
}

@route("/api/habits")
@tag("Habits")
interface Habits {
  /**
   * List all habits for the authenticated user
   */
  @get
  list(): {
    @statusCode statusCode: 200;
    @body habits: Habit[];
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Create a new habit
   */
  @post
  create(@body habit: CreateHabitRequest): {
    @statusCode statusCode: 201;
    @body habit: Habit;
  } | {
    @statusCode statusCode: 400;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Get a specific habit by ID
   */
  @get
  @route("/{id}")
  get(@path id: string): {
    @statusCode statusCode: 200;
    @body habit: Habit;
  } | {
    @statusCode statusCode: 404;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Update a habit
   */
  @patch(#{ implicitOptionality: true })
  @route("/{id}")
  update(@path id: string, @body habit: UpdateHabitRequest):
    | {
        @statusCode statusCode: 200;
        @body habit: Habit;
      }
    | {
        @statusCode statusCode: 400;
        @body error: ErrorResponse;
      }
    | {
        @statusCode statusCode: 404;
        @body error: ErrorResponse;
      }
    | {
        @statusCode statusCode: 500;
        @body error: ErrorResponse;
      };

  /**
   * Delete a habit
   */
  @delete
  @route("/{id}")
  delete(@path id: string): {
    @statusCode statusCode: 204;
  } | {
    @statusCode statusCode: 404;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Log a habit completion
   */
  @post
  @route("/{id}/log")
  logHabit(@path id: string, @body request: LogHabitRequest): {
    @statusCode statusCode: 200;
  } | {
    @statusCode statusCode: 404;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Delete a habit log entry
   */
  @delete
  @route("/{id}/log/{date}")
  deleteHabitLog(@path id: string, @path date: plainDate): {
    @statusCode statusCode: 204;
  } | {
    @statusCode statusCode: 404;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };
}

@route("/api/funs")
@tag("Funs")
interface Funs {
  /**
   * List all funs for the authenticated user
   */
  @get
  list(): {
    @statusCode statusCode: 200;
    @body funs: Fun[];
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Create a new fun
   */
  @post
  create(@body fun: CreateFunRequest): {
    @statusCode statusCode: 201;
    @body fun: Fun;
  } | {
    @statusCode statusCode: 400;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Get a specific fun by ID
   */
  @get
  @route("/{id}")
  get(@path id: string): {
    @statusCode statusCode: 200;
    @body fun: Fun;
  } | {
    @statusCode statusCode: 404;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Update a fun
   */
  @patch(#{ implicitOptionality: true })
  @route("/{id}")
  update(@path id: string, @body fun: UpdateFunRequest):
    | {
        @statusCode statusCode: 200;
        @body fun: Fun;
      }
    | {
        @statusCode statusCode: 400;
        @body error: ErrorResponse;
      }
    | {
        @statusCode statusCode: 404;
        @body error: ErrorResponse;
      }
    | {
        @statusCode statusCode: 500;
        @body error: ErrorResponse;
      };

  /**
   * Delete a fun
   */
  @delete
  @route("/{id}")
  delete(@path id: string): {
    @statusCode statusCode: 204;
  } | {
    @statusCode statusCode: 404;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Reorder a fun
   */
  @post
  @route("/{id}/reorder")
  reorder(@path id: string, @body request: ReorderTodoRequest):
    | {
        @statusCode statusCode: 200;
        @body fun: Fun;
      }
    | {
        @statusCode statusCode: 400;
        @body error: ErrorResponse;
      }
    | {
        @statusCode statusCode: 404;
        @body error: ErrorResponse;
      }
    | {
        @statusCode statusCode: 500;
        @body error: ErrorResponse;
      };
}

@route("/api/weighted-random-todos")
@tag("Todos")
interface WeightedRandomTodos {
  /**
   * Get weighted random todos for the authenticated user
   */
  @get
  list(
    @query n: int32,

    @query
    @encodedName("application/json", "max_time_estimate")
    maxTimeEstimate?: TimeEstimate,
  ): {
    @statusCode statusCode: 200;
    @body todos: Todo[];
  } | {
    @statusCode statusCode: 400;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };
}

@route("/api/weighted-random-funs")
@tag("Funs")
interface WeightedRandomFuns {
  /**
   * Get weighted random funs for the authenticated user
   */
  @get
  list(
    @query n: int32,

    @query
    @encodedName("application/json", "exclude_ids")
    excludeIds?: string[],
  ): {
    @statusCode statusCode: 200;
    @body funs: Fun[];
  } | {
    @statusCode statusCode: 400;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };
}

@route("/api/auth")
@tag("Authentication")
interface Auth {
  /**
   * Register a new user
   */
  @post
  @route("/register")
  @useAuth(NoAuth)
  register(@body user: UserRegisterRequest): {
    @statusCode statusCode: 201;
    @body user: User;
  } | {
    @statusCode statusCode: 400;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Login with email and password
   */
  @post
  @route("/login")
  @useAuth(NoAuth)
  login(@body credentials: UserLoginRequest): {
    @statusCode statusCode: 200;
    @body token: Token;
  } | {
    @statusCode statusCode: 401;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Get current authenticated user
   */
  @get
  @route("/me")
  getCurrentUser(): {
    @statusCode statusCode: 200;
    @body user: User;
  } | {
    @statusCode statusCode: 401;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Refresh access token using refresh token from httpOnly cookie
   */
  @post
  @route("/refresh")
  @useAuth(NoAuth)
  refreshToken(): {
    @statusCode statusCode: 200;
    @body token: Token;
  } | {
    @statusCode statusCode: 401;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Logout user by clearing refresh token cookie
   */
  @post
  @route("/logout")
  @useAuth(NoAuth)
  logout(): {
    @statusCode statusCode: 200;
  } | {
    @statusCode statusCode: 401;
    @body error: ErrorResponse;
  };
}
