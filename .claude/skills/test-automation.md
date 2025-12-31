# 테스트 자동화 스킬

> 프론트엔드/백엔드 테스트 자동화 및 TDD/BDD 지원

## 자동 활성화 조건
- 테스트 코드 작성
- "테스트", "test", "spec" 키워드
- Jest, Vitest, Playwright 사용
- TDD, BDD 언급

## 테스트 전략

### 테스트 피라미드
```
         /\
        /E2E\       (10%) - Playwright, Cypress
       /------\
      /Integrate\   (30%) - API, DB 통합
     /----------\
    /Unit Testing\  (60%) - Jest, Vitest
   /--------------\
```

---

## 단위 테스트 (Unit Test)

### 1. Jest 설정

```javascript
// jest.config.js
const nextJest = require('next/jest')

const createJestConfig = nextJest({
  dir: './',
})

const customJestConfig = {
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  testEnvironment: 'jest-environment-jsdom',
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  collectCoverageFrom: [
    'src/**/*.{js,jsx,ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/*.stories.tsx',
    '!src/**/index.ts',
  ],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70,
    },
  },
}

module.exports = createJestConfig(customJestConfig)
```

### 2. React 컴포넌트 테스트

```typescript
// __tests__/components/Button.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Button } from '@/components/ui/button';

describe('Button Component', () => {
  it('renders with text', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByText('Click me')).toBeInTheDocument();
  });

  it('handles click events', async () => {
    const handleClick = jest.fn();
    render(<Button onClick={handleClick}>Click me</Button>);

    const button = screen.getByRole('button');
    await userEvent.click(button);

    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('is disabled when disabled prop is true', () => {
    render(<Button disabled>Disabled</Button>);

    const button = screen.getByRole('button');
    expect(button).toBeDisabled();
  });

  it('shows loading state', () => {
    render(<Button loading>Loading</Button>);

    expect(screen.getByTestId('spinner')).toBeInTheDocument();
    expect(screen.getByText('Loading')).toBeInTheDocument();
  });
});
```

### 3. 커스텀 훅 테스트

```typescript
// __tests__/hooks/useCounter.test.ts
import { renderHook, act } from '@testing-library/react';
import { useCounter } from '@/lib/hooks/useCounter';

describe('useCounter Hook', () => {
  it('initializes with default value', () => {
    const { result } = renderHook(() => useCounter());
    expect(result.current.count).toBe(0);
  });

  it('initializes with custom value', () => {
    const { result } = renderHook(() => useCounter(10));
    expect(result.current.count).toBe(10);
  });

  it('increments counter', () => {
    const { result } = renderHook(() => useCounter());

    act(() => {
      result.current.increment();
    });

    expect(result.current.count).toBe(1);
  });

  it('decrements counter', () => {
    const { result } = renderHook(() => useCounter(5));

    act(() => {
      result.current.decrement();
    });

    expect(result.current.count).toBe(4);
  });

  it('resets counter', () => {
    const { result } = renderHook(() => useCounter(5));

    act(() => {
      result.current.increment();
      result.current.increment();
      result.current.reset();
    });

    expect(result.current.count).toBe(5);
  });
});
```

### 4. API 모킹

```typescript
// __tests__/api/users.test.ts
import { rest } from 'msw';
import { setupServer } from 'msw/node';
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useUsers } from '@/lib/hooks/useUsers';

const server = setupServer(
  rest.get('/api/users', (req, res, ctx) => {
    return res(
      ctx.json([
        { id: 1, name: 'John Doe', email: 'john@example.com' },
        { id: 2, name: 'Jane Doe', email: 'jane@example.com' },
      ])
    );
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

describe('useUsers Hook', () => {
  it('fetches users successfully', async () => {
    const queryClient = new QueryClient({
      defaultOptions: { queries: { retry: false } },
    });

    const wrapper = ({ children }: { children: React.ReactNode }) => (
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    );

    const { result } = renderHook(() => useUsers(), { wrapper });

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true);
    });

    expect(result.current.data).toHaveLength(2);
    expect(result.current.data[0].name).toBe('John Doe');
  });

  it('handles error', async () => {
    server.use(
      rest.get('/api/users', (req, res, ctx) => {
        return res(ctx.status(500), ctx.json({ error: 'Server Error' }));
      })
    );

    const queryClient = new QueryClient({
      defaultOptions: { queries: { retry: false } },
    });

    const wrapper = ({ children }: { children: React.ReactNode }) => (
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    );

    const { result } = renderHook(() => useUsers(), { wrapper });

    await waitFor(() => {
      expect(result.current.isError).toBe(true);
    });

    expect(result.current.error).toBeDefined();
  });
});
```

