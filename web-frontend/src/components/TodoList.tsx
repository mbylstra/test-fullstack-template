import { useState, useEffect, useRef } from 'react';
import { Button } from '@/components/shadcn/button';
import { Plus } from 'lucide-react';
import type { Todo, TodoStatus, TimeEstimate } from '@/types/todo';
import type { JSONContent } from '@tiptap/react';
import { SortableTodoItem } from '@/components/SortableTodoItem';
import RandomTodoDialog from '@/components/RandomTodoDialog';
import { todosStartTimer, todosStopTimer } from '@/lib/api';
import {
    DndContext,
    closestCenter,
    KeyboardSensor,
    PointerSensor,
    useSensor,
    useSensors,
    type DragEndEvent,
} from '@dnd-kit/core';
import {
    SortableContext,
    sortableKeyboardCoordinates,
    verticalListSortingStrategy,
} from '@dnd-kit/sortable';

interface TodoListProps {
    todos: Todo[];
    loading: boolean;
    onToggleTodo: (id: string, currentStatus: TodoStatus) => Promise<void>;
    onUpdateTodo: (
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
            >
        >
    ) => Promise<void>;
    onReorderTodos: (oldIndex: number, newIndex: number) => Promise<void>;
    onArchiveCompleted: () => Promise<void>;
    onDeleteTodo: (id: string) => Promise<void>;
    onAddTodo: (
        task: string,
        details: null,
        position?: 'top' | 'bottom',
        afterId?: string
    ) => Promise<string>;
    runningTimers: Set<string>;
    onRunningTimersChange: (timers: Set<string>) => void;
    timerStartTimes: Map<string, number>;
    finalizedElapsedTimes: Map<string, number>;
    onOpenRightPanel: (todoId: string) => void;
}

interface TodoSectionProps {
    todos: Todo[];
    editingId: string | null;
    editValue: string;
    editingDetailsId: string | null;
    detailsValue: JSONContent | null;
    onToggleTodo: (id: string, currentStatus: TodoStatus) => Promise<void>;
    onUpdateTodo: (
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
            >
        >
    ) => Promise<void>;
    onStartEdit: (todo: Todo) => void;
    onEditChange: (value: string) => void;
    onFinishEdit: () => Promise<void>;
    onKeyDown: (e: React.KeyboardEvent) => void;
    onStartEditDetails: (todo: Todo) => void;
    onDetailsChange: (content: JSONContent) => void;
    onFinishEditDetails: () => Promise<void>;
    onIncreaseImportance: (todoId: string) => void;
    onDecreaseImportance: (todoId: string) => void;
    onSetTimeEstimate: (todoId: string, estimate: TimeEstimate) => void;
    onSetAnnoyingness: (todoId: string, annoyingness: number) => void;
    onCommit: (todoId: string) => void;
    onDragEnd: (event: DragEndEvent) => Promise<void>;
    inputRef: React.RefObject<HTMLInputElement | null>;
    hoveringTodoId: string | null;
    onHoveringTodoIdChange: (id: string | null) => void;
    openMenusByTodoId: {
        timeEstimate: string | null;
        annoyingness: string | null;
        kebab: string | null;
    };
    onMenuOpen: (
        todoId: string,
        menuKey: 'timeEstimate' | 'annoyingness' | 'kebab'
    ) => void;
    runningTimers: Set<string>;
    onToggleTimer: (todoId: string) => void;
    timerStartTimes: Map<string, number>;
    finalizedElapsedTimes: Map<string, number>;
    onOpenRightPanel: (todoId: string) => void;
}

