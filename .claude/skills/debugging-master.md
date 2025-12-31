---
activation-keywords:
  - debug
  - error
  - bug
  - 디버그
  - 에러
  - 버그
  - fix
  - troubleshoot
  - not working
  - 안돼
  - 문제
---

# Systematic Debugging Master

## Debugging Philosophy

**"The most effective debugging tool is still careful thought, coupled with judiciously placed print statements." - Brian Kernighan**

디버깅은 추측이 아니라 체계적인 과학적 방법론입니다.

## The Scientific Method of Debugging

### 1. REPRODUCE: Isolate the Problem
```typescript
// Document exact steps to reproduce
const reproduceBug = () => {
  // Step 1: Navigate to /dashboard
  // Step 2: Click "Create New" button
  // Step 3: Fill form with specific data
  // Step 4: Submit → Error occurs

  // Expected: Success message
  // Actual: 500 Internal Server Error
};
```

### 2. HYPOTHESIZE: Form a Theory
```typescript
// Potential causes ranked by probability
const hypotheses = [
  { cause: "Null pointer in form validation", probability: 0.7 },
  { cause: "Database connection timeout", probability: 0.2 },
  { cause: "Race condition in async handler", probability: 0.1 }
];
```

### 3. TEST: Verify Hypothesis
```typescript
// Add strategic logging
console.log('[DEBUG] Form data:', formData);
console.log('[DEBUG] Validation result:', validationResult);
console.log('[DEBUG] DB query:', query);
```

### 4. FIX: Apply Minimal Solution
```typescript
// Fix only what's broken
if (!formData.email) {
  throw new Error('Email is required'); // Clear error message
}
```

## Debugging Patterns by Error Type

### 1. TypeError: Cannot read property of undefined

**Pattern Recognition:**
```javascript
// Common cause
user.profile.settings.theme // Error if profile is undefined
```

**Systematic Fix:**
```javascript
// Option 1: Optional chaining
user?.profile?.settings?.theme

// Option 2: Default values
const theme = user?.profile?.settings?.theme || 'light';

// Option 3: Guard clauses
if (!user?.profile) {
  return defaultSettings;
}
```

### 2. Async/Promise Errors

**Pattern Recognition:**
```javascript
// Unhandled promise rejection
fetchData().then(data => process(data)); // No error handling
```

**Systematic Fix:**
```javascript
// Always handle errors
try {
  const data = await fetchData();
  const result = await process(data);
} catch (error) {
  console.error('[ERROR] Processing failed:', error);
  // Specific error handling
  if (error.code === 'NETWORK_ERROR') {
    retryWithBackoff();
  }
}
```

### 3. Race Conditions

**Pattern Recognition:**
```javascript
// State updates racing
setLoading(true);
fetchData().then(data => {
  setData(data);
  setLoading(false); // May execute after component unmount
});
```

**Systematic Fix:**
```javascript
useEffect(() => {
  let isCancelled = false;

  const loadData = async () => {
    setLoading(true);
    try {
      const data = await fetchData();
      if (!isCancelled) {
        setData(data);
      }
    } finally {
      if (!isCancelled) {
        setLoading(false);
      }
    }
  };

  loadData();

  return () => {
    isCancelled = true;
  };
}, []);
```

## Advanced Debugging Tools

### 1. Browser DevTools Mastery

```javascript
// Conditional breakpoints
// Right-click on line number → Add conditional breakpoint
// Condition: user.role === 'admin'

// Logpoints (non-breaking console.log)
// Right-click → Add logpoint
// Message: 'User data:', user

// Watch expressions
// Add to Watch panel: JSON.stringify(complexObject, null, 2)
```

### 2. Performance Profiling

```javascript
// Measure specific operations
console.time('DataProcessing');
processLargeDataset();
console.timeEnd('DataProcessing'); // DataProcessing: 1234.56ms

// Memory profiling
const before = performance.memory.usedJSHeapSize;
runOperation();
const after = performance.memory.usedJSHeapSize;
console.log('Memory used:', (after - before) / 1024 / 1024, 'MB');
```

### 3. Network Debugging

```javascript
// Intercept and log all fetch requests
const originalFetch = window.fetch;
window.fetch = async (...args) => {
  console.log('[FETCH]', args);
  const response = await originalFetch(...args);
  console.log('[RESPONSE]', response.status, response.url);
  return response;
};
```

## React/Next.js Specific Debugging

### Component Render Tracking
```tsx
// Why did this render?
function useWhyDidYouRender(name: string, props: Record<string, any>) {
  const previousProps = useRef<Record<string, any>>();

  useEffect(() => {
    if (previousProps.current) {
      const changes = Object.entries(props).filter(
        ([key, val]) => previousProps.current![key] !== val
      );

      if (changes.length > 0) {
        console.log('[RENDER]', name, 'changed props:', changes);
      }
    }

    previousProps.current = props;
  });
}
```