---

## 통합 테스트 (Integration Test)

### 1. API 라우트 테스트

```typescript
// __tests__/api/routes/users.test.ts
import { createMocks } from 'node-mocks-http';
import handler from '@/app/api/users/route';
import { prisma } from '@/lib/prisma';

// Mock Prisma
jest.mock('@/lib/prisma', () => ({
  prisma: {
    user: {
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
  },
}));

describe('/api/users', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('GET', () => {
    it('returns list of users', async () => {
      const mockUsers = [
        { id: 1, name: 'User 1', email: 'user1@test.com' },
        { id: 2, name: 'User 2', email: 'user2@test.com' },
      ];

      (prisma.user.findMany as jest.Mock).mockResolvedValue(mockUsers);

      const { req, res } = createMocks({
        method: 'GET',
      });

      await handler(req, res);

      expect(res._getStatusCode()).toBe(200);
      expect(JSON.parse(res._getData())).toEqual(mockUsers);
    });
  });

  describe('POST', () => {
    it('creates a new user', async () => {
      const newUser = {
        name: 'New User',
        email: 'new@test.com',
      };

      const createdUser = { id: 3, ...newUser };

      (prisma.user.create as jest.Mock).mockResolvedValue(createdUser);

      const { req, res } = createMocks({
        method: 'POST',
        body: newUser,
      });

      await handler(req, res);

      expect(res._getStatusCode()).toBe(201);
      expect(JSON.parse(res._getData())).toEqual(createdUser);
      expect(prisma.user.create).toHaveBeenCalledWith({
        data: newUser,
      });
    });

    it('validates required fields', async () => {
      const { req, res } = createMocks({
        method: 'POST',
        body: { name: 'Test' }, // Missing email
      });

      await handler(req, res);

      expect(res._getStatusCode()).toBe(400);
      expect(JSON.parse(res._getData())).toHaveProperty('error');
    });
  });
});
```

### 2. 폼 제출 플로우 테스트

```typescript
// __tests__/integration/userRegistration.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { RegistrationPage } from '@/app/register/page';
import { server } from '@/test/server';
import { rest } from 'msw';

describe('User Registration Flow', () => {
  it('completes registration successfully', async () => {
    const user = userEvent.setup();

    // Mock successful registration
    server.use(
      rest.post('/api/register', async (req, res, ctx) => {
        const body = await req.json();
        return res(
          ctx.json({
            id: 1,
            email: body.email,
            name: body.name,
          })
        );
      })
    );

    render(<RegistrationPage />);

    // Fill form
    await user.type(screen.getByLabelText(/이름/i), '홍길동');
    await user.type(screen.getByLabelText(/이메일/i), 'hong@example.com');
    await user.type(screen.getByLabelText(/비밀번호/i), 'password123');
    await user.type(screen.getByLabelText(/비밀번호 확인/i), 'password123');

    // Submit
    await user.click(screen.getByRole('button', { name: /가입/i }));

    // Verify success
    await waitFor(() => {
      expect(screen.getByText(/가입이 완료되었습니다/i)).toBeInTheDocument();
    });
  });

  it('shows validation errors', async () => {
    const user = userEvent.setup();

    render(<RegistrationPage />);

    // Submit without filling form
    await user.click(screen.getByRole('button', { name: /가입/i }));

    // Check validation messages
    await waitFor(() => {
      expect(screen.getByText(/이름을 입력하세요/i)).toBeInTheDocument();
      expect(screen.getByText(/이메일을 입력하세요/i)).toBeInTheDocument();
      expect(screen.getByText(/비밀번호를 입력하세요/i)).toBeInTheDocument();
    });
  });
});
```

