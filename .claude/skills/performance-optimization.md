# 성능 최적화 스킬

> 웹 애플리케이션 성능 최적화 및 모니터링

## 자동 활성화 조건
- 성능 최적화, 속도 개선
- Lighthouse, Core Web Vitals 언급
- "느림", "최적화", "성능" 키워드
- 번들 사이즈, 로딩 속도 관련

## 성능 지표

### Core Web Vitals
- **LCP** (Largest Contentful Paint): < 2.5초
- **FID** (First Input Delay): < 100ms
- **CLS** (Cumulative Layout Shift): < 0.1
- **INP** (Interaction to Next Paint): < 200ms (FID 대체)

---

## Next.js 성능 최적화

### 1. 이미지 최적화

```tsx
// ❌ Bad
<img src="/hero.jpg" width="1200" height="600" />

// ✅ Good - next/image 사용
import Image from 'next/image';

<Image
  src="/hero.jpg"
  width={1200}
  height={600}
  alt="Hero image"
  priority // LCP 이미지는 priority
  placeholder="blur" // 블러 플레이스홀더
  blurDataURL={blurDataUrl} // Base64 인코딩된 블러 이미지
  sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
/>

// 외부 이미지 최적화
<Image
  src="https://example.com/image.jpg"
  width={800}
  height={600}
  alt="External image"
  loader={myLoader} // 커스텀 로더
  unoptimized={false} // 최적화 활성화
/>

// 커스텀 로더
const myLoader = ({ src, width, quality }) => {
  return `https://cdn.example.com/${src}?w=${width}&q=${quality || 75}`;
};
```

### 2. 폰트 최적화

```tsx
// app/layout.tsx
import { Inter, Noto_Sans_KR } from 'next/font/google';

// 가변 폰트 사용 (파일 크기 감소)
const inter = Inter({
  subsets: ['latin'],
  display: 'swap', // FOUT 방지
  variable: '--font-inter',
});

const notoSansKr = Noto_Sans_KR({
  subsets: ['latin'],
  weight: ['400', '700'], // 필요한 weight만
  display: 'swap',
  variable: '--font-noto',
  preload: false, // 한글 폰트는 preload 비활성화
});

export default function RootLayout({ children }) {
  return (
    <html lang="ko" className={`${inter.variable} ${notoSansKr.variable}`}>
      <body>{children}</body>
    </html>
  );
}

// CSS에서 사용
body {
  font-family: var(--font-inter), sans-serif;
}

h1, h2, h3 {
  font-family: var(--font-noto), sans-serif;
}
```

### 3. 코드 스플리팅

```tsx
// 동적 임포트로 번들 분리
import dynamic from 'next/dynamic';

// 컴포넌트 레벨 스플리팅
const HeavyComponent = dynamic(() => import('@/components/HeavyComponent'), {
  loading: () => <Skeleton />,
  ssr: false, // 클라이언트에서만 렌더링
});

// 조건부 로딩
const AdminDashboard = dynamic(() => import('@/components/AdminDashboard'));

function Page({ isAdmin }) {
  return (
    <div>
      {isAdmin && <AdminDashboard />}
    </div>
  );
}

// 라이브러리 레벨 스플리팅
const loadChart = async () => {
  const { Chart } = await import('chart.js');
  return Chart;
};

// 사용 시점에 로드
useEffect(() => {
  loadChart().then(Chart => {
    new Chart(ctx, config);
  });
}, []);
```

### 4. 정적 생성 최적화

```tsx
// app/posts/[slug]/page.tsx

// 정적 경로 생성
export async function generateStaticParams() {
  const posts = await getPosts();

  return posts.map((post) => ({
    slug: post.slug,
  }));
}

// ISR (Incremental Static Regeneration)
export const revalidate = 3600; // 1시간마다 재생성

// 또는 on-demand revalidation
import { revalidatePath, revalidateTag } from 'next/cache';

// 특정 경로 재검증
async function updatePost(slug: string) {
  await savePost(slug);
  revalidatePath(`/posts/${slug}`);
}

// 태그 기반 재검증
async function updatePosts() {
  await savePosts();
  revalidateTag('posts');
}
```

### 5. 서버 컴포넌트 최적화

```tsx
// app/page.tsx - 서버 컴포넌트 (기본값)
async function ServerComponent() {
  // 서버에서 데이터 페칭
  const data = await fetch('https://api.example.com/data', {
    next: { revalidate: 3600 }, // 캐싱
  });

  return <div>{/* 무거운 렌더링 로직 */}</div>;
}

