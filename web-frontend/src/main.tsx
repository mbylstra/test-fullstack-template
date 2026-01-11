import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import './index.css';
import App from './App.tsx';
import { ENABLE_REACT_STRICT_MODE } from './constants';

const root = createRoot(document.getElementById('root')!);

if (ENABLE_REACT_STRICT_MODE) {
    root.render(
        <StrictMode>
            <App />
        </StrictMode>
    );
} else {
    root.render(<App />);
}
