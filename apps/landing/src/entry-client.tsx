import { resolveSiteEnvironment } from '@child-life/web-config';
import { StrictMode } from 'react';
import { hydrateRoot } from 'react-dom/client';
import { startAnalytics } from './analytics';
import { App } from './App';
import { routeFor } from './routes';
import './styles/index.css';

// Refuse to run with mixed configuration (brief §03). The landing loads no Firebase SDK, so only
// the build mode and the host are checked.
const environment = resolveSiteEnvironment(import.meta.env.MODE, window.location.hostname);
const route = routeFor(window.location.pathname);

hydrateRoot(
  document.getElementById('root')!,
  <StrictMode>
    <App route={route} environment={environment} />
  </StrictMode>,
);
startAnalytics(environment);
