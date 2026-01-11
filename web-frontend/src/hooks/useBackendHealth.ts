import { useState, useEffect } from 'react';

interface HealthStatus {
    isHealthy: boolean;
    isChecking: boolean;
    error: string | null;
}

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

export function useBackendHealth() {
    const [status, setStatus] = useState<HealthStatus>({
        isHealthy: false,
        isChecking: true,
        error: null,
    });

    useEffect(() => {
        const checkHealth = async () => {
            try {
                const response = await fetch(`${API_URL}/health`, {
                    method: 'GET',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                });

                if (response.ok) {
                    const data = await response.json();
                    if (data.status === 'ok') {
                        setStatus({
                            isHealthy: true,
                            isChecking: false,
                            error: null,
                        });
                    } else {
                        setStatus({
                            isHealthy: false,
                            isChecking: false,
                            error: 'Backend returned unexpected status',
                        });
                    }
                } else {
                    setStatus({
                        isHealthy: false,
                        isChecking: false,
                        error: `Backend returned status ${response.status}`,
                    });
                }
            } catch (error) {
                setStatus({
                    isHealthy: false,
                    isChecking: false,
                    error:
                        error instanceof Error
                            ? error.message
                            : 'Failed to connect to backend',
                });
            }
        };

        checkHealth();
    }, []);

    return status;
}
