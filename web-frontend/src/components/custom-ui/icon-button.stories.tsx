import type { Meta, StoryObj } from '@storybook/react-vite';
import { IconButton } from './icon-button';

const meta = {
    title: 'Custom UI/IconButton',
    component: IconButton,
    parameters: {
        layout: 'centered',
    },
    tags: ['autodocs'],
    argTypes: {
        icon: {
            control: 'select',
            options: [
                'trash2',
                'notebookText',
                'plus',
                'minus',
                'moreVertical',
                'logOut',
                'edit',
                'copy',
                'chevronRight',
            ],
        },
        disabled: {
            control: 'boolean',
        },
        onClick: {
            action: 'clicked',
        },
    },
} satisfies Meta<typeof IconButton>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
    args: {
        icon: 'edit',
        ariaLabel: 'Edit',
        onClick: () => console.log('Edit clicked'),
    },
};

export const Delete: Story = {
    args: {
        icon: 'trash2',
        ariaLabel: 'Delete',
        onClick: () => console.log('Delete clicked'),
    },
};

export const AddDetails: Story = {
    args: {
        icon: 'notebookText',
        ariaLabel: 'Add details',
        onClick: () => console.log('Add details clicked'),
    },
};

export const IncreaseImportance: Story = {
    args: {
        icon: 'plus',
        ariaLabel: 'Increase importance',
        onClick: () => console.log('Increase importance clicked'),
    },
};

export const DecreaseImportance: Story = {
    args: {
        icon: 'minus',
        ariaLabel: 'Decrease importance',
        onClick: () => console.log('Decrease importance clicked'),
        disabled: false,
    },
};

export const Disabled: Story = {
    args: {
        icon: 'minus',
        ariaLabel: 'Decrease importance (disabled)',
        onClick: () => console.log('Clicked'),
        disabled: true,
    },
};

export const AlwaysVisible: Story = {
    args: {
        icon: 'copy',
        ariaLabel: 'Copy',
        onClick: () => console.log('Copy clicked'),
    },
};

export const AllVariants: Story = {
    args: {
        icon: 'edit',
        ariaLabel: 'Edit',
        onClick: () => console.log('Edit clicked'),
    },
    render: () => (
        <div className="flex flex-col gap-8">
            <div className="flex gap-2">
                <IconButton
                    icon="edit"
                    ariaLabel="Edit"
                    onClick={() => console.log('Edit')}
                />
                <IconButton
                    icon="trash2"
                    ariaLabel="Delete"
                    onClick={() => console.log('Delete')}
                />
                <IconButton
                    icon="notebookText"
                    ariaLabel="Add details"
                    onClick={() => console.log('Add details')}
                />
                <IconButton
                    icon="plus"
                    ariaLabel="Increase importance"
                    onClick={() => console.log('Increase')}
                />
                <IconButton
                    icon="minus"
                    ariaLabel="Decrease importance"
                    onClick={() => console.log('Decrease')}
                />
            </div>
            <div className="border-t pt-4">
                <h3 className="text-sm font-semibold mb-2">
                    Hover to see opacity transition
                </h3>
                <div className="flex gap-2 p-2 bg-muted/30 rounded-sm hover:bg-muted/50 transition-colors group">
                    <span className="text-sm">Todo item (hover me)</span>
                    <div className="flex items-center gap-1 ml-auto opacity-0 group-hover:opacity-100 transition-opacity">
                        <IconButton
                            icon="notebookText"
                            ariaLabel="Add details"
                            onClick={() => console.log('Add details')}
                        />
                        <IconButton
                            icon="minus"
                            ariaLabel="Decrease"
                            onClick={() => console.log('Decrease')}
                        />
                        <IconButton
                            icon="plus"
                            ariaLabel="Increase"
                            onClick={() => console.log('Increase')}
                        />
                    </div>
                </div>
            </div>
        </div>
    ),
};
