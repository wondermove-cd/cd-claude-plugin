---
activation-keywords:
  - UI
  - component
  - 컴포넌트
  - interface
  - 인터페이스
  - design
  - 디자인
  - shadcn
  - button
  - form
  - card
  - dialog
---

# shadcn/ui Component Library - Enhanced Design

## Design Philosophy

**shadcn/ui를 사용하더라도 절대 generic한 디자인을 만들지 마세요.**
기본 테마를 그대로 사용하지 말고, 프로젝트의 개성을 반영한 커스터마이징을 적용하세요.

## Theme Customization

### 1. Custom Color Schemes

절대 기본 회색 테마를 그대로 사용하지 마세요:

```css
/* app/globals.css - DON'T use default grays */
@layer base {
  :root {
    /* Dark theme with personality */
    --background: 222 47% 11%;  /* Deep navy instead of gray */
    --foreground: 210 40% 98%;

    --card: 222 47% 14%;
    --card-foreground: 210 40% 98%;

    /* Vibrant accents */
    --primary: 263 70% 50%;      /* Electric purple */
    --primary-foreground: 210 40% 98%;

    --secondary: 180 100% 35%;    /* Cyan */
    --secondary-foreground: 210 40% 98%;

    --muted: 215 20% 25%;
    --muted-foreground: 215 20% 65%;

    --accent: 339 90% 51%;        /* Hot pink */
    --accent-foreground: 210 40% 98%;

    --destructive: 0 84% 60%;
    --destructive-foreground: 210 40% 98%;

    --border: 215 20% 20%;
    --input: 215 20% 18%;
    --ring: 263 90% 60%;

    /* Custom spacing and radius */
    --radius: 0.75rem;  /* Slightly rounder */
  }

  .light {
    /* Light theme with character */
    --background: 60 9% 98%;      /* Warm white */
    --foreground: 222 47% 11%;

    --primary: 262 83% 58%;       /* Bright purple */
    --secondary: 173 80% 40%;     /* Teal */
    --accent: 343 80% 55%;        /* Coral */
  }
}
```

### 2. Typography Enhancement

```css
/* Custom font stack */
@import url('https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@300;400;500;600;700&family=Inter:wght@400;500;600;700&display=swap');

@layer base {
  :root {
    --font-heading: 'Space Grotesk', system-ui, sans-serif;
    --font-body: 'Inter', system-ui, sans-serif;
  }

  h1, h2, h3, h4, h5, h6 {
    font-family: var(--font-heading);
    font-weight: 600;
    letter-spacing: -0.02em;
  }
}
```

## Enhanced Component Patterns

### 1. Elevated Cards

```tsx
// Don't use plain cards
// ❌ BAD
<Card>
  <CardContent>Content</CardContent>
</Card>

// ✅ GOOD - Add depth and personality
<Card className="relative overflow-hidden border-0 bg-gradient-to-br from-card to-card/50 shadow-xl">
  <div className="absolute inset-0 bg-gradient-to-br from-primary/10 to-transparent" />
  <CardHeader className="relative">
    <CardTitle className="text-2xl font-bold bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">
      Title
    </CardTitle>
  </CardHeader>
  <CardContent className="relative">
    Content
  </CardContent>
</Card>
```

### 2. Dynamic Buttons

```tsx
// Enhanced button with animation
<Button
  className="relative overflow-hidden group"
  size="lg"
>
  <span className="relative z-10">Click me</span>
  <div className="absolute inset-0 bg-gradient-to-r from-primary/80 to-accent/80 transform scale-x-0 group-hover:scale-x-100 transition-transform origin-left" />
</Button>

// Glow effect button
<Button className="shadow-lg shadow-primary/25 hover:shadow-xl hover:shadow-primary/30 transition-all">
  Glow Button
</Button>

// Brutalist button
<Button className="rounded-none border-2 border-black shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] hover:shadow-[6px_6px_0px_0px_rgba(0,0,0,1)] hover:translate-x-[-2px] hover:translate-y-[-2px] transition-all">
  Brutal
</Button>
```

