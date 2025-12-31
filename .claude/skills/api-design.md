# API 설계 스킬

> RESTful API, GraphQL, tRPC 설계 및 문서화 자동화

## 자동 활성화 조건
- API 설계, 백엔드 개발
- OpenAPI, Swagger 언급
- GraphQL, tRPC 사용
- "API", "엔드포인트", "REST" 키워드

## API 설계 원칙

### RESTful API 원칙
1. **Resource-Based**: URL은 리소스를 나타냄
2. **HTTP Methods**: GET, POST, PUT, PATCH, DELETE 적절히 사용
3. **Stateless**: 각 요청은 독립적
4. **Consistent**: 일관된 네이밍과 구조
5. **Versioning**: API 버전 관리

---

## RESTful API 설계

### 1. URL 구조 설계

```
# 리소스 네이밍 규칙
/api/v1/users                 # 사용자 목록
/api/v1/users/{id}           # 특정 사용자
/api/v1/users/{id}/posts     # 사용자의 게시물
/api/v1/posts?author={id}    # 쿼리 파라미터

# HTTP Methods
GET    /users     # 목록 조회
GET    /users/1   # 상세 조회
POST   /users     # 생성
PUT    /users/1   # 전체 수정
PATCH  /users/1   # 부분 수정
DELETE /users/1   # 삭제
```

### 2. Next.js API Routes

```typescript
// app/api/v1/users/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { prisma } from '@/lib/prisma';

// 요청 스키마 정의
const CreateUserSchema = z.object({
  name: z.string().min(2).max(50),
  email: z.string().email(),
  role: z.enum(['admin', 'user', 'guest']).optional(),
});

const QuerySchema = z.object({
  page: z.coerce.number().min(1).default(1),
  limit: z.coerce.number().min(1).max(100).default(10),
  sort: z.enum(['name', 'email', 'createdAt']).default('createdAt'),
  order: z.enum(['asc', 'desc']).default('desc'),
  search: z.string().optional(),
});

// GET /api/v1/users
export async function GET(request: NextRequest) {
  try {
    // 쿼리 파라미터 파싱
    const searchParams = Object.fromEntries(request.nextUrl.searchParams);
    const query = QuerySchema.parse(searchParams);

    // 페이지네이션 계산
    const skip = (query.page - 1) * query.limit;

    // 검색 조건
    const where = query.search
      ? {
          OR: [
            { name: { contains: query.search, mode: 'insensitive' } },
            { email: { contains: query.search, mode: 'insensitive' } },
          ],
        }
      : {};

    // 데이터 조회
    const [users, total] = await prisma.$transaction([
      prisma.user.findMany({
        where,
        skip,
        take: query.limit,
        orderBy: { [query.sort]: query.order },
        select: {
          id: true,
          name: true,
          email: true,
          role: true,
          createdAt: true,
        },
      }),
      prisma.user.count({ where }),
    ]);

    // 응답 헤더 설정
    return NextResponse.json(
      {
        data: users,
        meta: {
          total,
          page: query.page,
          limit: query.limit,
          totalPages: Math.ceil(total / query.limit),
        },
      },
      {
        headers: {
          'X-Total-Count': total.toString(),
          'Cache-Control': 's-maxage=10, stale-while-revalidate',
        },
      }
    );
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Invalid query parameters', details: error.errors },
        { status: 400 }
      );
    }

    console.error('GET /api/v1/users error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

// POST /api/v1/users
export async function POST(request: NextRequest) {
  try {
    // 인증 확인
    const token = request.headers.get('authorization')?.replace('Bearer ', '');
    if (!token) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // 요청 바디 파싱
    const body = await request.json();
    const data = CreateUserSchema.parse(body);

    // 중복 확인
    const existing = await prisma.user.findUnique({
      where: { email: data.email },
    });

    if (existing) {
      return NextResponse.json(
        { error: 'Email already exists' },
        { status: 409 }
      );
    }

    // 사용자 생성
    const user = await prisma.user.create({
      data: {
        ...data,
        password: await hash(body.password), // bcrypt
      },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        createdAt: true,
      },
    });

    return NextResponse.json(user, { status: 201 });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Validation failed', details: error.errors },
        { status: 400 }
      );
    }

    console.error('POST /api/v1/users error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
```

### 3. 동적 라우트 처리

