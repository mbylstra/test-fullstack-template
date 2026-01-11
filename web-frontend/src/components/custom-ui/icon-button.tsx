import { Button } from '@/components/shadcn/button';
import {
    Tooltip,
    TooltipContent,
    TooltipTrigger,
} from '@/components/shadcn/tooltip';
import { TOOLTIP_DELAY_MS } from '@/constants';
import {
    Trash2,
    NotebookText,
    Plus,
    Minus,
    MoreVertical,
    LogOut,
    Edit,
    Copy,
    ChevronRight,
    Mail,
    Loader2,
    Check,
    ChevronDown,
    ChevronUp,
    Search,
    PanelLeft,
    PanelRight,
    GripVertical,
    X,
    AlertCircle,
    CheckCircle2,
    XCircle,
    Clock,
    Watch,
    Hourglass,
    BicepsFlexed,
} from 'lucide-react';

type IconName =
    | 'trash2'
    | 'notebookText'
    | 'plus'
    | 'minus'
    | 'moreVertical'
    | 'logOut'
    | 'edit'
    | 'copy'
    | 'chevronRight'
    | 'mail'
    | 'loader2'
    | 'check'
    | 'chevronDown'
    | 'chevronUp'
    | 'search'
    | 'panelLeft'
    | 'panelRight'
    | 'gripVertical'
    | 'x'
    | 'alertCircle'
    | 'checkCircle2'
    | 'xCircle'
    | 'watch'
    | 'clock'
    | 'hourglass'
    | 'bicepsFlexed';

const iconMap: Record<IconName, React.ComponentType<{ className?: string }>> = {
    trash2: Trash2,
    notebookText: NotebookText,
    plus: Plus,
    minus: Minus,
    moreVertical: MoreVertical,
    logOut: LogOut,
    edit: Edit,
    copy: Copy,
    chevronRight: ChevronRight,
    mail: Mail,
    loader2: Loader2,
    check: Check,
    chevronDown: ChevronDown,
    chevronUp: ChevronUp,
    search: Search,
    panelLeft: PanelLeft,
    panelRight: PanelRight,
    gripVertical: GripVertical,
    x: X,
    alertCircle: AlertCircle,
    checkCircle2: CheckCircle2,
    xCircle: XCircle,
    clock: Clock,
    watch: Watch,
    hourglass: Hourglass,
    bicepsFlexed: BicepsFlexed,
};

interface IconButtonProps {
    icon: IconName;
    ariaLabel: string;
    onClick: () => void;
    disabled?: boolean;
    className?: string;
    tooltip?: string;
}

/**
 * IconButton component for displaying icon buttons that appear on hover
 * Used primarily in list items for actions like delete, edit, etc.
 */
export function IconButton({
    icon,
    ariaLabel,
    onClick,
    disabled = false,
    className = '',
    tooltip,
}: IconButtonProps) {
    const Icon = iconMap[icon];
    const defaultClasses =
        'h-6 w-6 shrink-0 rounded-full bg-gray-200 hover:bg-gray-300 disabled:opacity-50 disabled:cursor-not-allowed';

    const button = (
        <Button
            variant="ghost"
            size="icon"
            className={`${defaultClasses} ${className}`}
            aria-label={ariaLabel}
            onClick={onClick}
            disabled={disabled}
        >
            <Icon className="h-2 w-2" />
        </Button>
    );

    if (tooltip) {
        return (
            <Tooltip delayDuration={TOOLTIP_DELAY_MS}>
                <TooltipTrigger asChild>{button}</TooltipTrigger>
                <TooltipContent>{tooltip}</TooltipContent>
            </Tooltip>
        );
    }

    return button;
}
