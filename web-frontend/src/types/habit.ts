import type { JSONContent } from '@tiptap/react';

export type HabitStatus = 'todo' | 'complete' | 'archived' | 'waiting';

export type FrequencyKind =
    | 'specific-days-per-week'
    | 'multiple-days-per-week'
    | 'specific-day-of-month'
    | 'multiple-days-per-month';

export type TimeEstimate =
    | '1-min'
    | '5-mins'
    | '15-mins'
    | '30-mins'
    | '1-hour'
    | '2-hours'
    | 'half-day'
    | 'one-day'
    | 'project';

export interface Habit {
    id: string;
    task: string;
    details: JSONContent | null;
    status: HabitStatus;
    dateCreated: Date;
    dateUpdated: Date;
    userId: string;
    order: string;
    priority?: number;
    desirability?: number;
    importance: number;
    timeEstimate?: TimeEstimate;
    annoyingness: number;
    committed: boolean;
    elapsedTimeSeconds: number;
    atomic: boolean;
    infinitelyDivisible: boolean;
    frequencyKind: FrequencyKind;
    daysOfWeek?: number[];
    numTimesPerWeek?: number;
    numTimesPerMonth?: number;
    dayOfMonth?: number;
    doneThisWeek: number[];
}
