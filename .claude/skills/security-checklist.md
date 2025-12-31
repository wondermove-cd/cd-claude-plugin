# 보안 체크리스트 스킬

> 웹 애플리케이션 보안 취약점 점검 및 대응

## 자동 활성화 조건
- 보안, 취약점, 해킹 방어
- OWASP, XSS, CSRF 언급
- 인증/인가 구현
- "보안", "암호화", "취약점" 키워드

## OWASP Top 10 (2024)

### 1. Broken Access Control (접근 제어 실패)
### 2. Cryptographic Failures (암호화 실패)
### 3. Injection (인젝션)
### 4. Insecure Design (안전하지 않은 설계)
### 5. Security Misconfiguration (보안 구성 오류)
### 6. Vulnerable Components (취약한 구성요소)
### 7. Authentication Failures (인증 실패)
### 8. Data Integrity Failures (데이터 무결성 실패)
### 9. Security Logging Failures (보안 로깅 실패)
### 10. SSRF (Server-Side Request Forgery)

---

## 인증 보안

### 1. 안전한 비밀번호 처리

```typescript
// ❌ Bad - 평문 저장
const user = await prisma.user.create({
  data: {
    email,
    password: plainPassword, // 절대 금지!
  }
});

// ✅ Good - bcrypt 해싱
import bcrypt from 'bcryptjs';

// 비밀번호 해싱
const saltRounds = 12; // 최소 10 이상 권장
const hashedPassword = await bcrypt.hash(plainPassword, saltRounds);

const user = await prisma.user.create({
  data: {
    email,
    password: hashedPassword,
  }
});

// 비밀번호 검증
const isValid = await bcrypt.compare(plainPassword, user.password);

// 비밀번호 정책 검증
function validatePassword(password: string): string[] {
  const errors = [];

  if (password.length < 8) {
    errors.push('비밀번호는 8자 이상이어야 합니다');
  }

  if (!/[A-Z]/.test(password)) {
    errors.push('대문자를 포함해야 합니다');
  }

  if (!/[a-z]/.test(password)) {
    errors.push('소문자를 포함해야 합니다');
  }

  if (!/[0-9]/.test(password)) {
    errors.push('숫자를 포함해야 합니다');
  }

  if (!/[!@#$%^&*]/.test(password)) {
    errors.push('특수문자를 포함해야 합니다');
  }

  // 일반적인 비밀번호 체크
  const commonPasswords = ['password', '123456', 'qwerty'];
  if (commonPasswords.includes(password.toLowerCase())) {
    errors.push('너무 일반적인 비밀번호입니다');
  }

  return errors;
}
```

### 2. JWT 토큰 보안

```typescript
// JWT 생성 및 검증
import jwt from 'jsonwebtoken';
import { randomBytes } from 'crypto';

// 환경변수에서 시크릿 로드
const JWT_SECRET = process.env.JWT_SECRET || randomBytes(64).toString('hex');
const REFRESH_SECRET = process.env.REFRESH_SECRET || randomBytes(64).toString('hex');

// 토큰 생성
function generateTokens(userId: string) {
  // Access Token - 짧은 만료시간
  const accessToken = jwt.sign(
    {
      userId,
      type: 'access',
    },
    JWT_SECRET,
    {
      expiresIn: '15m', // 15분
      issuer: 'myapp.com',
      audience: 'myapp.com',
    }
  );

  // Refresh Token - 긴 만료시간
  const refreshToken = jwt.sign(
    {
      userId,
      type: 'refresh',
    },
    REFRESH_SECRET,
    {
      expiresIn: '7d', // 7일
    }
  );

  return { accessToken, refreshToken };
}

// 토큰 검증 미들웨어
async function verifyToken(req: Request): Promise<User | null> {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');

    if (!token) {
      throw new Error('No token provided');
    }

    // 토큰 검증
    const decoded = jwt.verify(token, JWT_SECRET) as any;

    // 토큰 타입 확인
    if (decoded.type !== 'access') {
      throw new Error('Invalid token type');
    }

    // 사용자 확인
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
    });

    if (!user || user.suspended) {
      throw new Error('User not found or suspended');
    }

    return user;
  } catch (error) {
    return null;
  }
}

// Refresh Token 로테이션
async function refreshTokens(refreshToken: string) {
  try {
    const decoded = jwt.verify(refreshToken, REFRESH_SECRET) as any;

    // 블랙리스트 체크
    const isBlacklisted = await redis.get(`blacklist:${refreshToken}`);
    if (isBlacklisted) {
      throw new Error('Token is blacklisted');
    }

    // 기존 토큰 블랙리스트 추가
    await redis.setex(`blacklist:${refreshToken}`, 7 * 24 * 3600, '1');

    // 새 토큰 발급
    return generateTokens(decoded.userId);
  } catch (error) {
    throw new Error('Invalid refresh token');
  }
}
```

