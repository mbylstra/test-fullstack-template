import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { AuthProvider, useAuth } from '@/contexts/AuthContext';
import { Toaster } from '@/components/shadcn/sonner';
import { TooltipProvider } from '@/components/shadcn/tooltip';
import TopNav from '@/components/TopNav';
import Todos from '@/pages/Todos';
import Habits from '@/pages/Habits';
import Fun from '@/pages/Fun';
import Login from '@/pages/Login';
import { useBackendHealth } from '@/hooks/useBackendHealth';
import { useTodos } from '@/hooks/useTodos';
import { useHabits } from '@/hooks/useHabits';

function AppContent() {
    const { currentUser, loading } = useAuth();
    const { isHealthy, isChecking, error } = useBackendHealth();
    const todosHook = useTodos();
    const habitsHook = useHabits();

    // Check backend health first
    if (isChecking) {
        return (
            <div className="min-h-screen bg-background flex items-center justify-center">
                <div className="text-center">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto mb-4"></div>
                    <p className="text-muted-foreground">
                        Connecting to backend...
                    </p>
                </div>
            </div>
        );
    }

    // Show error if backend is not healthy
    if (!isHealthy) {
        return (
            <div className="min-h-screen bg-background flex items-center justify-center">
                <div className="text-center max-w-md px-4">
                    <div className="mb-6">
                        <svg
                            className="mx-auto h-12 w-12 text-destructive"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                        >
                            <path
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                strokeWidth={2}
                                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                            />
                        </svg>
                    </div>
                    <h1 className="text-2xl font-bold mb-2">
                        Backend Unavailable
                    </h1>
                    <p className="text-muted-foreground mb-4">
                        Unable to connect to the backend server.
                    </p>
                    {error && (
                        <p className="text-sm text-muted-foreground mb-6 font-mono bg-muted p-3 rounded">
                            {error}
                        </p>
                    )}
                    <button
                        onClick={() => window.location.reload()}
                        className="px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90"
                    >
                        Retry
                    </button>
                </div>
            </div>
        );
    }

    // Check auth loading
    if (loading) {
        return (
            <div className="min-h-screen bg-background flex items-center justify-center">
                <div className="text-center">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto mb-4"></div>
                    <p className="text-muted-foreground">Loading...</p>
                </div>
            </div>
        );
    }

    if (!currentUser) {
        return <Login />;
    }

    return (
        <BrowserRouter>
            <div className="h-screen flex flex-col overflow-hidden">
                <TopNav generateBreakUpTodos={todosHook.generateBreakUpTodos} />
                <div className="flex-1 overflow-hidden">
                    <Routes>
                        <Route
                            path="/"
                            element={
                                <Todos
                                    todosHook={todosHook}
                                    habitsHook={habitsHook}
                                />
                            }
                        />
                        <Route path="/habits" element={<Habits />} />
                        <Route path="/fun" element={<Fun />} />
                    </Routes>
                </div>
            </div>
        </BrowserRouter>
    );
}

function App() {
    return (
        <TooltipProvider>
            <AuthProvider>
                <AppContent />
                <Toaster />
            </AuthProvider>
        </TooltipProvider>
    );
}

export default App;