```typescript
// app/api/v1/users/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server';

// GET /api/v1/users/[id]
export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await prisma.user.findUnique({
      where: { id: params.id },
      include: {
        posts: {
          take: 5,
          orderBy: { createdAt: 'desc' },
        },
        _count: {
          select: { posts: true, comments: true },
        },
      },
    });

    if (!user) {
      return NextResponse.json(
        { error: 'User not found' },
        { status: 404 }
      );
    }

    // ETag 생성
    const etag = `"${Buffer.from(JSON.stringify(user)).toString('base64')}"`;

    // 조건부 요청 처리
    if (request.headers.get('if-none-match') === etag) {
      return new NextResponse(null, { status: 304 });
    }

    return NextResponse.json(user, {
      headers: {
        'ETag': etag,
        'Cache-Control': 'private, max-age=60',
      },
    });
  } catch (error) {
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

// PATCH /api/v1/users/[id]
export async function PATCH(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const body = await request.json();

    const UpdateSchema = z.object({
      name: z.string().min(2).optional(),
      email: z.string().email().optional(),
      bio: z.string().max(500).optional(),
    });

    const data = UpdateSchema.parse(body);

    const user = await prisma.user.update({
      where: { id: params.id },
      data,
    });

    return NextResponse.json(user);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Validation failed', details: error.errors },
        { status: 400 }
      );
    }

    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

// DELETE /api/v1/users/[id]
export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    await prisma.user.delete({
      where: { id: params.id },
    });

    return new NextResponse(null, { status: 204 });
  } catch (error) {
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
```

---

## GraphQL API

### 1. Schema 정의

```graphql
# schema.graphql
type User {
  id: ID!
  name: String!
  email: String!
  posts: [Post!]!
  createdAt: DateTime!
  updatedAt: DateTime!
}

type Post {
  id: ID!
  title: String!
  content: String!
  author: User!
  comments: [Comment!]!
  published: Boolean!
  createdAt: DateTime!
}

type Comment {
  id: ID!
  content: String!
  author: User!
  post: Post!
  createdAt: DateTime!
}

type Query {
  users(page: Int, limit: Int, search: String): UserConnection!
  user(id: ID!): User
  posts(filter: PostFilter): [Post!]!
  post(id: ID!): Post
}

type Mutation {
  createUser(input: CreateUserInput!): User!
  updateUser(id: ID!, input: UpdateUserInput!): User!
  deleteUser(id: ID!): Boolean!

  createPost(input: CreatePostInput!): Post!
  publishPost(id: ID!): Post!
}

type Subscription {
  postCreated: Post!
  commentAdded(postId: ID!): Comment!
}

input CreateUserInput {
  name: String!
  email: String!
  password: String!
}

input PostFilter {
  published: Boolean
  authorId: ID
  search: String
}

type UserConnection {
  edges: [UserEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type UserEdge {
  node: User!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}
```

### 2. GraphQL Resolvers