### 3. Glassmorphism Dialog

```tsx
<Dialog>
  <DialogContent className="border-white/10 bg-white/5 backdrop-blur-xl">
    <div className="absolute inset-0 bg-gradient-to-br from-primary/20 to-accent/20 rounded-lg" />
    <DialogHeader className="relative">
      <DialogTitle className="text-2xl font-bold">
        Glass Dialog
      </DialogTitle>
    </DialogHeader>
    {/* content */}
  </DialogContent>
</Dialog>
```

### 4. Animated Forms

```tsx
<Form {...form}>
  <form className="space-y-6">
    <FormField
      control={form.control}
      name="email"
      render={({ field }) => (
        <FormItem className="group">
          <FormLabel className="text-sm font-medium transition-colors group-focus-within:text-primary">
            Email
          </FormLabel>
          <FormControl>
            <div className="relative">
              <Input
                className="pl-10 transition-all focus:shadow-lg focus:shadow-primary/10"
                placeholder="your@email.com"
                {...field}
              />
              <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground transition-colors group-focus-within:text-primary" />
            </div>
          </FormControl>
          <FormMessage className="animate-slide-up-fade" />
        </FormItem>
      )}
    />
  </form>
</Form>
```

### 5. Data Table with Style

```tsx
<div className="rounded-xl border border-border/50 bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-card/30 overflow-hidden">
  <Table>
    <TableHeader className="bg-muted/50">
      <TableRow className="border-border/50 hover:bg-transparent">
        <TableHead className="font-semibold">Name</TableHead>
        <TableHead className="font-semibold">Status</TableHead>
        <TableHead className="font-semibold text-right">Actions</TableHead>
      </TableRow>
    </TableHeader>
    <TableBody>
      {data.map((row, i) => (
        <TableRow
          key={row.id}
          className="border-border/50 transition-colors hover:bg-muted/30"
          style={{
            animationDelay: `${i * 50}ms`,
          }}
        >
          <TableCell className="font-medium">{row.name}</TableCell>
          <TableCell>
            <Badge
              variant="outline"
              className="border-primary/50 bg-primary/10 text-primary"
            >
              {row.status}
            </Badge>
          </TableCell>
          <TableCell className="text-right">
            <Button variant="ghost" size="icon" className="hover:bg-primary/10">
              <MoreHorizontal className="h-4 w-4" />
            </Button>
          </TableCell>
        </TableRow>
      ))}
    </TableBody>
  </Table>
</div>
```

## Layout Patterns

### 1. Modern Dashboard

```tsx
<div className="min-h-screen bg-gradient-to-br from-background via-background to-primary/5">
  {/* Sidebar with glass effect */}
  <aside className="fixed left-0 top-0 h-full w-64 border-r border-border/50 bg-card/30 backdrop-blur-xl">
    <div className="p-6">
      <h2 className="text-2xl font-bold bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">
        Dashboard
      </h2>
    </div>
    <nav className="px-4 space-y-2">
      <Button variant="ghost" className="w-full justify-start hover:bg-primary/10">
        <Home className="mr-2 h-4 w-4" />
        Home
      </Button>
    </nav>
  </aside>

  {/* Main content with offset */}
  <main className="ml-64 p-8">
    <div className="grid gap-6">
      {/* Stats cards with gradient borders */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card className="relative overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-primary/10 to-transparent" />
          <CardContent className="relative p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Total Revenue</p>
                <p className="text-3xl font-bold">$45,231</p>
              </div>
              <div className="h-12 w-12 rounded-full bg-primary/10 flex items-center justify-center">
                <TrendingUp className="h-6 w-6 text-primary" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  </main>
</div>
```

### 2. Hero Section

