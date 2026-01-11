import type { Habit } from '@/types/habit';
import { Checkbox } from '@/components/shadcn/checkbox';
import { useState } from 'react';
import { habitsLogHabit, habitsDeleteHabitLog } from '@/lib/api';

interface HabitsListProps {
    habits: Habit[];
    loading: boolean;
    onHabitLogChange: () => Promise<void>;
}

const DAYS_OF_WEEK = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// Helper function to get the date for a day index in the current week (0=Mon, 6=Sun)
function getDateForDayOfWeek(dayIndex: number): string {
    const today = new Date();
    const currentDayOfWeek = today.getDay(); // 0=Sun, 1=Mon, ..., 6=Sat
    // Convert to Mon=0, Tue=1, ..., Sun=6
    const adjustedCurrentDay =
        currentDayOfWeek === 0 ? 6 : currentDayOfWeek - 1;
    const daysFromMonday = adjustedCurrentDay;
    const monday = new Date(today);
    monday.setDate(today.getDate() - daysFromMonday);

    const targetDate = new Date(monday);
    targetDate.setDate(monday.getDate() + dayIndex);

    // Return in YYYY-MM-DD format
    const year = targetDate.getFullYear();
    const month = String(targetDate.getMonth() + 1).padStart(2, '0');
    const day = String(targetDate.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}

export function HabitsList({
    habits,
    loading,
    onHabitLogChange,
}: HabitsListProps) {
    const [processingLogs, setProcessingLogs] = useState<Set<string>>(
        new Set()
    );

    if (loading) {
        return <div className="text-muted-foreground">Loading habits...</div>;
    }

    // Filter habits with frequency kind of multiple-days-per-week
    const multipleDaysHabits = habits.filter(
        (habit) => habit.frequencyKind === 'multiple-days-per-week'
    );

    if (multipleDaysHabits.length === 0) {
        return null;
    }

    const getGoalText = (habit: Habit): string => {
        if (habit.numTimesPerWeek === 1) {
            return 'Once a week';
        } else if (habit.numTimesPerWeek === 2) {
            return 'Twice a week';
        } else if (habit.numTimesPerWeek) {
            return `${habit.numTimesPerWeek} times per week`;
        }
        return '';
    };

    const handleCheckboxChange = async (
        habitId: string,
        dayIndex: number,
        isCurrentlyChecked: boolean
    ): Promise<void> => {
        const date = getDateForDayOfWeek(dayIndex);
        const logKey = `${habitId}-${date}`;

        // Prevent multiple simultaneous requests for the same log
        if (processingLogs.has(logKey)) {
            return;
        }

        setProcessingLogs((prev) => new Set(prev).add(logKey));

        try {
            if (isCurrentlyChecked) {
                // Delete the habit log
                await habitsDeleteHabitLog({
                    path: { id: habitId, date },
                });
            } else {
                // Create a habit log
                await habitsLogHabit({
                    path: { id: habitId },
                    body: { when: date },
                });
            }
            // Refetch habits to get updated doneThisWeek data
            await onHabitLogChange();
        } catch (error) {
            console.error('Failed to update habit log:', error);
            // TODO: Show error toast to user
        } finally {
            setProcessingLogs((prev) => {
                const newSet = new Set(prev);
                newSet.delete(logKey);
                return newSet;
            });
        }
    };

    const getTodayDateString = (): string => {
        const today = new Date();
        const year = today.getFullYear();
        const month = String(today.getMonth() + 1).padStart(2, '0');
        const day = String(today.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    };

    const todayDateString = getTodayDateString();

    return (
        <div className="space-y-2">
            {/* Headers */}
            <div className="flex items-center gap-4">
                <div className="flex-1" />
                <div className="w-32 flex items-center justify-center">
                    <span className="text-xs font-semibold">Goal</span>
                </div>
                <div className="flex gap-2">
                    {DAYS_OF_WEEK.map((day, index) => {
                        const date = getDateForDayOfWeek(index);
                        const isFutureDay = date > todayDateString;

                        return (
                            <div
                                key={day}
                                className="flex items-center justify-center w-9"
                            >
                                <span
                                    className={`text-xs font-semibold ${
                                        isFutureDay
                                            ? 'text-muted-foreground/40'
                                            : ''
                                    }`}
                                >
                                    {day}
                                </span>
                            </div>
                        );
                    })}
                </div>
            </div>
            {/* Habit rows */}
            {multipleDaysHabits.map((habit) => (
                <div key={habit.id} className="flex items-center gap-4">
                    <div className="flex-1">
                        <span className="text-sm font-medium">
                            {habit.task}
                        </span>
                    </div>
                    <div className="w-32 flex items-center justify-center">
                        <span className="text-xs text-muted-foreground">
                            {getGoalText(habit)}
                        </span>
                    </div>
                    <div className="flex gap-2">
                        {DAYS_OF_WEEK.map((day, index) => {
                            const date = getDateForDayOfWeek(index);
                            const logKey = `${habit.id}-${date}`;
                            const isChecked = habit.doneThisWeek.includes(
                                index
                            );
                            const isProcessing = processingLogs.has(logKey);
                            const isFutureDay = date > todayDateString;

                            return (
                                <div
                                    key={day}
                                    className="flex items-center justify-center w-9"
                                >
                                    <Checkbox
                                        id={`${habit.id}-${index}`}
                                        checked={isChecked}
                                        disabled={isProcessing || isFutureDay}
                                        onCheckedChange={() =>
                                            handleCheckboxChange(
                                                habit.id,
                                                index,
                                                isChecked
                                            )
                                        }
                                    />
                                </div>
                            );
                        })}
                    </div>
                </div>
            ))}
        </div>
    );
}
