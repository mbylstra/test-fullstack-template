import type { Todo } from '@/types/todo';
import { TIME_ESTIMATE_LABELS } from '@/types/todo';
import { IconButton } from '@/components/custom-ui/icon-button';
import { formatDesirability, formatElapsedTime } from '@/lib/utils';
import { RichTextEditor } from '@/components/custom-ui/rich-text-editor';
import { Button } from '@/components/shadcn/button';
import { Checkbox } from '@/components/shadcn/checkbox';
import { MoreVertical, Trash2 } from 'lucide-react';
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
} from '@/components/shadcn/dropdown-menu';
import {
    Tooltip,
    TooltipContent,
    TooltipTrigger,
} from '@/components/shadcn/tooltip';
import { TOOLTIP_DELAY_MS } from '@/constants';

interface TodoDetailsPanelProps {
    todo: Todo | null;
    onClose: () => void;
    onDelete: (todoId: string) => void;
    onUpdate: (
        id: string,
        updates: Partial<Pick<Todo, 'atomic' | 'infinitelyDivisible'>>
    ) => void;
}

export function TodoDetailsPanel({
    todo,
    onClose,
    onDelete,
    onUpdate,
}: TodoDetailsPanelProps) {
    return (
        <div className="h-full flex flex-col bg-muted/20">
            <div className="flex-none p-2 flex items-center justify-end gap-1 border-b bg-background/50">
                <DropdownMenu>
                    <Tooltip delayDuration={TOOLTIP_DELAY_MS}>
                        <TooltipTrigger asChild>
                            <DropdownMenuTrigger asChild>
                                <Button
                                    variant="ghost"
                                    size="icon"
                                    className="h-6 w-6 shrink-0 rounded-full bg-gray-200 hover:bg-gray-300"
                                    aria-label="Todo menu"
                                >
                                    <MoreVertical className="h-2 w-2" />
                                </Button>
                            </DropdownMenuTrigger>
                        </TooltipTrigger>
                        <TooltipContent>More options</TooltipContent>
                    </Tooltip>
                    <DropdownMenuContent align="end">
                        <DropdownMenuItem
                            onClick={() => {
                                if (todo) {
                                    onDelete(todo.id);
                                }
                            }}
                            className="text-destructive"
                        >
                            <Trash2 className="h-4 w-4 mr-2" />
                            Delete
                        </DropdownMenuItem>
                    </DropdownMenuContent>
                </DropdownMenu>
                <IconButton
                    icon="x"
                    ariaLabel="Close right panel"
                    onClick={onClose}
                    tooltip="Close panel"
                />
            </div>
            <div className="flex-1 overflow-y-auto p-4">
                {todo ? (
                    <div className="space-y-6">
                        <div>
                            <h2 className="text-lg font-semibold">
                                {todo.task}
                            </h2>
                        </div>

                        <div className="space-y-3">
                            <div className="flex items-center space-x-2">
                                <Checkbox
                                    id="can-be-broken-up"
                                    checked={!todo.atomic}
                                    onCheckedChange={(checked) => {
                                        onUpdate(todo.id, {
                                            atomic: !checked,
                                        });
                                    }}
                                />
                                <label
                                    htmlFor="can-be-broken-up"
                                    className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
                                >
                                    Can be broken up
                                </label>
                            </div>
                            {!todo.atomic && (
                                <div className="flex items-center space-x-2">
                                    <Checkbox
                                        id="infinitely-divisible"
                                        checked={todo.infinitelyDivisible}
                                        onCheckedChange={(checked) => {
                                            onUpdate(todo.id, {
                                                infinitelyDivisible: !!checked,
                                            });
                                        }}
                                    />
                                    <label
                                        htmlFor="infinitely-divisible"
                                        className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
                                    >
                                        Infinitely divisible
                                    </label>
                                </div>
                            )}
                        </div>

                        <div className="space-y-4 text-sm">
                            <div>
                                <p className="text-muted-foreground mb-1">
                                    Status
                                </p>
                                <p className="capitalize font-medium">
                                    {todo.status}
                                </p>
                            </div>

                            <div>
                                <p className="text-muted-foreground mb-1">
                                    Importance
                                </p>
                                <p className="font-medium">
                                    {todo.importance}/5
                                </p>
                            </div>

                            <div>
                                <p className="text-muted-foreground mb-1">
                                    Annoyingness
                                </p>
                                <p className="font-medium">
                                    {todo.annoyingness}/10
                                </p>
                            </div>

                            {todo.timeEstimate && (
                                <div>
                                    <p className="text-muted-foreground mb-1">
                                        Time Estimate
                                    </p>
                                    <p className="font-medium">
                                        {
                                            TIME_ESTIMATE_LABELS[
                                                todo.timeEstimate
                                            ]
                                        }
                                    </p>
                                </div>
                            )}

                            {todo.desirability !== undefined &&
                                todo.desirability !== null && (
                                    <div>
                                        <p className="text-muted-foreground mb-1">
                                            Desirability
                                        </p>
                                        <p className="font-medium">
                                            {formatDesirability(
                                                todo.desirability
                                            )}
                                            %
                                        </p>
                                    </div>
                                )}

                            <div>
                                <p className="text-muted-foreground mb-1">
                                    Elapsed Time
                                </p>
                                <p className="font-medium">
                                    {formatElapsedTime(todo.elapsedTimeSeconds)}
                                </p>
                            </div>

                            <div>
                                <p className="text-muted-foreground mb-1">
                                    Committed
                                </p>
                                <p className="font-medium">
                                    {todo.committed ? 'Yes' : 'No'}
                                </p>
                            </div>
                        </div>

                        {todo.details && (
                            <div className="border-t pt-4">
                                <p className="text-muted-foreground mb-3 text-sm">
                                    Details
                                </p>
                                <RichTextEditor
                                    content={todo.details}
                                    onChange={() => {}}
                                    editable={false}
                                    showToolbar={false}
                                    className="prose prose-sm max-w-none text-sm"
                                />
                            </div>
                        )}
                    </div>
                ) : (
                    <p className="text-muted-foreground">
                        Select a todo to view details
                    </p>
                )}
            </div>
        </div>
    );
}
