# shadcn/ui 기반 UI 설계

> UI 컴포넌트 설계 시 shadcn/ui 라이브러리를 기본으로 사용합니다.

## 자동 활성화 조건
- UI 설계, 화면 설계, 컴포넌트 설계
- 디자인 시스템이 없는 프로젝트
- React/Next.js 프로젝트

## 핵심 규칙

### 1. 프로젝트 체크
프로젝트에 기존 디자인 시스템이 있는지 먼저 확인:
- `package.json`에서 UI 라이브러리 확인 (MUI, Ant Design, Chakra UI 등)
- `/components/ui` 폴더 존재 여부 확인
- 기존 디자인 시스템이 있으면 그것을 우선 사용

### 2. shadcn/ui 컴포넌트 사용

#### 기본 컴포넌트 매핑
| 용도 | shadcn 컴포넌트 | 사용 예시 |
|------|-----------------|----------|
| 버튼 | Button | `<Button variant="default\|secondary\|outline\|ghost\|link\|destructive">` |
| 입력 | Input | `<Input type="text" placeholder="..." />` |
| 선택 | Select | `<Select><SelectTrigger>...</SelectTrigger><SelectContent>...</SelectContent></Select>` |
| 카드 | Card | `<Card><CardHeader><CardTitle/><CardDescription/></CardHeader><CardContent/></Card>` |
| 대화상자 | Dialog | `<Dialog><DialogTrigger/><DialogContent><DialogHeader/><DialogFooter/></DialogContent></Dialog>` |
| 알림 | Alert | `<Alert><AlertTitle/><AlertDescription/></Alert>` |
| 토스트 | Toast | `toast({ title: "...", description: "..." })` |
| 폼 | Form | `<Form><FormField><FormItem><FormLabel/><FormControl/><FormMessage/></FormItem></FormField></Form>` |
| 테이블 | Table | `<Table><TableHeader><TableRow><TableHead/></TableRow></TableHeader><TableBody>...</TableBody></Table>` |
| 탭 | Tabs | `<Tabs><TabsList><TabsTrigger/></TabsList><TabsContent/></Tabs>` |
| 드롭다운 | DropdownMenu | `<DropdownMenu><DropdownMenuTrigger/><DropdownMenuContent>...</DropdownMenuContent></DropdownMenu>` |
| 시트 | Sheet | `<Sheet><SheetTrigger/><SheetContent><SheetHeader/></SheetContent></Sheet>` |
| 아코디언 | Accordion | `<Accordion><AccordionItem><AccordionTrigger/><AccordionContent/></AccordionItem></Accordion>` |
| 배지 | Badge | `<Badge variant="default\|secondary\|destructive\|outline">...</Badge>` |
| 체크박스 | Checkbox | `<Checkbox checked={...} onCheckedChange={...} />` |
| 라디오 | RadioGroup | `<RadioGroup><RadioGroupItem value="..." /></RadioGroup>` |
| 스위치 | Switch | `<Switch checked={...} onCheckedChange={...} />` |
| 슬라이더 | Slider | `<Slider defaultValue={[50]} max={100} step={1} />` |
| 프로그레스 | Progress | `<Progress value={33} />` |
| 아바타 | Avatar | `<Avatar><AvatarImage src="..." /><AvatarFallback>CN</AvatarFallback></Avatar>` |
| 툴팁 | Tooltip | `<Tooltip><TooltipTrigger>...</TooltipTrigger><TooltipContent>...</TooltipContent></Tooltip>` |
| 팝오버 | Popover | `<Popover><PopoverTrigger>...</PopoverTrigger><PopoverContent>...</PopoverContent></Popover>` |
| 커맨드 | Command | `<Command><CommandInput/><CommandList><CommandItem>...</CommandItem></CommandList></Command>` |
| 컨텍스트메뉴 | ContextMenu | `<ContextMenu><ContextMenuTrigger>...</ContextMenuTrigger><ContextMenuContent>...</ContextMenuContent></ContextMenu>` |

#### 색상 시스템
```css
/* shadcn/ui 기본 색상 변수 */
--background: 배경색
--foreground: 전경색
--primary: 주요 색상
--secondary: 보조 색상
--muted: 음소거 색상
--accent: 강조 색상
--destructive: 위험/삭제 색상
--border: 테두리 색상
--ring: 포커스 링 색상
```

#### 반응형 디자인
```tsx
// Tailwind CSS 클래스 사용
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  // sm: 640px, md: 768px, lg: 1024px, xl: 1280px, 2xl: 1536px
</div>
```

### 3. 폼 설계 패턴

```tsx
// React Hook Form + Zod + shadcn/ui
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import * as z from "zod"

const formSchema = z.object({
  username: z.string().min(2).max(50),
  email: z.string().email(),
})

function MyForm() {
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      username: "",
      email: "",
    },
  })

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-8">
        <FormField
          control={form.control}
          name="username"
          render={({ field }) => (
            <FormItem>
              <FormLabel>사용자명</FormLabel>
              <FormControl>
                <Input placeholder="이름을 입력하세요" {...field} />
              </FormControl>
              <FormDescription>
                공개 프로필에 표시되는 이름입니다.
              </FormDescription>
              <FormMessage />
            </FormItem>
          )}
        />
        <Button type="submit">제출</Button>
      </form>
    </Form>
  )
}
```

### 4. 레이아웃 패턴

