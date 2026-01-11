import "@typespec/http";
import "@typespec/openapi3";

using TypeSpec.Http;

@service(#{ title: "Fllstck Tmplt API" })
@server("http://localhost:8000", "Development server")
@useAuth(BearerAuth)
namespace FllstckTmpltAPI;

@route("/api/auth")
@tag("Authentication")
interface AuthAPI {
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

@route("/api/note")
@tag("Note")
interface NoteAPI {
  /**
   * List all notes for the authenticated user
   */
  @get
  list(): {
    @statusCode statusCode: 200;
    @body notes: Note[];
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Create a new note
   */
  @post
  create(@body note: CreateNoteRequest): {
    @statusCode statusCode: 201;
    @body note: Note;
  } | {
    @statusCode statusCode: 400;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Get a specific note by ID
   */
  @get
  @route("/{id}")
  get(@path id: string): {
    @statusCode statusCode: 200;
    @body note: Note;
  } | {
    @statusCode statusCode: 404;
    @body error: ErrorResponse;
  } | {
    @statusCode statusCode: 500;
    @body error: ErrorResponse;
  };

  /**
   * Update a note
   */
  @patch(#{ implicitOptionality: true })
  @route("/{id}")
  update(@path id: string, @body note: UpdateNoteRequest):
    | {
        @statusCode statusCode: 200;
        @body note: Note;
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
   * Delete a note
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
}

model ErrorResponse {
  message: string;
  code?: string;
}

model User {
  id: string;
  email: string;

  @encodedName("application/json", "is_active")
  isActive: boolean;

  @encodedName("application/json", "date_created")
  dateCreated: utcDateTime;

  @encodedName("application/json", "date_updated")
  dateUpdated: utcDateTime;
}

model UserRegisterRequest {
  email: string;
  password: string;
}

model UserLoginRequest {
  email: string;
  password: string;
}

model Token {
  @encodedName("application/json", "access_token")
  accessToken: string;

  @encodedName("application/json", "token_type")
  tokenType: string;
}

model Note {
  id: string;
  title: string;
  content: string;

  @encodedName("application/json", "user_id")
  userId: string;

  @encodedName("application/json", "date_created")
  dateCreated: utcDateTime;

  @encodedName("application/json", "date_updated")
  dateUpdated: utcDateTime;
}

model CreateNoteRequest {
  title: string;
  content: string;
}

model UpdateNoteRequest {
  title?: string;
  content?: string;
}