### 3. 세션 보안

```typescript
// express-session 설정
import session from 'express-session';
import RedisStore from 'connect-redis';

app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: process.env.SESSION_SECRET!,
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production', // HTTPS only
    httpOnly: true, // XSS 방어
    maxAge: 1000 * 60 * 60 * 24, // 24시간
    sameSite: 'strict', // CSRF 방어
  },
  name: 'sessionId', // 기본 이름 변경
}));

// 세션 고정 공격 방어
app.post('/login', async (req, res) => {
  // 로그인 성공 후 세션 재생성
  req.session.regenerate((err) => {
    if (err) {
      return res.status(500).json({ error: 'Session error' });
    }

    req.session.userId = user.id;
    req.session.save();
    res.json({ success: true });
  });
});
```

---

## 입력 검증 & 삭제

### 1. SQL Injection 방어

```typescript
// ❌ Bad - SQL Injection 취약
const query = `SELECT * FROM users WHERE email = '${email}'`;

// ✅ Good - Parameterized Query (Prisma)
const user = await prisma.user.findUnique({
  where: { email },
});

// ✅ Good - Prepared Statement
const query = 'SELECT * FROM users WHERE email = $1';
const result = await db.query(query, [email]);

// 입력 검증
import { z } from 'zod';

const UserSchema = z.object({
  email: z.string().email().max(255),
  name: z.string().min(1).max(100).regex(/^[a-zA-Z\s]+$/),
  age: z.number().min(0).max(150),
});

// 사용
try {
  const validatedData = UserSchema.parse(req.body);
  // 안전한 데이터 사용
} catch (error) {
  // 검증 실패
}
```

### 2. XSS 방어

```typescript
// DOM 정화
import DOMPurify from 'isomorphic-dompurify';

// HTML 렌더링 전 정화
const sanitizedHTML = DOMPurify.sanitize(userInput, {
  ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a'],
  ALLOWED_ATTR: ['href'],
});

// React는 기본적으로 XSS 방어
<div>{userInput}</div> // 자동 이스케이프

// 위험: dangerouslySetInnerHTML
<div dangerouslySetInnerHTML={{ __html: sanitizedHTML }} />

// CSP (Content Security Policy) 헤더
export async function middleware(request: NextRequest) {
  const response = NextResponse.next();

  response.headers.set(
    'Content-Security-Policy',
    "default-src 'self'; " +
    "script-src 'self' 'unsafe-inline' 'unsafe-eval'; " +
    "style-src 'self' 'unsafe-inline'; " +
    "img-src 'self' data: https:; " +
    "font-src 'self' data:; " +
    "connect-src 'self' https://api.example.com; " +
    "frame-ancestors 'none';"
  );

  return response;
}
```

### 3. CSRF 방어

```typescript
// CSRF 토큰 생성 및 검증
import csrf from 'csurf';

const csrfProtection = csrf({ cookie: true });

// 토큰 발급
app.get('/form', csrfProtection, (req, res) => {
  res.json({ csrfToken: req.csrfToken() });
});

// 토큰 검증
app.post('/submit', csrfProtection, (req, res) => {
  // CSRF 토큰이 유효한 경우만 처리
});

// Next.js에서 CSRF
import { getCsrfToken } from 'next-auth/react';

export default function Form() {
  const [csrfToken, setCsrfToken] = useState('');

  useEffect(() => {
    getCsrfToken().then(setCsrfToken);
  }, []);

  return (
    <form method="post">
      <input type="hidden" name="csrfToken" value={csrfToken} />
      {/* 폼 필드 */}
    </form>
  );
}
```

---

## 파일 업로드 보안

```typescript
import multer from 'multer';
import path from 'path';
import { randomBytes } from 'crypto';

// 안전한 파일 업로드 설정
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/'); // 웹 루트 외부 저장
  },
  filename: (req, file, cb) => {
    // 원본 파일명 사용하지 않고 랜덤 생성
    const uniqueName = randomBytes(16).toString('hex');
    const ext = path.extname(file.originalname);
    cb(null, `${uniqueName}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB 제한
    files: 1, // 파일 개수 제한
  },
  fileFilter: (req, file, cb) => {
    // 허용된 MIME 타입만
    const allowedMimes = [
      'image/jpeg',
      'image/png',
      'image/gif',
      'application/pdf',
    ];

    if (allowedMimes.includes(file.mimetype)) {
      // 실제 파일 내용 검증 (Magic Number)
      const fileExtension = path.extname(file.originalname).toLowerCase();
      const validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.pdf'];

      if (validExtensions.includes(fileExtension)) {
        cb(null, true);
      } else {
        cb(new Error('Invalid file extension'));
      }
    } else {
      cb(new Error('Invalid file type'));
    }
  },
});

