import type { Habit } from '@/types/habit';
import { Card, CardContent, CardHeader } from '@/components/shadcn/card';

interface HabitCardProps {
    habit: Habit;
}

const DAYS_OF_WEEK = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

function formatFrequency(habit: Habit): string {
    switch (habit.frequencyKind) {
        case 'specific-days-per-week':
            if (habit.daysOfWeek && habit.daysOfWeek.length > 0) {
                const dayNames = habit.daysOfWeek
                    .map((day) => DAYS_OF_WEEK[day])
                    .join(', ');
                return `Every ${dayNames}`;
            }
            return 'Specific days per week';

        case 'multiple-days-per-week':
            if (habit.numTimesPerWeek === 7) {
                return 'Every Day';
            }
            const timesPerWeek = habit.numTimesPerWeek || 0;
            return `${timesPerWeek} ${timesPerWeek === 1 ? 'time' : 'times'} per week`;

        case 'specific-day-of-month':
            return `Day ${habit.dayOfMonth} of each month`;

        case 'multiple-days-per-month':
            const timesPerMonth = habit.numTimesPerMonth || 0;
            return `${timesPerMonth} ${timesPerMonth === 1 ? 'time' : 'times'} per month`;

        default:
            return 'Unknown frequency';
    }
}

export default function HabitCard({ habit }: HabitCardProps) {
    return (
        <Card className="w-full">
            <CardHeader>
                <div className="flex items-start justify-between">
                    <h3 className="text-lg font-semibold">{habit.task}</h3>
                </div>
            </CardHeader>
            <CardContent>
                <div className="text-sm text-muted-foreground">
                    {formatFrequency(habit)}
                </div>
            </CardContent>
        </Card>
    );
}