function TodoSection({
    todos,
    editingId,
    editValue,
    editingDetailsId,
    detailsValue,
    onToggleTodo,
    onUpdateTodo,
    onStartEdit,
    onEditChange,
    onFinishEdit,
    onKeyDown,
    onStartEditDetails,
    onDetailsChange,
    onFinishEditDetails,
    onIncreaseImportance,
    onDecreaseImportance,
    onSetTimeEstimate,
    onSetAnnoyingness,
    onCommit,
    onDragEnd,
    inputRef,
    hoveringTodoId,
    onHoveringTodoIdChange,
    openMenusByTodoId,
    onMenuOpen,
    runningTimers,
    onToggleTimer,
    timerStartTimes,
    finalizedElapsedTimes,
    onOpenRightPanel,
}: TodoSectionProps) {
    const sensors = useSensors(
        useSensor(PointerSensor, {
            activationConstraint: {
                distance: 8,
            },
        }),
        useSensor(KeyboardSensor, {
            coordinateGetter: sortableKeyboardCoordinates,
        })
    );

    return (
        <DndContext
            sensors={sensors}
            collisionDetection={closestCenter}
            onDragEnd={onDragEnd}
        >
            <SortableContext
                items={todos.map((todo) => todo.id)}
                strategy={verticalListSortingStrategy}
            >
                <div>
                    {todos.map((todo) => (
                        <SortableTodoItem
                            key={todo.id}
                            todo={todo}
                            isEditing={editingId === todo.id}
                            editValue={editValue}
                            isEditingDetails={editingDetailsId === todo.id}
                            detailsValue={detailsValue}
                            onToggle={() => onToggleTodo(todo.id, todo.status)}
                            onStartEdit={() => onStartEdit(todo)}
                            onEditChange={onEditChange}
                            onFinishEdit={onFinishEdit}
                            onKeyDown={onKeyDown}
                            onStartEditDetails={() => onStartEditDetails(todo)}
                            onDetailsChange={onDetailsChange}
                            onFinishEditDetails={onFinishEditDetails}
                            onIncreaseImportance={() =>
                                onIncreaseImportance(todo.id)
                            }
                            onDecreaseImportance={() =>
                                onDecreaseImportance(todo.id)
                            }
                            onChangeStatus={(status) =>
                                onUpdateTodo(todo.id, { status })
                            }
                            onSetTimeEstimate={(estimate) =>
                                onSetTimeEstimate(todo.id, estimate)
                            }
                            onSetAnnoyingness={(annoyingness) =>
                                onSetAnnoyingness(todo.id, annoyingness)
                            }
                            onCommit={() => onCommit(todo.id)}
                            inputRef={inputRef}
                            isHovering={
                                hoveringTodoId === todo.id ||
                                openMenusByTodoId.timeEstimate === todo.id ||
                                openMenusByTodoId.annoyingness === todo.id ||
                                openMenusByTodoId.kebab === todo.id
                            }
                            onHoveringChange={(isHovering) =>
                                onHoveringTodoIdChange(
                                    isHovering ? todo.id : null
                                )
                            }
                            onMenuOpenChange={(menuKey, open) => {
                                if (open) {
                                    onMenuOpen(todo.id, menuKey);
                                }
                            }}
                            isTimerRunning={runningTimers.has(todo.id)}
                            onToggleTimer={() => onToggleTimer(todo.id)}
                            timerStartTime={timerStartTimes.get(todo.id)}
                            finalizedElapsedTime={finalizedElapsedTimes.get(
                                todo.id
                            )}
                            onOpenRightPanel={onOpenRightPanel}
                        />
                    ))}
                </div>
            </SortableContext>
        </DndContext>
    );
}

