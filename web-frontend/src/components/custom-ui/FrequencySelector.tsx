import { useState } from 'react';
import { ChevronDown } from 'lucide-react';
import {
    Popover,
    PopoverContent,
    PopoverTrigger,
} from '@/components/shadcn/popover';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/shadcn/tabs';
import { Button } from '@/components/shadcn/button';

export type FrequencyType =
    | 'specific-days'
    | 'weekly-goal'
    | 'monthly-goal'
    | 'once-per-month';

export type DayOfWeek = 'monday' | 'tuesday' | 'wednesday' | 'thursday' | 'friday' | 'saturday' | 'sunday';

export interface FrequencyData {
    type: FrequencyType;
    specificDays?: DayOfWeek[];
    daysPerWeek?: number;
    timesPerMonth?: number;
    dayOfMonth?: number;
}

interface FrequencySelectorProps {
    value: FrequencyData | null;
    onChange: (value: FrequencyData) => void;
}

const frequencyLabels: Record<FrequencyType, string> = {
    'specific-days': 'Specific days',
    'weekly-goal': 'Weekly goal',
    'monthly-goal': 'Monthly goal',
    'once-per-month': 'Once per month',
};

const dayLabels: { value: DayOfWeek; short: string }[] = [
    { value: 'monday', short: 'Mo' },
    { value: 'tuesday', short: 'Tu' },
    { value: 'wednesday', short: 'We' },
    { value: 'thursday', short: 'Th' },
    { value: 'friday', short: 'Fr' },
    { value: 'saturday', short: 'Sa' },
    { value: 'sunday', short: 'Su' },
];

