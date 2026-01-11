import { Checkbox } from '@/components/shadcn/checkbox';
import { Input } from '@/components/shadcn/input';
import { Button } from '@/components/shadcn/button';
import { Clock, Annoyed, Timer } from 'lucide-react';
import { useState } from 'react';
import { TOOLTIP_DELAY_MS } from '@/constants';
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
import type { Todo, TodoStatus, TimeEstimate } from '@/types/todo';
import { TIME_ESTIMATE_LABELS } from '@/types/todo';
import type { JSONContent } from '@tiptap/react';
import {
    RichTextEditor,
    isEditorEmpty,
} from '@/components/custom-ui/rich-text-editor';
import { IconButton } from '@/components/custom-ui/icon-button';
import { AnnoyingnessIcon } from '@/components/custom-ui/annoyingness-icon';
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { formatDesirability, formatElapsedTime } from '@/lib/utils';
import { todosOverrideElapsedTime } from '@/lib/api';

export interface SortableTodoItemProps {
    todo: Todo;
    isEditing: boolean;
    editValue: string;
    isEditingDetails: boolean;
    detailsValue: JSONContent | null;
    onToggle: () => void;
    onStartEdit: () => void;
    onEditChange: (value: string) => void;
    onFinishEdit: () => void;
    onKeyDown: (e: React.KeyboardEvent) => void;
    onStartEditDetails: () => void;
    onDetailsChange: (content: JSONContent) => void;
    onFinishEditDetails: () => void;
    onIncreaseImportance: () => void;
    onDecreaseImportance: () => void;
    onChangeStatus: (status: TodoStatus) => void;
    onSetTimeEstimate: (estimate: TimeEstimate) => void;
    onSetAnnoyingness: (annoyingness: number) => void;
    onCommit: () => void;
    inputRef: React.RefObject<HTMLInputElement | null>;
    isHovering: boolean;
    onHoveringChange: (isHovering: boolean) => void;
    onMenuOpenChange: (
        menuKey: 'timeEstimate' | 'annoyingness',
        open: boolean
    ) => void;
    isTimerRunning: boolean;
    onToggleTimer: () => void;
    timerStartTime?: number;
    finalizedElapsedTime?: number;
    onOpenRightPanel: (todoId: string) => void;
}