---

## E2E 테스트 (End-to-End)

### 1. Playwright 설정

```typescript
// playwright.config.ts
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
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

### 2. E2E 테스트 시나리오

```typescript
// e2e/auth.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Authentication', () => {
  test('user can login', async ({ page }) => {
    await page.goto('/login');

    // Fill login form
    await page.fill('[name="email"]', 'test@example.com');
    await page.fill('[name="password"]', 'password123');

    // Submit
    await page.click('button[type="submit"]');

    // Wait for navigation
    await page.waitForURL('/dashboard');

    // Verify logged in
    await expect(page.locator('h1')).toContainText('대시보드');
  });

  test('user can logout', async ({ page }) => {
    // Setup: Login first
    await page.goto('/login');
    await page.fill('[name="email"]', 'test@example.com');
    await page.fill('[name="password"]', 'password123');
    await page.click('button[type="submit"]');
    await page.waitForURL('/dashboard');

    // Logout
    await page.click('button:has-text("로그아웃")');

    // Verify redirected to login
    await page.waitForURL('/login');
    await expect(page.locator('h1')).toContainText('로그인');
  });
});

// e2e/user-flow.spec.ts
test.describe('User Management', () => {
  test.beforeEach(async ({ page }) => {
    // Login before each test
    await page.goto('/login');
    await page.fill('[name="email"]', 'admin@example.com');
    await page.fill('[name="password"]', 'admin123');
    await page.click('button[type="submit"]');
    await page.waitForURL('/dashboard');
  });

  test('create new user', async ({ page }) => {
    await page.goto('/dashboard/users');

    // Open create form
    await page.click('button:has-text("새 사용자")');

    // Fill form
    await page.fill('[name="name"]', 'New User');
    await page.fill('[name="email"]', 'newuser@example.com');
    await page.selectOption('[name="role"]', 'user');

    // Submit
    await page.click('button:has-text("저장")');

    // Verify success
    await expect(page.locator('.toast')).toContainText('사용자가 생성되었습니다');

    // Verify in list
    await expect(page.locator('table')).toContainText('New User');
  });

  test('edit user', async ({ page }) => {
    await page.goto('/dashboard/users');

    // Click edit button for first user
    await page.click('table tbody tr:first-child button:has-text("편집")');

    // Update name
    await page.fill('[name="name"]', 'Updated Name');

    // Save
    await page.click('button:has-text("저장")');

    // Verify
    await expect(page.locator('.toast')).toContainText('수정되었습니다');
    await expect(page.locator('table')).toContainText('Updated Name');
  });

  test('delete user', async ({ page }) => {
    await page.goto('/dashboard/users');

    // Count initial rows
    const initialCount = await page.locator('table tbody tr').count();

    // Delete first user
    await page.click('table tbody tr:first-child button:has-text("삭제")');

    // Confirm
    await page.click('button:has-text("확인")');

    // Verify
    await expect(page.locator('.toast')).toContainText('삭제되었습니다');

    // Check row count decreased
    const finalCount = await page.locator('table tbody tr').count();
    expect(finalCount).toBe(initialCount - 1);
  });
});
```

### 3. 비주얼 테스트

```typescript
// e2e/visual.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Visual Regression', () => {
  test('homepage screenshot', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveScreenshot('homepage.png');
  });

  test('dashboard screenshot', async ({ page }) => {
    // Login
    await page.goto('/login');
    await page.fill('[name="email"]', 'test@example.com');
    await page.fill('[name="password"]', 'password123');
    await page.click('button[type="submit"]');
    await page.waitForURL('/dashboard');

    // Take screenshot
    await expect(page).toHaveScreenshot('dashboard.png', {
      fullPage: true,
      animations: 'disabled',
    });
  });

  test('mobile view', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 }); // iPhone SE
    await page.goto('/');
    await expect(page).toHaveScreenshot('homepage-mobile.png');
  });
});
```

---

## 테스트 유틸리티

### 1. 테스트 헬퍼

```typescript
// test/helpers.ts
import { render, RenderOptions } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