```tsx
<section className="relative min-h-[90vh] overflow-hidden">
  {/* Animated background */}
  <div className="absolute inset-0 bg-gradient-to-br from-primary/20 via-transparent to-accent/20" />
  <div className="absolute inset-0 bg-grid-white/[0.02] bg-[size:50px_50px]" />

  <div className="relative z-10 container mx-auto px-4 py-32">
    <div className="max-w-4xl mx-auto text-center space-y-8">
      <h1 className="text-6xl md:text-8xl font-bold">
        <span className="bg-gradient-to-r from-primary via-accent to-primary bg-clip-text text-transparent animate-gradient bg-[length:200%_auto]">
          Amazing Title
        </span>
      </h1>
      <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
        Compelling description with personality
      </p>
      <div className="flex gap-4 justify-center">
        <Button size="lg" className="shadow-lg shadow-primary/25">
          Get Started
        </Button>
        <Button size="lg" variant="outline" className="border-2">
          Learn More
        </Button>
      </div>
    </div>
  </div>
</section>
```

## Animation Utilities

Add these to your global CSS:

```css
@keyframes slide-up-fade {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes gradient {
  0%, 100% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
}

@keyframes pulse-glow {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.animate-slide-up-fade {
  animation: slide-up-fade 0.3s ease-out;
}

.animate-gradient {
  animation: gradient 3s ease infinite;
}

.animate-pulse-glow {
  animation: pulse-glow 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

/* Stagger animation for lists */
.stagger-animation > * {
  animation: slide-up-fade 0.5s ease-out forwards;
  opacity: 0;
}

.stagger-animation > *:nth-child(1) { animation-delay: 0ms; }
.stagger-animation > *:nth-child(2) { animation-delay: 50ms; }
.stagger-animation > *:nth-child(3) { animation-delay: 100ms; }
.stagger-animation > *:nth-child(4) { animation-delay: 150ms; }
.stagger-animation > *:nth-child(5) { animation-delay: 200ms; }
```

## Custom Utilities

```tsx
// lib/utils.ts - Enhanced cn function
import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

// Generate dynamic gradients
export function generateGradient(color1: string, color2: string, deg = 135) {
  return `linear-gradient(${deg}deg, ${color1}, ${color2})`
}

// Random accent color
export function getRandomAccent() {
  const accents = ['primary', 'secondary', 'accent']
  return accents[Math.floor(Math.random() * accents.length)]
}
```

## DO's and DON'Ts

### ✅ DO's
- Use gradient backgrounds and borders
- Add shadows for depth (shadow-xl, shadow-2xl)
- Use animation for interactions
- Create visual hierarchy with size and weight
- Use backdrop-blur for glass effects
- Add hover states with transform
- Use decorative elements (gradients, patterns)

### ❌ DON'Ts
- Don't use default gray color scheme
- Don't use plain white/gray backgrounds
- Don't use cards without shadows or borders
- Don't use default button styles only
- Don't forget hover/focus states
- Don't use boring centered layouts only
- Don't skip animation and transitions

## Installation Commands

```bash
# Core shadcn/ui setup
npx shadcn-ui@latest init

# Essential components for great design
npx shadcn-ui@latest add button card dialog form input
npx shadcn-ui@latest add dropdown-menu sheet tabs badge
npx shadcn-ui@latest add toast alert skeleton avatar
npx shadcn-ui@latest add tooltip popover command

# Icons and animations
npm install lucide-react framer-motion

# Optional: Advanced styling
npm install tailwindcss-animate @tailwindcss/typography
```

## Remember

**shadcn/ui는 도구일 뿐입니다. 당신의 창의성이 디자인을 특별하게 만듭니다.**

- 기본 스타일을 베이스로 사용하되, 항상 커스터마이징하세요
- 그라디언트, 애니메이션, 독특한 레이아웃을 활용하세요
- "또 다른 shadcn 사이트"가 아닌 독특한 경험을 만드세요