```tsx
// 대시보드 레이아웃
<div className="flex h-screen bg-background">
  {/* 사이드바 */}
  <aside className="w-64 border-r">
    <nav className="p-4 space-y-2">
      <Button variant="ghost" className="w-full justify-start">
        메뉴 아이템
      </Button>
    </nav>
  </aside>

  {/* 메인 콘텐츠 */}
  <main className="flex-1 overflow-y-auto">
    {/* 헤더 */}
    <header className="border-b p-4">
      <h1 className="text-2xl font-bold">페이지 제목</h1>
    </header>

    {/* 콘텐츠 */}
    <div className="p-6">
      <div className="grid gap-4">
        <Card>...</Card>
      </div>
    </div>
  </main>
</div>
```

### 5. 모달/다이얼로그 패턴

```tsx
// 확인 다이얼로그
<AlertDialog>
  <AlertDialogTrigger asChild>
    <Button variant="destructive">삭제</Button>
  </AlertDialogTrigger>
  <AlertDialogContent>
    <AlertDialogHeader>
      <AlertDialogTitle>정말로 삭제하시겠습니까?</AlertDialogTitle>
      <AlertDialogDescription>
        이 작업은 되돌릴 수 없습니다. 영구적으로 삭제됩니다.
      </AlertDialogDescription>
    </AlertDialogHeader>
    <AlertDialogFooter>
      <AlertDialogCancel>취소</AlertDialogCancel>
      <AlertDialogAction onClick={handleDelete}>삭제</AlertDialogAction>
    </AlertDialogFooter>
  </AlertDialogContent>
</AlertDialog>
```

### 6. 데이터 테이블 패턴

```tsx
// TanStack Table + shadcn/ui
<div className="rounded-md border">
  <Table>
    <TableHeader>
      <TableRow>
        <TableHead>이름</TableHead>
        <TableHead>이메일</TableHead>
        <TableHead>상태</TableHead>
        <TableHead className="text-right">작업</TableHead>
      </TableRow>
    </TableHeader>
    <TableBody>
      {data.map((row) => (
        <TableRow key={row.id}>
          <TableCell className="font-medium">{row.name}</TableCell>
          <TableCell>{row.email}</TableCell>
          <TableCell>
            <Badge variant={row.status === 'active' ? 'default' : 'secondary'}>
              {row.status}
            </Badge>
          </TableCell>
          <TableCell className="text-right">
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon">
                  <MoreHorizontal className="h-4 w-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem>편집</DropdownMenuItem>
                <DropdownMenuItem>복사</DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem className="text-destructive">
                  삭제
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </TableCell>
        </TableRow>
      ))}
    </TableBody>
  </Table>
</div>
```

### 7. 로딩 상태

```tsx
// 스켈레톤 로딩
import { Skeleton } from "@/components/ui/skeleton"

<div className="space-y-3">
  <Skeleton className="h-4 w-[250px]" />
  <Skeleton className="h-4 w-[200px]" />
  <Skeleton className="h-4 w-[150px]" />
</div>

// 스피너
import { Loader2 } from "lucide-react"

<Button disabled>
  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
  처리 중...
</Button>
```

### 8. 토스트 알림

```tsx
import { useToast } from "@/components/ui/use-toast"

function MyComponent() {
  const { toast } = useToast()

  const handleSuccess = () => {
    toast({
      title: "성공",
      description: "작업이 완료되었습니다.",
    })
  }

  const handleError = () => {
    toast({
      variant: "destructive",
      title: "오류 발생",
      description: "문제가 발생했습니다. 다시 시도해주세요.",
    })
  }
}
```

### 9. 아이콘 사용

```tsx
// Lucide React 아이콘 사용
import {
  Home,
  User,
  Settings,
  Search,
  ChevronRight,
  X,
  Check,
  AlertCircle,
  Info
} from "lucide-react"

<Button>
  <Home className="mr-2 h-4 w-4" />
  홈으로
</Button>
```

### 10. 접근성 고려사항

- 모든 인터랙티브 요소에 적절한 ARIA 레이블 제공
- 키보드 네비게이션 지원
- 포커스 관리
- 스크린 리더 호환성

```tsx
<Button
  aria-label="메뉴 열기"
  aria-expanded={isOpen}
  aria-controls="navigation-menu"
>
  <Menu className="h-4 w-4" />
</Button>
```

## 설치 가이드 제공

프로젝트에 shadcn/ui가 없는 경우:

```bash
# 1. 초기 설정
npx shadcn-ui@latest init

# 2. 필요한 컴포넌트 추가
npx shadcn-ui@latest add button
npx shadcn-ui@latest add card
npx shadcn-ui@latest add form
npx shadcn-ui@latest add table
# ... 필요한 컴포넌트 추가

# 3. 아이콘 라이브러리
npm install lucide-react
```

## 실제 적용 예시

### 로그인 화면
```tsx
<Card className="w-[400px]">
  <CardHeader>
    <CardTitle>로그인</CardTitle>
    <CardDescription>계정에 로그인하세요</CardDescription>
  </CardHeader>
  <CardContent>
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
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
        <FormField
          control={form.control}
          name="password"
          render={({ field }) => (
            <FormItem>
              <FormLabel>비밀번호</FormLabel>
              <FormControl>
                <Input type="password" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <Button type="submit" className="w-full">
          로그인
        </Button>
      </form>
    </Form>
  </CardContent>
  <CardFooter>
    <p className="text-sm text-muted-foreground">
      계정이 없으신가요? <Link href="/signup" className="underline">가입하기</Link>
    </p>
  </CardFooter>
</Card>
```

---

이 스킬은 UI 설계 관련 작업 시 자동으로 활성화되며,
프로젝트에 기존 디자인 시스템이 없는 경우 shadcn/ui를 기본으로 사용합니다.