export function FrequencySelector({ value, onChange }: FrequencySelectorProps) {
    const [open, setOpen] = useState(false);
    const [tempValue, setTempValue] = useState<FrequencyData | null>(value);

    const getDisplayText = () => {
        if (!value) return 'Please choose';

        if (value.type === 'specific-days' && value.specificDays && value.specificDays.length > 0) {
            return value.specificDays
                .map((day) => dayLabels.find((d) => d.value === day)?.short)
                .filter(Boolean)
                .join(', ');
        }

        if (value.type === 'weekly-goal' && value.daysPerWeek !== undefined) {
            if (value.daysPerWeek === 7) {
                return 'Every day';
            }
            return `${value.daysPerWeek} days per week`;
        }

        if (value.type === 'monthly-goal' && value.timesPerMonth !== undefined) {
            return `${value.timesPerMonth} times per month`;
        }

        if (value.type === 'once-per-month' && value.dayOfMonth !== undefined) {
            return `Day ${value.dayOfMonth} of month`;
        }

        return frequencyLabels[value.type];
    };

    const handleTabChange = (newValue: string) => {
        const newType = newValue as FrequencyType;
        setTempValue({
            type: newType,
            specificDays: newType === 'specific-days' ? [] : undefined,
            daysPerWeek: newType === 'weekly-goal' ? undefined : undefined,
        });
    };

    const toggleDay = (day: DayOfWeek) => {
        if (!tempValue || tempValue.type !== 'specific-days') return;

        const currentDays = tempValue.specificDays || [];
        const newDays = currentDays.includes(day)
            ? currentDays.filter((d) => d !== day)
            : [...currentDays, day];

        setTempValue({
            ...tempValue,
            specificDays: newDays,
        });
    };

    const setDaysPerWeek = (days: number) => {
        if (!tempValue || tempValue.type !== 'weekly-goal') return;

        setTempValue({
            ...tempValue,
            daysPerWeek: days,
        });
    };

    const setTimesPerMonth = (times: number) => {
        if (!tempValue || tempValue.type !== 'monthly-goal') return;

        setTempValue({
            ...tempValue,
            timesPerMonth: times,
        });
    };

    const setDayOfMonth = (day: number) => {
        if (!tempValue || tempValue.type !== 'once-per-month') return;

        setTempValue({
            ...tempValue,
            dayOfMonth: day,
        });
    };

    const handleCancel = () => {
        setTempValue(value);
        setOpen(false);
    };

    const handleOk = () => {
        if (tempValue) {
            onChange(tempValue);
        }
        setOpen(false);
    };

    const handleOpenChange = (newOpen: boolean) => {
        if (newOpen) {
            setTempValue(value ?? { type: 'specific-days', specificDays: [] });
        }
        setOpen(newOpen);
    };

    return (
        <Popover open={open} onOpenChange={handleOpenChange}>
            <PopoverTrigger asChild>
                <button
                    type="button"
                    className="border-input data-[placeholder]:text-muted-foreground [&_svg:not([class*='text-'])]:text-muted-foreground focus-visible:border-ring focus-visible:ring-ring/50 flex w-full items-center justify-between gap-2 rounded-md border bg-transparent px-3 py-2 text-sm shadow-xs transition-[color,box-shadow] outline-none focus-visible:ring-[3px] disabled:cursor-not-allowed disabled:opacity-50 h-9"
                >
                    <span className={value ? '' : 'text-muted-foreground'}>
                        {getDisplayText()}
                    </span>
                    <ChevronDown className="size-4 opacity-50" />
                </button>
            </PopoverTrigger>
            <PopoverContent className="w-[var(--radix-popover-trigger-width)] p-0" align="start">
                <Tabs
                    value={tempValue?.type ?? 'specific-days'}
                    onValueChange={handleTabChange}
                    className="w-full"
                >
                    <TabsList className="w-full grid grid-cols-4 h-auto p-1">
                        <TabsTrigger value="specific-days" className="text-xs px-1">
                            Specific days
                        </TabsTrigger>
                        <TabsTrigger value="weekly-goal" className="text-xs px-1">
                            Weekly goal
                        </TabsTrigger>
                        <TabsTrigger value="monthly-goal" className="text-xs px-1">
                            Monthly goal
                        </TabsTrigger>
                        <TabsTrigger value="once-per-month" className="text-xs px-1">
                            Once per month
                        </TabsTrigger>
                    </TabsList>
                    <div className="p-4">
                        <TabsContent value="specific-days" className="mt-0">
                            <div className="flex gap-1">
                                {dayLabels.map((day) => (
                                    <Button
                                        key={day.value}
                                        type="button"
                                        variant={tempValue?.specificDays?.includes(day.value) ? 'default' : 'outline'}
                                        size="sm"
                                        onClick={() => toggleDay(day.value)}
                                        className="min-w-[2.5rem]"
                                    >
                                        {day.short}
                                    </Button>
                                ))}
                            </div>
                        </TabsContent>
                        <TabsContent value="weekly-goal" className="mt-0">
                            <div className="space-y-2 flex flex-col items-center">
                                <Button
                                    type="button"
                                    variant={tempValue?.daysPerWeek === 7 ? 'default' : 'outline'}
                                    size="sm"
                                    onClick={() => setDaysPerWeek(7)}
                                >
                                    Every day
                                </Button>
                                <div className="text-sm text-muted-foreground">or</div>
                                <div className="flex gap-2 items-center">
                                    {[1, 2, 3, 4, 5, 6].map((days) => (
                                        <Button
                                            key={days}
                                            type="button"
                                            variant={tempValue?.daysPerWeek === days ? 'default' : 'outline'}
                                            size="sm"
                                            onClick={() => setDaysPerWeek(days)}
                                            className="min-w-[2.5rem]"
                                        >
                                            {days}
                                        </Button>
                                    ))}
                                </div>
                                <div className="text-sm text-muted-foreground">days per week</div>
                            </div>
                        </TabsContent>
                        <TabsContent value="monthly-goal" className="mt-0">
                            <div className="space-y-2 flex flex-col items-center">
                                <div className="flex gap-2 items-center">
                                    {[1, 2, 3, 4].map((times) => (
                                        <Button
                                            key={times}
                                            type="button"
                                            variant={tempValue?.timesPerMonth === times ? 'default' : 'outline'}
                                            size="sm"
                                            onClick={() => setTimesPerMonth(times)}
                                            className="min-w-[2.5rem]"
                                        >
                                            {times}
                                        </Button>
                                    ))}
                                </div>
                                <div className="text-sm text-muted-foreground">times per month</div>
                            </div>
                        </TabsContent>
                        <TabsContent value="once-per-month" className="mt-0">
                            <div className="space-y-2">
                                <div className="text-sm text-muted-foreground text-center">Day of the month</div>
                                <div className="grid grid-cols-7 gap-1">
                                    {Array.from({ length: 31 }, (_, i) => i + 1).map((day) => (
                                        <Button
                                            key={day}
                                            type="button"
                                            variant={tempValue?.dayOfMonth === day ? 'default' : 'outline'}
                                            size="sm"
                                            onClick={() => setDayOfMonth(day)}
                                            className="min-w-[2.5rem]"
                                        >
                                            {day}
                                        </Button>
                                    ))}
                                </div>
                            </div>
                        </TabsContent>
                    </div>
                </Tabs>
                <div className="flex justify-end gap-2 px-4 pt-4 pb-4 border-t">
                    <Button
                        variant="outline"
                        size="sm"
                        onClick={handleCancel}
                    >
                        Cancel
                    </Button>
                    <Button
                        size="sm"
                        onClick={handleOk}
                    >
                        OK
                    </Button>
                </div>
            </PopoverContent>
        </Popover>
    );
}
