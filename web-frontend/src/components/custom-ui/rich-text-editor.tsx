import { useEditor, EditorContent } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import Placeholder from '@tiptap/extension-placeholder';
import { useEffect } from 'react';
import type { JSONContent } from '@tiptap/react';
import {
    Bold,
    Italic,
    List,
    ListOrdered,
    RemoveFormatting,
} from 'lucide-react';
import { Toggle } from '@/components/shadcn/toggle';
import { Button } from '@/components/shadcn/button';

interface RichTextEditorProps {
    content: JSONContent | null;
    onChange: (content: JSONContent) => void;
    onBlur?: () => void;
    onKeyDown?: (e: React.KeyboardEvent) => void;
    placeholder?: string;
    editable?: boolean;
    className?: string;
    showToolbar?: boolean;
    autoFocus?: boolean;
}

export function RichTextEditor({
    content,
    onChange,
    onBlur,
    onKeyDown,
    placeholder = 'Add details...',
    editable = true,
    className = '',
    showToolbar = true,
    autoFocus = false,
}: RichTextEditorProps) {
    const editor = useEditor({
        extensions: [
            StarterKit.configure({
                heading: {
                    levels: [1, 2, 3],
                },
            }),
            Placeholder.configure({
                placeholder,
            }),
        ],
        content: content || undefined,
        editable,
        autofocus: autoFocus ? 'end' : false,
        onUpdate: ({ editor }) => {
            onChange(editor.getJSON());
        },
        editorProps: {
            attributes: {
                class: 'prose prose-sm max-w-none focus:outline-none',
            },
            handleKeyDown: (_view, event) => {
                if (event.key === 'Escape' && onKeyDown) {
                    onKeyDown(event as unknown as React.KeyboardEvent);
                    return true;
                }
                return false;
            },
        },
    });

    // Update editor content when prop changes
    useEffect(() => {
        if (editor && content !== null) {
            const currentContent = editor.getJSON();
            // Only update if content actually changed to avoid cursor issues
            if (JSON.stringify(currentContent) !== JSON.stringify(content)) {
                editor.commands.setContent(content);
            }
        }
    }, [content, editor]);

    // Update editable state
    useEffect(() => {
        if (editor) {
            editor.setEditable(editable);
        }
    }, [editable, editor]);

    // Update focus state
    useEffect(() => {
        if (editor && autoFocus && !editor.isFocused) {
            editor.commands.focus('end');
        }
    }, [editor, autoFocus]);

    if (!editor) {
        return null;
    }

    return (
        <div className={className}>
            {showToolbar && editable && (
                <div className="border-b pb-2 mb-2 flex flex-wrap gap-1">
                    <Toggle
                        size="sm"
                        pressed={editor.isActive('bold')}
                        onPressedChange={() =>
                            editor.chain().focus().toggleBold().run()
                        }
                        aria-label="Toggle bold"
                    >
                        <Bold className="h-4 w-4" />
                    </Toggle>
                    <Toggle
                        size="sm"
                        pressed={editor.isActive('italic')}
                        onPressedChange={() =>
                            editor.chain().focus().toggleItalic().run()
                        }
                        aria-label="Toggle italic"
                    >
                        <Italic className="h-4 w-4" />
                    </Toggle>

                    <Toggle
                        size="sm"
                        pressed={editor.isActive('bulletList')}
                        onPressedChange={() =>
                            editor.chain().focus().toggleBulletList().run()
                        }
                        aria-label="Toggle bullet list"
                    >
                        <List className="h-4 w-4" />
                    </Toggle>
                    <Toggle
                        size="sm"
                        pressed={editor.isActive('orderedList')}
                        onPressedChange={() =>
                            editor.chain().focus().toggleOrderedList().run()
                        }
                        aria-label="Toggle ordered list"
                    >
                        <ListOrdered className="h-4 w-4" />
                    </Toggle>
                    <div className="w-px bg-gray-200 mx-1" />
                    <Toggle
                        size="sm"
                        onPressedChange={() =>
                            editor.chain().selectAll().unsetAllMarks().run()
                        }
                        aria-label="Clear formatting"
                    >
                        <RemoveFormatting className="h-4 w-4" />
                    </Toggle>
                </div>
            )}
            <EditorContent editor={editor} />
            {editable && onBlur && (
                <div className="mt-2 flex justify-end">
                    <Button size="sm" variant="outline" onClick={onBlur}>
                        Done
                    </Button>
                </div>
            )}
        </div>
    );
}

// Helper function to check if editor content is empty
export function isEditorEmpty(content: JSONContent | null): boolean {
    if (!content) return true;

    // Check if there's any text content
    const hasText = JSON.stringify(content).includes('"text"');
    return !hasText;
}

// Helper function to get plain text from editor content
export function getPlainTextFromContent(content: JSONContent | null): string {
    if (!content) return '';

    let text = '';

    const extractText = (node: JSONContent) => {
        if (node.text) {
            text += node.text;
        }
        if (node.content) {
            node.content.forEach(extractText);
        }
    };

    extractText(content);
    return text;
}
