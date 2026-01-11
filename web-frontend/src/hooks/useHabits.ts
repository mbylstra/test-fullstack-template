import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import type { Habit } from '@/types/habit';
import { habitsList } from '@/lib/api';

export function useHabits() {
    const [habits, setHabits] = useState<Habit[]>([]);
    const [loading, setLoading] = useState(true);
    const { currentUser } = useAuth();

    const fetchHabits = useCallback(async () => {
        if (!currentUser) {
            setHabits([]);
            setLoading(false);
            return;
        }

        try {
            const { data: habitsData } = await habitsList();

            if (habitsData) {
                // Filter to show only active habits (not archived)
                const activeHabits = habitsData.filter((habit) =>
                    ['todo', 'complete', 'waiting'].includes(habit.status)
                );

                // Convert backend format to frontend format
                const formattedHabits: Habit[] = activeHabits.map(
                    (habit) => ({
                        id: habit.id,
                        task: habit.task,
                        details: habit.details || null,
                        status: habit.status,
                        dateCreated: new Date(habit.date_created),
                        dateUpdated: new Date(habit.date_updated),
                        userId: habit.user_id,
                        order: habit.order,
                        importance: habit.importance ?? 1,
                        timeEstimate: habit.time_estimate,
                        annoyingness: habit.annoyingness,
                        committed: habit.committed,
                        elapsedTimeSeconds: habit.elapsedTimeSeconds ?? 0,
                        atomic: habit.atomic,
                        infinitelyDivisible: habit.infinitely_divisible,
                        frequencyKind: habit.frequency_kind,
                        daysOfWeek: habit.days_of_week,
                        numTimesPerWeek: habit.num_times_per_week,
                        numTimesPerMonth: habit.num_times_per_month,
                        dayOfMonth: habit.day_of_month,
                        doneThisWeek: habit.done_this_week ?? [],
                    })
                );

                // Backend already returns habits sorted by order field
                setHabits(formattedHabits);
            }
        } catch (error) {
            console.error('Failed to fetch habits:', error);
        } finally {
            setLoading(false);
        }
    }, [currentUser]);

    useEffect(() => {
        fetchHabits();
    }, [fetchHabits]);

    return {
        habits,
        loading,
        setHabits,
        setLoading,
        refetch: fetchHabits,
    };
}
