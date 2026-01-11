import type { JSONContent } from '@tiptap/react';

export type TodoStatus = 'todo' | 'complete' | 'archived' | 'waiting';

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

export const TIME_ESTIMATE_LABELS: Record<TimeEstimate, string> = {
    '1-min': '1 min',
    '5-mins': '5 mins',
    '15-mins': '15 mins',
    '30-mins': '30 mins',
    '1-hour': '1 hour',
    '2-hours': '2 hours',
    'half-day': 'Half a day',
    'one-day': '1 Day',
    project: 'Project',
};

export interface Todo {
    id: string;
    task: string;
    details: JSONContent | null;
    status: TodoStatus;
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
}

export type TodoInput = Omit<
    Todo,
    'id' | 'dateCreated' | 'dateUpdated' | 'userId'
>;
