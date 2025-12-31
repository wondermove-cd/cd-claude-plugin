---
description: 프로토타입 개발을 위한 프로젝트 초기 설정 및 보일러플레이트 생성
allowed-tools: Read, Write, Edit, Bash
argument-hint: [프로젝트명]
---

# 프로토타입 개발 초기화

## 목적

빠른 프로토타입 개발을 위한 Next.js/React 프로젝트 설정 및 필수 패키지 설치

## 워크플로우

```mermaid
flowchart LR
    A["/dev-prototype"] --> B["프로젝트 생성"]
    B --> C["패키지 설치"]
    C --> D["기본 구조 생성"]
    D --> E["개발 서버 실행"]
```

## 실행 절차

### Step 1: 프로젝트 타입 확인

```bash
# package.json 확인
ls package.json
```

- 있으면: 기존 프로젝트에 추가
- 없으면: 새 프로젝트 생성

### Step 2: Next.js 프로젝트 생성

새 프로젝트인 경우:

```bash
npx create-next-app@latest . \
  --typescript \
  --tailwind \
  --app \
  --src-dir \
  --import-alias "@/*" \
  --use-npm
```

### Step 3: 필수 패키지 설치

#### 개발 관련 패키지

```bash
# UI 컴포넌트
npx shadcn-ui@latest init
npx shadcn-ui@latest add button card form input table

# 상태 관리 & 데이터 페칭
npm install @tanstack/react-query zustand axios

# 폼 & 검증
npm install react-hook-form @hookform/resolvers zod

# 유틸리티
npm install clsx tailwind-merge date-fns

# 개발 도구
npm install -D @types/node prettier eslint-config-prettier
```

#### 테스트 도구

```bash
# 테스트 프레임워크
npm install -D jest @testing-library/react @testing-library/jest-dom
npm install -D @testing-library/user-event jest-environment-jsdom

# E2E 테스트
npm install -D @playwright/test
```

### Step 4: 프로젝트 구조 생성

```
src/
├── app/
│   ├── layout.tsx
│   ├── page.tsx
│   ├── providers.tsx         # React Query, Zustand 프로바이더
│   └── api/
│       └── [...]/route.ts
├── components/
│   ├── ui/                  # shadcn/ui 컴포넌트
│   ├── layout/
│   │   ├── Header.tsx
│   │   ├── Footer.tsx
│   │   └── Sidebar.tsx
│   └── features/            # 기능별 컴포넌트
├── lib/
│   ├── api.ts              # API 클라이언트
│   ├── utils.ts            # 유틸리티 함수
│   ├── hooks/              # 커스텀 훅
│   └── store/              # Zustand 스토어
├── types/                  # TypeScript 타입
└── styles/
    └── globals.css
```

### Step 5: 기본 파일 생성

#### API 클라이언트 (lib/api.ts)

```typescript
import axios from 'axios';

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || '/api',
  timeout: 10000,
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response.data,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;
```

#### Providers (app/providers.tsx)

```typescript
'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import { useState } from 'react';

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () => new QueryClient({
      defaultOptions: {
        queries: {
          staleTime: 60 * 1000,
          gcTime: 5 * 60 * 1000,
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

#### 유틸리티 (lib/utils.ts)

```typescript
import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatDate(date: Date | string) {
  return new Intl.DateTimeFormat('ko-KR').format(new Date(date));
}

export function sleep(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

### Step 6: 스크립트 설정

package.json에 추가:

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:e2e": "playwright test",
    "format": "prettier --write ."
  }
}
```

### Step 7: 환경 변수 설정

.env.local 생성:

```bash
# API
NEXT_PUBLIC_API_URL=http://localhost:3000/api

# 인증
JWT_SECRET=your-secret-key-change-in-production

# 데이터베이스 (필요시)
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
```

### Step 8: Git 설정

```bash
git init
git add .
git commit -m "Initial prototype setup"
```

---

## 완료 보고

```
============================================
 [DEV PROTOTYPE] 프로토타입 환경 구성 완료
============================================

 프로젝트: {프로젝트명}

 설치된 패키지:
 ✅ Next.js 14 (App Router)
 ✅ TypeScript
 ✅ Tailwind CSS
 ✅ shadcn/ui
 ✅ React Query
 ✅ Zustand
 ✅ React Hook Form + Zod

 생성된 구조:
 • src/app - 라우팅
 • src/components - 컴포넌트
 • src/lib - 유틸리티
 • src/types - 타입 정의

 다음 단계:
 1. 개발 서버 실행: npm run dev
 2. shadcn 컴포넌트 추가: npx shadcn-ui@latest add [component]
 3. API 라우트 생성: /api-design
 4. 테스트 작성: /test-setup

============================================
```

---

## 추가 옵션

### 데이터베이스 설정

Prisma 사용 시:

```bash
npm install prisma @prisma/client
npx prisma init
```

### 인증 설정

NextAuth 사용 시:

```bash
npm install next-auth
npm install @auth/prisma-adapter
```

### 스타일링 옵션

```bash
# Styled Components
npm install styled-components

# Emotion
npm install @emotion/react @emotion/styled

# Framer Motion
npm install framer-motion
```

---

## 자동 활성화 스킬

이 명령어 실행 시 자동으로 활성화:

- `prototype-dev` - 프로토타입 개발 패턴
- `shadcn-ui` - UI 컴포넌트 가이드
- `api-design` - API 설계 패턴