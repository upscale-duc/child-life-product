import { createContext, useContext } from 'react';
import { brand } from './brand';
export type Theme = 'light' | 'dark';
export const ThemeContext = createContext<Theme>('light');
export const useTheme = () => useContext(ThemeContext);
export const useBrand = () =>
  useTheme() === 'dark'
    ? {
        ...brand,
        cloud: '#0c1719',
        ink: '#e6f2f1',
        mintDeep: '#3fd0c3',
        muted: '#9db3b4',
        surface: '#15242a',
        surface2: '#1c2e33',
        separator: '#294147',
      }
    : brand;
