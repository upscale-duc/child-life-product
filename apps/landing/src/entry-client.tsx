import { resolveWebEnvironment } from '@child-life/web-config';
import { StrictMode } from 'react';
import { hydrateRoot } from 'react-dom/client';
import { App } from './App';
import { routeFor } from './routes';
import './styles/index.css';

// Refuse to run with mixed or missing configuration (brief §03).
const { environment } = resolveWebEnvironment(
  import.meta.env.MODE,
  'landing',
  window.location.hostname,
);
const route = routeFor(window.location.pathname);

hydrateRoot(
  document.getElementById('root')!,
  <StrictMode>
    <App route={route} environment={environment} />
  </StrictMode>,
);
