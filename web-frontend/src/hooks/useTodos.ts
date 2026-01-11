import { useEffect, useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import type { Todo, TodoStatus } from '@/types/todo';
import type { JSONContent } from '@tiptap/react';
import {
    todosList,
    todosCreate,
    todosUpdate,
    todosDelete,
    todosGenerateBreakUpTodos,
    todosReorder,
} from '@/lib/api';

export function useTodos() {
    const [todos, setTodos] = useState<Todo[]>([]);
    const [loading, setLoading] = useState(true);
    const { currentUser } = useAuth();

    useEffect(() => {
        if (!currentUser) {
            setTodos([]);
            setLoading(false);
            return;
        }

        const fetchTodos = async () => {
            try {
                const { data: todosData } = await todosList();

                if (todosData) {
                    // Filter to show only active todos (not archived)
                    const activeTodos = todosData.filter((todo) =>
                        ['todo', 'complete', 'waiting'].includes(todo.status)
                    );

                    // Convert backend format to frontend format
                    const formattedTodos: Todo[] = activeTodos.map((todo) => ({
                        id: todo.id,
                        task: todo.task,
                        details: todo.details || null,
                        status: todo.status,
                        dateCreated: new Date(todo.date_created),
                        dateUpdated: new Date(todo.date_updated),
                        userId: todo.user_id,
                        order: todo.order,
                        importance: todo.importance ?? 1,
                        timeEstimate: todo.time_estimate,
                        annoyingness: todo.annoyingness,
                        committed: todo.committed,
                        elapsedTimeSeconds: todo.elapsedTimeSeconds ?? 0,
                        atomic: todo.atomic,
                        infinitelyDivisible: todo.infinitely_divisible,
                    }));

                    // Backend already returns todos sorted by order field
                    setTodos(formattedTodos);
                }
            } catch (error) {
                console.error('Failed to fetch todos:', error);
            } finally {
                setLoading(false);
            }
        };

        fetchTodos();
    }, [currentUser]);

    const addTodo = async (
        task: string,
        details: JSONContent | null,
        position: 'top' | 'bottom' = 'top',
        afterId?: string
    ): Promise<string> => {
        if (!currentUser) throw new Error('User must be logged in');

        // Determine insert index for optimistic update
        let insertIndex: number;
        if (afterId) {
            const afterIndex = todos.findIndex((t) => t.id === afterId);
            if (afterIndex === -1) {
                throw new Error('Todo not found');
            }
            insertIndex = afterIndex + 1;
        } else if (position === 'bottom') {
            insertIndex = todos.length;
        } else {
            insertIndex = 0;
        }

        try {
            // Build position parameter
            let positionParam;
            if (afterId) {
                positionParam = { type: 'after' as const, id: afterId };
            } else if (position === 'bottom') {
                positionParam = { type: 'bottom' as const };
            } else {
                positionParam = { type: 'top' as const };
            }

            // Create the todo on the backend
            const { data: newTodo } = await todosCreate({
                body: {
                    task,
                    details: details || undefined,
                    status: 'todo',
                    position: positionParam,
                    importance: 1,
                    annoyingness: 0,
                },
            });

            if (newTodo) {
                // Add to local state at the correct position
                const formattedTodo: Todo = {
                    id: newTodo.id,
                    task: newTodo.task,
                    details: newTodo.details || null,
                    status: newTodo.status,
                    dateCreated: new Date(newTodo.date_created),
                    dateUpdated: new Date(newTodo.date_updated),
                    userId: newTodo.user_id,
                    order: newTodo.order,
                    importance: newTodo.importance ?? 1,
                    timeEstimate: newTodo.time_estimate,
                    annoyingness: newTodo.annoyingness,
                    committed: newTodo.committed,
                    elapsedTimeSeconds: newTodo.elapsedTimeSeconds ?? 0,
                    atomic: newTodo.atomic,
                    infinitelyDivisible: newTodo.infinitely_divisible,
                };

                setTodos((prevTodos) => {
                    const updated = [...prevTodos];
                    updated.splice(insertIndex, 0, formattedTodo);
                    return updated;
                });

                return newTodo.id;
            }

            throw new Error('Failed to create todo - no response from server');
        } catch (error) {
            console.error('Failed to create todo:', error);
            throw error;
        }
    };

    const toggleTodo = async (id: string, currentStatus: TodoStatus) => {
        const newStatus: TodoStatus =
            currentStatus === 'todo' ? 'complete' : 'todo';
        const now = new Date();

        // Update local state immediately for optimistic UI
        setTodos((prevTodos) =>
            prevTodos.map((todo) =>
                todo.id === id
                    ? { ...todo, status: newStatus, dateUpdated: now }
                    : todo
            )
        );

        try {
            // Sync to backend
            await todosUpdate({
                path: { id },
                body: { status: newStatus },
            });
        } catch (error) {
            // Rollback on error
            setTodos((prevTodos) =>
                prevTodos.map((todo) =>
                    todo.id === id ? { ...todo, status: currentStatus } : todo
                )
            );
            console.error('Failed to toggle todo:', error);
        }
    };

    const updateTodo = async (
        id: string,
        updates: Partial<
            Pick<
                Todo,
                | 'task'
                | 'details'
                | 'importance'
                | 'status'
                | 'timeEstimate'
                | 'annoyingness'
                | 'committed'
                | 'atomic'
                | 'infinitelyDivisible'
            >
        >
    ) => {
        const now = new Date();

        // Update local state immediately for optimistic UI
        setTodos((prevTodos) =>
            prevTodos.map((todo) =>
                todo.id === id
                    ? { ...todo, ...updates, dateUpdated: now }
                    : todo
            )
        );

        // Only save if task has content (if task is being updated)
        if (updates.task !== undefined && !updates.task.trim()) {
            return;
        }

        try {
            // Sync to backend
            await todosUpdate({
                path: { id },
                body: {
                    ...(updates.task !== undefined && {
                        task: updates.task.trim(),
                    }),
                    ...(updates.details !== undefined &&
                        updates.details !== null && {
                            details: updates.details,
                        }),
                    ...(updates.importance !== undefined && {
                        importance: updates.importance,
                    }),
                    ...(updates.status !== undefined && {
                        status: updates.status,
                    }),
                    ...(updates.timeEstimate !== undefined && {
                        time_estimate: updates.timeEstimate,
                    }),
                    ...(updates.annoyingness !== undefined && {
                        annoyingness: updates.annoyingness,
                    }),
                    ...(updates.committed !== undefined && {
                        committed: updates.committed,
                    }),
                    ...(updates.atomic !== undefined && {
                        atomic: updates.atomic,
                    }),
                    ...(updates.infinitelyDivisible !== undefined && {
                        infinitely_divisible: updates.infinitelyDivisible,
                    }),
                },
            });
        } catch (error) {
            console.error('Failed to update todo:', error);
        }
    };

    const deleteTodo = async (id: string) => {
        // Remove from local state immediately for optimistic UI
        setTodos((prevTodos) => prevTodos.filter((todo) => todo.id !== id));

        try {
            // Delete from backend
            await todosDelete({ path: { id } });
        } catch (error) {
            console.error('Failed to delete todo:', error);
        }
    };

    const reorderTodos = async (oldIndex: number, newIndex: number) => {
        if (oldIndex === newIndex) return;

        const movedTodo = todos[oldIndex];

        // Determine position parameter for backend
        let positionParam;
        if (newIndex === 0) {
            // Moving to the top
            positionParam = { type: 'top' as const };
        } else if (newIndex === todos.length - 1) {
            // Moving to the bottom
            positionParam = { type: 'bottom' as const };
        } else if (oldIndex < newIndex) {
            // Moving down - insert after the todo that's currently at newIndex
            positionParam = { type: 'after' as const, id: todos[newIndex].id };
        } else {
            // Moving up - insert after the todo that's before newIndex
            positionParam = { type: 'after' as const, id: todos[newIndex - 1].id };
        }

        // Optimistically update local state
        setTodos((prevTodos) => {
            const updated = [...prevTodos];
            const [moved] = updated.splice(oldIndex, 1);
            updated.splice(newIndex, 0, moved);
            return updated;
        });

        try {
            // Sync to backend
            const { data: updatedTodo } = await todosReorder({
                path: { id: movedTodo.id },
                body: { position: positionParam },
            });

            // Update with the server-calculated order
            if (updatedTodo) {
                setTodos((prevTodos) =>
                    prevTodos.map((todo) =>
                        todo.id === updatedTodo.id
                            ? {
                                  ...todo,
                                  order: updatedTodo.order,
                                  dateUpdated: new Date(updatedTodo.date_updated),
                              }
                            : todo
                    )
                );
            }
        } catch (error) {
            console.error('Failed to reorder todo:', error);
            // Rollback on error - refetch todos
            const { data: todosData } = await todosList();
            if (todosData) {
                const activeTodos = todosData.filter((todo) =>
                    ['todo', 'complete', 'waiting'].includes(todo.status)
                );
                const formattedTodos: Todo[] = activeTodos.map((todo) => ({
                    id: todo.id,
                    task: todo.task,
                    details: todo.details || null,
                    status: todo.status,
                    dateCreated: new Date(todo.date_created),
                    dateUpdated: new Date(todo.date_updated),
                    userId: todo.user_id,
                    order: todo.order,
                    importance: todo.importance ?? 1,
                    timeEstimate: todo.time_estimate,
                    annoyingness: todo.annoyingness,
                    committed: todo.committed,
                    elapsedTimeSeconds: todo.elapsedTimeSeconds ?? 0,
                    atomic: todo.atomic,
                    infinitelyDivisible: todo.infinitely_divisible,
                }));
                setTodos(formattedTodos);
            }
        }
    };

    const archiveCompleted = async () => {
        const completedTodos = todos.filter(
            (todo) => todo.status === 'complete'
        );

        if (completedTodos.length === 0) return;

        const now = new Date();

        // Update local state immediately for optimistic UI
        setTodos((prevTodos) =>
            prevTodos.map((todo) =>
                todo.status === 'complete'
                    ? {
                          ...todo,
                          status: 'archived' as TodoStatus,
                          dateUpdated: now,
                      }
                    : todo
            )
        );

        try {
            // Update each completed todo to archived status
            await Promise.all(
                completedTodos.map((todo) =>
                    todosUpdate({
                        path: { id: todo.id },
                        body: { status: 'archived' },
                    })
                )
            );
        } catch (error) {
            console.error('Failed to archive completed todos:', error);
        }
    };

    const generateBreakUpTodos = async () => {
        if (!currentUser) throw new Error('User must be logged in');

        try {
            // Call the API to generate break-up todos
            const { data: todosData } = await todosGenerateBreakUpTodos();

            if (todosData) {
                // Filter to show only active todos (not archived)
                const activeTodos = todosData.filter((todo) =>
                    ['todo', 'complete', 'waiting'].includes(todo.status)
                );

                // Convert backend format to frontend format
                const formattedTodos: Todo[] = activeTodos.map((todo) => ({
                    id: todo.id,
                    task: todo.task,
                    details: todo.details || null,
                    status: todo.status,
                    dateCreated: new Date(todo.date_created),
                    dateUpdated: new Date(todo.date_updated),
                    userId: todo.user_id,
                    order: todo.order,
                    importance: todo.importance ?? 1,
                    timeEstimate: todo.time_estimate,
                    annoyingness: todo.annoyingness,
                    committed: todo.committed,
                    elapsedTimeSeconds: todo.elapsedTimeSeconds ?? 0,
                    atomic: todo.atomic,
                    infinitelyDivisible: todo.infinitely_divisible,
                }));

                // Update the todos state with the new list
                setTodos(formattedTodos);
            }
        } catch (error) {
            console.error('Failed to generate break-up todos:', error);
            throw error;
        }
    };

    return {
        todos,
        loading,
        addTodo,
        toggleTodo,
        updateTodo,
        deleteTodo,
        reorderTodos,
        archiveCompleted,
        generateBreakUpTodos,
    };
}
