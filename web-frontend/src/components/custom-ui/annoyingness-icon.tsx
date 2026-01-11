import React from 'react';
import { Meh, Annoyed, Frown, Angry, HeartCrack } from 'lucide-react';

interface AnnoyingnessIconProps {
    annoyingness: number;
    className?: string;
}

const colorMap: Record<number, string> = {
    0: 'text-gray-400',
    1: 'text-black',
    2: 'text-yellow-700',
    3: 'text-orange-700',
    4: 'text-red-600',
};

export const AnnoyingnessIcon: React.FC<AnnoyingnessIconProps> = ({
    annoyingness,
    className = '',
}) => {
    const color = colorMap[annoyingness];
    if (!color) {
        throw new Error(
            `Invalid annoyingness value: ${annoyingness}. Expected value between 0 and 4.`
        );
    }

    const combinedClassName = `${color} ${className} `.trim();

    switch (annoyingness) {
        case 0:
            return <Meh className={combinedClassName} />;
        case 1:
            return <Annoyed className={combinedClassName} />;
        case 2:
            return <Frown className={combinedClassName} />;
        case 3:
            return <Angry className={combinedClassName} />;
        case 4:
            return <HeartCrack className={combinedClassName} />;
    }
};