// 클라이언트 컴포넌트 최소화
'use client';

function InteractiveButton() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(count + 1)}>{count}</button>;
}

// 혼합 사용
export default async function Page() {
  const data = await getData(); // 서버에서 실행

  return (
    <div>
      <ServerComponent data={data} />
      <InteractiveButton /> {/* 클라이언트만 */}
    </div>
  );
}
```

---

## React 성능 최적화

### 1. 메모이제이션

```tsx
// React.memo - 컴포넌트 메모이제이션
const ExpensiveComponent = React.memo(({ data, onClick }) => {
  return <div>{/* 복잡한 렌더링 */}</div>;
}, (prevProps, nextProps) => {
  // 커스텀 비교 로직
  return prevProps.data.id === nextProps.data.id;
});

// useMemo - 값 메모이제이션
function Component({ items, filter }) {
  const filteredItems = useMemo(() => {
    console.log('Filtering items...');
    return items.filter(item => item.includes(filter));
  }, [items, filter]); // 의존성 배열

  const expensiveValue = useMemo(() => {
    return computeExpensiveValue(items);
  }, [items]);

  return <List items={filteredItems} />;
}

// useCallback - 함수 메모이제이션
function ParentComponent({ data }) {
  const handleClick = useCallback((id) => {
    console.log('Clicked:', id);
    // API 호출 등
  }, []); // 의존성이 없으면 함수 재생성 안됨

  const handleUpdate = useCallback((id, value) => {
    updateData(id, value);
  }, [updateData]); // updateData 변경 시만 재생성

  return (
    <ChildComponent onClick={handleClick} onUpdate={handleUpdate} />
  );
}
```

### 2. 가상화 (Virtualization)

```tsx
// react-window 사용 - 긴 리스트 최적화
import { FixedSizeList } from 'react-window';
import AutoSizer from 'react-virtualized-auto-sizer';

function VirtualList({ items }) {
  const Row = ({ index, style }) => (
    <div style={style}>
      <ListItem item={items[index]} />
    </div>
  );

  return (
    <AutoSizer>
      {({ height, width }) => (
        <FixedSizeList
          height={height}
          width={width}
          itemCount={items.length}
          itemSize={80} // 각 아이템 높이
          overscanCount={5} // 추가 렌더링할 아이템 수
        >
          {Row}
        </FixedSizeList>
      )}
    </AutoSizer>
  );
}

// 무한 스크롤 with Intersection Observer
function InfiniteList() {
  const [items, setItems] = useState([]);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(false);
  const observerTarget = useRef(null);

  useEffect(() => {
    const observer = new IntersectionObserver(
      entries => {
        if (entries[0].isIntersecting && !loading) {
          loadMore();
        }
      },
      { threshold: 0.1 }
    );

    if (observerTarget.current) {
      observer.observe(observerTarget.current);
    }

    return () => observer.disconnect();
  }, [loading]);

  const loadMore = async () => {
    setLoading(true);
    const newItems = await fetchItems(page);
    setItems(prev => [...prev, ...newItems]);
    setPage(prev => prev + 1);
    setLoading(false);
  };

  return (
    <>
      {items.map(item => <Item key={item.id} {...item} />)}
      <div ref={observerTarget} />
      {loading && <Spinner />}
    </>
  );
}
```

### 3. 상태 최적화

```tsx
// 상태 분리 - 불필요한 리렌더링 방지
function BadExample() {
  const [state, setState] = useState({
    user: null,
    posts: [],
    comments: [],
  });

  // user 변경 시 posts, comments도 리렌더링
  const updateUser = (user) => {
    setState(prev => ({ ...prev, user }));
  };
}

function GoodExample() {
  const [user, setUser] = useState(null);
  const [posts, setPosts] = useState([]);
  const [comments, setComments] = useState([]);

  // user 변경 시 user 컴포넌트만 리렌더링
  const updateUser = (user) => {
    setUser(user);
  };
}

