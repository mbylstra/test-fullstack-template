import { useState, useRef, useCallback } from 'react';
import { Button } from '@/components/shadcn/button';
import { Input } from '@/components/shadcn/input';
import { Plus } from 'lucide-react';
import { SortableFunItem } from '@/components/SortableFunItem';
import RandomFunDialog from '@/components/RandomFunDialog';
import type { Fun } from '@/lib/api-client/types.gen';
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

interface FunListProps {
    funs: Fun[];
    onAddFun: (title: string, position: 'top' | 'bottom') => Promise<void>;
    onUpdateFun: (id: string, updates: { title?: string }) => Promise<void>;
    onDeleteFun: (id: string) => Promise<void>;
    onReorderFuns: (oldIndex: number, newIndex: number) => Promise<void>;
}

export default function FunList({
    funs,
    onAddFun,
    onUpdateFun,
    onDeleteFun,
    onReorderFuns,
}: FunListProps) {
    const [newFunTitle, setNewFunTitle] = useState('');
    const [isAddingTop, setIsAddingTop] = useState(false);
    const [isAddingBottom, setIsAddingBottom] = useState(false);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [editValue, setEditValue] = useState('');
    const [hoveringFunId, setHoveringFunId] = useState<string | null>(null);

    const inputRef = useRef<HTMLInputElement>(null);
    const addTopInputRef = useRef<HTMLInputElement>(null);
    const addBottomInputRef = useRef<HTMLInputElement>(null);

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

    const handleDragEnd = useCallback(
        (event: DragEndEvent) => {
            const { active, over } = event;

            if (over && active.id !== over.id) {
                const oldIndex = funs.findIndex((fun) => fun.id === active.id);
                const newIndex = funs.findIndex((fun) => fun.id === over.id);

                if (oldIndex !== -1 && newIndex !== -1) {
                    onReorderFuns(oldIndex, newIndex);
                }
            }
        },
        [funs, onReorderFuns]
    );

    const handleAddFun = async (position: 'top' | 'bottom') => {
        const title = newFunTitle.trim();
        if (!title) return;

        await onAddFun(title, position);
        setNewFunTitle('');
        setIsAddingTop(false);
        setIsAddingBottom(false);
    };

    const handleStartEdit = (fun: Fun) => {
        setEditingId(fun.id);
        setEditValue(fun.title);
        setTimeout(() => inputRef.current?.focus(), 0);
    };

    const handleFinishEdit = async () => {
        if (
            editingId &&
            editValue.trim() &&
            editValue !== funs.find((f) => f.id === editingId)?.title
        ) {
            await onUpdateFun(editingId, { title: editValue.trim() });
        }
        setEditingId(null);
        setEditValue('');
    };

    const handleKeyDown = (
        e: React.KeyboardEvent,
        position?: 'top' | 'bottom'
    ) => {
        if (e.key === 'Enter') {
            e.preventDefault();
            if (position) {
                handleAddFun(position);
            } else {
                handleFinishEdit();
            }
        } else if (e.key === 'Escape') {
            if (position) {
                setNewFunTitle('');
                setIsAddingTop(false);
                setIsAddingBottom(false);
            } else {
                setEditingId(null);
                setEditValue('');
            }
        }
    };

    return (
        <div className="max-w-4xl mx-auto p-6">
            <div className="space-y-4">
                {/* Random Fun Thing Button */}
                <div className="mb-4">
                    <RandomFunDialog count={3} />
                </div>

                {/* Add to top */}
                <div className="border-b pb-4">
                    {isAddingTop ? (
                        <div className="flex gap-2">
                            <Input
                                ref={addTopInputRef}
                                value={newFunTitle}
                                onChange={(e) => setNewFunTitle(e.target.value)}
                                onBlur={() => {
                                    if (!newFunTitle.trim()) {
                                        setIsAddingTop(false);
                                    }
                                }}
                                onKeyDown={(e) => handleKeyDown(e, 'top')}
                                placeholder="What's fun?"
                                autoFocus
                            />
                            <Button
                                onClick={() => handleAddFun('top')}
                                disabled={!newFunTitle.trim()}
                            >
                                Add
                            </Button>
                            <Button
                                variant="outline"
                                onClick={() => {
                                    setNewFunTitle('');
                                    setIsAddingTop(false);
                                }}
                            >
                                Cancel
                            </Button>
                        </div>
                    ) : (
                        <Button
                            variant="outline"
                            onClick={() => {
                                setIsAddingTop(true);
                                setTimeout(
                                    () => addTopInputRef.current?.focus(),
                                    0
                                );
                            }}
                            className="w-full"
                        >
                            <Plus className="h-4 w-4 mr-2" />
                            Add to top
                        </Button>
                    )}
                </div>

                {/* Fun list with drag and drop */}
                {funs.length > 0 ? (
                    <DndContext
                        sensors={sensors}
                        collisionDetection={closestCenter}
                        onDragEnd={handleDragEnd}
                    >
                        <SortableContext
                            items={funs.map((fun) => fun.id)}
                            strategy={verticalListSortingStrategy}
                        >
                            <div className="space-y-1">
                                {funs.map((fun) => (
                                    <SortableFunItem
                                        key={fun.id}
                                        fun={fun}
                                        isEditing={editingId === fun.id}
                                        editValue={editValue}
                                        onStartEdit={() => handleStartEdit(fun)}
                                        onEditChange={setEditValue}
                                        onFinishEdit={handleFinishEdit}
                                        onKeyDown={handleKeyDown}
                                        onDelete={() => onDeleteFun(fun.id)}
                                        inputRef={inputRef}
                                        isHovering={hoveringFunId === fun.id}
                                        onHoveringChange={(isHovering) =>
                                            setHoveringFunId(
                                                isHovering ? fun.id : null
                                            )
                                        }
                                    />
                                ))}
                            </div>
                        </SortableContext>
                    </DndContext>
                ) : (
                    <div className="text-center text-gray-500 py-8">
                        No fun items yet. Add one to get started!
                    </div>
                )}

                {/* Add to bottom */}
                <div className="border-t pt-4">
                    {isAddingBottom ? (
                        <div className="flex gap-2">
                            <Input
                                ref={addBottomInputRef}
                                value={newFunTitle}
                                onChange={(e) => setNewFunTitle(e.target.value)}
                                onBlur={() => {
                                    if (!newFunTitle.trim()) {
                                        setIsAddingBottom(false);
                                    }
                                }}
                                onKeyDown={(e) => handleKeyDown(e, 'bottom')}
                                placeholder="What's fun?"
                                autoFocus
                            />
                            <Button
                                onClick={() => handleAddFun('bottom')}
                                disabled={!newFunTitle.trim()}
                            >
                                Add
                            </Button>
                            <Button
                                variant="outline"
                                onClick={() => {
                                    setNewFunTitle('');
                                    setIsAddingBottom(false);
                                }}
                            >
                                Cancel
                            </Button>
                        </div>
                    ) : (
                        <Button
                            variant="outline"
                            onClick={() => {
                                setIsAddingBottom(true);
                                setTimeout(
                                    () => addBottomInputRef.current?.focus(),
                                    0
                                );
                            }}
                            className="w-full"
                        >
                            <Plus className="h-4 w-4 mr-2" />
                            Add to bottom
                        </Button>
                    )}
                </div>
            </div>
        </div>
    );
}
