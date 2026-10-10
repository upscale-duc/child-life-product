import type { Environment } from '@child-life/contracts';
import { renderToString } from 'react-dom/server';
import { App } from './App';
import { contentFor } from './content';
import { alternateOf, routeFor, routes, type Route } from './routes';
import { buildHead } from './seo';
import { siteOrigin } from './site';

export { routes, siteOrigin };

export function alternates(route: Route): Route[] {
  return [alternateOf(route, 'vi'), alternateOf(route, 'en')];
}

export function render(path: string, environment: Environment) {
  const route = routeFor(path);
  const content = contentFor(route.locale);
  return {
    lang: route.locale,
    head: buildHead(route, content, environment),
    html: renderToString(<App route={route} environment={environment} />),
  };
}
