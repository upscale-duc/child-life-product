import { readSavedLocale, resolveLocale, resolveWebEnvironment } from '@child-life/web-config';
import { initializeApp } from 'firebase/app';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { App } from './App';

const { environment, firebase } = resolveWebEnvironment(
  import.meta.env.MODE,
  'admin',
  window.location.hostname,
);
const app = initializeApp(firebase);
const locale = resolveLocale(readSavedLocale(), navigator.languages);
document.documentElement.lang = locale;

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App app={app} environment={environment} locale={locale} />
  </StrictMode>,
);
