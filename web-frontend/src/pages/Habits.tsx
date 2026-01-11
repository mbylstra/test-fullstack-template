import { useCallback } from 'react';
import AddHabitDialog from '@/components/AddHabitDialog';
import HabitCard from '@/components/HabitCard';
import { useHabits } from '@/hooks/useHabits';
import { habitsList } from '@/lib/api';

function Habits() {
    const { habits, loading, setHabits, setLoading } = useHabits();

    const handleHabitCreated = useCallback(async () => {
        try {
            setLoading(true);
            const { data: habitsData } = await habitsList();

            if (habitsData) {
                // Filter to show only active habits (not archived)
                const activeHabits = habitsData.filter((habit) =>
                    ['todo', 'complete', 'waiting'].includes(habit.status)
                );

                // Convert backend format to frontend format
                const formattedHabits = activeHabits.map((habit) => ({
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
                }));

                setHabits(formattedHabits);
            }
        } catch (error) {
            console.error('Failed to refresh habits:', error);
        } finally {
            setLoading(false);
        }
    }, [setHabits, setLoading]);

    return (
        <div className="h-full bg-background">
            <div className="container mx-auto px-4 py-4 max-w-4xl">
                <div className="flex items-center justify-between mb-4">
                    <h1 className="text-3xl font-bold">Habits</h1>
                    <AddHabitDialog onHabitCreated={handleHabitCreated} />
                </div>
                {loading ? (
                    <p className="text-muted-foreground">Loading habits...</p>
                ) : habits.length === 0 ? (
                    <p className="text-muted-foreground">
                        No habits yet. Click "New Habit" to create one.
                    </p>
                ) : (
                    <div className="space-y-3">
                        {habits.map((habit) => (
                            <HabitCard key={habit.id} habit={habit} />
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
}

export default Habits;
