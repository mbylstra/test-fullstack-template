import type { Meta, StoryObj } from '@storybook/react-vite';
import TodoList from './TodoList';
import type { Todo } from '@/types/todo';

const meta = {
    title: 'Components/TodoList',
    component: TodoList,
    parameters: {
        layout: 'padded',
    },
    tags: ['autodocs'],
} satisfies Meta<typeof TodoList>;

export default meta;
type Story = StoryObj<typeof meta>;

const mockTodos: Todo[] = [
    {
        id: '1',
        task: 'Buy groceries',
        details: null,
        status: 'todo',
        userId: 'user1',
        dateCreated: new Date('2024-01-01'),
        dateUpdated: new Date('2024-01-01'),
        order: 'a0',
        importance: 1,
        annoyingness: 0,
        committed: false,
        elapsedTimeSeconds: 0,
        atomic: false,
        infinitelyDivisible: false,
    },
    {
        id: '2',
        task: 'Finish project report',
        details: {
            type: 'doc',
            content: [
                {
                    type: 'paragraph',
                    content: [
                        {
                            type: 'text',
                            text: 'Due by end of week',
                        },
                    ],
                },
            ],
        },
        status: 'complete',
        userId: 'user1',
        dateCreated: new Date('2024-01-02'),
        dateUpdated: new Date('2024-01-02'),
        order: 'a1',
        importance: 3,
        annoyingness: 0,
        committed: true,
        elapsedTimeSeconds: 0,
        atomic: false,
        infinitelyDivisible: false,
    },
    {
        id: '3',
        task: 'Call dentist for appointment',
        details: {
            type: 'doc',
            content: [
                {
                    type: 'paragraph',
                    content: [
                        {
                            type: 'text',
                            text: 'Schedule for next month',
                        },
                    ],
                },
            ],
        },
        status: 'todo',
        userId: 'user1',
        dateCreated: new Date('2024-01-03'),
        dateUpdated: new Date('2024-01-03'),
        order: 'a2',
        importance: 2,
        annoyingness: 0,
        committed: false,
        elapsedTimeSeconds: 0,
        atomic: false,
        infinitelyDivisible: false,
    },
];

export const Default: Story = {
    args: {
        todos: mockTodos,
        loading: false,
        onToggleTodo: async (id: string) => {
            console.log('Toggling todo:', id);
        },
        onUpdateTodo: async (id: string, updates) => {
            console.log('Updating todo:', id, updates);
        },
        onReorderTodos: async (oldIndex: number, newIndex: number) => {
            console.log('Reordering todos:', { oldIndex, newIndex });
        },
        onArchiveCompleted: async () => {
            console.log('Archiving completed todos');
        },
        onDeleteTodo: async (id: string) => {
            console.log('Deleting todo:', id);
        },
        onAddTodo: async (task: string, details) => {
            console.log('Adding todo:', { task, details });
            return 'new-todo-id';
        },
        runningTimers: new Set(),
        onRunningTimersChange: () => {},
        timerStartTimes: new Map(),
        finalizedElapsedTimes: new Map(),
        onOpenRightPanel: () => console.log('Open right panel'),
    },
};

export const Empty: Story = {
    args: {
        todos: [],
        loading: false,
        onToggleTodo: async () => {},
        onUpdateTodo: async () => {},
        onReorderTodos: async () => {},
        onArchiveCompleted: async () => {},
        onDeleteTodo: async () => {},
        onAddTodo: async () => 'new-todo-id',
        runningTimers: new Set(),
        onRunningTimersChange: () => {},
        timerStartTimes: new Map(),
        finalizedElapsedTimes: new Map(),
        onOpenRightPanel: () => console.log('Open right panel'),
    },
};

export const Loading: Story = {
    args: {
        todos: [],
        loading: true,
        onToggleTodo: async () => {},
        onUpdateTodo: async () => {},
        onReorderTodos: async () => {},
        onArchiveCompleted: async () => {},
        onDeleteTodo: async () => {},
        onAddTodo: async () => 'new-todo-id',
        runningTimers: new Set(),
        onRunningTimersChange: () => {},
        timerStartTimes: new Map(),
        finalizedElapsedTimes: new Map(),
        onOpenRightPanel: () => console.log('Open right panel'),
    },
};

export const AllComplete: Story = {
    args: {
        todos: [
            {
                id: '1',
                task: 'Task 1',
                details: null,
                status: 'complete',
                userId: 'user1',
                dateCreated: new Date(),
                dateUpdated: new Date(),
                order: 'a0',
                importance: 1,
                annoyingness: 0,
                committed: true,
                elapsedTimeSeconds: 0,
                atomic: false,
                infinitelyDivisible: false,
            },
            {
                id: '2',
                task: 'Task 2',
                details: null,
                status: 'complete',
                userId: 'user1',
                dateCreated: new Date(),
                dateUpdated: new Date(),
                order: 'a1',
                importance: 1,
                annoyingness: 0,
                committed: true,
                elapsedTimeSeconds: 0,
                atomic: false,
                infinitelyDivisible: false,
            },
        ],
        loading: false,
        onToggleTodo: async () => {},
        onUpdateTodo: async () => {},
        onReorderTodos: async () => {},
        onArchiveCompleted: async () => {},
        onDeleteTodo: async () => {},
        onAddTodo: async () => 'new-todo-id',
        runningTimers: new Set(),
        onRunningTimersChange: () => {},
        timerStartTimes: new Map(),
        finalizedElapsedTimes: new Map(),
        onOpenRightPanel: () => console.log('Open right panel'),
    },
};

export const ManyTodos: Story = {
    args: {
        todos: Array.from({ length: 10 }, (_, i) => ({
            id: `todo-${i}`,
            task: `Todo item ${i + 1}`,
            details:
                i % 2 === 0
                    ? null
                    : {
                          type: 'doc',
                          content: [
                              {
                                  type: 'paragraph',
                                  content: [
                                      {
                                          type: 'text',
                                          text: `Details for todo ${i + 1}`,
                                      },
                                  ],
                              },
                          ],
                      },
            status: i % 3 === 0 ? 'complete' : 'todo',
            userId: 'user1',
            dateCreated: new Date(),
            dateUpdated: new Date(),
            order: `a${i}`,
            importance: (i % 5) + 1,
            annoyingness: i % 5,
            committed: i % 3 === 0,
            elapsedTimeSeconds: 0,
            atomic: false,
            infinitelyDivisible: false,
        })),
        loading: false,
        onToggleTodo: async (id: string) => {
            console.log('Toggling todo:', id);
        },
        onUpdateTodo: async (id: string, updates) => {
            console.log('Updating todo:', id, updates);
        },
        onReorderTodos: async (oldIndex: number, newIndex: number) => {
            console.log('Reordering todos:', { oldIndex, newIndex });
        },
        onArchiveCompleted: async () => {
            console.log('Archiving completed todos');
        },
        onDeleteTodo: async (id: string) => {
            console.log('Deleting todo:', id);
        },
        onAddTodo: async (task: string, details) => {
            console.log('Adding todo:', { task, details });
            return 'new-todo-id';
        },
        runningTimers: new Set(),
        onRunningTimersChange: () => {},
        timerStartTimes: new Map(),
        finalizedElapsedTimes: new Map(),
        onOpenRightPanel: () => console.log('Open right panel'),
    },
};
