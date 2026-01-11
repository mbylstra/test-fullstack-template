import { useState } from 'react';
import { Plus } from 'lucide-react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import type { JSONContent } from '@tiptap/react';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from '@/components/shadcn/dialog';
import {
    Form,
    FormControl,
    FormField,
    FormItem,
    FormLabel,
    FormMessage,
} from '@/components/shadcn/form';
import { Input } from '@/components/shadcn/input';
import { Button } from '@/components/shadcn/button';
import { toast } from 'sonner';
import { RichTextEditor } from '@/components/custom-ui/rich-text-editor';

const todoFormSchema = z.object({
    task: z.string().min(1, 'Task is required'),
    details: z.custom<JSONContent | null>(),
});

type TodoFormValues = z.infer<typeof todoFormSchema>;

interface AddTodoDialogProps {
    onAddTodo: (task: string, details: JSONContent | null) => Promise<void>;
}

export default function AddTodoDialog({ onAddTodo }: AddTodoDialogProps) {
    const [open, setOpen] = useState(false);
    const form = useForm<TodoFormValues>({
        resolver: zodResolver(todoFormSchema),
        defaultValues: {
            task: '',
            details: null,
        },
    });

    const onSubmit = async (data: TodoFormValues) => {
        try {
            await onAddTodo(data.task, data.details);
            form.reset();
            setOpen(false);
            toast.success('Todo added successfully!');
        } catch (error) {
            console.error('Error adding todo:', error);
            toast.error('Failed to add todo');
        }
    };

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <Button>
                    <Plus className="h-4 w-4 mr-2" />
                    Add Todo
                </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[425px]">
                <DialogHeader>
                    <DialogTitle>Add New Todo</DialogTitle>
                    <DialogDescription>
                        Create a new todo item. Fill in the task and optional
                        details.
                    </DialogDescription>
                </DialogHeader>
                <Form {...form}>
                    <form
                        onSubmit={form.handleSubmit(onSubmit)}
                        className="space-y-4"
                    >
                        <FormField
                            control={form.control}
                            name="task"
                            render={({ field }) => (
                                <FormItem>
                                    <FormLabel>Task</FormLabel>
                                    <FormControl>
                                        <Input
                                            placeholder="Enter task name"
                                            {...field}
                                        />
                                    </FormControl>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />
                        <FormField
                            control={form.control}
                            name="details"
                            render={({ field }) => (
                                <FormItem>
                                    <FormLabel>Details (optional)</FormLabel>
                                    <FormControl>
                                        <RichTextEditor
                                            content={field.value}
                                            onChange={field.onChange}
                                            placeholder="Add details..."
                                            className="border rounded-md p-2 min-h-[120px] bg-background"
                                        />
                                    </FormControl>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />
                        <div className="flex justify-end gap-3">
                            <Button
                                type="button"
                                variant="outline"
                                onClick={() => setOpen(false)}
                            >
                                Cancel
                            </Button>
                            <Button type="submit">Add Todo</Button>
                        </div>
                    </form>
                </Form>
            </DialogContent>
        </Dialog>
    );
}
