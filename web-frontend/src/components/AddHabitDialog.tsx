import { useState } from 'react';
import { Plus } from 'lucide-react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import type { JSONContent } from '@tiptap/react';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from '@/components/shadcn/dialog';
import {
    Form,
    FormControl,
    FormField,
    FormItem,
    FormLabel,
    FormMessage,
} from '@/components/shadcn/form';
import { Input } from '@/components/shadcn/input';
import { Button } from '@/components/shadcn/button';
import { RichTextEditor } from '@/components/custom-ui/rich-text-editor';
import {
    FrequencySelector,
    type FrequencyData,
} from '@/components/custom-ui/FrequencySelector';
import { habitsCreate } from '@/lib/api';
import type { FrequencyKind } from '@/lib/api-client';

const habitFormSchema = z.object({
    title: z.string().min(1, 'Title is required'),
    description: z.custom<JSONContent | null>(),
    frequency: z.custom<FrequencyData | null>().refine((val) => val !== null, {
        message: 'Frequency is required',
    }),
});

type HabitFormValues = z.infer<typeof habitFormSchema>;

interface AddHabitDialogProps {
    onHabitCreated?: () => void | Promise<void>;
}

function mapFrequencyDataToApi(frequency: FrequencyData): {
    frequency_kind: FrequencyKind;
    days_of_week?: number[];
    num_times_per_week?: number;
    num_times_per_month?: number;
    day_of_month?: number;
} {
    const dayMap: Record<string, number> = {
        sunday: 0,
        monday: 1,
        tuesday: 2,
        wednesday: 3,
        thursday: 4,
        friday: 5,
        saturday: 6,
    };

    switch (frequency.type) {
        case 'specific-days':
            return {
                frequency_kind: 'specific-days-per-week',
                days_of_week: (frequency.specificDays ?? []).map(
                    (day) => dayMap[day]
                ),
            };
        case 'weekly-goal':
            return {
                frequency_kind: 'multiple-days-per-week',
                num_times_per_week: frequency.daysPerWeek ?? 1,
            };
        case 'monthly-goal':
            return {
                frequency_kind: 'multiple-days-per-month',
                num_times_per_month: frequency.timesPerMonth ?? 1,
            };
        case 'once-per-month':
            return {
                frequency_kind: 'specific-day-of-month',
                day_of_month: frequency.dayOfMonth ?? 1,
            };
        default:
            const _exhaustive: never = frequency.type;
            return _exhaustive;
    }
}

export default function AddHabitDialog({
    onHabitCreated,
}: AddHabitDialogProps) {
    const [open, setOpen] = useState(false);
    const [isLoading, setIsLoading] = useState(false);
    const form = useForm<HabitFormValues>({
        resolver: zodResolver(habitFormSchema),
        defaultValues: {
            title: '',
            description: null,
            frequency: null,
        },
    });

    const onSubmit = async (data: HabitFormValues) => {
        try {
            setIsLoading(true);
            const frequencyData = mapFrequencyDataToApi(data.frequency!);

            await habitsCreate({
                body: {
                    task: data.title,
                    details: data.description ? { description: data.description } : undefined,
                    ...frequencyData,
                },
            });

            form.reset();
            setOpen(false);

            // Notify parent component to refresh habits
            if (onHabitCreated) {
                await onHabitCreated();
            }
        } catch (error) {
            console.error('Failed to create habit:', error);
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <Button>
                    <Plus className="h-4 w-4 mr-2" />
                    New Habit
                </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[425px]">
                <DialogHeader>
                    <DialogTitle>Add New Habit</DialogTitle>
                    <DialogDescription>
                        Create a new habit to track. Fill in the title and
                        optional description.
                    </DialogDescription>
                </DialogHeader>
                <Form {...form}>
                    <form
                        onSubmit={form.handleSubmit(onSubmit)}
                        className="space-y-4"
                    >
                        <FormField
                            control={form.control}
                            name="title"
                            render={({ field }) => (
                                <FormItem>
                                    <FormLabel>Title</FormLabel>
                                    <FormControl>
                                        <Input
                                            placeholder="Enter habit name"
                                            {...field}
                                        />
                                    </FormControl>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />
                        <FormField
                            control={form.control}
                            name="frequency"
                            render={({ field }) => (
                                <FormItem>
                                    <FormLabel>Frequency</FormLabel>
                                    <FormControl>
                                        <FrequencySelector
                                            value={field.value}
                                            onChange={field.onChange}
                                        />
                                    </FormControl>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />
                        <FormField
                            control={form.control}
                            name="description"
                            render={({ field }) => (
                                <FormItem>
                                    <FormLabel>
                                        Description (optional)
                                    </FormLabel>
                                    <FormControl>
                                        <RichTextEditor
                                            content={field.value}
                                            onChange={field.onChange}
                                            placeholder="Add description..."
                                            className="border rounded-md p-2 min-h-[120px] bg-background"
                                        />
                                    </FormControl>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />
                        <div className="flex justify-end gap-3">
                            <Button
                                type="button"
                                variant="outline"
                                onClick={() => setOpen(false)}
                                disabled={isLoading}
                            >
                                Cancel
                            </Button>
                            <Button type="submit" disabled={isLoading}>
                                {isLoading ? 'Creating...' : 'Add Habit'}
                            </Button>
                        </div>
                    </form>
                </Form>
            </DialogContent>
        </Dialog>
    );
}