// useReducer로 복잡한 상태 관리
function ComplexState() {
  const [state, dispatch] = useReducer(reducer, initialState);

  // 배치 업데이트
  const updateMultiple = () => {
    dispatch({ type: 'UPDATE_USER', payload: userData });
    dispatch({ type: 'UPDATE_POSTS', payload: postsData });
    // React 18은 자동 배칭
  };
}
```

---

## 번들 최적화

### 1. 번들 분석

```bash
# 번들 분석 도구 설치
npm install @next/bundle-analyzer

# next.config.js
const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true',
});

module.exports = withBundleAnalyzer({
  // 설정
});

# 실행
ANALYZE=true npm run build
```

### 2. Tree Shaking

```javascript
// ❌ Bad - 전체 라이브러리 임포트
import _ from 'lodash';
const result = _.debounce(fn, 300);

// ✅ Good - 필요한 것만 임포트
import debounce from 'lodash/debounce';
const result = debounce(fn, 300);

// 또는 ES6 모듈
import { debounce } from 'lodash-es';

// package.json - sideEffects 설정
{
  "sideEffects": false, // Tree shaking 활성화
  // 또는 특정 파일만 제외
  "sideEffects": ["*.css", "*.scss"]
}
```

### 3. 동적 임포트 패턴

```typescript
// 라우트 기반 스플리팅
const routes = [
  {
    path: '/admin',
    component: lazy(() => import('./pages/Admin')),
  },
  {
    path: '/dashboard',
    component: lazy(() => import('./pages/Dashboard')),
  },
];

// 조건부 폴리필 로딩
if (!window.IntersectionObserver) {
  import('intersection-observer').then(() => {
    // 폴리필 로드 후 실행
  });
}

// 사용자 액션 기반 로딩
button.addEventListener('click', async () => {
  const module = await import('./heavy-module');
  module.doSomething();
});
```

---

## 네트워크 최적화

### 1. API 호출 최적화

```typescript
// 요청 중복 제거 (Request Deduplication)
const cache = new Map();

async function fetchWithCache(url: string) {
  if (cache.has(url)) {
    return cache.get(url);
  }

  const promise = fetch(url).then(r => r.json());
  cache.set(url, promise);

  // 캐시 정리
  setTimeout(() => cache.delete(url), 60000);

  return promise;
}

// 배치 요청
class BatchLoader {
  private queue: string[] = [];
  private timer: NodeJS.Timeout | null = null;

  load(id: string): Promise<any> {
    return new Promise((resolve) => {
      this.queue.push({ id, resolve });

      if (!this.timer) {
        this.timer = setTimeout(() => this.flush(), 50);
      }
    });
  }

  private async flush() {
    const batch = this.queue.splice(0);
    const results = await fetch('/api/batch', {
      method: 'POST',
      body: JSON.stringify({ ids: batch.map(b => b.id) }),
    }).then(r => r.json());

    batch.forEach(({ resolve }, i) => resolve(results[i]));
    this.timer = null;
  }
}
```

### 2. 프리페칭 전략

```tsx
// Link 프리페칭
import Link from 'next/link';

<Link href="/about" prefetch={true}>
  About
</Link>

// 프로그래매틱 프리페칭
import { useRouter } from 'next/router';

function Component() {
  const router = useRouter();

  useEffect(() => {
    // 사용자가 보고 있을 가능성이 높은 페이지 프리페치
    router.prefetch('/dashboard');
  }, []);

  // hover 시 프리페치
  const handleMouseEnter = () => {
    router.prefetch('/expensive-page');
  };
}

// Resource hints
<link rel="dns-prefetch" href="https://api.example.com" />
<link rel="preconnect" href="https://api.example.com" />
<link rel="prefetch" href="/critical-data.json" />
<link rel="preload" href="/fonts/main.woff2" as="font" type="font/woff2" crossorigin />
```

---

## 런타임 성능 최적화

### 1. Web Workers

```typescript
// worker.ts
self.addEventListener('message', (event) => {
  const result = heavyComputation(event.data);
  self.postMessage(result);
});

// main.ts
const worker = new Worker('/worker.js');

worker.postMessage({ cmd: 'process', data: largeData });

worker.addEventListener('message', (event) => {
  console.log('Result:', event.data);
});

