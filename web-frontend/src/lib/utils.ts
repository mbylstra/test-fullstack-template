import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
    return twMerge(clsx(inputs));
}

/**
 * Formats a desirability value (0-1) as a percentage with 2 decimal places.
 * @param desirability - The desirability value between 0 and 1
 * @returns Formatted string like "66.45" or null if input is null/undefined
 */
export function formatDesirability(
    desirability: number | null | undefined
): string | null {
    if (desirability === null || desirability === undefined) {
        return null;
    }
    return (desirability * 100).toFixed(2);
}

/**
 * Formats elapsed time in seconds to human-readable format.
 * @param seconds - The elapsed time in seconds
 * @returns Formatted string like "3 hrs, 10 mins, 25 secs", or "no time recorded" if 0
 */
export function formatElapsedTime(seconds: number): string {
    if (seconds === 0) {
        return 'no time recorded';
    }

    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const remainingSeconds = seconds % 60;

    const parts: string[] = [];
    if (hours > 0) parts.push(`${hours} hrs`);
    if (minutes > 0) parts.push(`${minutes} mins`);
    if (remainingSeconds > 0) parts.push(`${remainingSeconds} secs`);

    return parts.join(', ');
}