### React DevTools Profiler
```tsx
// Wrap components to measure performance
import { Profiler } from 'react';

function onRenderCallback(
  id: string,
  phase: 'mount' | 'update',
  actualDuration: number
) {
  console.log(`${id} (${phase}) took ${actualDuration}ms`);
}

<Profiler id="Navigation" onRender={onRenderCallback}>
  <Navigation />
</Profiler>
```

## Error Boundary Pattern

```tsx
class ErrorBoundary extends React.Component<Props, State> {
  state = { hasError: false, error: null };

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    // Log to error reporting service
    console.error('[ErrorBoundary]', error, errorInfo);

    // Send to monitoring
    if (typeof window !== 'undefined') {
      window.Sentry?.captureException(error, {
        contexts: { react: errorInfo }
      });
    }
  }

  render() {
    if (this.state.hasError) {
      return <ErrorFallback error={this.state.error} />;
    }

    return this.props.children;
  }
}
```

## Database Query Debugging

### SQL Query Logging
```typescript
// Prisma query logging
const prisma = new PrismaClient({
  log: [
    { emit: 'event', level: 'query' },
    { emit: 'stdout', level: 'error' },
    { emit: 'stdout', level: 'warn' }
  ],
});

prisma.$on('query', (e) => {
  console.log('Query:', e.query);
  console.log('Duration:', e.duration, 'ms');
});
```

## Node.js Debugging

### Debug Module Pattern
```javascript
const debug = require('debug');
const dbDebug = debug('app:database');
const apiDebug = debug('app:api');
const authDebug = debug('app:auth');

// Use throughout code
dbDebug('Connecting to database...');
apiDebug('API request:', req.method, req.url);
authDebug('User authenticated:', user.id);

// Enable with: DEBUG=app:* node server.js
// Or specific: DEBUG=app:database node server.js
```

### Memory Leak Detection
```javascript
// Monitor memory usage
setInterval(() => {
  const used = process.memoryUsage();
  console.log('Memory Usage:');
  for (let key in used) {
    console.log(`${key}: ${Math.round(used[key] / 1024 / 1024 * 100) / 100} MB`);
  }
}, 10000);
```

## Production Debugging

### Structured Logging
```typescript
class Logger {
  private context: Record<string, any> = {};

  setContext(ctx: Record<string, any>) {
    this.context = { ...this.context, ...ctx };
  }

  log(level: string, message: string, data?: any) {
    const logEntry = {
      timestamp: new Date().toISOString(),
      level,
      message,
      ...this.context,
      ...data
    };

    console.log(JSON.stringify(logEntry));
  }

  error(message: string, error: Error) {
    this.log('ERROR', message, {
      error: {
        message: error.message,
        stack: error.stack,
        name: error.name
      }
    });
  }
}
```

### Feature Flags for Debugging
```typescript
const debugFlags = {
  VERBOSE_LOGGING: process.env.NODE_ENV === 'development',
  SHOW_SQL_QUERIES: process.env.DEBUG_SQL === 'true',
  TRACE_RENDERS: process.env.DEBUG_RENDERS === 'true'
};

if (debugFlags.VERBOSE_LOGGING) {
  console.log('[VERBOSE]', detailedInfo);
}
```

## Debugging Checklist

### Before You Start
- [ ] Can you reproduce the issue consistently?
- [ ] Have you checked the browser console?
- [ ] Have you checked network requests?
- [ ] Is this environment-specific?
- [ ] Did it work before? What changed?

### During Investigation
- [ ] Add logging at key points
- [ ] Check data types and null values
- [ ] Verify async operation order
- [ ] Look for race conditions
- [ ] Check error boundaries
- [ ] Review recent commits

### After Fixing
- [ ] Write a test to prevent regression
- [ ] Document the root cause
- [ ] Update error messages for clarity
- [ ] Consider adding monitoring
- [ ] Share learnings with team

## Common Gotchas

### JavaScript/TypeScript
```typescript
// Gotcha 1: Floating point precision
0.1 + 0.2 === 0.3 // false!
// Fix: Use epsilon comparison
Math.abs((0.1 + 0.2) - 0.3) < Number.EPSILON

// Gotcha 2: Array mutation
const arr = [1, 2, 3];
const sorted = arr.sort(); // Mutates original!
// Fix: Create copy first
const sorted = [...arr].sort();

// Gotcha 3: Closure in loops
for (var i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 100); // Prints 3, 3, 3
}
// Fix: Use let or IIFE
for (let i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 100); // Prints 0, 1, 2
}
```

## Remember

**"Debugging is twice as hard as writing the code in the first place. Therefore, if you write the code as cleverly as possible, you are, by definition, not smart enough to debug it." - Brian Kernighan**

체계적으로 접근하고, 가정을 검증하고, 항상 근본 원인을 찾으세요!