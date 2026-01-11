import { useState } from 'react';
import { Dices, X } from 'lucide-react';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from '@/components/shadcn/dialog';
import { Button } from '@/components/shadcn/button';
import { weightedRandomFunsList } from '@/lib/api-client';
import { toast } from 'sonner';
import type { Fun } from '@/lib/api-client';

interface RandomFunDialogProps {
    count?: number;
}

export default function RandomFunDialog({ count = 3 }: RandomFunDialogProps) {
    const [open, setOpen] = useState(false);
    const [loading, setLoading] = useState(false);
    const [funs, setFuns] = useState<Fun[]>([]);
    const [error, setError] = useState<string | null>(null);
    const [replacingIndex, setReplacingIndex] = useState<number | null>(null);
    const [excludeIds, setExcludeIds] = useState<string[]>([]);

    const handleOpenChange = async (newOpen: boolean) => {
        if (newOpen) {
            setExcludeIds([]);
            await fetchRandomFuns();
        } else {
            setFuns([]);
            setError(null);
            setExcludeIds([]);
            setReplacingIndex(null);
        }
        setOpen(newOpen);
    };

    const fetchRandomFuns = async () => {
        setLoading(true);
        setError(null);
        try {
            const response = await weightedRandomFunsList({
                query: { n: count, excludeIds: excludeIds },
            });
            if (response.data) {
                setFuns(response.data);
                // Add shown IDs to exclude list
                const newIds = response.data.map((fun) => fun.id);
                setExcludeIds((prev) => [...prev, ...newIds]);
            } else {
                const errorMsg = 'Failed to fetch random funs';
                setError(errorMsg);
                toast.error(errorMsg);
            }
        } catch (error) {
            const errorMsg = 'Failed to fetch random funs';
            setError(errorMsg);
            toast.error(errorMsg);
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    const handleCantDo = async (index: number) => {
        setReplacingIndex(index);
        try {
            // Fetch one new fun, excluding all shown IDs
            const response = await weightedRandomFunsList({
                query: { n: 1, excludeIds: excludeIds },
            });

            if (response.data && response.data.length > 0) {
                const newFun = response.data[0];

                // Replace the fun at the given index
                setFuns((prevFuns) => {
                    const updatedFuns = [...prevFuns];
                    updatedFuns[index] = newFun;
                    return updatedFuns;
                });

                // Add the new fun ID to exclude list
                setExcludeIds((prev) => [...prev, newFun.id]);
            } else {
                // No more options available - remove this item from the list
                setFuns((prevFuns) => {
                    const updatedFuns = prevFuns.filter((_, i) => i !== index);
                    if (updatedFuns.length === 0) {
                        toast.info('No more fun things available!');
                    }
                    return updatedFuns;
                });
            }
        } catch (error) {
            toast.error('Failed to fetch new fun thing');
            console.error(error);
        } finally {
            setReplacingIndex(null);
        }
    };

    return (
        <Dialog open={open} onOpenChange={handleOpenChange}>
            <DialogTrigger asChild>
                <Button variant="outline" size="sm">
                    <Dices className="h-4 w-4 mr-2" />
                    Random Fun Thing
                </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[425px]">
                <DialogHeader>
                    <DialogTitle>Random Fun Things</DialogTitle>
                    <DialogDescription>
                        Pick a fun thing to do!
                    </DialogDescription>
                </DialogHeader>
                {loading ? (
                    <div className="flex items-center justify-center py-8">
                        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
                    </div>
                ) : error ? (
                    <div className="flex flex-col items-center justify-center py-8">
                        <p className="text-sm text-destructive font-medium">
                            {error}
                        </p>
                        <button
                            onClick={fetchRandomFuns}
                            className="mt-4 text-sm text-primary hover:underline"
                        >
                            Try again
                        </button>
                    </div>
                ) : funs.length > 0 ? (
                    <div className="space-y-3">
                        {funs.map((fun, index) => (
                            <div
                                key={fun.id}
                                className="flex gap-2 items-start"
                            >
                                <div className="flex-1 p-3 border rounded-lg bg-card hover:bg-accent hover:border-primary transition-colors">
                                    <h3 className="font-medium text-sm">
                                        {fun.title}
                                    </h3>
                                </div>
                                <Button
                                    variant="outline"
                                    size="sm"
                                    onClick={() => handleCantDo(index)}
                                    disabled={replacingIndex === index}
                                    className="shrink-0"
                                >
                                    {replacingIndex === index ? (
                                        <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-primary"></div>
                                    ) : (
                                        <>
                                            <X className="h-4 w-4 mr-1" />
                                            Can't do
                                        </>
                                    )}
                                </Button>
                            </div>
                        ))}
                    </div>
                ) : (
                    <p className="text-sm text-muted-foreground text-center py-8">
                        No more options available
                    </p>
                )}
            </DialogContent>
        </Dialog>
    );
}
