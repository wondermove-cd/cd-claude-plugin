---
activation-keywords:
  - review
  - code review
  - 코드 리뷰
  - check
  - 검토
  - feedback
  - PR
  - pull request
  - merge request
---

# Code Review Excellence

## Review Philosophy

**"Code review is about knowledge sharing, not finding mistakes."**

좋은 코드 리뷰는:
- 🧠 Knowledge transfer
- 🛡️ Quality assurance
- 👥 Team collaboration
- 📚 Documentation
- 🎓 Learning opportunity

## Code Review Checklist

### 1. Functionality ✅
```typescript
// Questions to ask:
- Does the code do what it's supposed to do?
- Are edge cases handled?
- Is error handling appropriate?
- Are there any potential bugs?

// Example review comment:
"Consider handling the case when `user.profile` is null.
This could cause a runtime error on line 42."
```

### 2. Design & Architecture 🏗️
```typescript
// Review points:
- Is the solution over-engineered or under-engineered?
- Does it follow SOLID principles?
- Is it maintainable and extensible?
- Are abstractions at the right level?

// Example feedback:
"This logic might be better extracted into a custom hook
like `useUserPermissions()` for reusability."
```

### 3. Performance ⚡
```typescript
// Check for:
- N+1 queries
- Unnecessary re-renders
- Memory leaks
- Bundle size impact
- Inefficient algorithms

// Example:
// ❌ Problematic
users.map(user => {
  const profile = await fetchProfile(user.id); // N+1
  return { ...user, profile };
});

// ✅ Better
const profiles = await fetchProfiles(users.map(u => u.id));
const usersWithProfiles = users.map(user => ({
  ...user,
  profile: profiles.find(p => p.userId === user.id)
}));
```

### 4. Security 🔒
```typescript
// Security checklist:
- SQL injection vulnerabilities
- XSS vulnerabilities
- Authentication/authorization checks
- Sensitive data exposure
- Input validation
- CORS configuration

// Example:
// ❌ Vulnerable
const query = `SELECT * FROM users WHERE id = ${userId}`;

// ✅ Secure
const query = 'SELECT * FROM users WHERE id = ?';
db.query(query, [userId]);
```

### 5. Code Quality 📝
```typescript
// Review for:
- Readability and clarity
- Consistent naming conventions
- DRY (Don't Repeat Yourself)
- KISS (Keep It Simple, Stupid)
- YAGNI (You Aren't Gonna Need It)

// Example feedback:
"This function name `processData` is too generic.
Consider `normalizeUserProfiles` to be more specific."
```

## Review Comment Templates