// React Hook
function useWebWorker(workerFunction: Function) {
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);
  const workerRef = useRef<Worker>();

  useEffect(() => {
    const blob = new Blob([`(${workerFunction.toString()})()`], {
      type: 'application/javascript',
    });
    const workerUrl = URL.createObjectURL(blob);
    workerRef.current = new Worker(workerUrl);

    workerRef.current.onmessage = (e) => setResult(e.data);
    workerRef.current.onerror = (e) => setError(e);

    return () => {
      workerRef.current?.terminate();
      URL.revokeObjectURL(workerUrl);
    };
  }, []);

  const run = useCallback((data) => {
    workerRef.current?.postMessage(data);
  }, []);

  return { result, error, run };
}
```

### 2. 디바운싱 & 쓰로틀링

```typescript
// 디바운스 훅
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => clearTimeout(handler);
  }, [value, delay]);

  return debouncedValue;
}

// 사용
function SearchComponent() {
  const [searchTerm, setSearchTerm] = useState('');
  const debouncedSearch = useDebounce(searchTerm, 500);

  useEffect(() => {
    if (debouncedSearch) {
      searchAPI(debouncedSearch);
    }
  }, [debouncedSearch]);
}

// 쓰로틀 훅
function useThrottle<T>(value: T, delay: number): T {
  const [throttledValue, setThrottledValue] = useState<T>(value);
  const lastRan = useRef(Date.now());

  useEffect(() => {
    const handler = setTimeout(() => {
      if (Date.now() - lastRan.current >= delay) {
        setThrottledValue(value);
        lastRan.current = Date.now();
      }
    }, delay - (Date.now() - lastRan.current));

    return () => clearTimeout(handler);
  }, [value, delay]);

  return throttledValue;
}
```

---

## 모니터링

### 1. Performance API

```typescript
// 성능 측정
function measurePerformance() {
  // Navigation Timing
  const navigation = performance.getEntriesByType('navigation')[0];
  console.log('Page Load Time:', navigation.loadEventEnd - navigation.fetchStart);

  // Resource Timing
  const resources = performance.getEntriesByType('resource');
  resources.forEach(resource => {
    console.log(`${resource.name}: ${resource.duration}ms`);
  });

  // User Timing
  performance.mark('myTask-start');
  // ... 작업 수행
  performance.mark('myTask-end');
  performance.measure('myTask', 'myTask-start', 'myTask-end');

  const measure = performance.getEntriesByName('myTask')[0];
  console.log(`Task took ${measure.duration}ms`);
}

// React DevTools Profiler
import { Profiler } from 'react';

function onRenderCallback(id, phase, actualDuration) {
  console.log(`${id} (${phase}) took ${actualDuration}ms`);
}

<Profiler id="Navigation" onRender={onRenderCallback}>
  <Navigation />
</Profiler>
```

### 2. Lighthouse CI

```yaml
# .github/workflows/lighthouse.yml
name: Lighthouse CI
on: [push]

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm ci
      - run: npm run build

      - name: Run Lighthouse CI
        uses: treosh/lighthouse-ci-action@v9
        with:
          urls: |
            http://localhost:3000
            http://localhost:3000/about
          budgetPath: ./lighthouse-budget.json
          uploadArtifacts: true

# lighthouse-budget.json
{
  "path": "/*",
  "resourceSizes": [
    { "resourceType": "script", "budget": 300 },
    { "resourceType": "total", "budget": 500 }
  ],
  "resourceCounts": [
    { "resourceType": "third-party", "budget": 10 }
  ]
}
```

---

## 성능 체크리스트

### 초기 로드
- [ ] Critical CSS 인라인
- [ ] 폰트 프리로드
- [ ] 이미지 lazy loading
- [ ] 번들 사이즈 < 200KB (gzipped)
- [ ] 코드 스플리팅 적용

### 런타임
- [ ] 메모이제이션 적용
- [ ] 가상화 구현 (긴 리스트)
- [ ] 디바운싱/쓰로틀링
- [ ] Web Worker 활용

### 네트워크
- [ ] API 응답 캐싱
- [ ] CDN 사용
- [ ] Brotli/Gzip 압축
- [ ] HTTP/2 또는 HTTP/3

### 모니터링
- [ ] Core Web Vitals 측정
- [ ] 에러 트래킹
- [ ] 성능 예산 설정
- [ ] A/B 테스트

---

이 스킬은 성능 최적화 작업 시 자동으로 활성화되며,
웹 애플리케이션의 로딩 속도와 런타임 성능을 개선합니다.