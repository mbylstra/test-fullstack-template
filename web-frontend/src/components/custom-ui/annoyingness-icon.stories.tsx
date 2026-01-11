import type { Meta, StoryObj } from '@storybook/react-vite';
import { AnnoyingnessIcon } from './annoyingness-icon';

const meta = {
    title: 'Custom UI/AnnoyingnessIcon',
    component: AnnoyingnessIcon,
    parameters: {
        layout: 'centered',
    },
    tags: ['autodocs'],
    argTypes: {
        annoyingness: {
            control: {
                type: 'select',
            },
            options: [0, 1, 2, 3, 4],
        },
        className: {
            control: 'text',
        },
    },
} satisfies Meta<typeof AnnoyingnessIcon>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Meh: Story = {
    args: {
        annoyingness: 0,
    },
};

export const Annoyed: Story = {
    args: {
        annoyingness: 1,
    },
};

export const Sad: Story = {
    args: {
        annoyingness: 2,
    },
};

export const Angry: Story = {
    args: {
        annoyingness: 3,
    },
};

export const HeartBroken: Story = {
    args: {
        annoyingness: 4,
    },
};

export const WithCustomSize: Story = {
    args: {
        annoyingness: 3,
        className: 'w-16 h-16',
    },
};

export const AllLevels: Story = {
    args: {
        annoyingness: 0,
    },
    render: () => (
        <div className="flex flex-col gap-8">
            <div className="flex gap-8 items-center">
                <div className="flex flex-col items-center gap-2">
                    <AnnoyingnessIcon annoyingness={0} className="w-8 h-8" />
                    <span className="text-sm">Meh (0)</span>
                </div>
                <div className="flex flex-col items-center gap-2">
                    <AnnoyingnessIcon annoyingness={1} className="w-8 h-8" />
                    <span className="text-sm">Annoyed (1)</span>
                </div>
                <div className="flex flex-col items-center gap-2">
                    <AnnoyingnessIcon annoyingness={2} className="w-8 h-8" />
                    <span className="text-sm">Sad (2)</span>
                </div>
                <div className="flex flex-col items-center gap-2">
                    <AnnoyingnessIcon annoyingness={3} className="w-8 h-8" />
                    <span className="text-sm">Angry (3)</span>
                </div>
                <div className="flex flex-col items-center gap-2">
                    <AnnoyingnessIcon annoyingness={4} className="w-8 h-8" />
                    <span className="text-sm">HeartBroken (4)</span>
                </div>
            </div>
        </div>
    ),
};