### Suggesting Improvements
```markdown
**Suggestion:** Consider using optional chaining here.

```diff
- if (user && user.profile && user.profile.settings) {
+ if (user?.profile?.settings) {
```

This makes the code more concise and readable.
```

### Asking Questions
```markdown
**Question:** I'm curious about the reasoning behind this approach.

Could you explain why we're using recursion here instead of iteration?
Are there specific benefits for this use case?
```

### Pointing Out Issues
```markdown
**Issue:** Potential memory leak detected.

The event listener is added but never removed. Consider:

```javascript
useEffect(() => {
  const handler = (e) => handleClick(e);
  window.addEventListener('click', handler);

  return () => {
    window.removeEventListener('click', handler); // Cleanup
  };
}, []);
```
```

### Giving Praise
```markdown
**Great work! 🎉**

This refactoring significantly improves readability.
The extraction of `calculateTotalPrice` makes the intent much clearer.
```

## Code Smells to Watch For

### 1. Long Functions
```typescript
// 🚫 Code smell: Function doing too much
function processOrder(order) {
  // Validate order
  if (!order.items || order.items.length === 0) {
    throw new Error('Empty order');
  }

  // Calculate prices
  let total = 0;
  for (const item of order.items) {
    total += item.price * item.quantity;
  }

  // Apply discounts
  if (order.coupon) {
    total = total * (1 - order.coupon.discount);
  }

  // Check inventory
  for (const item of order.items) {
    if (!checkInventory(item.id, item.quantity)) {
      throw new Error('Out of stock');
    }
  }

  // Process payment
  const payment = processPayment(order.payment, total);

  // Update inventory
  updateInventory(order.items);

  // Send confirmation
  sendEmail(order.user.email, 'Order confirmed');

  return { order, payment, total };
}

// ✅ Better: Single Responsibility
function validateOrder(order) { /* ... */ }
function calculateOrderTotal(items, coupon) { /* ... */ }
function checkOrderInventory(items) { /* ... */ }
function processOrderPayment(payment, total) { /* ... */ }
function finalizeOrder(order) { /* ... */ }

function processOrder(order) {
  validateOrder(order);
  const total = calculateOrderTotal(order.items, order.coupon);
  checkOrderInventory(order.items);
  const payment = processOrderPayment(order.payment, total);
  return finalizeOrder({ order, payment, total });
}
```

### 2. Duplicate Code
```typescript
// 🚫 Duplication
function getUserDisplayName(user) {
  if (user.firstName && user.lastName) {
    return `${user.firstName} ${user.lastName}`;
  }
  return user.email;
}

function getAdminDisplayName(admin) {
  if (admin.firstName && admin.lastName) {
    return `${admin.firstName} ${admin.lastName}`;
  }
  return admin.email;
}

// ✅ DRY
function getDisplayName(person) {
  if (person.firstName && person.lastName) {
    return `${person.firstName} ${person.lastName}`;
  }
  return person.email;
}
```

### 3. Magic Numbers/Strings
```typescript
// 🚫 Magic values
if (user.age >= 18) { /* ... */ }
if (status === 'active') { /* ... */ }
setTimeout(refresh, 5000);

// ✅ Named constants
const LEGAL_AGE = 18;
const STATUS = {
  ACTIVE: 'active',
  INACTIVE: 'inactive',
  PENDING: 'pending'
};
const REFRESH_INTERVAL_MS = 5000;

if (user.age >= LEGAL_AGE) { /* ... */ }
if (status === STATUS.ACTIVE) { /* ... */ }
setTimeout(refresh, REFRESH_INTERVAL_MS);
```

## React/Next.js Specific Reviews

### Component Patterns
```typescript
// 🚫 Avoid
function UserCard({ user }) {
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState(null);

  // Effect doing too much
  useEffect(() => {
    setLoading(true);
    fetch(`/api/users/${user.id}`)
      .then(res => res.json())
      .then(setData)
      .finally(() => setLoading(false));
  }, [user.id]);

  // Inline styles
  return (
    <div style={{ padding: '20px', border: '1px solid #ccc' }}>
      {loading ? 'Loading...' : data?.name}
    </div>
  );
}

// ✅ Better
function UserCard({ user }) {
  const { data, loading } = useUserData(user.id); // Custom hook

  return (
    <Card className="p-5 border border-gray-200">
      {loading ? (
        <Skeleton className="h-4 w-32" />
      ) : (
        <Text>{data?.name}</Text>
      )}
    </Card>
  );
}
```

### Performance Patterns
```typescript
// 🚫 Unnecessary re-renders
function Parent() {
  const [count, setCount] = useState(0);

  // New object every render
  const config = { theme: 'dark', size: 'large' };

  // New function every render
  const handleClick = () => console.log('clicked');

  return <Child config={config} onClick={handleClick} />;
}

// ✅ Optimized
function Parent() {
  const [count, setCount] = useState(0);

  // Memoized object
  const config = useMemo(
    () => ({ theme: 'dark', size: 'large' }),
    []
  );

  // Memoized callback
  const handleClick = useCallback(
    () => console.log('clicked'),
    []
  );

  return <Child config={config} onClick={handleClick} />;
}
```

## Automated Review Tools

### ESLint Configuration
```javascript
// .eslintrc.js
module.exports = {
  extends: [
    'next/core-web-vitals',
    'plugin:@typescript-eslint/recommended',
    'plugin:react-hooks/recommended',
    'plugin:jsx-a11y/recommended'
  ],
  rules: {
    'complexity': ['error', 10],
    'max-lines-per-function': ['error', 50],
    'max-depth': ['error', 3],
    'no-console': 'warn',
    'no-unused-vars': 'error',
    '@typescript-eslint/explicit-function-return-type': 'warn'
  }
};
```

### Pre-commit Hooks
```json
// package.json
{
  "husky": {
    "hooks": {
      "pre-commit": "lint-staged"
    }
  },
  "lint-staged": {
    "*.{js,jsx,ts,tsx}": [
      "eslint --fix",
      "prettier --write",
      "jest --bail --findRelatedTests"
    ]
  }
}
```

## Review Metrics

### What to Measure
```typescript
interface ReviewMetrics {
  reviewTime: number;        // Time to first review
  approvalTime: number;      // Time to approval
  commentsCount: number;     // Number of comments
  changesRequested: number;  // Number of change requests
  defectsFound: number;      // Bugs caught in review
  knowledgeShared: number;   // Learning moments
}

// Track effectiveness
const reviewEffectiveness = {
  defectDetectionRate: defectsFound / totalDefects,
  reviewCoverage: reviewedCode / totalCode,
  averageReviewTime: totalReviewTime / reviewsCount
};
```

## Best Practices

### For Reviewers
- ✅ Review promptly (within 24 hours)
- ✅ Be constructive and kind
- ✅ Explain the "why" behind suggestions
- ✅ Differentiate must-fix vs nice-to-have
- ✅ Acknowledge good code
- ✅ Ask questions to understand context
- ✅ Check tests are included

### For Authors
- ✅ Keep PRs small and focused
- ✅ Write descriptive PR descriptions
- ✅ Self-review before requesting
- ✅ Respond to all comments
- ✅ Test your code thoroughly
- ✅ Update documentation
- ✅ Add context for complex changes

## PR Description Template

```markdown
## Summary
Brief description of what this PR does.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## How Has This Been Tested?
- [ ] Unit tests
- [ ] Integration tests
- [ ] Manual testing

## Checklist
- [ ] My code follows the style guidelines
- [ ] I have performed a self-review
- [ ] I have commented my code where necessary
- [ ] I have updated the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix/feature works
- [ ] All tests pass locally

## Screenshots (if applicable)
[Add screenshots here]

## Additional Context
Any additional context or notes for reviewers.
```

## Remember

**"The best code review is the one that teaches something new to both the reviewer and the author."**

Focus on:
- 🎯 Impact over perfection
- 🤝 Collaboration over criticism
- 📈 Learning over judgment
- 🚀 Progress over process

좋은 코드 리뷰는 팀을 성장시킵니다!