// Custom render with providers
export function renderWithProviders(
  ui: React.ReactElement,
  options?: RenderOptions
) {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });

  function Wrapper({ children }: { children: React.ReactNode }) {
    return (
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    );
  }

  return render(ui, { wrapper: Wrapper, ...options });
}

// Mock next/router
export function mockRouter(router: Partial<NextRouter> = {}) {
  const mockRouter: NextRouter = {
    route: '/',
    pathname: '/',
    query: {},
    asPath: '/',
    basePath: '',
    push: jest.fn(() => Promise.resolve(true)),
    replace: jest.fn(() => Promise.resolve(true)),
    reload: jest.fn(),
    back: jest.fn(),
    prefetch: jest.fn(() => Promise.resolve()),
    beforePopState: jest.fn(),
    events: {
      on: jest.fn(),
      off: jest.fn(),
      emit: jest.fn(),
    },
    isFallback: false,
    isReady: true,
    isPreview: false,
    isLocaleDomain: false,
    ...router,
  };

  return mockRouter;
}

// Wait for async updates
export const waitForAsync = () =>
  new Promise(resolve => setTimeout(resolve, 0));

// Generate mock data
export function createMockUser(overrides = {}) {
  return {
    id: Math.random().toString(36).substr(2, 9),
    name: 'Test User',
    email: 'test@example.com',
    createdAt: new Date().toISOString(),
    ...overrides,
  };
}
```

### 2. 테스트 데이터 팩토리

```typescript
// test/factories.ts
import { faker } from '@faker-js/faker';

export const UserFactory = {
  create: (overrides = {}) => ({
    id: faker.string.uuid(),
    name: faker.person.fullName(),
    email: faker.internet.email(),
    avatar: faker.image.avatar(),
    role: faker.helpers.arrayElement(['admin', 'user', 'guest']),
    createdAt: faker.date.past(),
    ...overrides,
  }),

  createMany: (count: number, overrides = {}) =>
    Array.from({ length: count }, () => UserFactory.create(overrides)),
};

export const PostFactory = {
  create: (overrides = {}) => ({
    id: faker.string.uuid(),
    title: faker.lorem.sentence(),
    content: faker.lorem.paragraphs(3),
    authorId: faker.string.uuid(),
    tags: faker.lorem.words(3).split(' '),
    published: faker.datatype.boolean(),
    createdAt: faker.date.past(),
    ...overrides,
  }),
};
```

---

## 테스트 명령어

```json
// package.json
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
    "test:all": "npm run test:unit && npm run test:integration && npm run test:e2e"
  }
}
```

---

## CI/CD 통합

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: Test

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  unit-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - run: npm ci
      - run: npm run test:unit

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/coverage-final.json

  e2e-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - run: npm ci
      - run: npx playwright install --with-deps
      - run: npm run build
      - run: npm run test:e2e

      - uses: actions/upload-artifact@v3
        if: always()
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 30
```

---

## 테스트 모범 사례

### DO's ✅
- 테스트는 독립적으로 실행 가능해야 함
- 테스트 이름은 명확하고 구체적으로
- Arrange-Act-Assert 패턴 사용
- 모킹은 최소한으로
- 중요한 사용자 시나리오 우선 테스트

### DON'Ts ❌
- 구현 세부사항 테스트 피하기
- 너무 많은 assertion 피하기
- 랜덤 데이터 과도하게 사용 피하기
- 테스트 간 상태 공유 피하기
- 느린 테스트 방치하기

---

이 스킬은 테스트 관련 작업 시 자동으로 활성화되며,
TDD/BDD 개발을 위한 테스트 코드 패턴을 제공합니다.