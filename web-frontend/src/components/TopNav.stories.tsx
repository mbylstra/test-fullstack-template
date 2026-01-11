import type { Meta, StoryObj } from '@storybook/react-vite';
import TopNav from './TopNav';
import { BrowserRouter } from 'react-router-dom';
import { AuthProvider } from '@/contexts/AuthContext';

const mockGenerateBreakUpTodos = async () => {
    console.log('Generate break-up todos called');
};

const meta = {
    title: 'Components/TopNav',
    component: TopNav,
    parameters: {
        layout: 'fullscreen',
    },
    tags: ['autodocs'],
    args: {
        generateBreakUpTodos: mockGenerateBreakUpTodos,
    },
    decorators: [
        (Story) => (
            <BrowserRouter>
                <AuthProvider>
                    <Story />
                </AuthProvider>
            </BrowserRouter>
        ),
    ],
} satisfies Meta<typeof TopNav>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export const WithEmail: Story = {
    parameters: {
        // This would show the TopNav with a user logged in
        // The actual user email comes from the AuthContext
    },
};

export const InPage: Story = {
    decorators: [
        (Story) => (
            <div className="min-h-screen bg-background">
                <Story />
                <main className="container mx-auto px-4 py-8">
                    <h1 className="text-3xl font-bold mb-4">Page Content</h1>
                    <p className="text-muted-foreground">
                        The TopNav component is sticky at the top of the page.
                    </p>
                </main>
            </div>
        ),
    ],
};
