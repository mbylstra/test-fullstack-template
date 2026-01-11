import { useState } from 'react';
import { Dices } from 'lucide-react';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from '@/components/shadcn/dialog';
import { Button } from '@/components/shadcn/button';
import { weightedRandomTodosList } from '@/lib/api-client';
import { toast } from 'sonner';
import type { Todo } from '@/types/todo';
import type { Todo as ApiTodo } from '@/lib/api-client';
import { formatDesirability } from '@/lib/utils';

interface RandomTodoDialogProps {
    count?: number;
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
}

export default function RandomTodoDialog({
    count = 3,
    onUpdateTodo,
}: RandomTodoDialogProps) {
    const [open, setOpen] = useState(false);
    const [loading, setLoading] = useState(false);
    const [todos, setTodos] = useState<Todo[]>([]);
    const [error, setError] = useState<string | null>(null);

    const handleOpenChange = async (newOpen: boolean) => {
        if (newOpen) {
            await fetchRandomTodos();
        } else {
            setTodos([]);
            setError(null);
        }
        setOpen(newOpen);
    };

    const fetchRandomTodos = async () => {
        setLoading(true);
        setError(null);
        try {
            const response = await weightedRandomTodosList({
                query: { n: count, maxTimeEstimate: '30-mins' },
            });
            if (response.data) {
                const transformedTodos: Todo[] = response.data.map(
                    (apiTodo: ApiTodo) => ({
                        id: apiTodo.id,
                        task: apiTodo.task,
                        details: null,
                        status: apiTodo.status,
                        dateCreated: new Date(apiTodo.date_created),
                        dateUpdated: new Date(apiTodo.date_updated),
                        userId: apiTodo.user_id,
                        order: apiTodo.order,
                        priority: apiTodo.priority,
                        desirability: apiTodo.desirability,
                        importance: apiTodo.importance || 0,
                        timeEstimate: apiTodo.time_estimate,
                        annoyingness: apiTodo.annoyingness,
                        committed: apiTodo.committed,
                        elapsedTimeSeconds: apiTodo.elapsedTimeSeconds ?? 0,
                        atomic: apiTodo.atomic,
                        infinitelyDivisible: apiTodo.infinitely_divisible,
                    })
                );
                setTodos(transformedTodos);
            } else {
                const errorMsg = 'Failed to fetch random todos';
                setError(errorMsg);
                toast.error(errorMsg);
            }
        } catch (error) {
            const errorMsg = 'Failed to fetch random todos';
            setError(errorMsg);
            toast.error(errorMsg);
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    const handleSelectTodo = async (todo: Todo) => {
        try {
            await onUpdateTodo(todo.id, { committed: true });
            toast.success('Todo committed!');
            setOpen(false);
        } catch (error) {
            toast.error('Failed to commit todo');
            console.error(error);
        }
    };

    return (
        <Dialog open={open} onOpenChange={handleOpenChange}>
            <DialogTrigger asChild>
                <Button variant="outline" size="sm">
                    <Dices className="h-4 w-4 mr-2" />
                    Random Todo
                </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[425px]">
                <DialogHeader>
                    <DialogTitle>Random Todos</DialogTitle>
                    <DialogDescription>
                        Choose a todo to commit to
                    </DialogDescription>
                </DialogHeader>
                {loading ? (
                    <div className="flex items-center justify-center py-8">
                        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
                    </div>
                ) : error ? (
                    <div className="flex flex-col items-center justify-center py-8">
                        <p className="text-sm text-destructive font-medium">
                            {error}
                        </p>
                        <button
                            onClick={fetchRandomTodos}
                            className="mt-4 text-sm text-primary hover:underline"
                        >
                            Try again
                        </button>
                    </div>
                ) : todos.length > 0 ? (
                    <div className="space-y-3">
                        {todos.map((todo) => (
                            <button
                                key={todo.id}
                                onClick={() => handleSelectTodo(todo)}
                                className="w-full p-3 border rounded-lg bg-card hover:bg-accent hover:border-primary transition-colors cursor-pointer text-left"
                            >
                                <h3 className="font-medium text-sm">
                                    {todo.task}
                                </h3>
                                <div className="flex flex-wrap gap-x-3 gap-y-1 mt-1">
                                    {todo.timeEstimate && (
                                        <p className="text-xs text-muted-foreground">
                                            Time: {todo.timeEstimate}
                                        </p>
                                    )}
                                    {todo.importance != null && (
                                        <p className="text-xs text-muted-foreground">
                                            Importance: {todo.importance}/5
                                        </p>
                                    )}
                                    {todo.annoyingness != null && (
                                        <p className="text-xs text-muted-foreground">
                                            Annoyingness: {todo.annoyingness}/4
                                        </p>
                                    )}
                                </div>
                                <div className="flex flex-wrap gap-x-3 gap-y-1 mt-1">
                                    <p className="text-xs text-muted-foreground font-medium">
                                        Priority: #
                                        {todo.priority != null
                                            ? todo.priority + 1
                                            : '?'}
                                    </p>
                                    <p className="text-xs text-muted-foreground font-medium">
                                        Desirability:{' '}
                                        {formatDesirability(
                                            todo.desirability
                                        ) ?? '?'}
                                    </p>
                                </div>
                            </button>
                        ))}
                    </div>
                ) : (
                    <p className="text-sm text-muted-foreground text-center py-8">
                        No todos found
                    </p>
                )}
            </DialogContent>
        </Dialog>
    );
}
