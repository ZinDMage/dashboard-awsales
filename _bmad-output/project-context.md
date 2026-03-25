---
project_name: 'AwSales'
user_name: 'Lucaskurt'
date: '2026-03-24'
sections_completed:
  - technology_stack
  - language_rules
  - framework_rules
  - testing_rules
  - quality_rules
  - workflow_rules
  - anti_patterns
status: 'complete'
rule_count: 87
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

### Core Framework & Build
- **React** `19.2.4` - Latest React with concurrent features
- **Vite** `8.0.2` - Development server and build tool (port 3000)
- **@vitejs/plugin-react** `6.0.1` - React Fast Refresh support

### Backend & Services
- **Supabase** `@supabase/supabase-js@2.100.0`
  - Authentication service
  - PostgreSQL database access
  - Real-time subscriptions
  - Storage API

### Language & Runtime
- **JavaScript (ESM)** - No TypeScript, pure JS/JSX
- **Node.js** - ES Modules format
- **Browser target** - Modern evergreen browsers with CSS variables support

### Key Dependencies
- **@rolldown/binding-linux-arm64-gnu** `^1.0.0-rc.11` - Build optimization

### Version Constraints
- React 19+ features in use (ensure agent uses compatible patterns)
- Supabase v2 API (not v1) - auth methods and client initialization differ
- Vite 8+ configuration format
- **CRITICAL**: Project uses JavaScript ONLY - NEVER add TypeScript

---

## Critical Implementation Rules

### Language-Specific Rules

#### JavaScript & ES Modules
- **Pure JavaScript** - NO TypeScript files (.ts, .tsx) allowed in this project
- **ES Modules format** - Use `import`/`export`, not CommonJS `require()`
- **File extensions**:
  - Use `.jsx` for React components
  - Use `.js` for services, utilities, and configurations
- **Export patterns**:
  - `export default` for main components (e.g., `export default function App()`)
  - `export const` for services and clients (e.g., `export const supabase`)

#### Import/Export Conventions
- React imports: `import { useState, useEffect } from 'react'`
- Supabase client: `import { supabase } from './supabaseClient'`
- Always use named destructuring for React hooks
- No default React import needed (React 19+ JSX transform)

#### Variable & Naming Patterns
- Use `const` by default, `let` only when mutation needed
- Camelcase for functions and variables
- PascalCase for React components
- Descriptive service module names (e.g., `dataService.js`, `supabaseClient.js`)

#### Error Handling
- Use try-catch for async Supabase operations
- Handle loading states explicitly with useState
- Check for null/undefined before accessing nested properties
- Use optional chaining (`?.`) for safe property access

### Framework-Specific Rules (React)

#### React 19+ Patterns

- **Use `ReactDOM.createRoot()`** - Not legacy `ReactDOM.render()`
- **React.StrictMode enabled** - All components run in strict mode
- **No PropTypes** - Project doesn't use PropTypes validation
- **Functional components only** - No class components in this project

#### Hooks Usage

- **Import hooks explicitly**: `import { useState, useEffect, useMemo, useCallback } from 'react'`
- **useState for component state** - Loading, session, data states
- **useEffect for side effects** - Auth listeners, data fetching
- **useMemo for expensive calculations** - Data aggregation, filtering
- **useCallback for event handlers** - Prevent unnecessary re-renders

#### Component Structure

- **Component files**: One main component per file
- **Export default** for main component function
- **Inline helper functions** above component when small and component-specific
- **Separate service modules** for data fetching logic (e.g., `dataService.js`)

#### State Management

- **No external state library** - Use React built-in state (useState, useContext)
- **Session state at App level** - Auth session managed in App.jsx
- **Local state for UI** - Loading states, UI toggles in component scope
- **Prop drilling** - Pass state down through props (no Context API yet)

#### Supabase Integration

- **Auth pattern**:
  - Check session: `supabase.auth.getSession()`
  - Listen to changes: `supabase.auth.onAuthStateChange()`
  - Always unsubscribe in cleanup: `return () => subscription.unsubscribe()`
- **Data fetching**: Use async/await with try-catch in service modules
- **Real-time subscriptions**: Handle in useEffect with cleanup

#### Performance Patterns

- **Memoize expensive computations** with useMemo
- **Memoize callbacks** passed to child components with useCallback
- **Loading states** - Always show loading UI during async operations
- **Conditional rendering** - Check session/data before rendering main content

