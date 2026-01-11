import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/shadcn/card';
import { Input } from '@/components/shadcn/input';
import { Textarea } from '@/components/shadcn/textarea';
import { Button } from '@/components/shadcn/button';
import { noteApiList, noteApiCreate, noteApiUpdate, noteApiDelete } from '@/lib/api';
import { Plus, Trash2 } from 'lucide-react';
import type { Note } from '@/lib/api-client';

export default function Notes() {
    const [notes, setNotes] = useState<Note[]>([]);
    const [loading, setLoading] = useState(true);
    const [newTitle, setNewTitle] = useState('');
    const [newContent, setNewContent] = useState('');

    useEffect(() => {
        loadNotes();
    }, []);

    const loadNotes = async () => {
        try {
            const { data } = await noteApiList();
            setNotes(data || []);
        } catch (error) {
            console.error('Failed to load notes:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleCreate = async () => {
        if (!newTitle.trim()) return;

        try {
            const { data } = await noteApiCreate({
                body: { title: newTitle, content: newContent }
            });
            if (data) {
                setNotes([...notes, data]);
                setNewTitle('');
                setNewContent('');
            }
        } catch (error) {
            console.error('Failed to create note:', error);
        }
    };

    const handleUpdate = async (id: string, title: string, content: string) => {
        try {
            const { data } = await noteApiUpdate({
                path: { id },
                body: { title, content }
            });
            if (data) {
                setNotes(notes.map(n => n.id === id ? data : n));
            }
        } catch (error) {
            console.error('Failed to update note:', error);
        }
    };

    const handleDelete = async (id: string) => {
        try {
            await noteApiDelete({ path: { id } });
            setNotes(notes.filter(n => n.id !== id));
        } catch (error) {
            console.error('Failed to delete note:', error);
        }
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center h-screen">
                <div className="text-gray-500">Loading...</div>
            </div>
        );
    }

    return (
        <div className="container mx-auto py-8 max-w-4xl">
            <h1 className="text-3xl font-bold mb-8">Notes</h1>

            {/* Create New Note */}
            <Card className="mb-6">
                <CardHeader>
                    <CardTitle>Create New Note</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                    <Input
                        placeholder="Title"
                        value={newTitle}
                        onChange={(e) => setNewTitle(e.target.value)}
                    />
                    <Textarea
                        placeholder="Content"
                        value={newContent}
                        onChange={(e) => setNewContent(e.target.value)}
                        rows={4}
                    />
                    <Button onClick={handleCreate}>
                        <Plus className="w-4 h-4 mr-2" />
                        Add Note
                    </Button>
                </CardContent>
            </Card>

            {/* Notes List */}
            <div className="space-y-4">
                {notes.length === 0 ? (
                    <div className="text-center text-gray-500 py-8">
                        No notes yet. Create one above!
                    </div>
                ) : (
                    notes.map((note) => (
                        <NoteCard
                            key={note.id}
                            note={note}
                            onUpdate={handleUpdate}
                            onDelete={handleDelete}
                        />
                    ))
                )}
            </div>
        </div>
    );
}

function NoteCard({
    note,
    onUpdate,
    onDelete
}: {
    note: Note;
    onUpdate: (id: string, title: string, content: string) => void;
    onDelete: (id: string) => void;
}) {
    const [isEditing, setIsEditing] = useState(false);
    const [title, setTitle] = useState(note.title);
    const [content, setContent] = useState(note.content);

    const handleSave = () => {
        onUpdate(note.id, title, content);
        setIsEditing(false);
    };

    const handleCancel = () => {
        setTitle(note.title);
        setContent(note.content);
        setIsEditing(false);
    };

    return (
        <Card>
            <CardHeader className="flex flex-row items-start justify-between space-y-0">
                <div className="flex-1">
                    {isEditing ? (
                        <Input
                            value={title}
                            onChange={(e) => setTitle(e.target.value)}
                            className="font-semibold"
                        />
                    ) : (
                        <CardTitle>{note.title}</CardTitle>
                    )}
                </div>
                <div className="flex gap-2">
                    {isEditing ? (
                        <>
                            <Button size="sm" onClick={handleSave}>Save</Button>
                            <Button size="sm" variant="outline" onClick={handleCancel}>Cancel</Button>
                        </>
                    ) : (
                        <>
                            <Button size="sm" variant="outline" onClick={() => setIsEditing(true)}>
                                Edit
                            </Button>
                            <Button
                                size="sm"
                                variant="destructive"
                                onClick={() => onDelete(note.id)}
                            >
                                <Trash2 className="w-4 h-4" />
                            </Button>
                        </>
                    )}
                </div>
            </CardHeader>
            <CardContent>
                {isEditing ? (
                    <Textarea
                        value={content}
                        onChange={(e) => setContent(e.target.value)}
                        rows={6}
                    />
                ) : (
                    <p className="whitespace-pre-wrap">{note.content}</p>
                )}
            </CardContent>
        </Card>
    );
}
