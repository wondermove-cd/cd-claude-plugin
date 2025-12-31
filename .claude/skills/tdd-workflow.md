---
activation-keywords:
  - test
  - testing
  - TDD
  - 테스트
  - spec
  - jest
  - vitest
  - pytest
  - unit test
  - integration test
---

# Test-Driven Development (TDD) Workflow

## Philosophy

**Write tests first, code second. Let tests drive the design.**

TDD는 단순한 테스팅이 아니라 설계 방법론입니다. 테스트가 코드의 설계를 이끌어냅니다.

## TDD Cycle: Red → Green → Refactor

### 1. RED: Write a Failing Test
```typescript
// ❌ Test first (should fail)
describe('Calculator', () => {
  it('should add two numbers', () => {
    const result = add(2, 3);
    expect(result).toBe(5);
  });
});
// Error: add is not defined
```

### 2. GREEN: Write Minimal Code to Pass
```typescript
// ✅ Minimal implementation
function add(a: number, b: number): number {
  return a + b;
}
```

### 3. REFACTOR: Improve Code Quality
```typescript
// 🔧 Refactored with validation
function add(a: number, b: number): number {
  if (!Number.isFinite(a) || !Number.isFinite(b)) {
    throw new Error('Invalid input: numbers required');
  }
  return a + b;
}
```

## Testing Patterns

### Unit Test Structure
```typescript
describe('Component/Function Name', () => {
  // Arrange
  beforeEach(() => {
    // Setup test environment
  });

  // Act & Assert
  it('should [expected behavior] when [condition]', () => {
    // Given
    const input = prepareTestData();

    // When
    const result = functionUnderTest(input);

    // Then
    expect(result).toEqual(expectedOutput);
  });

  // Cleanup
  afterEach(() => {
    // Reset mocks, clear data
  });
});
```

### Integration Test Pattern
```typescript
describe('API Integration', () => {
  let server: Server;

  beforeAll(async () => {
    server = await createTestServer();
  });

  afterAll(async () => {
    await server.close();
  });

  it('should create and retrieve a user', async () => {
    // Create
    const createResponse = await request(server)
      .post('/users')
      .send({ name: 'John', email: 'john@test.com' });

    expect(createResponse.status).toBe(201);
    const userId = createResponse.body.id;

    // Retrieve
    const getResponse = await request(server)
      .get(`/users/${userId}`);

    expect(getResponse.body.name).toBe('John');
  });
});
```

### E2E Test Pattern
```typescript
// Playwright E2E
test('user can complete checkout flow', async ({ page }) => {
  // Navigate
  await page.goto('/products');

  // Add to cart
  await page.click('[data-testid="add-to-cart-1"]');

  // Go to cart
  await page.click('[data-testid="cart-icon"]');
  await expect(page).toHaveURL('/cart');

  // Checkout
  await page.click('[data-testid="checkout-btn"]');

  // Fill form
  await page.fill('[name="email"]', 'test@example.com');
  await page.fill('[name="card"]', '4242424242424242');

  // Submit
  await page.click('[type="submit"]');

  // Verify success
  await expect(page.locator('.success-message')).toBeVisible();
});
```

## Mock & Stub Patterns

### Mocking External Dependencies
```typescript
// Mock API calls
jest.mock('@/lib/api', () => ({
  fetchUser: jest.fn(() =>
    Promise.resolve({ id: 1, name: 'Mock User' })
  )
}));

// Mock modules
jest.mock('next/router', () => ({
  useRouter: () => ({
    push: jest.fn(),
    query: { id: '123' }
  })
}));
```

### Using MSW for API Mocking
```typescript
import { rest } from 'msw';
import { setupServer } from 'msw/node';

const server = setupServer(
  rest.get('/api/user/:id', (req, res, ctx) => {
    return res(
      ctx.json({
        id: req.params.id,
        name: 'John Doe'
      })
    );
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

## Test Data Patterns

### Factory Pattern
```typescript
// Test data factory
class UserFactory {
  static build(overrides = {}) {
    return {
      id: faker.datatype.uuid(),
      name: faker.name.fullName(),
      email: faker.internet.email(),
      createdAt: new Date(),
      ...overrides
    };
  }