### Testing Rules

#### Test Setup (To Be Implemented)

- **Testing framework**: Not yet configured - agents should propose testing setup if needed
- **Recommended for React**: Vitest + React Testing Library (compatible with Vite)
- **Test file naming**: `ComponentName.test.jsx` or `ComponentName.spec.jsx`
- **Test location**: Co-located with components or in `__tests__/` folder

#### Test Organization (When Implemented)

- **Unit tests**: Individual functions, utilities, and components in isolation
- **Integration tests**: Component + data service interactions
- **E2E tests**: Full user flows with authentication and data fetching
- **Test structure**: Describe blocks for component/function, it/test for individual cases

#### Testing Patterns to Follow

- **Mock Supabase client** for unit tests - don't hit real database
- **Test authentication flows** - session presence, login/logout
- **Test loading states** - verify loading UI appears and disappears
- **Test error handling** - verify error states render correctly
- **Async testing** - use async/await for Supabase operations

#### Coverage Expectations (When Implemented)

- **Critical paths**: Auth flows, data fetching, user interactions must be tested
- **Business logic**: Data aggregation and classification functions must have tests
- **UI components**: Key components should have basic render tests

### Code Quality & Style Rules

#### File & Folder Structure

- **Root source files**: Components in `Dash AwSales/` directory
- **Component naming**: PascalCase for files (e.g., `App.jsx`, `Login.jsx`, `Dashboard.jsx`)
- **Service files**: camelCase (e.g., `dataService.js`, `supabaseClient.js`)
- **Configuration files**: lowercase (e.g., `vite.config.js`)
- **Entry point**: `main.jsx` imports and renders root App component

#### Naming Conventions

- **Components**: PascalCase - `function Dashboard()`, `export default App`
- **Variables & functions**: camelCase - `const fetchData`, `let currentUser`
- **Constants**: UPPER_SNAKE_CASE for true constants - `const MESES = [...]`, `const COLORS = {...}`
- **Service exports**: Named exports with camelCase - `export const supabase`
- **File names match exports**: `App.jsx` exports `App`, `Login.jsx` exports `Login`

#### Code Organization

- **One component per file** - Main component should match filename
- **Helper functions before component** - Define utilities above the component that uses them
- **Service modules separate** - Data fetching logic in dedicated service files
- **Configuration centralized** - Supabase client in single `supabaseClient.js`
- **Constants at file top** - Define arrays, objects, configs before functions

#### Documentation & Comments

- **JSDoc for service functions** - Document public API functions with /** */ comments
- **Inline comments in Portuguese** - Business logic explained in pt-BR
- **Comment business rules** - Explain non-obvious logic (e.g., MQL qualification rules)
- **No obvious comments** - Don't comment what code already makes clear
- **Section separators** - Use `// ──` style for major sections in large files

#### Code Style (No Linter Configured)

- **Semicolons**: Not used consistently - follow existing file's pattern
- **Quotes**: Single quotes `'` preferred for strings
- **Indentation**: 2 spaces (not tabs)
- **Line length**: Keep under ~120 characters when possible
- **Trailing commas**: Used in arrays and objects
- **Arrow functions**: Preferred for inline callbacks and handlers

#### Localization

- **All UI text in Portuguese** - Labels, messages, errors in pt-BR
- **Comments in Portuguese** - Code explanations in pt-BR
- **Number formatting**: Use `toLocaleString('pt-BR')` for numbers
- **Currency formatting**: Prefix with `R$` and use pt-BR locale
- **Date formatting**: Brazilian format when displayed to users

### Development Workflow Rules

#### Development Environment

- **Dev server**: Run with `npm run dev` or `vite` (port 3000)
- **Hot reload**: Vite HMR is enabled - changes reflect immediately
- **Browser support**: Test on modern browsers with ES6+ support
- **Supabase connection**: Requires valid Supabase URL and anon key in `supabaseClient.js`

#### Build & Deployment

- **Build command**: `npm run build` or `vite build`
- **Build output**: `dist/` directory (gitignored)
- **Preview build**: `npm run preview` to test production build locally
- **Environment variables**: Store Supabase credentials securely (not hardcoded in production)

#### Git Workflow (Recommended)

