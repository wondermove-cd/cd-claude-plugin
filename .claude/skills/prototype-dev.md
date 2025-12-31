# 프로토타입 개발 스킬

> 빠른 프로토타입 개발을 위한 베스트 프랙티스와 보일러플레이트 코드 제공

## 자동 활성화 조건
- 프로토타입, POC, MVP 개발
- Next.js/React 프로젝트 시작
- "빠른 개발", "데모", "시연" 키워드

## 핵심 원칙

### 1. 시작은 간단하게
- 복잡한 설정보다 빠른 실행 우선
- 기본 제공 기능 최대한 활용
- 외부 라이브러리는 필수적인 것만

### 2. 점진적 복잡도
- 기본 기능 먼저 구현
- 필요할 때 리팩토링
- 과도한 최적화 지양

---

## 프로젝트 초기 설정

### Next.js 프로젝트 생성

```bash
# TypeScript + Tailwind + App Router
npx create-next-app@latest my-app --typescript --tailwind --app

# 추가 권장 설정
cd my-app
npm install @tanstack/react-query axios zod react-hook-form @hookform/resolvers
```

### 프로젝트 구조

```
src/
├── app/                    # App Router
│   ├── layout.tsx         # 루트 레이아웃
│   ├── page.tsx          # 홈페이지
│   ├── api/              # API Routes
│   │   └── [...]
│   └── (routes)/         # 그룹화된 라우트
├── components/           # 컴포넌트
│   ├── ui/              # shadcn/ui 컴포넌트
│   ├── layout/          # 레이아웃 컴포넌트
│   └── features/        # 기능별 컴포넌트
├── lib/                 # 유틸리티
│   ├── api.ts          # API 클라이언트
│   ├── utils.ts        # 헬퍼 함수
│   └── hooks/          # 커스텀 훅
├── types/              # TypeScript 타입
└── styles/             # 글로벌 스타일
```

---

## 빠른 개발 패턴

### 1. API 클라이언트 설정

```typescript
// lib/api.ts
import axios from 'axios';

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || '/api',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// 요청 인터셉터
api.interceptors.request.use(
  (config) => {
    // 토큰 자동 추가
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// 응답 인터셉터
api.interceptors.response.use(
  (response) => response.data,
  (error) => {
    if (error.response?.status === 401) {
      // 로그아웃 처리
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;
```

### 2. React Query 설정

```typescript
// app/providers.tsx
'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import { useState } from 'react';

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () => new QueryClient({
      defaultOptions: {
        queries: {
          staleTime: 60 * 1000, // 1분
          gcTime: 5 * 60 * 1000, // 5분 (이전 cacheTime)
          retry: 1,
          refetchOnWindowFocus: false,
        },
      },
    })
  );

  return (
    <QueryClientProvider client={queryClient}>
      {children}
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  );
}
```

### 3. 데이터 페칭 훅

```typescript
// lib/hooks/useApi.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '@/lib/api';

// GET 요청
export function useApiGet<T>(
  key: string | string[],
  url: string,
  options = {}
) {
  return useQuery<T>({
    queryKey: Array.isArray(key) ? key : [key],
    queryFn: () => api.get(url),
    ...options,
  });
}

// POST 요청
export function useApiPost<T, V>(
  url: string,
  options = {}
) {
  const queryClient = useQueryClient();

  return useMutation<T, Error, V>({
    mutationFn: (data: V) => api.post(url, data),
    onSuccess: () => {
      // 관련 쿼리 무효화
      queryClient.invalidateQueries();
    },
    ...options,
  });
}

// 사용 예시
export function useUsers() {
  return useApiGet<User[]>('users', '/users');
}

export function useCreateUser() {
  return useApiPost<User, CreateUserDto>('/users');
}
```

### 4. 폼 처리 패턴

```tsx
// components/forms/UserForm.tsx
'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';

const formSchema = z.object({
  name: z.string().min(2, '이름은 2자 이상'),
  email: z.string().email('올바른 이메일 형식이 아닙니다'),
  password: z.string().min(8, '비밀번호는 8자 이상'),
});

type FormData = z.infer<typeof formSchema>;

export function UserForm({ onSubmit }: { onSubmit: (data: FormData) => void }) {
  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      name: '',
      email: '',
      password: '',
    },
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel>이름</FormLabel>
              <FormControl>
                <Input placeholder="홍길동" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>이메일</FormLabel>
              <FormControl>
                <Input type="email" placeholder="email@example.com" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <Button type="submit" disabled={form.formState.isSubmitting}>
          {form.formState.isSubmitting ? '저장 중...' : '저장'}
        </Button>
      </form>
    </Form>
  );
}
```

