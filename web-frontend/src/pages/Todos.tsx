import { useEffect, useState, useRef, useReducer } from 'react';
import TodoList from '@/components/TodoList';
import { TodoDetailsPanel } from '@/components/TodoDetailsPanel';
import { HabitsList } from '@/components/HabitsList';
import { Panel, PanelGroup, PanelResizeHandle } from 'react-resizable-panels';
import type { Todo, TodoStatus } from '@/types/todo';
import type { Habit } from '@/types/habit';
import type { JSONContent } from '@tiptap/react';

type HomeState = {
    isRightPanelOpen: boolean;
    activeTodoId: string | null;
};

type HomeAction =
    | { type: 'OPEN_RIGHT_PANEL'; todoId: string }
    | { type: 'CLOSE_RIGHT_PANEL' }
    | { type: 'TOGGLE_RIGHT_PANEL' };

function homeReducer(state: HomeState, action: HomeAction): HomeState {
    switch (action.type) {
        case 'OPEN_RIGHT_PANEL':
            return {
                ...state,
                isRightPanelOpen: true,
                activeTodoId: action.todoId,
            };
        case 'CLOSE_RIGHT_PANEL':
            return { ...state, isRightPanelOpen: false };
        case 'TOGGLE_RIGHT_PANEL':
            return { ...state, isRightPanelOpen: !state.isRightPanelOpen };
        default:
            return state;
    }
}

const initialHomeState: HomeState = {
    isRightPanelOpen: false,
    activeTodoId: null,
};

interface HomeProps {
    todosHook: {
        todos: Todo[];
        loading: boolean;
        addTodo: (
            task: string,
            details: JSONContent | null,
            position?: 'top' | 'bottom',
            afterId?: string
        ) => Promise<string>;
        toggleTodo: (id: string, currentStatus: TodoStatus) => Promise<void>;
        updateTodo: (
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
        ) => Promise<void>;
        deleteTodo: (id: string) => Promise<void>;
        reorderTodos: (oldIndex: number, newIndex: number) => Promise<void>;
        archiveCompleted: () => Promise<void>;
    };
    habitsHook: {
        habits: Habit[];
        loading: boolean;
        refetch: () => Promise<void>;
    };
}

function Todos({ todosHook, habitsHook }: HomeProps) {
    const [homeState, dispatch] = useReducer(homeReducer, initialHomeState);

    const {
        todos,
        loading,
        addTodo,
        toggleTodo,
        updateTodo,
        deleteTodo,
        reorderTodos,
        archiveCompleted,
    } = todosHook;

    const { habits, loading: habitsLoading, refetch: refetchHabits } = habitsHook;
    const [runningTimers, setRunningTimers] = useState<Set<string>>(new Set());
    const [, setTick] = useState(0);
    const timerStartTimesRef = useRef<Map<string, number>>(new Map());
    const [finalizedElapsedTimes, setFinalizedElapsedTimes] = useState<
        Map<string, number>
    >(new Map());

    // Update elapsed time every second for running timers
    useEffect(() => {
        if (runningTimers.size === 0) return;

        const intervalId = setInterval(() => {
            setTick((prev) => prev + 1);
        }, 1000);

        return () => clearInterval(intervalId);
    }, [runningTimers]);

    // Track when timers start and handle elapsed time when timers stop
    useEffect(() => {
        const prevRunningTimers = timerStartTimesRef.current;
        const newRunningTimers = new Set(runningTimers);

        // Add any newly started timers
        newRunningTimers.forEach((todoId) => {
            if (!prevRunningTimers.has(todoId)) {
                prevRunningTimers.set(todoId, Date.now());
                // Clear any finalized time for this todo when starting again
                setFinalizedElapsedTimes((prev) => {
                    const newMap = new Map(prev);
                    newMap.delete(todoId);
                    return newMap;
                });
            }
        });

        // Remove any stopped timers and save their final elapsed time
        const stoppedTimers: string[] = [];
        prevRunningTimers.forEach((startTime, todoId) => {
            if (!newRunningTimers.has(todoId)) {
                stoppedTimers.push(todoId);
                // Calculate final elapsed time
                const todo = todos.find((t) => t.id === todoId);
                if (todo) {
                    const finalElapsedSeconds =
                        todo.elapsedTimeSeconds +
                        Math.floor((Date.now() - startTime) / 1000);
                    // Store the final elapsed time so UI displays it until server syncs
                    setFinalizedElapsedTimes((prev) => {
                        const newMap = new Map(prev);
                        newMap.set(todoId, finalElapsedSeconds);
                        return newMap;
                    });
                }
            }
        });
        stoppedTimers.forEach((todoId) => prevRunningTimers.delete(todoId));
    }, [runningTimers, todos]);

    return (
        <div className="h-full bg-background">
            <PanelGroup direction="horizontal">
                <Panel
                    defaultSize={homeState.isRightPanelOpen ? 70 : 100}
                    minSize={30}
                >
                    <div className="h-full overflow-y-auto">
                        <div className="container mx-auto px-4 py-4 max-w-4xl">
                            <h1 className="text-3xl font-bold mb-4">Habits</h1>
                            <HabitsList
                                habits={habits}
                                loading={habitsLoading}
                                onHabitLogChange={refetchHabits}
                            />
                            <h1 className="text-3xl font-bold mb-4 mt-8">
                                Todos
                            </h1>
                            <TodoList
                                todos={todos}
                                loading={loading}
                                onToggleTodo={toggleTodo}
                                onUpdateTodo={updateTodo}
                                onReorderTodos={reorderTodos}
                                onArchiveCompleted={archiveCompleted}
                                onDeleteTodo={deleteTodo}
                                onAddTodo={addTodo}
                                runningTimers={runningTimers}
                                onRunningTimersChange={setRunningTimers}
                                timerStartTimes={timerStartTimesRef.current}
                                finalizedElapsedTimes={finalizedElapsedTimes}
                                onOpenRightPanel={(todoId) =>
                                    dispatch({
                                        type: 'OPEN_RIGHT_PANEL',
                                        todoId,
                                    })
                                }
                            />
                        </div>
                    </div>
                </Panel>
                {homeState.isRightPanelOpen && (
                    <>
                        <PanelResizeHandle className="w-1 bg-border hover:bg-primary transition-colors" />
                        <Panel defaultSize={30} minSize={20}>
                            <TodoDetailsPanel
                                todo={
                                    todos.find(
                                        (t) => t.id === homeState.activeTodoId
                                    ) || null
                                }
                                onClose={() =>
                                    dispatch({
                                        type: 'CLOSE_RIGHT_PANEL',
                                    })
                                }
                                onDelete={(todoId) => {
                                    deleteTodo(todoId);
                                    dispatch({ type: 'CLOSE_RIGHT_PANEL' });
                                }}
                                onUpdate={updateTodo}
                            />
                        </Panel>
                    </>
                )}
            </PanelGroup>
        </div>
    );
}

export default Todos;