- **Branch naming**: Use descriptive names (e.g., `feature/auth-improvements`, `fix/data-fetch-error`)
- **Commit messages**: Clear, descriptive messages in Portuguese or English
- **Before commit**: Test locally that app runs without errors
- **Pull requests**: Review changes before merging to main branch

#### Code Changes Guidelines

- **Test authentication** after changes to auth-related code
- **Test data fetching** after changes to Supabase queries or dataService
- **Check console** for errors and warnings during development
- **Verify styling** on both light and dark mode (CSS variables change)
- **Mobile responsiveness**: Check viewport scaling (viewport set to 0.8 in index.html)

#### Dependency Management

- **Package installation**: `npm install` after pulling changes
- **Adding dependencies**: Use `npm install <package>` and commit package.json
- **Version pinning**: Use exact versions (no `^` or `~`) for critical dependencies
- **Security updates**: Keep Supabase and React updated for security patches

### Critical Don't-Miss Rules

#### NEVER DO - Language & Framework

- ❌ **NEVER add TypeScript** - This is a pure JavaScript project, do not create .ts or .tsx files
- ❌ **NEVER use CommonJS** - Always use ES Modules (`import`/`export`, not `require`)
- ❌ **NEVER use class components** - Only functional components with hooks
- ❌ **NEVER use legacy React APIs** - No `ReactDOM.render()`, use `createRoot()`
- ❌ **NEVER skip React import** when needed - Import React explicitly for JSX (though React 19+ doesn't require it for JSX transform)

#### NEVER DO - Supabase & Authentication

- ❌ **NEVER use Supabase v1 API** - This project uses v2 (`@supabase/supabase-js@2.x`)
- ❌ **NEVER forget to unsubscribe** - Always cleanup auth listeners: `return () => subscription.unsubscribe()`
- ❌ **NEVER hardcode credentials** - Keep Supabase keys in `supabaseClient.js`, consider env vars for production
- ❌ **NEVER call database directly without try-catch** - All Supabase operations must handle errors
- ❌ **NEVER assume session exists** - Always check for null session before rendering authenticated content

#### NEVER DO - State & Performance

- ❌ **NEVER mutate state directly** - Use `setState()`, don't do `state.value = newValue`
- ❌ **NEVER forget dependencies in useEffect** - Include all used variables in dependency array
- ❌ **NEVER create functions inside render without useCallback** - Causes unnecessary re-renders
- ❌ **NEVER forget loading states** - Always show loading UI during async operations
- ❌ **NEVER skip error boundaries** - Handle errors gracefully, show user-friendly messages

#### NEVER DO - Styling & UI

- ❌ **NEVER hardcode colors** - Use CSS variables from `:root` (`var(--color-*)`)
- ❌ **NEVER break dark mode support** - Always use CSS variables, test both light/dark modes
- ❌ **NEVER ignore mobile viewport** - Remember viewport is set to 0.8 scale
- ❌ **NEVER use inline styles without objects** - Use `style={{}}` with JS objects, not strings

#### NEVER DO - Code Quality

- ❌ **NEVER add English UI text** - All user-facing text must be in Portuguese (pt-BR)
- ❌ **NEVER commit console.log debugging** - Remove debug statements before committing
- ❌ **NEVER skip error handling** - Handle errors explicitly, don't let them fail silently
- ❌ **NEVER create huge components** - Break down large components into smaller, focused ones

#### Edge Cases to Handle

- **Null/undefined data** - Always check before accessing nested properties (use `?.`)
- **Empty arrays** - Check array length before `.map()` or array methods
- **Failed Supabase queries** - Handle network errors, show retry options
- **Session expiration** - Handle auth state changes, redirect to login when session expires
- **Missing environment config** - Validate Supabase connection on app start

#### Security Considerations

- **Supabase RLS (Row Level Security)** - Ensure database policies are configured server-side
- **Client-side validation** - Don't trust client input, validate on Supabase side
- **Sensitive data** - Never log passwords, tokens, or sensitive user data
- **API keys** - Anon key is safe for client, but never expose service role key

---

## Usage Guidelines

**For AI Agents:**

- Read this file before implementing any code
- Follow ALL rules exactly as documented
- When in doubt, prefer the more restrictive option
- Update this file if new patterns emerge

**For Humans:**

- Keep this file lean and focused on agent needs
- Update when technology stack changes
- Review quarterly for outdated rules
- Remove rules that become obvious over time

**Last Updated:** 2026-03-24