### 5. 로딩/에러 처리 패턴

```tsx
// components/DataDisplay.tsx
'use client';

import { Skeleton } from '@/components/ui/skeleton';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { AlertCircle } from 'lucide-react';

interface DataDisplayProps<T> {
  data: T | undefined;
  isLoading: boolean;
  error: Error | null;
  children: (data: T) => React.ReactNode;
  loadingFallback?: React.ReactNode;
  errorFallback?: React.ReactNode;
  emptyFallback?: React.ReactNode;
}

export function DataDisplay<T>({
  data,
  isLoading,
  error,
  children,
  loadingFallback,
  errorFallback,
  emptyFallback = <p>데이터가 없습니다</p>,
}: DataDisplayProps<T>) {
  if (isLoading) {
    return loadingFallback || <DefaultLoader />;
  }

  if (error) {
    return errorFallback || <DefaultError error={error} />;
  }

  if (!data || (Array.isArray(data) && data.length === 0)) {
    return emptyFallback;
  }

  return <>{children(data)}</>;
}

function DefaultLoader() {
  return (
    <div className="space-y-3">
      <Skeleton className="h-4 w-full" />
      <Skeleton className="h-4 w-3/4" />
      <Skeleton className="h-4 w-1/2" />
    </div>
  );
}

function DefaultError({ error }: { error: Error }) {
  return (
    <Alert variant="destructive">
      <AlertCircle className="h-4 w-4" />
      <AlertDescription>
        {error.message || '데이터를 불러오는 중 오류가 발생했습니다.'}
      </AlertDescription>
    </Alert>
  );
}
```

### 6. 인증 처리

```tsx
// lib/auth.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface User {
  id: string;
  email: string;
  name: string;
}

interface AuthState {
  user: User | null;
  token: string | null;
  login: (user: User, token: string) => void;
  logout: () => void;
  isAuthenticated: () => boolean;
}

export const useAuth = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      login: (user, token) => {
        set({ user, token });
        localStorage.setItem('token', token);
      },
      logout: () => {
        set({ user: null, token: null });
        localStorage.removeItem('token');
      },
      isAuthenticated: () => !!get().token,
    }),
    {
      name: 'auth-storage',
    }
  )
);

// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const token = request.cookies.get('token');
  const isAuthPage = request.nextUrl.pathname.startsWith('/login');

  if (!token && !isAuthPage) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  if (token && isAuthPage) {
    return NextResponse.redirect(new URL('/dashboard', request.url));
  }
}

export const config = {
  matcher: ['/dashboard/:path*', '/login'],
};
```

### 7. 실시간 데이터 (WebSocket)

```typescript
// lib/websocket.ts
import { useEffect, useState } from 'react';

export function useWebSocket(url: string) {
  const [socket, setSocket] = useState<WebSocket | null>(null);
  const [lastMessage, setLastMessage] = useState<any>(null);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    const ws = new WebSocket(url);

    ws.onopen = () => {
      setIsConnected(true);
      console.log('WebSocket Connected');
    };

    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      setLastMessage(data);
    };

    ws.onclose = () => {
      setIsConnected(false);
      console.log('WebSocket Disconnected');
    };

    ws.onerror = (error) => {
      console.error('WebSocket Error:', error);
    };

    setSocket(ws);

    return () => {
      ws.close();
    };
  }, [url]);

  const sendMessage = (message: any) => {
    if (socket?.readyState === WebSocket.OPEN) {
      socket.send(JSON.stringify(message));
    }
  };

  return { sendMessage, lastMessage, isConnected };
}
```

---

## 빠른 UI 구성

### 1. 대시보드 레이아웃

```tsx
// app/dashboard/layout.tsx
export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex h-screen">
      {/* 사이드바 */}
      <aside className="w-64 bg-gray-900 text-white p-4">
        <nav className="space-y-2">
          <Link href="/dashboard" className="block p-2 hover:bg-gray-800 rounded">
            대시보드
          </Link>
          <Link href="/dashboard/users" className="block p-2 hover:bg-gray-800 rounded">
            사용자 관리
          </Link>
        </nav>
      </aside>

      {/* 메인 콘텐츠 */}
      <main className="flex-1 overflow-auto">
        {/* 헤더 */}
        <header className="bg-white shadow-sm p-4 border-b">
          <h1 className="text-2xl font-bold">관리자 대시보드</h1>
        </header>

        {/* 콘텐츠 영역 */}
        <div className="p-6">
          {children}
        </div>
      </main>
    </div>
  );
}
```

