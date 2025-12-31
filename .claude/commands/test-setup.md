---
description: 테스트 환경 설정 및 테스트 코드 생성
allowed-tools: Read, Write, Edit, Bash
argument-hint: [테스트타입]
---

# 테스트 환경 설정

## 목적

프로젝트에 테스트 환경을 구성하고 샘플 테스트 코드를 생성합니다.

## 테스트 타입

- **unit**: 단위 테스트 (Jest)
- **integration**: 통합 테스트 (Jest + MSW)
- **e2e**: E2E 테스트 (Playwright)
- **all**: 모든 테스트 환경

## 실행 절차

### Step 1: 프로젝트 타입 확인

```bash
# package.json 확인
cat package.json | grep "next"
```

### Step 2: 테스트 도구 설치

#### Jest 설정 (unit/integration)

```bash
# Jest 및 관련 패키지
npm install -D jest @types/jest jest-environment-jsdom
npm install -D @testing-library/react @testing-library/jest-dom @testing-library/user-event

# Next.js 설정
npm install -D @testing-library/react-hooks
```

jest.config.js 생성:

```javascript
const nextJest = require('next/jest');

const createJestConfig = nextJest({
  dir: './',
});

const customJestConfig = {
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  testEnvironment: 'jest-environment-jsdom',
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  testMatch: [
    '**/__tests__/**/*.test.[jt]s?(x)',
    '**/?(*.)+(spec|test).[jt]s?(x)',
  ],
  collectCoverageFrom: [
    'src/**/*.{js,jsx,ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/*.stories.tsx',
  ],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70,
    },
  },
};

module.exports = createJestConfig(customJestConfig);
```

jest.setup.js 생성:

```javascript
import '@testing-library/jest-dom';

// Mock environment variables
process.env.NEXT_PUBLIC_API_URL = 'http://localhost:3000/api';

// Mock next/router
jest.mock('next/router', () => ({
  useRouter() {
    return {
      route: '/',
      pathname: '/',
      query: {},
      asPath: '/',
      push: jest.fn(),
      replace: jest.fn(),
    };
  },
}));
```

#### MSW 설정 (API 모킹)

```bash
npm install -D msw
npx msw init public/ --save
```

src/mocks/handlers.ts 생성:

```typescript
import { rest } from 'msw';

export const handlers = [
  rest.get('/api/users', (req, res, ctx) => {
    return res(
      ctx.json([
        { id: 1, name: 'John Doe', email: 'john@example.com' },
        { id: 2, name: 'Jane Doe', email: 'jane@example.com' },
      ])
    );
  }),

  rest.post('/api/users', async (req, res, ctx) => {
    const body = await req.json();
    return res(
      ctx.status(201),
      ctx.json({
        id: 3,
        ...body,
      })
    );
  }),
];
```

src/mocks/server.ts 생성:

```typescript
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);
```

#### Playwright 설정 (E2E)

```bash
npm install -D @playwright/test
npx playwright install
```

playwright.config.ts 생성:

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

### Step 3: 테스트 디렉토리 구조 생성

```
src/
├── __tests__/
│   ├── components/
│   │   └── Button.test.tsx
│   ├── hooks/
│   │   └── useAuth.test.ts
│   └── utils/
│       └── helpers.test.ts
├── integration/
│   └── api/
│       └── users.test.ts
e2e/
├── auth.spec.ts
├── navigation.spec.ts
└── user-flow.spec.ts
```

### Step 4: 샘플 테스트 생성

#### 컴포넌트 테스트 예시

src/__tests__/components/Button.test.tsx:

```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from '@/components/ui/button';

describe('Button Component', () => {
  it('renders with text', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByText('Click me')).toBeInTheDocument();
  });

  it('handles click events', () => {
    const handleClick = jest.fn();
    render(<Button onClick={handleClick}>Click me</Button>);

    fireEvent.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('can be disabled', () => {
    render(<Button disabled>Disabled</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });
});
```