export default function TodoList({
    todos,
    loading,
    onToggleTodo,
    onUpdateTodo,
    onReorderTodos,
    onArchiveCompleted,
    onDeleteTodo,
    onAddTodo,
    runningTimers,
    onRunningTimersChange,
    timerStartTimes,
    finalizedElapsedTimes,
    onOpenRightPanel,
}: TodoListProps) {
    const [editingId, setEditingId] = useState<string | null>(null);
    const [editValue, setEditValue] = useState('');
    const [editingDetailsId, setEditingDetailsId] = useState<string | null>(
        null
    );
    const [detailsValue, setDetailsValue] = useState<JSONContent | null>(null);
    const [newTodoId, setNewTodoId] = useState<string | null>(null);
    const [hoveringTodoId, setHoveringTodoId] = useState<string | null>(null);
    const [openMenusByTodoId, setOpenMenusByTodoId] = useState<{
        timeEstimate: string | null;
        annoyingness: string | null;
        kebab: string | null;
    }>({
        timeEstimate: null,
        annoyingness: null,
        kebab: null,
    });
    const debounceTimerRef = useRef<NodeJS.Timeout | null>(null);
    const detailsDebounceTimerRef = useRef<NodeJS.Timeout | null>(null);
    const inputRef = useRef<HTMLInputElement>(null);
    const finishEditRef = useRef<(() => Promise<void>) | null>(null);

    const handleAddTodo = async (
        position: 'top' | 'bottom' = 'top',
        afterId?: string
    ) => {
        // Finish current edit first if there is one
        if (finishEditRef.current) {
            await finishEditRef.current();
        }

        // Create new todo and enter edit mode
        const newId = await onAddTodo('', null, position, afterId);
        setNewTodoId(newId);
        setEditingId(newId);
        setEditValue('');
    };

    // Auto-focus input when editing starts
    useEffect(() => {
        if (editingId && inputRef.current) {
            inputRef.current.focus();
            inputRef.current.select();
        }
    }, [editingId]);

    // Cleanup debounce timers on unmount
    useEffect(() => {
        return () => {
            if (debounceTimerRef.current) {
                clearTimeout(debounceTimerRef.current);
            }
            if (detailsDebounceTimerRef.current) {
                clearTimeout(detailsDebounceTimerRef.current);
            }
        };
    }, []);

    // Expose handleFinishEdit to parent via ref
    useEffect(() => {
        if (finishEditRef) {
            finishEditRef.current = handleFinishEdit;
        }
    });

    const handleStartEdit = (todo: Todo) => {
        setEditingId(todo.id);
        setEditValue(todo.task);
    };

    const handleEditChange = (value: string) => {
        setEditValue(value);

        // Clear existing debounce timer
        if (debounceTimerRef.current) {
            clearTimeout(debounceTimerRef.current);
        }

        // Set new debounce timer for autosave
        debounceTimerRef.current = setTimeout(async () => {
            if (editingId) {
                await onUpdateTodo(editingId, { task: value.trim() });
            }
        }, 500); // 500ms debounce
    };

    const handleFinishEdit = async (options?: { immediate?: boolean }) => {
        if (debounceTimerRef.current) {
            clearTimeout(debounceTimerRef.current);
        }

        const isNewTodo = editingId === newTodoId;
        const todoId = editingId;
        const todoValue = editValue.trim();

        // Clear editing state immediately if requested (for optimistic updates)
        if (options?.immediate) {
            setEditingId(null);
            setEditValue('');
            if (isNewTodo) {
                setNewTodoId(null);
            }
        }

        // Trigger save/delete in background
        if (todoId && todoValue) {
            const savePromise = onUpdateTodo(todoId, { task: todoValue });
            // If not immediate mode, wait for save to complete
            if (!options?.immediate) {
                await savePromise;
            }
        } else if (isNewTodo && todoId) {
            // Delete empty new todo if user exits without entering a title
            const deletePromise = onDeleteTodo(todoId);
            // If not immediate mode, wait for delete to complete
            if (!options?.immediate) {
                await deletePromise;
            }
        }

        // Clear editing state after save if not in immediate mode
        if (!options?.immediate) {
            setEditingId(null);
            setEditValue('');
            if (isNewTodo) {
                setNewTodoId(null);
            }
        }
    };

    const handleKeyDown = async (e: React.KeyboardEvent) => {
        if (e.key === 'Enter') {
            e.preventDefault(); // Prevent default form submission
            const isNewTodo = editingId === newTodoId;
            const hasContent = editValue.trim().length > 0;
            const currentTodoId = editingId;

            await handleFinishEdit({ immediate: true });

            // If it was a new todo with content, immediately create another new todo below it
            if (isNewTodo && hasContent && currentTodoId) {
                await handleAddTodo('top', currentTodoId);
            }
        } else if (e.key === 'Escape') {
            // Call handleFinishEdit to properly clean up, including deleting empty new todos
            await handleFinishEdit();
        }
    };

    const handleStartEditDetails = (todo: Todo) => {
        setEditingDetailsId(todo.id);
        setDetailsValue(todo.details);
    };

    const handleDetailsChange = (content: JSONContent) => {
        setDetailsValue(content);

        // Clear existing debounce timer
        if (detailsDebounceTimerRef.current) {
            clearTimeout(detailsDebounceTimerRef.current);
        }

        // Set new debounce timer for autosave
        detailsDebounceTimerRef.current = setTimeout(async () => {
            if (editingDetailsId) {
                await onUpdateTodo(editingDetailsId, { details: content });
            }
        }, 500); // 500ms debounce
    };

    const handleFinishEditDetails = async () => {
        if (detailsDebounceTimerRef.current) {
            clearTimeout(detailsDebounceTimerRef.current);
        }

        if (editingDetailsId) {
            await onUpdateTodo(editingDetailsId, { details: detailsValue });
        }

        setEditingDetailsId(null);
        setDetailsValue(null);
    };

    const handleIncreaseImportance = (todoId: string) => {
        const todo = todos.find((t) => t.id === todoId);
        if (todo && todo.importance < 5) {
            onUpdateTodo(todoId, { importance: todo.importance + 1 });
        }
    };

    const handleDecreaseImportance = (todoId: string) => {
        const todo = todos.find((t) => t.id === todoId);
        if (todo && todo.importance > 1) {
            onUpdateTodo(todoId, { importance: todo.importance - 1 });
        }
    };

    const handleSetTimeEstimate = (todoId: string, estimate: TimeEstimate) => {
        onUpdateTodo(todoId, { timeEstimate: estimate });
    };

    const handleSetAnnoyingness = (todoId: string, annoyingness: number) => {
        onUpdateTodo(todoId, { annoyingness });
    };

    const handleCommit = (todoId: string) => {
        const todo = todos.find((t) => t.id === todoId);
        if (todo) {
            onUpdateTodo(todoId, { committed: !todo.committed });
        }
    };

    const handleMenuOpen = (
        todoId: string,
        menuKey: 'timeEstimate' | 'annoyingness' | 'kebab'
    ) => {
        setOpenMenusByTodoId((prev) => ({
            ...prev,
            [menuKey]: todoId,
        }));
    };

    const handleToggleTimer = async (todoId: string) => {
        const isRunning = runningTimers.has(todoId);

        // Update local state immediately for optimistic UI
        const newSet = new Set(runningTimers);
        if (newSet.has(todoId)) {
            newSet.delete(todoId);
        } else {
            newSet.add(todoId);
        }
        onRunningTimersChange(newSet);

        try {
            // Call the appropriate API endpoint
            if (isRunning) {
                // Stop timer
                await todosStopTimer({ path: { id: todoId } });
            } else {
                // Start timer
                await todosStartTimer({ path: { id: todoId } });
            }
        } catch (error) {
            // Rollback on error
            const rollbackSet = new Set(runningTimers);
            if (isRunning) {
                rollbackSet.add(todoId);
            } else {
                rollbackSet.delete(todoId);
            }
            onRunningTimersChange(rollbackSet);
            console.error('Failed to toggle timer:', error);
        }
    };

    const handleDragEnd = async (event: DragEndEvent) => {
        const { active, over } = event;

        if (!over || active.id === over.id) {
            return;
        }

        const visibleTodos = todos.filter((todo) => todo.status !== 'archived');
        const oldIndex = visibleTodos.findIndex(
            (todo) => todo.id === active.id
        );
        const newIndex = visibleTodos.findIndex((todo) => todo.id === over.id);

        await onReorderTodos(oldIndex, newIndex);
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center py-12">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
            </div>
        );
    }

    // Filter out archived todos for display
    const visibleTodos = todos.filter((todo) => todo.status !== 'archived');
    const committedTodos = visibleTodos.filter((todo) => todo.committed);
    const nonCommittedVisibleTodos = visibleTodos.filter(
        (todo) => !todo.committed
    );
    const waitingTodos = nonCommittedVisibleTodos.filter(
        (todo) => todo.status === 'waiting'
    );
    const otherTodos = nonCommittedVisibleTodos.filter(
        (todo) => todo.status !== 'waiting'
    );
    const completedCount = todos.filter(
        (todo) => todo.status === 'complete'
    ).length;

    if (visibleTodos.length === 0) {
        return (
            <div className="text-center py-12">
                <p className="text-muted-foreground text-lg mb-4">
                    No todos yet. Click the Add Todo button to add one!
                </p>
                <Button onClick={() => handleAddTodo('top')} className="w-fit">
                    <Plus className="h-4 w-4 mr-2" />
                    Add Todo
                </Button>
            </div>
        );
    }

    const activeTodos = todos.filter((t) => t.status === 'todo');
    const todoCount = activeTodos.length;
    const priorityCounts = {
        superImportant: activeTodos.filter((t) => t.importance === 5).length,
        veryImportant: activeTodos.filter((t) => t.importance === 4).length,
        important: activeTodos.filter((t) => t.importance === 3).length,
        necessary: activeTodos.filter((t) => t.importance === 2).length,
        unimportant: activeTodos.filter((t) => t.importance === 1).length,
        noImportance: activeTodos.filter(
            (t) => t.importance < 1 || t.importance > 5
        ).length,
    };

    return (
        <div className="flex flex-col gap-4">
            <div className="text-sm">
                <h2 className="text-sm font-semibold text-muted-foreground">
                    {todoCount} thing{todoCount !== 1 ? 's' : ''} to do
                </h2>
                <div>
                    {priorityCounts.superImportant > 0 && (
                        <span className="font-bold text-red-600">
                            {priorityCounts.superImportant} super important
                        </span>
                    )}
                    {priorityCounts.superImportant > 0 &&
                        (priorityCounts.veryImportant > 0 ||
                            priorityCounts.important > 0 ||
                            priorityCounts.necessary > 0 ||
                            priorityCounts.unimportant > 0) && (
                            <span className="text-muted-foreground">, </span>
                        )}
                    {priorityCounts.veryImportant > 0 && (
                        <span className="font-bold text-orange-500">
                            {priorityCounts.veryImportant} very important
                        </span>
                    )}
                    {priorityCounts.veryImportant > 0 &&
                        (priorityCounts.important > 0 ||
                            priorityCounts.necessary > 0 ||
                            priorityCounts.unimportant > 0) && (
                            <span className="text-muted-foreground">, </span>
                        )}
                    {priorityCounts.important > 0 && (
                        <span className="font-bold text-yellow-500">
                            {priorityCounts.important} important
                        </span>
                    )}
                    {priorityCounts.important > 0 &&
                        (priorityCounts.necessary > 0 ||
                            priorityCounts.unimportant > 0) && (
                            <span className="text-muted-foreground">, </span>
                        )}
                    {priorityCounts.necessary > 0 && (
                        <span className="font-bold">
                            {priorityCounts.necessary} necessary
                        </span>
                    )}
                    {priorityCounts.necessary > 0 &&
                        priorityCounts.unimportant > 0 && (
                            <span className="text-muted-foreground">, </span>
                        )}
                    {priorityCounts.unimportant > 0 && (
                        <span className="text-muted-foreground">
                            {priorityCounts.unimportant} unimportant
                        </span>
                    )}
                    {priorityCounts.unimportant > 0 &&
                        priorityCounts.noImportance > 0 && (
                            <span className="text-muted-foreground">, </span>
                        )}
                    {priorityCounts.noImportance > 0 && (
                        <span className="text-red-500 font-bold">
                            {priorityCounts.noImportance} no priority set
                        </span>
                    )}
                </div>
            </div>
            <div className="mb-4">
                <RandomTodoDialog count={3} onUpdateTodo={onUpdateTodo} />
            </div>

            {committedTodos.length > 0 && (
                <div>
                    <div className="flex items-center gap-2 mb-2">
                        <h2 className="text-sm font-semibold text-muted-foreground">
                            Committed
                        </h2>
                    </div>
                    <div className="rounded-lg bg-blue-50 p-4">
                        <TodoSection
                            todos={committedTodos}
                            editingId={editingId}
                            editValue={editValue}
                            editingDetailsId={editingDetailsId}
                            detailsValue={detailsValue}
                            onToggleTodo={onToggleTodo}
                            onUpdateTodo={onUpdateTodo}
                            onStartEdit={handleStartEdit}
                            onEditChange={handleEditChange}
                            onFinishEdit={handleFinishEdit}
                            onKeyDown={handleKeyDown}
                            onStartEditDetails={handleStartEditDetails}
                            onDetailsChange={handleDetailsChange}
                            onFinishEditDetails={handleFinishEditDetails}
                            onIncreaseImportance={handleIncreaseImportance}
                            onDecreaseImportance={handleDecreaseImportance}
                            onSetTimeEstimate={handleSetTimeEstimate}
                            onSetAnnoyingness={handleSetAnnoyingness}
                            onCommit={handleCommit}
                            onDragEnd={handleDragEnd}
                            inputRef={inputRef}
                            hoveringTodoId={hoveringTodoId}
                            onHoveringTodoIdChange={setHoveringTodoId}
                            openMenusByTodoId={openMenusByTodoId}
                            onMenuOpen={handleMenuOpen}
                            runningTimers={runningTimers}
                            onToggleTimer={handleToggleTimer}
                            timerStartTimes={timerStartTimes}
                            finalizedElapsedTimes={finalizedElapsedTimes}
                            onOpenRightPanel={onOpenRightPanel}
                        />
                    </div>
                </div>
            )}

            {waitingTodos.length > 0 && (
                <div>
                    <div className="flex items-center gap-2 mb-2">
                        <h2 className="text-sm font-semibold text-muted-foreground">
                            Waiting
                        </h2>
                    </div>
                    <div className="rounded-lg bg-purple-50 p-4">
                        <TodoSection
                            todos={waitingTodos}
                            editingId={editingId}
                            editValue={editValue}
                            editingDetailsId={editingDetailsId}
                            detailsValue={detailsValue}
                            onToggleTodo={onToggleTodo}
                            onUpdateTodo={onUpdateTodo}
                            onStartEdit={handleStartEdit}
                            onEditChange={handleEditChange}
                            onFinishEdit={handleFinishEdit}
                            onKeyDown={handleKeyDown}
                            onStartEditDetails={handleStartEditDetails}
                            onDetailsChange={handleDetailsChange}
                            onFinishEditDetails={handleFinishEditDetails}
                            onIncreaseImportance={handleIncreaseImportance}
                            onDecreaseImportance={handleDecreaseImportance}
                            onSetTimeEstimate={handleSetTimeEstimate}
                            onSetAnnoyingness={handleSetAnnoyingness}
                            onCommit={handleCommit}
                            onDragEnd={handleDragEnd}
                            inputRef={inputRef}
                            hoveringTodoId={hoveringTodoId}
                            onHoveringTodoIdChange={setHoveringTodoId}
                            openMenusByTodoId={openMenusByTodoId}
                            onMenuOpen={handleMenuOpen}
                            runningTimers={runningTimers}
                            onToggleTimer={handleToggleTimer}
                            timerStartTimes={timerStartTimes}
                            finalizedElapsedTimes={finalizedElapsedTimes}
                            onOpenRightPanel={onOpenRightPanel}
                        />
                    </div>
                </div>
            )}

            {otherTodos.length > 0 && (
                <div>
                    <h2 className="text-sm font-semibold text-muted-foreground mb-2">
                        Todos
                    </h2>
                    <div className="flex gap-2 mb-4">
                        <Button
                            onClick={() => handleAddTodo('top')}
                            className="w-fit"
                        >
                            <Plus className="h-4 w-4 mr-2" />
                            Add to top
                        </Button>
                        <Button
                            onClick={() => handleAddTodo('bottom')}
                            variant="outline"
                            className="w-fit"
                        >
                            <Plus className="h-4 w-4 mr-2" />
                            Add to bottom
                        </Button>
                    </div>
                    <TodoSection
                        todos={otherTodos}
                        editingId={editingId}
                        editValue={editValue}
                        editingDetailsId={editingDetailsId}
                        detailsValue={detailsValue}
                        onToggleTodo={onToggleTodo}
                        onUpdateTodo={onUpdateTodo}
                        onStartEdit={handleStartEdit}
                        onEditChange={handleEditChange}
                        onFinishEdit={handleFinishEdit}
                        onKeyDown={handleKeyDown}
                        onStartEditDetails={handleStartEditDetails}
                        onDetailsChange={handleDetailsChange}
                        onFinishEditDetails={handleFinishEditDetails}
                        onIncreaseImportance={handleIncreaseImportance}
                        onDecreaseImportance={handleDecreaseImportance}
                        onSetTimeEstimate={handleSetTimeEstimate}
                        onSetAnnoyingness={handleSetAnnoyingness}
                        onCommit={handleCommit}
                        onDragEnd={handleDragEnd}
                        inputRef={inputRef}
                        hoveringTodoId={hoveringTodoId}
                        onHoveringTodoIdChange={setHoveringTodoId}
                        openMenusByTodoId={openMenusByTodoId}
                        onMenuOpen={handleMenuOpen}
                        runningTimers={runningTimers}
                        onToggleTimer={handleToggleTimer}
                        timerStartTimes={timerStartTimes}
                        finalizedElapsedTimes={finalizedElapsedTimes}
                        onOpenRightPanel={onOpenRightPanel}
                    />
                    <div className="mt-4">
                        <Button
                            onClick={() => handleAddTodo('bottom')}
                            className="w-fit"
                        >
                            <Plus className="h-4 w-4 mr-2" />
                            Add Todo
                        </Button>
                    </div>
                </div>
            )}

            {completedCount > 0 && (
                <Button
                    onClick={onArchiveCompleted}
                    variant="outline"
                    className="w-full"
                >
                    Archive Completed ({completedCount})
                </Button>
            )}
        </div>
    );
}
