import { createContext, useContext, useEffect, useState, useRef } from 'react';
import type { ReactNode } from 'react';
import { jwtDecode } from 'jwt-decode';
import {
    authApiLogin,
    authApiRegister,
    authApiGetCurrentUser,
    authTokenManager,
    authApiLogout,
    authApiRefreshToken,
} from '@/lib/api';
import type { User } from '@/lib/api-client';

interface AuthContextType {
    currentUser: User | null;
    loading: boolean;
    signIn: (email: string, password: string) => Promise<void>;
    signUp: (email: string, password: string) => Promise<void>;
    logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function useAuth() {
    const context = useContext(AuthContext);
    if (context === undefined) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
}

interface AuthProviderProps {
    children: ReactNode;
}

export function AuthProvider({ children }: AuthProviderProps) {
    const [currentUser, setCurrentUser] = useState<User | null>(null);
    const [loading, setLoading] = useState(true);
    const refreshTimerRef = useRef<number | null>(null);

    // Set up token refresh timer
    const setupRefreshTimer = (token: string) => {
        // Clear existing timer
        if (refreshTimerRef.current) {
            clearTimeout(refreshTimerRef.current);
        }

        try {
            const decoded = jwtDecode<{ exp: number }>(token);
            const expirationTime = decoded.exp * 1000; // Convert to milliseconds
            const now = Date.now();
            const timeUntilExpiration = expirationTime - now;

            // Refresh 2 minutes before expiration (120000 ms)
            const refreshTime = Math.max(0, timeUntilExpiration - 120000);

            if (refreshTime > 0) {
                refreshTimerRef.current = window.setTimeout(async () => {
                    try {
                        const response = await authApiRefreshToken();
                        if (response.data?.access_token) {
                            authTokenManager.setToken(
                                response.data.access_token
                            );
                            // Set up timer for the new token
                            setupRefreshTimer(response.data.access_token);
                        } else {
                            // Refresh failed, logout user
                            handleLogout();
                        }
                    } catch (error) {
                        console.error('Token refresh failed:', error);
                        handleLogout();
                    }
                }, refreshTime);
            }
        } catch (error) {
            console.error('Failed to set up refresh timer:', error);
        }
    };

    const handleLogout = () => {
        authTokenManager.clearToken();
        setCurrentUser(null);
    };

    useEffect(() => {
        // Check for backend auth token on mount
        const initAuth = async () => {
            const token = authTokenManager.getToken();
            if (token) {
                try {
                    const { data: user } = await authApiGetCurrentUser();
                    if (user) {
                        setCurrentUser(user);
                        // Set up refresh timer for the token
                        setupRefreshTimer(token);
                    }
                } catch (error) {
                    // Token might be invalid, clear it
                    authTokenManager.clearToken();
                }
            }
            setLoading(false);
        };

        initAuth();

        // Cleanup timer on unmount
        return () => {
            if (refreshTimerRef.current) {
                clearTimeout(refreshTimerRef.current);
            }
        };
    }, []);

    const signIn = async (email: string, password: string) => {
        const response = await authApiLogin({
            body: { email, password },
        });

        if (response.error) {
            // Extract error message from API response
            if (
                response.error &&
                typeof response.error === 'object' &&
                'detail' in response.error
            ) {
                throw new Error(response.error.detail as string);
            } else if (
                response.error &&
                typeof response.error === 'object' &&
                'message' in response.error
            ) {
                throw new Error(response.error.message as string);
            } else {
                throw new Error('Failed to sign in');
            }
        }

        if (response.data) {
            authTokenManager.setToken(response.data.access_token);
            const { data: user } = await authApiGetCurrentUser();
            if (user) {
                setCurrentUser(user);
                // Set up refresh timer for the new token
                setupRefreshTimer(response.data.access_token);
            }
        }
    };

    const signUp = async (email: string, password: string) => {
        const response = await authApiRegister({
            body: { email, password },
        });

        if (response.error) {
            // Extract error message from API response
            if (
                response.error &&
                typeof response.error === 'object' &&
                'detail' in response.error
            ) {
                throw new Error(response.error.detail as string);
            } else if (
                response.error &&
                typeof response.error === 'object' &&
                'message' in response.error
            ) {
                throw new Error(response.error.message as string);
            } else {
                throw new Error('Failed to sign up');
            }
        }

        if (response.data) {
            // After registration, automatically log in
            await signIn(email, password);
        }
    };

    const logout = async () => {
        try {
            // Call logout endpoint to clear refresh token cookie
            await authApiLogout();
        } catch (error) {
            console.error('Logout endpoint call failed:', error);
            // Continue with client-side logout even if server call fails
        }

        // Clear client-side state
        if (refreshTimerRef.current) {
            clearTimeout(refreshTimerRef.current);
        }
        authTokenManager.clearToken();
        setCurrentUser(null);
    };

    const value: AuthContextType = {
        currentUser,
        loading,
        signIn,
        signUp,
        logout,
    };

    return (
        <AuthContext.Provider value={value}>
            {!loading && children}
        </AuthContext.Provider>
    );
}