#### Hook 테스트 예시

src/__tests__/hooks/useCounter.test.ts:

```typescript
import { renderHook, act } from '@testing-library/react';
import { useCounter } from '@/lib/hooks/useCounter';

describe('useCounter Hook', () => {
  it('initializes with default value', () => {
    const { result } = renderHook(() => useCounter());
    expect(result.current.count).toBe(0);
  });

  it('increments counter', () => {
    const { result } = renderHook(() => useCounter());

    act(() => {
      result.current.increment();
    });

    expect(result.current.count).toBe(1);
  });
});
```

#### API 통합 테스트 예시

src/integration/api/users.test.ts:

```typescript
import { server } from '@/mocks/server';
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useUsers } from '@/lib/hooks/useUsers';

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

describe('User API Integration', () => {
  it('fetches users successfully', async () => {
    const queryClient = new QueryClient({
      defaultOptions: { queries: { retry: false } },
    });

    const wrapper = ({ children }) => (
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    );

    const { result } = renderHook(() => useUsers(), { wrapper });

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true);
    });

    expect(result.current.data).toHaveLength(2);
  });
});
```

#### E2E 테스트 예시

e2e/auth.spec.ts:

```typescript
import { test, expect } from '@playwright/test';

test.describe('Authentication', () => {
  test('user can login', async ({ page }) => {
    await page.goto('/login');

    await page.fill('[name="email"]', 'test@example.com');
    await page.fill('[name="password"]', 'password123');
    await page.click('button[type="submit"]');

    await page.waitForURL('/dashboard');
    await expect(page.locator('h1')).toContainText('Dashboard');
  });
});
```

### Step 5: 테스트 스크립트 추가

package.json 업데이트:

```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:unit": "jest --testPathPattern=__tests__",
    "test:integration": "jest --testPathPattern=integration",
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:debug": "playwright test --debug",
    "test:all": "npm run test && npm run test:e2e"
  }
}
```

### Step 6: CI/CD 설정

.github/workflows/test.yml 생성:

```yaml
name: Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run unit tests
        run: npm run test:coverage

      - name: Install Playwright
        run: npx playwright install --with-deps

      - name: Run E2E tests
        run: npm run test:e2e

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/coverage-final.json

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: |
            coverage/
            playwright-report/
```

---

## 완료 보고

```
============================================
 [TEST SETUP] 테스트 환경 구성 완료
============================================

 테스트 타입: {테스트타입}

 설치된 도구:
 ✅ Jest - 단위/통합 테스트
 ✅ Testing Library - 컴포넌트 테스트
 ✅ MSW - API 모킹
 ✅ Playwright - E2E 테스트

 생성된 파일:
 • jest.config.js
 • jest.setup.js
 • playwright.config.ts
 • 샘플 테스트 파일

 테스트 실행:
 • npm test - 단위 테스트
 • npm run test:e2e - E2E 테스트
 • npm run test:coverage - 커버리지

 CI/CD:
 • GitHub Actions 워크플로우 생성

============================================
```

---

## 테스트 작성 가이드

### 테스트 명명 규칙

```typescript
describe('[Component/Function Name]', () => {
  describe('[Method/Behavior]', () => {
    it('should [expected behavior] when [condition]', () => {
      // Test implementation
    });
  });
});
```

### 테스트 우선순위

1. **Critical Path**: 핵심 사용자 플로우
2. **Happy Path**: 정상 동작 시나리오
3. **Edge Cases**: 경계값, 특수 케이스
4. **Error Handling**: 에러 상황 처리

### 커버리지 목표

- Statements: 80%+
- Branches: 75%+
- Functions: 80%+
- Lines: 80%+

---

## 자동 활성화 스킬

이 명령어 실행 시 자동으로 활성화:

- `test-automation` - 테스트 자동화 패턴
- `api-design` - API 모킹 패턴