  static buildList(count: number) {
    return Array.from({ length: count }, () => this.build());
  }
}

// Usage
const user = UserFactory.build({ name: 'Custom Name' });
const users = UserFactory.buildList(5);
```

### Fixture Pattern
```typescript
// fixtures/users.ts
export const validUser = {
  name: 'John Doe',
  email: 'john@example.com',
  password: 'SecurePass123!'
};

export const invalidUsers = [
  { name: '', email: 'john@example.com' }, // Missing name
  { name: 'John', email: 'invalid-email' }, // Invalid email
  { name: 'John', email: 'john@example.com', password: '123' } // Weak password
];
```

## Coverage Goals

### Recommended Coverage Targets
```json
{
  "jest": {
    "collectCoverageFrom": [
      "src/**/*.{js,jsx,ts,tsx}",
      "!src/**/*.d.ts",
      "!src/**/*.stories.tsx"
    ],
    "coverageThreshold": {
      "global": {
        "branches": 80,
        "functions": 80,
        "lines": 80,
        "statements": 80
      }
    }
  }
}
```

## Testing React Components

### Component Testing Pattern
```tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

describe('LoginForm', () => {
  it('should handle form submission', async () => {
    const mockSubmit = jest.fn();
    const user = userEvent.setup();

    render(<LoginForm onSubmit={mockSubmit} />);

    // Type in fields
    await user.type(screen.getByLabelText(/email/i), 'test@example.com');
    await user.type(screen.getByLabelText(/password/i), 'password123');

    // Submit form
    await user.click(screen.getByRole('button', { name: /login/i }));

    // Verify
    await waitFor(() => {
      expect(mockSubmit).toHaveBeenCalledWith({
        email: 'test@example.com',
        password: 'password123'
      });
    });
  });
});
```

### Hook Testing
```typescript
import { renderHook, act } from '@testing-library/react';

describe('useCounter', () => {
  it('should increment counter', () => {
    const { result } = renderHook(() => useCounter());

    expect(result.current.count).toBe(0);

    act(() => {
      result.current.increment();
    });

    expect(result.current.count).toBe(1);
  });
});
```

## Continuous Testing

### Watch Mode Configuration
```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:changed": "jest -o",
    "test:ci": "jest --ci --coverage --maxWorkers=2"
  }
}
```

### Pre-commit Hook
```json
// .husky/pre-commit
#!/bin/sh
npm run test:changed
npm run lint
```

## TDD Best Practices

### DO's ✅
- Write test first, always
- One assertion per test (when possible)
- Test behavior, not implementation
- Use descriptive test names
- Keep tests independent
- Mock external dependencies
- Test edge cases
- Maintain test code quality

### DON'Ts ❌
- Don't test implementation details
- Don't write tests after code
- Don't skip the refactor step
- Don't test framework code
- Don't use production data
- Don't ignore flaky tests
- Don't aim for 100% coverage blindly

## Advanced Patterns

### Parameterized Tests
```typescript
describe.each([
  [1, 1, 2],
  [1, 2, 3],
  [2, 1, 3],
])('add(%i, %i)', (a, b, expected) => {
  test(`returns ${expected}`, () => {
    expect(add(a, b)).toBe(expected);
  });
});
```

### Snapshot Testing
```typescript
it('should render correctly', () => {
  const tree = renderer
    .create(<Button variant="primary">Click me</Button>)
    .toJSON();

  expect(tree).toMatchSnapshot();
});
```

### Performance Testing
```typescript
it('should complete within performance budget', async () => {
  const start = performance.now();

  await processLargeDataset(data);

  const duration = performance.now() - start;
  expect(duration).toBeLessThan(1000); // Less than 1 second
});
```

## Remember

**"테스트 없는 코드는 레거시 코드다" - Michael Feathers**

TDD는 단순히 버그를 잡는 것이 아니라:
- 더 나은 설계를 만들고
- 리팩토링을 안전하게 하며
- 문서화 역할을 합니다

항상 Red → Green → Refactor 사이클을 따르세요!