import { useEffect, useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import type { Fun } from '@/lib/api-client/types.gen';
import {
    funsList,
    funsCreate,
    funsUpdate,
    funsDelete,
    funsReorder,
} from '@/lib/api';

export function useFuns() {
    const [funs, setFuns] = useState<Fun[]>([]);
    const [loading, setLoading] = useState(true);
    const { currentUser } = useAuth();

    useEffect(() => {
        if (!currentUser) {
            setFuns([]);
            setLoading(false);
            return;
        }

        const fetchFuns = async () => {
            try {
                const { data: funsData } = await funsList();

                if (funsData) {
                    setFuns(funsData);
                }
            } catch (error) {
                console.error('Failed to fetch funs:', error);
            } finally {
                setLoading(false);
            }
        };

        fetchFuns();
    }, [currentUser]);

    const addFun = async (
        title: string,
        position: 'top' | 'bottom' = 'top',
        afterId?: string
    ): Promise<string> => {
        if (!currentUser) throw new Error('User must be logged in');

        // Determine insert index for optimistic update
        let insertIndex: number;
        if (afterId) {
            const afterIndex = funs.findIndex((f) => f.id === afterId);
            if (afterIndex === -1) {
                throw new Error('Fun not found');
            }
            insertIndex = afterIndex + 1;
        } else if (position === 'bottom') {
            insertIndex = funs.length;
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

            // Create the fun on the backend
            const { data: newFun } = await funsCreate({
                body: {
                    title,
                    position: positionParam,
                },
            });

            if (newFun) {
                // Add to local state at the correct position
                setFuns((prevFuns) => {
                    const updated = [...prevFuns];
                    updated.splice(insertIndex, 0, newFun);
                    return updated;
                });

                return newFun.id;
            }

            throw new Error('Failed to create fun - no response from server');
        } catch (error) {
            console.error('Failed to create fun:', error);
            throw error;
        }
    };

    const updateFun = async (id: string, updates: { title?: string }) => {
        // Update local state immediately for optimistic UI
        setFuns((prevFuns) =>
            prevFuns.map((fun) =>
                fun.id === id ? { ...fun, ...updates } : fun
            )
        );

        // Only save if title has content
        if (updates.title !== undefined && !updates.title.trim()) {
            return;
        }

        try {
            // Sync to backend
            await funsUpdate({
                path: { id },
                body: {
                    ...(updates.title !== undefined && {
                        title: updates.title.trim(),
                    }),
                },
            });
        } catch (error) {
            console.error('Failed to update fun:', error);
        }
    };

    const deleteFun = async (id: string) => {
        // Remove from local state immediately for optimistic UI
        setFuns((prevFuns) => prevFuns.filter((fun) => fun.id !== id));

        try {
            // Delete from backend
            await funsDelete({ path: { id } });
        } catch (error) {
            console.error('Failed to delete fun:', error);
        }
    };

    const reorderFuns = async (oldIndex: number, newIndex: number) => {
        if (oldIndex === newIndex) return;

        const movedFun = funs[oldIndex];

        // Determine position parameter for backend
        let positionParam;
        if (newIndex === 0) {
            // Moving to the top
            positionParam = { type: 'top' as const };
        } else if (newIndex === funs.length - 1) {
            // Moving to the bottom
            positionParam = { type: 'bottom' as const };
        } else if (oldIndex < newIndex) {
            // Moving down - insert after the fun that's currently at newIndex
            positionParam = { type: 'after' as const, id: funs[newIndex].id };
        } else {
            // Moving up - insert after the fun that's before newIndex
            positionParam = {
                type: 'after' as const,
                id: funs[newIndex - 1].id,
            };
        }

        // Optimistically update local state
        setFuns((prevFuns) => {
            const updated = [...prevFuns];
            const [moved] = updated.splice(oldIndex, 1);
            updated.splice(newIndex, 0, moved);
            return updated;
        });

        try {
            // Sync to backend
            const { data: updatedFun } = await funsReorder({
                path: { id: movedFun.id },
                body: { position: positionParam },
            });

            // Update with the server-calculated order
            if (updatedFun) {
                setFuns((prevFuns) =>
                    prevFuns.map((fun) =>
                        fun.id === updatedFun.id
                            ? { ...fun, order: updatedFun.order }
                            : fun
                    )
                );
            }
        } catch (error) {
            console.error('Failed to reorder fun:', error);
            // Rollback on error - refetch funs
            const { data: funsData } = await funsList();
            if (funsData) {
                setFuns(funsData);
            }
        }
    };

    return {
        funs,
        loading,
        addFun,
        updateFun,
        deleteFun,
        reorderFuns,
    };
}
