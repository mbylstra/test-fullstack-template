import type { Meta, StoryObj } from '@storybook/react-vite';
import { SortableTodoItem } from './SortableTodoItem';
import type { SortableTodoItemProps } from './SortableTodoItem';
import { DndContext, closestCenter } from '@dnd-kit/core';
import {
    SortableContext,
    verticalListSortingStrategy,
} from '@dnd-kit/sortable';
import type { ReactNode } from 'react';

const meta = {
    title: 'Components/SortableTodoItem',
    component: SortableTodoItem,
    decorators: [
        (Story: () => ReactNode) => (
            <DndContext collisionDetection={closestCenter}>
                <SortableContext
                    items={['todo-1']}
                    strategy={verticalListSortingStrategy}
                >
                    <Story />
                </SortableContext>
            </DndContext>
        ),
    ],
} satisfies Meta<typeof SortableTodoItem>;

export default meta;
type Story = StoryObj<typeof meta>;

const defaultProps: SortableTodoItemProps = {
    todo: {
        id: 'todo-1',
        task: 'Buy groceries',
        details: null,
        status: 'todo',
        dateCreated: new Date(),
        dateUpdated: new Date(),
        userId: 'user-1',
        order: '1',
        importance: 1,
        annoyingness: 0,
        committed: false,
        elapsedTimeSeconds: 0,
        atomic: false,
        infinitelyDivisible: false,
    },
    isEditing: false,
    editValue: '',
    isEditingDetails: false,
    detailsValue: null,
    onToggle: () => console.log('Toggle'),
    onStartEdit: () => console.log('Start edit'),
    onEditChange: (value) => console.log('Edit change:', value),
    onFinishEdit: () => console.log('Finish edit'),
    onKeyDown: (e) => console.log('Key down:', e.key),
    onStartEditDetails: () => console.log('Start edit details'),
    onDetailsChange: () => console.log('Details change'),
    onFinishEditDetails: () => console.log('Finish edit details'),
    onIncreaseImportance: () => console.log('Increase importance'),
    onDecreaseImportance: () => console.log('Decrease importance'),
    onChangeStatus: (status) => console.log('Change status:', status),
    onSetTimeEstimate: (estimate) =>
        console.log('Set time estimate:', estimate),
    onSetAnnoyingness: (annoyingness) =>
        console.log('Set annoyingness:', annoyingness),
    onCommit: () => console.log('Commit'),
    inputRef: { current: null },
    isHovering: false,
    onHoveringChange: (isHovering) =>
        console.log('Hovering change:', isHovering),
    onMenuOpenChange: (menuKey, open) =>
        console.log('Menu open change:', menuKey, open),
    isTimerRunning: false,
    onToggleTimer: () => console.log('Toggle timer'),
    onOpenRightPanel: () => console.log('Open right panel'),
};

export const Default: Story = {
    args: defaultProps,
};

export const Hovering: Story = {
    args: {
        ...defaultProps,
        isHovering: true,
    },
};

export const Editing: Story = {
    args: {
        ...defaultProps,
        isEditing: true,
        editValue: 'Buy groceries',
    },
};

export const Complete: Story = {
    args: {
        ...defaultProps,
        todo: {
            ...defaultProps.todo,
            status: 'complete',
        },
    },
};

export const HighImportance: Story = {
    args: {
        ...defaultProps,
        todo: {
            ...defaultProps.todo,
            importance: 5,
            task: 'Critical task - super important',
        },
    },
};

export const VeryImportant: Story = {
    args: {
        ...defaultProps,
        todo: {
            ...defaultProps.todo,
            importance: 4,
            task: 'Very important task',
        },
    },
};

export const Important: Story = {
    args: {
        ...defaultProps,
        todo: {
            ...defaultProps.todo,
            importance: 3,
            task: 'Important task',
        },
    },
};

export const Necessary: Story = {
    args: {
        ...defaultProps,
        todo: {
            ...defaultProps.todo,
            importance: 2,
            task: 'Necessary task',
        },
    },
};

export const WithTimeEstimate: Story = {
    args: {
        ...defaultProps,
        todo: {
            ...defaultProps.todo,
            timeEstimate: '1-hour' as const,
            task: 'Task that takes about 1 hour',
        },
    },
};

export const Waiting: Story = {
    args: {
        ...defaultProps,
        todo: {
            ...defaultProps.todo,
            status: 'waiting',
            task: 'Waiting for response',
        },
    },
};

export const WithDetails: Story = {
    args: {
        ...defaultProps,
        todo: {
            ...defaultProps.todo,
            task: 'Task with details',
            details: {
                type: 'doc',
                content: [
                    {
                        type: 'paragraph',
                        content: [
                            {
                                type: 'text',
                                text: 'This is a task with some detailed information about what needs to be done.',
                            },
                        ],
                    },
                ],
            },
        },
    },
};

export const EditingDetails: Story = {
    args: {
        ...defaultProps,
        isEditingDetails: true,
        detailsValue: {
            type: 'doc',
            content: [
                {
                    type: 'paragraph',
                    content: [
                        {
                            type: 'text',
                            text: 'Editing details...',
                        },
                    ],
                },
            ],
        },
    },
};

export const HighAnnoyingness: Story = {
    args: {
        ...defaultProps,
        todo: {
            ...defaultProps.todo,
            annoyingness: 4,
            task: 'Very annoying task',
        },
    },
};
