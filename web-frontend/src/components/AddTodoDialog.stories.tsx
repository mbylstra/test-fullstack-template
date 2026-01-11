import type { Meta, StoryObj } from '@storybook/react-vite';
import AddTodoDialog from './AddTodoDialog';
import { Toaster } from 'sonner';

const meta = {
    title: 'Components/AddTodoDialog',
    component: AddTodoDialog,
    parameters: {
        layout: 'centered',
    },
    tags: ['autodocs'],
    decorators: [
        (Story) => (
            <>
                <Story />
                <Toaster />
            </>
        ),
    ],
} satisfies Meta<typeof AddTodoDialog>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
    args: {
        onAddTodo: async (task: string, details) => {
            console.log('Adding todo:', { task, details });
            // Simulate API call
            await new Promise((resolve) => setTimeout(resolve, 500));
        },
    },
};

export const WithLongTaskName: Story = {
    args: {
        onAddTodo: async (task: string, details) => {
            console.log('Adding todo:', { task, details });
            await new Promise((resolve) => setTimeout(resolve, 500));
        },
    },
    play: async ({ canvasElement }) => {
        // Open dialog and show it with a long task name
        const button = canvasElement.querySelector('button');
        button?.click();
    },
};

export const HandleSuccess: Story = {
    args: {
        onAddTodo: async (task: string, details) => {
            console.log('Todo added successfully:', { task, details });
            await new Promise((resolve) => setTimeout(resolve, 300));
        },
    },
};

export const HandleError: Story = {
    args: {
        onAddTodo: async () => {
            await new Promise((resolve) => setTimeout(resolve, 300));
            throw new Error('Failed to add todo - simulated error');
        },
    },
};