export function SortableTodoItem({
    todo,
    isEditing,
    editValue,
    isEditingDetails,
    detailsValue,
    onToggle,
    onStartEdit,
    onEditChange,
    onFinishEdit,
    onKeyDown,
    onStartEditDetails,
    onDetailsChange,
    onFinishEditDetails,
    onIncreaseImportance,
    onDecreaseImportance,
    onChangeStatus,
    onSetTimeEstimate,
    onSetAnnoyingness,
    onCommit,
    inputRef,
    isHovering,
    onHoveringChange,
    onMenuOpenChange,
    isTimerRunning,
    onToggleTimer,
    timerStartTime,
    finalizedElapsedTime,
    onOpenRightPanel,
}: SortableTodoItemProps) {
    const {
        attributes,
        listeners,
        setNodeRef,
        transform,
        transition,
        isDragging,
    } = useSortable({ id: todo.id });

    const style = {
        transform: CSS.Transform.toString(transform),
        transition,
        opacity: isDragging ? 0.5 : 1,
    };

    // Disable dragging when editing to prevent keyboard event interference
    const dragProps =
        isEditing || isEditingDetails ? {} : { ...attributes, ...listeners };

    // Compute live elapsed time when timer is running
    // Use finalized time if timer was just stopped, otherwise compute from start time or use stored value
    const liveElapsedTimeSeconds =
        finalizedElapsedTime !== undefined
            ? finalizedElapsedTime
            : timerStartTime
              ? todo.elapsedTimeSeconds +
                Math.floor((Date.now() - timerStartTime) / 1000)
              : todo.elapsedTimeSeconds;

    // Override form state
    const [isShowingOverride, setIsShowingOverride] = useState(false);
    const [overrideHoursStr, setOverrideHoursStr] = useState(
        Math.floor(liveElapsedTimeSeconds / 3600).toString()
    );
    const [overrideMinutesStr, setOverrideMinutesStr] = useState(
        Math.floor((liveElapsedTimeSeconds % 3600) / 60).toString()
    );
    const [isSubmittingOverride, setIsSubmittingOverride] = useState(false);
    const [overriddenElapsedTime, setOverriddenElapsedTime] = useState<
        number | null
    >(null);

    const displayedElapsedTime =
        overriddenElapsedTime !== null
            ? overriddenElapsedTime
            : liveElapsedTimeSeconds;

    const handleOverrideSubmit = async () => {
        try {
            setIsSubmittingOverride(true);
            const hours = parseInt(overrideHoursStr) || 0;
            const minutes = parseInt(overrideMinutesStr) || 0;
            await todosOverrideElapsedTime({
                path: { id: todo.id },
                body: {
                    hours,
                    minutes,
                },
            });
            // Update displayed time to show the overridden value
            const newElapsedSeconds = hours * 3600 + minutes * 60;
            setOverriddenElapsedTime(newElapsedSeconds);
            setIsShowingOverride(false);
        } catch (error) {
            console.error('Failed to override elapsed time:', error);
        } finally {
            setIsSubmittingOverride(false);
        }
    };

    return (
        <div
            ref={setNodeRef}
            style={style}
            className={`px-1 transition-colors ${
                isHovering ? 'bg-muted/50' : ''
            } rounded-sm group ${todo.status === 'complete' ? 'opacity-50' : ''}`}
            {...dragProps}
            onMouseEnter={() => onHoveringChange(true)}
            onMouseLeave={() => onHoveringChange(false)}
        >
            <div className="flex items-start gap-3 justify-between min-h-8">
                <Checkbox
                    checked={todo.status === 'complete'}
                    onCheckedChange={onToggle}
                    className="cursor-pointer flex-shrink-0 mt-[8px]"
                />
                <div className="flex-1 min-w-0">
                    <div className="max-w-[600px] flex items-start gap-2">
                        {!isEditing && (
                            <AnnoyingnessIcon
                                annoyingness={todo.annoyingness}
                                className="h-4 w-4 flex-shrink-0 mt-[8px]"
                            />
                        )}
                        <div className="flex-1 min-w-0">
                            {isEditing ? (
                                <Input
                                    ref={inputRef}
                                    value={editValue}
                                    onChange={(e) =>
                                        onEditChange(e.target.value)
                                    }
                                    onBlur={onFinishEdit}
                                    onKeyDown={onKeyDown}
                                    className="h-7 text-sm -ml-3"
                                />
                            ) : (
                                <h3
                                    onClick={onStartEdit}
                                    className={`text-sm cursor-pointer transition-colors m-0 mt-[6px] leading-5 ${
                                        todo.status === 'complete'
                                            ? 'line-through text-muted-foreground'
                                            : ''
                                    } ${
                                        todo.importance === 2
                                            ? 'font-bold'
                                            : todo.importance === 3
                                              ? 'font-bold text-yellow-500'
                                              : todo.importance === 4
                                                ? 'font-bold text-orange-500'
                                                : todo.importance === 5
                                                  ? 'font-bold text-red-600'
                                                  : ''
                                    }`}
                                >
                                    {todo.task}
                                </h3>
                            )}
                            {isEditingDetails ? (
                                <div className="mt-2">
                                    <RichTextEditor
                                        key="editing-details"
                                        content={detailsValue}
                                        onChange={onDetailsChange}
                                        onBlur={onFinishEditDetails}
                                        onKeyDown={(e) => {
                                            if (e.key === 'Escape') {
                                                onFinishEditDetails();
                                            }
                                        }}
                                        placeholder="Add details..."
                                        className="text-xs border rounded-md p-2 min-h-[80px] bg-background"
                                        autoFocus={true}
                                    />
                                </div>
                            ) : (
                                todo.details &&
                                !isEditorEmpty(todo.details) && (
                                    <div
                                        onClick={onStartEditDetails}
                                        className="mt-1 cursor-pointer hover:opacity-80 transition-opacity"
                                    >
                                        <RichTextEditor
                                            key="viewing-details"
                                            content={todo.details}
                                            onChange={() => {}}
                                            editable={false}
                                            showToolbar={false}
                                            className={`text-xs ${
                                                todo.status === 'complete'
                                                    ? 'text-muted-foreground line-through'
                                                    : 'text-muted-foreground'
                                            }`}
                                        />
                                    </div>
                                )
                            )}
                            <div className="mt-2 flex gap-3 text-xs text-muted-foreground">
                                {todo.timeEstimate && (
                                    <span>
                                        {
                                            TIME_ESTIMATE_LABELS[
                                                todo.timeEstimate
                                            ]
                                        }
                                    </span>
                                )}
                                {formatDesirability(todo.desirability) && (
                                    <span className="font-medium">
                                        Desirability:{' '}
                                        {formatDesirability(todo.desirability)}
                                    </span>
                                )}
                            </div>
                            {todo.committed && todo.status !== 'complete' && (
                                <div className="mt-3 flex items-center gap-2">
                                    <Button
                                        variant={
                                            isTimerRunning
                                                ? 'default'
                                                : 'outline'
                                        }
                                        size="sm"
                                        className="w-fit"
                                        onClick={onToggleTimer}
                                    >
                                        <Timer className="h-4 w-4 mr-2" />
                                        {isTimerRunning ? 'Stop' : 'Start'}
                                    </Button>
                                    <>
                                        {isShowingOverride &&
                                        !isTimerRunning ? (
                                            <div className="flex items-center gap-2">
                                                <Input
                                                    type="number"
                                                    min="0"
                                                    value={overrideHoursStr}
                                                    onChange={(e) =>
                                                        setOverrideHoursStr(
                                                            e.target.value
                                                        )
                                                    }
                                                    className="h-6 w-12 text-xs p-1 bg-white"
                                                />
                                                <span className="text-xs text-muted-foreground">
                                                    hrs
                                                </span>
                                                <Input
                                                    type="number"
                                                    min="0"
                                                    max="59"
                                                    value={overrideMinutesStr}
                                                    onChange={(e) =>
                                                        setOverrideMinutesStr(
                                                            e.target.value
                                                        )
                                                    }
                                                    className="h-6 w-12 text-xs p-1 bg-white"
                                                />
                                                <span className="text-xs text-muted-foreground">
                                                    mins
                                                </span>
                                                <Button
                                                    size="sm"
                                                    className="h-6 px-2 text-xs"
                                                    onClick={
                                                        handleOverrideSubmit
                                                    }
                                                    disabled={
                                                        isSubmittingOverride
                                                    }
                                                >
                                                    {isSubmittingOverride
                                                        ? 'Saving...'
                                                        : 'Override'}
                                                </Button>
                                            </div>
                                        ) : (
                                            <span
                                                className={`text-xs text-muted-foreground ${
                                                    !isTimerRunning
                                                        ? 'cursor-pointer hover:underline'
                                                        : ''
                                                }`}
                                                onClick={() => {
                                                    if (!isTimerRunning) {
                                                        setIsShowingOverride(
                                                            true
                                                        );
                                                    }
                                                }}
                                            >
                                                {formatElapsedTime(
                                                    displayedElapsedTime
                                                )}
                                            </span>
                                        )}
                                    </>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
                {isHovering && (
                    <div
                        className={`flex items-center gap-1 mt-0 transition-opacity ${
                            isHovering ? 'opacity-100' : 'opacity-0'
                        }`}
                    >
                        <IconButton
                            icon="notebookText"
                            ariaLabel="Add details"
                            onClick={onStartEditDetails}
                            tooltip="Add details"
                        />
                        <IconButton
                            icon="minus"
                            ariaLabel="Decrease importance"
                            onClick={onDecreaseImportance}
                            disabled={todo.importance <= 1}
                            tooltip="Decrease importance"
                        />
                        <IconButton
                            icon="plus"
                            ariaLabel="Increase importance"
                            onClick={onIncreaseImportance}
                            disabled={todo.importance >= 5}
                            tooltip="Increase importance"
                        />
                        <DropdownMenu
                            onOpenChange={(open) =>
                                onMenuOpenChange('timeEstimate', open)
                            }
                        >
                            <Tooltip delayDuration={TOOLTIP_DELAY_MS}>
                                <TooltipTrigger asChild>
                                    <DropdownMenuTrigger asChild>
                                        <Button
                                            variant="ghost"
                                            size="icon"
                                            className="h-6 w-6 shrink-0 rounded-full bg-gray-200 hover:bg-gray-300"
                                            aria-label="Set time estimate"
                                        >
                                            <Clock className="h-2 w-2" />
                                        </Button>
                                    </DropdownMenuTrigger>
                                </TooltipTrigger>
                                <TooltipContent>
                                    Change time estimate
                                </TooltipContent>
                            </Tooltip>
                            <DropdownMenuContent align="end">
                                {(
                                    [
                                        '1-min',
                                        '5-mins',
                                        '15-mins',
                                        '30-mins',
                                        '1-hour',
                                        '2-hours',
                                        'half-day',
                                        'one-day',
                                        'project',
                                    ] as const
                                ).map((estimate) => (
                                    <DropdownMenuItem
                                        key={estimate}
                                        onClick={() =>
                                            onSetTimeEstimate(estimate)
                                        }
                                    >
                                        {TIME_ESTIMATE_LABELS[estimate]}
                                    </DropdownMenuItem>
                                ))}
                            </DropdownMenuContent>
                        </DropdownMenu>
                        <DropdownMenu
                            onOpenChange={(open) =>
                                onMenuOpenChange('annoyingness', open)
                            }
                        >
                            <Tooltip delayDuration={TOOLTIP_DELAY_MS}>
                                <TooltipTrigger asChild>
                                    <DropdownMenuTrigger asChild>
                                        <Button
                                            variant="ghost"
                                            size="icon"
                                            className="h-6 w-6 shrink-0 rounded-full bg-gray-200 hover:bg-gray-300"
                                            aria-label="Set annoyingness level"
                                        >
                                            <Annoyed className="h-3 w-3 text-black" />
                                        </Button>
                                    </DropdownMenuTrigger>
                                </TooltipTrigger>
                                <TooltipContent>
                                    Change annoyingness level
                                </TooltipContent>
                            </Tooltip>
                            <DropdownMenuContent align="end">
                                {([0, 1, 2, 3, 4] as const).map((level) => (
                                    <DropdownMenuItem
                                        key={level}
                                        onClick={() => onSetAnnoyingness(level)}
                                        className="flex items-center gap-2"
                                    >
                                        <AnnoyingnessIcon
                                            annoyingness={level}
                                            className="h-4 w-4"
                                        />
                                        <span>Level {level}</span>
                                    </DropdownMenuItem>
                                ))}
                            </DropdownMenuContent>
                        </DropdownMenu>
                        <IconButton
                            icon="hourglass"
                            ariaLabel="Mark as waiting"
                            onClick={() => {
                                if (todo.status === 'waiting') {
                                    onChangeStatus('todo');
                                } else {
                                    onChangeStatus('waiting');
                                }
                            }}
                            tooltip="Set to Waiting status"
                        />
                        <IconButton
                            icon="bicepsFlexed"
                            ariaLabel="Commit to this todo"
                            onClick={onCommit}
                            tooltip="Commit"
                        />
                        <IconButton
                            icon="panelRight"
                            ariaLabel="More Options"
                            onClick={() => onOpenRightPanel(todo.id)}
                            tooltip="More Options"
                        />
                    </div>
                )}
            </div>
        </div>
    );
}