// 파일 내용 스캔 (바이러스 스캔)
import NodeClam from 'clamscan';

const clamscan = await new NodeClam().init({
  clamdscan: {
    host: '127.0.0.1',
    port: 3310,
  },
});

app.post('/upload', upload.single('file'), async (req, res) => {
  try {
    // 바이러스 스캔
    const { isInfected, file, viruses } = await clamscan.scanFile(req.file.path);

    if (isInfected) {
      // 감염된 파일 삭제
      await fs.unlink(req.file.path);
      return res.status(400).json({ error: 'Infected file detected' });
    }

    // DB에 메타데이터만 저장
    const fileRecord = await prisma.file.create({
      data: {
        filename: req.file.filename,
        originalName: req.file.originalname,
        mimeType: req.file.mimetype,
        size: req.file.size,
        userId: req.user.id,
      },
    });

    res.json({ success: true, fileId: fileRecord.id });
  } catch (error) {
    res.status(500).json({ error: 'Upload failed' });
  }
});
```

---

## API 보안

### 1. Rate Limiting

```typescript
import rateLimit from 'express-rate-limit';

// 일반 API 제한
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15분
  max: 100, // 최대 100개 요청
  message: 'Too many requests',
  standardHeaders: true,
  legacyHeaders: false,
});

// 로그인 제한 (더 엄격하게)
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // 15분당 5회 시도
  skipSuccessfulRequests: true, // 성공 요청은 카운트 안함
});

app.use('/api', apiLimiter);
app.use('/api/login', loginLimiter);

// IP 기반 차단
const blacklist = new Set();

app.use((req, res, next) => {
  const ip = req.ip;

  if (blacklist.has(ip)) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  // 의심스러운 활동 감지
  if (isSuspicious(req)) {
    blacklist.add(ip);
    // 일정 시간 후 차단 해제
    setTimeout(() => blacklist.delete(ip), 3600000);
  }

  next();
});
```

### 2. API Key 관리

```typescript
// API Key 생성
import { randomBytes } from 'crypto';

function generateApiKey(): string {
  return randomBytes(32).toString('hex');
}

// API Key 해싱 저장
const apiKey = generateApiKey();
const hashedKey = await bcrypt.hash(apiKey, 10);

await prisma.apiKey.create({
  data: {
    key: hashedKey,
    userId,
    permissions: ['read', 'write'],
    expiresAt: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000), // 90일
  },
});

// API Key 검증 미들웨어
async function validateApiKey(req: Request, res: Response, next: NextFunction) {
  const apiKey = req.headers['x-api-key'] as string;

  if (!apiKey) {
    return res.status(401).json({ error: 'API key required' });
  }

  // DB에서 모든 키 조회 후 비교 (타이밍 공격 방어)
  const keys = await prisma.apiKey.findMany({
    where: {
      expiresAt: { gt: new Date() },
    },
  });

  let validKey = null;
  for (const key of keys) {
    if (await bcrypt.compare(apiKey, key.key)) {
      validKey = key;
      break;
    }
  }

  if (!validKey) {
    return res.status(401).json({ error: 'Invalid API key' });
  }

  req.apiKey = validKey;
  next();
}
```

---

## 데이터 보안

### 1. 암호화

```typescript
import crypto from 'crypto';

// AES-256 암호화
class Encryption {
  private algorithm = 'aes-256-gcm';
  private key: Buffer;

  constructor() {
    // 환경변수에서 키 로드 (32 bytes)
    this.key = Buffer.from(process.env.ENCRYPTION_KEY!, 'hex');
  }

  encrypt(text: string): string {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv(this.algorithm, this.key, iv);

    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');

    const authTag = cipher.getAuthTag();

    return iv.toString('hex') + ':' + authTag.toString('hex') + ':' + encrypted;
  }

  decrypt(encryptedData: string): string {
    const parts = encryptedData.split(':');
    const iv = Buffer.from(parts[0], 'hex');
    const authTag = Buffer.from(parts[1], 'hex');
    const encrypted = parts[2];

    const decipher = crypto.createDecipheriv(this.algorithm, this.key, iv);
    decipher.setAuthTag(authTag);

    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');

    return decrypted;
  }
}