### 2. 데이터 테이블

```tsx
// components/DataTable.tsx
'use client';

import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useState } from 'react';

interface Column<T> {
  key: keyof T;
  header: string;
  render?: (value: any, item: T) => React.ReactNode;
}

interface DataTableProps<T> {
  data: T[];
  columns: Column<T>[];
  searchable?: boolean;
  onRowClick?: (item: T) => void;
}

export function DataTable<T extends Record<string, any>>({
  data,
  columns,
  searchable = false,
  onRowClick,
}: DataTableProps<T>) {
  const [search, setSearch] = useState('');

  const filteredData = searchable
    ? data.filter(item =>
        Object.values(item).some(value =>
          String(value).toLowerCase().includes(search.toLowerCase())
        )
      )
    : data;

  return (
    <div className="space-y-4">
      {searchable && (
        <Input
          placeholder="검색..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="max-w-sm"
        />
      )}

      <div className="rounded-md border">
        <Table>
          <TableHeader>
            <TableRow>
              {columns.map((column) => (
                <TableHead key={String(column.key)}>
                  {column.header}
                </TableHead>
              ))}
            </TableRow>
          </TableHeader>
          <TableBody>
            {filteredData.map((item, index) => (
              <TableRow
                key={index}
                onClick={() => onRowClick?.(item)}
                className={onRowClick ? 'cursor-pointer hover:bg-gray-50' : ''}
              >
                {columns.map((column) => (
                  <TableCell key={String(column.key)}>
                    {column.render
                      ? column.render(item[column.key], item)
                      : String(item[column.key])}
                  </TableCell>
                ))}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}
```

---

## 모바일 반응형

### 반응형 네비게이션

```tsx
// components/MobileNav.tsx
'use client';

import { useState } from 'react';
import { Menu, X } from 'lucide-react';
import { Sheet, SheetContent, SheetTrigger } from '@/components/ui/sheet';

export function MobileNav() {
  const [open, setOpen] = useState(false);

  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger asChild>
        <Button variant="ghost" size="icon" className="md:hidden">
          <Menu className="h-5 w-5" />
        </Button>
      </SheetTrigger>
      <SheetContent side="left" className="w-64">
        <nav className="flex flex-col space-y-4">
          <Link href="/" onClick={() => setOpen(false)}>
            홈
          </Link>
          <Link href="/about" onClick={() => setOpen(false)}>
            소개
          </Link>
        </nav>
      </SheetContent>
    </Sheet>
  );
}
```

---

## 배포 준비

### 1. 환경 변수 설정

```bash
# .env.local
NEXT_PUBLIC_API_URL=https://api.example.com
DATABASE_URL=postgresql://user:password@localhost:5432/db
JWT_SECRET=your-secret-key
```

### 2. Docker 설정

```dockerfile
# Dockerfile
FROM node:18-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --only=production

FROM node:18-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:18-alpine AS runner
WORKDIR /app
ENV NODE_ENV production
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
EXPOSE 3000
CMD ["node", "server.js"]
```

### 3. Vercel 배포

```json
// vercel.json
{
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "devCommand": "npm run dev",
  "installCommand": "npm install",
  "framework": "nextjs"
}
```

---

## 성능 최적화 체크리스트

- [ ] 이미지 최적화 (next/image 사용)
- [ ] 폰트 최적화 (next/font 사용)
- [ ] 코드 스플리팅 (dynamic imports)
- [ ] API 라우트 캐싱
- [ ] 정적 페이지 생성 (generateStaticParams)
- [ ] React.memo 적용
- [ ] useMemo/useCallback 최적화
- [ ] 번들 사이즈 분석 (next-bundle-analyzer)

---

## 디버깅 도구

```typescript
// lib/debug.ts
export const debug = {
  log: (...args: any[]) => {
    if (process.env.NODE_ENV === 'development') {
      console.log('[DEBUG]', ...args);
    }
  },
  error: (...args: any[]) => {
    console.error('[ERROR]', ...args);
  },
  table: (data: any) => {
    if (process.env.NODE_ENV === 'development') {
      console.table(data);
    }
  },
  time: (label: string) => {
    if (process.env.NODE_ENV === 'development') {
      console.time(label);
    }
  },
  timeEnd: (label: string) => {
    if (process.env.NODE_ENV === 'development') {
      console.timeEnd(label);
    }
  },
};
```

---

이 스킬은 프로토타입 개발 시 자동으로 활성화되며,
빠른 개발을 위한 보일러플레이트 코드와 패턴을 제공합니다.