```typescript
// lib/graphql/resolvers.ts
import { GraphQLError } from 'graphql';
import { prisma } from '@/lib/prisma';

export const resolvers = {
  Query: {
    users: async (_: any, args: any, context: any) => {
      const { page = 1, limit = 10, search } = args;

      const where = search
        ? {
            OR: [
              { name: { contains: search, mode: 'insensitive' } },
              { email: { contains: search, mode: 'insensitive' } },
            ],
          }
        : {};

      const [users, totalCount] = await prisma.$transaction([
        prisma.user.findMany({
          where,
          skip: (page - 1) * limit,
          take: limit,
        }),
        prisma.user.count({ where }),
      ]);

      const edges = users.map((user) => ({
        node: user,
        cursor: Buffer.from(user.id).toString('base64'),
      }));

      return {
        edges,
        pageInfo: {
          hasNextPage: page * limit < totalCount,
          hasPreviousPage: page > 1,
          startCursor: edges[0]?.cursor,
          endCursor: edges[edges.length - 1]?.cursor,
        },
        totalCount,
      };
    },

    user: async (_: any, { id }: { id: string }) => {
      const user = await prisma.user.findUnique({
        where: { id },
      });

      if (!user) {
        throw new GraphQLError('User not found', {
          extensions: { code: 'USER_NOT_FOUND' },
        });
      }

      return user;
    },

    posts: async (_: any, { filter }: any) => {
      const where: any = {};

      if (filter?.published !== undefined) {
        where.published = filter.published;
      }

      if (filter?.authorId) {
        where.authorId = filter.authorId;
      }

      if (filter?.search) {
        where.OR = [
          { title: { contains: filter.search, mode: 'insensitive' } },
          { content: { contains: filter.search, mode: 'insensitive' } },
        ];
      }

      return prisma.post.findMany({
        where,
        orderBy: { createdAt: 'desc' },
      });
    },
  },

  Mutation: {
    createUser: async (_: any, { input }: any, context: any) => {
      // 인증 확인
      if (!context.user) {
        throw new GraphQLError('Unauthorized', {
          extensions: { code: 'UNAUTHORIZED' },
        });
      }

      // 중복 확인
      const existing = await prisma.user.findUnique({
        where: { email: input.email },
      });

      if (existing) {
        throw new GraphQLError('Email already exists', {
          extensions: { code: 'EMAIL_EXISTS' },
        });
      }

      return prisma.user.create({
        data: {
          ...input,
          password: await hash(input.password),
        },
      });
    },

    updateUser: async (_: any, { id, input }: any, context: any) => {
      // 권한 확인
      if (context.user.id !== id && context.user.role !== 'admin') {
        throw new GraphQLError('Forbidden', {
          extensions: { code: 'FORBIDDEN' },
        });
      }

      return prisma.user.update({
        where: { id },
        data: input,
      });
    },

    createPost: async (_: any, { input }: any, context: any) => {
      if (!context.user) {
        throw new GraphQLError('Unauthorized', {
          extensions: { code: 'UNAUTHORIZED' },
        });
      }

      const post = await prisma.post.create({
        data: {
          ...input,
          authorId: context.user.id,
        },
      });

      // 구독 알림
      pubsub.publish('POST_CREATED', { postCreated: post });

      return post;
    },
  },

  Subscription: {
    postCreated: {
      subscribe: () => pubsub.asyncIterator(['POST_CREATED']),
    },

    commentAdded: {
      subscribe: (_: any, { postId }: { postId: string }) =>
        pubsub.asyncIterator([`COMMENT_ADDED_${postId}`]),
    },
  },

  // Field Resolvers
  User: {
    posts: async (parent: any) => {
      return prisma.post.findMany({
        where: { authorId: parent.id },
      });
    },
  },

  Post: {
    author: async (parent: any) => {
      return prisma.user.findUnique({
        where: { id: parent.authorId },
      });
    },

    comments: async (parent: any) => {
      return prisma.comment.findMany({
        where: { postId: parent.id },
      });
    },
  },
};
```

---

## tRPC API

### 1. Router 설정

```typescript
// server/api/root.ts
import { createTRPCRouter } from '@/server/api/trpc';
import { userRouter } from '@/server/api/routers/user';
import { postRouter } from '@/server/api/routers/post';

export const appRouter = createTRPCRouter({
  user: userRouter,
  post: postRouter,
});

export type AppRouter = typeof appRouter;
```

### 2. Procedure 정의