// 사용
const encryption = new Encryption();

// 민감한 데이터 암호화
const encryptedSSN = encryption.encrypt(socialSecurityNumber);
await prisma.user.update({
  where: { id: userId },
  data: { ssn: encryptedSSN },
});

// 복호화
const decryptedSSN = encryption.decrypt(user.ssn);
```

### 2. 데이터 마스킹

```typescript
// 민감한 정보 마스킹
function maskEmail(email: string): string {
  const [local, domain] = email.split('@');
  const maskedLocal = local[0] + '*'.repeat(local.length - 2) + local[local.length - 1];
  return `${maskedLocal}@${domain}`;
}

function maskPhone(phone: string): string {
  return phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2');
}

function maskCreditCard(card: string): string {
  return '*'.repeat(card.length - 4) + card.slice(-4);
}

// API 응답에서 민감한 정보 제거
function sanitizeUser(user: User) {
  return {
    ...user,
    email: maskEmail(user.email),
    phone: maskPhone(user.phone),
    creditCard: undefined, // 완전 제거
    password: undefined,
    ssn: undefined,
  };
}
```

---

## 보안 헤더

```typescript
// Next.js 보안 헤더 설정
// next.config.js
module.exports = {
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'X-DNS-Prefetch-Control',
            value: 'on',
          },
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=63072000; includeSubDomains; preload',
          },
          {
            key: 'X-Frame-Options',
            value: 'SAMEORIGIN',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block',
          },
          {
            key: 'Referrer-Policy',
            value: 'origin-when-cross-origin',
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=()',
          },
        ],
      },
    ];
  },
};

// Helmet 사용 (Express)
import helmet from 'helmet';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
}));
```

---

## 보안 로깅 & 모니터링

```typescript
// 보안 이벤트 로깅
import winston from 'winston';

const securityLogger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'security.log' }),
  ],
});

// 로그인 시도 로깅
function logLoginAttempt(email: string, success: boolean, ip: string) {
  securityLogger.info('Login attempt', {
    email,
    success,
    ip,
    timestamp: new Date().toISOString(),
    userAgent: req.headers['user-agent'],
  });

  // 실패 횟수 추적
  if (!success) {
    const key = `login_failures:${ip}`;
    const failures = await redis.incr(key);
    await redis.expire(key, 3600); // 1시간

    if (failures > 5) {
      // 알림 발송
      notifyAdmins(`Suspicious login activity from IP: ${ip}`);
    }
  }
}

// 의심스러운 활동 감지
function detectAnomalies(req: Request) {
  const patterns = [
    /\.\.\//,  // Path traversal
    /<script/i,  // XSS attempt
    /union.*select/i,  // SQL injection
    /eval\(/,  // Code injection
  ];

  const url = req.url + JSON.stringify(req.body);

  for (const pattern of patterns) {
    if (pattern.test(url)) {
      securityLogger.warn('Suspicious activity detected', {
        pattern: pattern.toString(),
        url: req.url,
        ip: req.ip,
        body: req.body,
      });
      return true;
    }
  }

  return false;
}
```

---

## 보안 체크리스트

### 인증 & 인가
- [ ] 비밀번호 해싱 (bcrypt/argon2)
- [ ] 다단계 인증 (MFA/2FA)
- [ ] 세션 만료 처리
- [ ] 비밀번호 재설정 보안
- [ ] 계정 잠금 정책

### 입력 검증
- [ ] 모든 입력 검증
- [ ] SQL Injection 방어
- [ ] XSS 방어
- [ ] CSRF 토큰
- [ ] XXE 방어

### API 보안
- [ ] Rate Limiting
- [ ] API 키 관리
- [ ] CORS 설정
- [ ] 입력 크기 제한
- [ ] 타임아웃 설정

### 데이터 보호
- [ ] HTTPS 강제
- [ ] 민감 데이터 암호화
- [ ] 안전한 쿠키 설정
- [ ] 데이터 마스킹
- [ ] 백업 암호화

### 의존성 관리
- [ ] npm audit 정기 실행
- [ ] 의존성 업데이트
- [ ] 알려진 취약점 패치
- [ ] SBOM 생성

### 모니터링
- [ ] 보안 로그 수집
- [ ] 이상 탐지 설정
- [ ] 알림 시스템
- [ ] 정기 보안 감사
- [ ] 침투 테스트

---

이 스킬은 보안 관련 작업 시 자동으로 활성화되며,
웹 애플리케이션의 보안 취약점을 예방하고 대응합니다.