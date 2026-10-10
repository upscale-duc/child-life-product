import { functionsRegion } from '@child-life/contracts';
import { readSavedLocale, resolveLocale, resolveWebEnvironment } from '@child-life/web-config';
import { initializeApp } from 'firebase/app';
import { connectAuthEmulator, getAuth } from 'firebase/auth';
import { connectFunctionsEmulator, getFunctions } from 'firebase/functions';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { createApi } from './api';
import { App } from './App';
import './styles.css';

const host = window.location.hostname;
const { environment, firebase } = resolveWebEnvironment(import.meta.env.MODE, 'admin', host);
const app = initializeApp(firebase);
const auth = getAuth(app);
const functions = getFunctions(app, functionsRegion);
// Local emulators only: a dev build served from localhost with VITE_CL_EMULATORS=true.
if (
  import.meta.env.VITE_CL_EMULATORS === 'true' &&
  (host === 'localhost' || host === '127.0.0.1')
) {
  connectAuthEmulator(auth, `http://${host}:9099`, { disableWarnings: true });
  connectFunctionsEmulator(functions, host, 5001);
}
const locale = resolveLocale(readSavedLocale(), navigator.languages);
document.documentElement.lang = locale;

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App auth={auth} api={createApi(functions)} environment={environment} initialLocale={locale} />
  </StrictMode>,
);
