import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/shadcn/button';
import { LogOut, MoreVertical, Loader2, Split } from 'lucide-react';
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
} from '@/components/shadcn/dropdown-menu';
import { toast } from 'sonner';

interface TopNavProps {
    generateBreakUpTodos: () => Promise<void>;
}

function TopNav({ generateBreakUpTodos }: TopNavProps) {
    const { currentUser, logout } = useAuth();
    const [isGenerating, setIsGenerating] = useState(false);

    const handleGenerateBreakUpTodos = async () => {
        setIsGenerating(true);
        try {
            await generateBreakUpTodos();
            toast.success('Break-up todos generated successfully');
        } catch (error) {
            console.error('Failed to generate break-up todos:', error);
            toast.error('Failed to generate break-up todos');
        } finally {
            setIsGenerating(false);
        }
    };

    return (
        <nav className="border-b bg-background sticky top-0 z-50">
            <div className="container mx-auto px-4 h-16 flex items-center justify-between">
                <div className="flex items-center gap-8">
                    <Link to="/" className="font-bold text-xl">
                        Fllstck Tmplt
                    </Link>
                    <div className="flex items-center gap-6">
                        <Link
                            to="/"
                            className="text-muted-foreground hover:text-foreground transition-colors"
                        >
                            Todos
                        </Link>
                        <Link
                            to="/habits"
                            className="text-muted-foreground hover:text-foreground transition-colors"
                        >
                            Habits
                        </Link>
                        <Link
                            to="/fun"
                            className="text-muted-foreground hover:text-foreground transition-colors"
                        >
                            Fun
                        </Link>
                    </div>
                </div>

                <div className="flex items-center gap-4">
                    <span className="text-sm text-muted-foreground">
                        {currentUser?.email}
                    </span>
                    <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="sm">
                                <MoreVertical className="h-4 w-4" />
                            </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                            <DropdownMenuItem
                                onClick={handleGenerateBreakUpTodos}
                                disabled={isGenerating}
                            >
                                {isGenerating ? (
                                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                                ) : (
                                    <Split className="h-4 w-4 mr-2" />
                                )}
                                Generate breakup todos
                            </DropdownMenuItem>
                            <DropdownMenuItem onClick={logout}>
                                <LogOut className="h-4 w-4 mr-2" />
                                Sign Out
                            </DropdownMenuItem>
                        </DropdownMenuContent>
                    </DropdownMenu>
                </div>
            </div>
        </nav>
    );
}

export default TopNav;
