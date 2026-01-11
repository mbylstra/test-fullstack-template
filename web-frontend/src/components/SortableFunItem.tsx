import { Input } from '@/components/shadcn/input';
import { Button } from '@/components/shadcn/button';
import { Trash2, GripVertical } from 'lucide-react';
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import type { Fun } from '@/lib/api-client/types.gen';

export interface SortableFunItemProps {
    fun: Fun;
    isEditing: boolean;
    editValue: string;
    onStartEdit: () => void;
    onEditChange: (value: string) => void;
    onFinishEdit: () => void;
    onKeyDown: (e: React.KeyboardEvent) => void;
    onDelete: () => void;
    inputRef: React.RefObject<HTMLInputElement | null>;
    isHovering: boolean;
    onHoveringChange: (isHovering: boolean) => void;
}

export function SortableFunItem({
    fun,
    isEditing,
    editValue,
    onStartEdit,
    onEditChange,
    onFinishEdit,
    onKeyDown,
    onDelete,
    inputRef,
    isHovering,
    onHoveringChange,
}: SortableFunItemProps) {
    const {
        attributes,
        listeners,
        setNodeRef,
        transform,
        transition,
        isDragging,
    } = useSortable({ id: fun.id });

    const style = {
        transform: CSS.Transform.toString(transform),
        transition,
        opacity: isDragging ? 0.5 : 1,
    };

    return (
        <div
            ref={setNodeRef}
            style={style}
            className="flex items-center gap-2 py-2 px-3 hover:bg-gray-50 rounded-md group"
            onMouseEnter={() => onHoveringChange(true)}
            onMouseLeave={() => onHoveringChange(false)}
        >
            {/* Drag handle */}
            <div
                {...attributes}
                {...listeners}
                className="cursor-grab active:cursor-grabbing opacity-30 hover:opacity-100 transition-opacity"
            >
                <GripVertical className="h-4 w-4 text-gray-400" />
            </div>

            {/* Title */}
            <div className="flex-1">
                {isEditing ? (
                    <Input
                        ref={inputRef}
                        value={editValue}
                        onChange={(e) => onEditChange(e.target.value)}
                        onBlur={onFinishEdit}
                        onKeyDown={onKeyDown}
                        className="h-8"
                        autoFocus
                    />
                ) : (
                    <div
                        onClick={onStartEdit}
                        className="cursor-text py-1 px-2 rounded hover:bg-gray-100"
                    >
                        {fun.title}
                    </div>
                )}
            </div>

            {/* Delete button */}
            {isHovering && !isEditing && (
                <Button
                    variant="ghost"
                    size="icon"
                    onClick={onDelete}
                    className="h-8 w-8 opacity-0 group-hover:opacity-100 transition-opacity"
                >
                    <Trash2 className="h-4 w-4 text-red-500" />
                </Button>
            )}
        </div>
    );
}