```typescript
// server/api/routers/user.ts
import { z } from 'zod';
import { createTRPCRouter, publicProcedure, protectedProcedure } from '@/server/api/trpc';
import { TRPCError } from '@trpc/server';

export const userRouter = createTRPCRouter({
  // Query: 사용자 목록
  list: publicProcedure
    .input(
      z.object({
        page: z.number().min(1).default(1),
        limit: z.number().min(1).max(100).default(10),
        search: z.string().optional(),
      })
    )
    .query(async ({ ctx, input }) => {
      const { page, limit, search } = input;
      const skip = (page - 1) * limit;

      const where = search
        ? {
            OR: [
              { name: { contains: search, mode: 'insensitive' } },
              { email: { contains: search, mode: 'insensitive' } },
            ],
          }
        : {};

      const [users, total] = await ctx.prisma.$transaction([
        ctx.prisma.user.findMany({
          where,
          skip,
          take: limit,
          orderBy: { createdAt: 'desc' },
        }),
        ctx.prisma.user.count({ where }),
      ]);

      return {
        users,
        total,
        hasMore: skip + users.length < total,
      };
    }),

  // Query: 사용자 상세
  byId: publicProcedure
    .input(z.object({ id: z.string() }))
    .query(async ({ ctx, input }) => {
      const user = await ctx.prisma.user.findUnique({
        where: { id: input.id },
        include: {
          posts: true,
          _count: {
            select: { posts: true, comments: true },
          },
        },
      });

      if (!user) {
        throw new TRPCError({
          code: 'NOT_FOUND',
          message: 'User not found',
        });
      }

      return user;
    }),

  // Mutation: 사용자 생성
  create: protectedProcedure
    .input(
      z.object({
        name: z.string().min(2).max(50),
        email: z.string().email(),
        password: z.string().min(8),
      })
    )
    .mutation(async ({ ctx, input }) => {
      // 권한 확인
      if (ctx.session.user.role !== 'admin') {
        throw new TRPCError({
          code: 'FORBIDDEN',
          message: 'Only admins can create users',
        });
      }

      // 중복 확인
      const existing = await ctx.prisma.user.findUnique({
        where: { email: input.email },
      });

      if (existing) {
        throw new TRPCError({
          code: 'CONFLICT',
          message: 'Email already exists',
        });
      }

      return ctx.prisma.user.create({
        data: {
          ...input,
          password: await hash(input.password),
        },
      });
    }),

  // Mutation: 사용자 수정
  update: protectedProcedure
    .input(
      z.object({
        id: z.string(),
        name: z.string().min(2).optional(),
        email: z.string().email().optional(),
        bio: z.string().max(500).optional(),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const { id, ...data } = input;

      // 본인 또는 관리자만 수정 가능
      if (ctx.session.user.id !== id && ctx.session.user.role !== 'admin') {
        throw new TRPCError({
          code: 'FORBIDDEN',
          message: 'You can only update your own profile',
        });
      }

      return ctx.prisma.user.update({
        where: { id },
        data,
      });
    }),

  // Mutation: 사용자 삭제
  delete: protectedProcedure
    .input(z.object({ id: z.string() }))
    .mutation(async ({ ctx, input }) => {
      if (ctx.session.user.role !== 'admin') {
        throw new TRPCError({
          code: 'FORBIDDEN',
          message: 'Only admins can delete users',
        });
      }

      await ctx.prisma.user.delete({
        where: { id: input.id },
      });

      return { success: true };
    }),

  // Subscription: 실시간 업데이트
  onUpdate: publicProcedure.subscription(async ({ ctx }) => {
    return observable<User>((observer) => {
      const channel = ctx.redis.subscribe('user:update');

      channel.on('message', (_, message) => {
        observer.next(JSON.parse(message));
      });

      return () => {
        channel.unsubscribe();
      };
    });
  }),
});
```

### 3. 클라이언트 사용

```typescript
// app/users/page.tsx
'use client';

import { api } from '@/utils/api';

export default function UsersPage() {
  const [page, setPage] = useState(1);

  // Query
  const { data, isLoading, error } = api.user.list.useQuery({
    page,
    limit: 20,
  });

  // Mutation
  const createUser = api.user.create.useMutation({
    onSuccess: () => {
      // 캐시 무효화
      utils.user.list.invalidate();
      toast.success('User created successfully');
    },
    onError: (error) => {
      toast.error(error.message);
    },
  });

  // Optimistic update
  const updateUser = api.user.update.useMutation({
    onMutate: async (newData) => {
      // 이전 데이터 백업
      await utils.user.byId.cancel({ id: newData.id });
      const previousUser = utils.user.byId.getData({ id: newData.id });

      // Optimistic update
      utils.user.byId.setData({ id: newData.id }, (old) => ({
        ...old!,
        ...newData,
      }));

      return { previousUser };
    },
    onError: (err, newData, context) => {
      // 롤백
      utils.user.byId.setData(
        { id: newData.id },
        context?.previousUser
      );
    },
    onSettled: () => {
      utils.user.byId.invalidate();
    },
  });

  if (isLoading) return <Loading />;
  if (error) return <Error error={error} />;

  return (
    <div>
      {/* UI */}
    </div>
  );
}
```

---

## API 문서화

### 1. OpenAPI/Swagger

```typescript
// lib/swagger.ts
import { createSwaggerSpec } from 'next-swagger-doc';

export const getApiDocs = () => {
  const spec = createSwaggerSpec({
    definition: {
      openapi: '3.0.0',
      info: {
        title: 'My API',
        version: '1.0.0',
        description: 'API documentation',
      },
      servers: [
        {
          url: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000',
        },
      ],
      components: {
        securitySchemes: {
          BearerAuth: {
            type: 'http',
            scheme: 'bearer',
            bearerFormat: 'JWT',
          },
        },
      },
    },
    apis: ['./app/api/**/*.ts'],
  });

  return spec;
};

// app/api/docs/route.ts
import { NextResponse } from 'next/server';
import { getApiDocs } from '@/lib/swagger';

export async function GET() {
  const spec = getApiDocs();
  return NextResponse.json(spec);
}
```

### 2. API 주석으로 문서화

```typescript
/**
 * @swagger
 * /api/v1/users:
 *   get:
 *     summary: Get users list
 *     tags: [Users]
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           minimum: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *         description: Items per page
 *     responses:
 *       200:
 *         description: Success
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/User'
 *                 meta:
 *                   type: object
 *                   properties:
 *                     total:
 *                       type: integer
 *                     page:
 *                       type: integer
 *                     totalPages:
 *                       type: integer
 */
export async function GET(request: NextRequest) {
  // Implementation
}
```

---

## API 보안

### 1. Rate Limiting

```typescript
// middleware.ts
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '10 s'),
  analytics: true,
});

export async function middleware(request: NextRequest) {
  if (request.nextUrl.pathname.startsWith('/api')) {
    const ip = request.ip ?? '127.0.0.1';
    const { success, limit, reset, remaining } = await ratelimit.limit(ip);

    if (!success) {
      return NextResponse.json(
        { error: 'Too many requests' },
        {
          status: 429,
          headers: {
            'X-RateLimit-Limit': limit.toString(),
            'X-RateLimit-Remaining': remaining.toString(),
            'X-RateLimit-Reset': new Date(reset).toISOString(),
          },
        }
      );
    }
  }

  return NextResponse.next();
}
```

### 2. CORS 설정

```typescript
// lib/cors.ts
export const corsHeaders = {
  'Access-Control-Allow-Origin': process.env.ALLOWED_ORIGIN || '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Max-Age': '86400',
};

// API Route에 적용
export async function OPTIONS() {
  return new NextResponse(null, { status: 200, headers: corsHeaders });
}
```

---

## 에러 처리

### 표준 에러 응답

```typescript
// lib/api-error.ts
export class ApiError extends Error {
  constructor(
    public statusCode: number,
    public message: string,
    public details?: any
  ) {
    super(message);
  }

  static badRequest(message = 'Bad Request', details?: any) {
    return new ApiError(400, message, details);
  }

  static unauthorized(message = 'Unauthorized') {
    return new ApiError(401, message);
  }

  static forbidden(message = 'Forbidden') {
    return new ApiError(403, message);
  }

  static notFound(message = 'Not Found') {
    return new ApiError(404, message);
  }

  static conflict(message = 'Conflict', details?: any) {
    return new ApiError(409, message, details);
  }

  static tooManyRequests(message = 'Too Many Requests') {
    return new ApiError(429, message);
  }

  static internal(message = 'Internal Server Error') {
    return new ApiError(500, message);
  }
}

// 에러 핸들러
export function handleApiError(error: any) {
  if (error instanceof ApiError) {
    return NextResponse.json(
      {
        error: error.message,
        details: error.details,
      },
      { status: error.statusCode }
    );
  }

  if (error instanceof z.ZodError) {
    return NextResponse.json(
      {
        error: 'Validation failed',
        details: error.errors,
      },
      { status: 400 }
    );
  }

  console.error('Unhandled error:', error);

  return NextResponse.json(
    { error: 'Internal server error' },
    { status: 500 }
  );
}
```

---

## API 테스트

### Postman Collection

```json
{
  "info": {
    "name": "My API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Users",
      "item": [
        {
          "name": "Get Users",
          "request": {
            "method": "GET",
            "header": [],
            "url": {
              "raw": "{{baseUrl}}/api/v1/users?page=1&limit=10",
              "host": ["{{baseUrl}}"],
              "path": ["api", "v1", "users"],
              "query": [
                { "key": "page", "value": "1" },
                { "key": "limit", "value": "10" }
              ]
            }
          }
        },
        {
          "name": "Create User",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{token}}"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"name\": \"John Doe\",\n  \"email\": \"john@example.com\"\n}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{baseUrl}}/api/v1/users",
              "host": ["{{baseUrl}}"],
              "path": ["api", "v1", "users"]
            }
          }
        }
      ]
    }
  ],
  "variable": [
    {
      "key": "baseUrl",
      "value": "http://localhost:3000"
    },
    {
      "key": "token",
      "value": ""
    }
  ]
}
```

---

이 스킬은 API 설계 시 자동으로 활성화되며,
RESTful API, GraphQL, tRPC 패턴과 문서화를 지원합니다.