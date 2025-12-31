---
name: design-system
description: 독특하고 기억에 남는 디자인 시스템을 자동으로 적용합니다.
activation-keywords:
  - 디자인
  - design
  - 컴포넌트
  - component
  - 색상
  - color
  - 타이포
  - typography
  - UI
  - 인터페이스
  - interface
  - 레이아웃
  - layout
---

# Modern Design System - Beyond Generic

## Core Philosophy

**절대 규칙: Generic AI 디자인을 만들지 마세요**

- ❌ 기본 회색 팔레트
- ❌ Inter/Roboto 폰트
- ❌ 평범한 카드 레이아웃
- ❌ 부트스트랩 스타일

대신:
- ✅ 대담한 색상 조합
- ✅ 독특한 타이포그래피
- ✅ 창의적인 레이아웃
- ✅ 기억에 남는 인터랙션

## 1. Color Systems

### 1.1 Vibrant Palettes (Not Gray!)

#### Dark Theme First
```css
:root {
  /* Deep Space Theme */
  --background: #0a0e27;        /* Deep space blue */
  --surface: #151932;            /* Elevated surface */
  --primary: #7c3aed;           /* Electric purple */
  --secondary: #06b6d4;         /* Cyan */
  --accent: #f59e0b;            /* Amber */
  --danger: #ef4444;            /* Red */
  --success: #10b981;           /* Emerald */

  /* Text with contrast */
  --text-primary: #f3f4f6;
  --text-secondary: #9ca3af;
  --text-muted: #6b7280;
}
```

#### Light Theme with Character
```css
.light {
  --background: #fefce8;        /* Warm yellow tint */
  --surface: #ffffff;
  --primary: #8b5cf6;          /* Vibrant purple */
  --secondary: #0891b2;         /* Teal */
  --accent: #ea580c;           /* Orange */
}
```

### 1.2 Gradient Systems

```css
/* Primary Gradients */
--gradient-purple: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
--gradient-sunset: linear-gradient(135deg, #fa709a 0%, #fee140 100%);
--gradient-ocean: linear-gradient(135deg, #48c6ef 0%, #6f86d6 100%);
--gradient-fire: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);

/* Mesh Gradients */
--gradient-mesh:
  radial-gradient(at 40% 20%, hsla(28, 100%, 74%, 1) 0px, transparent 50%),
  radial-gradient(at 80% 0%, hsla(189, 100%, 56%, 1) 0px, transparent 50%),
  radial-gradient(at 0% 50%, hsla(355, 100%, 93%, 1) 0px, transparent 50%);
```

## 2. Typography That Stands Out

### 2.1 Font Combinations

```css
/* Technical/Developer */
--font-display: 'Space Grotesk', sans-serif;
--font-body: 'Inter Tight', sans-serif;
--font-code: 'JetBrains Mono', monospace;

/* Editorial/Content */
--font-display: 'Playfair Display', serif;
--font-body: 'Crimson Pro', serif;

/* Modern/Startup */
--font-display: 'Bebas Neue', sans-serif;
--font-body: 'Manrope', sans-serif;

/* Bold/Brutalist */
--font-display: 'Archivo Black', sans-serif;
--font-body: 'Work Sans', sans-serif;
```

### 2.2 Dramatic Scale

```css
/* Use extreme size differences */
--text-xs: 0.75rem;     /* 12px */
--text-base: 1rem;      /* 16px */
--text-xl: 1.5rem;      /* 24px */
--text-3xl: 3rem;       /* 48px - 3x jump! */
--text-5xl: 6rem;       /* 96px - massive headers */
--text-giant: 10rem;    /* 160px - hero text */

/* Extreme weights */
--font-thin: 100;
--font-regular: 400;
--font-black: 900;
```

## 3. Component Patterns

### 3.1 Buttons with Personality

```tsx
// Cyberpunk Button
<button className="
  relative overflow-hidden
  bg-gradient-to-r from-purple-600 to-pink-600
  text-white font-bold py-3 px-6
  border-2 border-purple-400
  shadow-[0_0_20px_rgba(168,85,247,0.5)]
  hover:shadow-[0_0_30px_rgba(168,85,247,0.8)]
  transition-all duration-300
  before:absolute before:inset-0
  before:bg-gradient-to-r before:from-transparent before:via-white/20 before:to-transparent
  before:translate-x-[-200%] hover:before:translate-x-[200%]
  before:transition-transform before:duration-700
">
  <span className="relative z-10">LAUNCH</span>
</button>

// Brutalist Button
<button className="
  bg-black text-white
  px-8 py-4 text-lg font-black uppercase
  border-4 border-black
  shadow-[8px_8px_0px_0px_rgba(255,0,255,1)]
  hover:shadow-[12px_12px_0px_0px_rgba(255,0,255,1)]
  hover:translate-x-[-4px] hover:translate-y-[-4px]
  transition-all duration-200
">
  CLICK ME
</button>

// Glassmorphism Button
<button className="
  bg-white/10 backdrop-blur-md
  border border-white/20
  text-white px-6 py-3 rounded-2xl
  shadow-lg shadow-black/20
  hover:bg-white/20 hover:shadow-xl
  transition-all duration-300
">
  Glass Button
</button>
```

### 3.2 Cards That Pop

```tsx
// Floating Card with Gradient Border
<div className="relative p-[2px] rounded-2xl bg-gradient-to-r from-purple-500 to-pink-500">
  <div className="bg-black rounded-2xl p-6">
    <h3 className="text-2xl font-bold bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent">
      Gradient Border Card
    </h3>
  </div>
</div>

// 3D Transform Card
<div className="
  bg-white rounded-xl p-6
  shadow-2xl
  transform perspective-1000 rotateX-2 rotateY-3
  hover:rotateX-0 hover:rotateY-0
  transition-transform duration-500
">
  3D Card Content
</div>

// Neon Glow Card
<div className="
  bg-gray-900 rounded-xl p-6
  border border-purple-500/50
  shadow-[0_0_30px_rgba(168,85,247,0.3)]
  hover:shadow-[0_0_50px_rgba(168,85,247,0.5)]
  hover:border-purple-400
  transition-all duration-300
">
  Neon Card
</div>
```

### 3.3 Forms with Style

```tsx
// Floating Label Input
<div className="relative">
  <input className="
    peer w-full px-4 py-3 pt-6
    bg-transparent border-2 border-gray-600
    rounded-lg outline-none
    focus:border-purple-500
    transition-colors duration-300
  " />
  <label className="
    absolute left-4 top-2 text-xs text-gray-500
    peer-placeholder-shown:top-4 peer-placeholder-shown:text-base
    peer-focus:top-2 peer-focus:text-xs peer-focus:text-purple-500
    transition-all duration-300
  ">
    Email Address
  </label>
</div>

// Gradient Focus Input
<input className="
  w-full px-4 py-3 rounded-lg
  bg-gray-900 border-2 border-gray-700
  outline-none
  focus:border-transparent
  focus:bg-gradient-to-r focus:from-purple-900/20 focus:to-pink-900/20
  focus:shadow-[0_0_20px_rgba(168,85,247,0.3)]
  transition-all duration-300
"/>
```

## 4. Layout Patterns

### 4.1 Bento Grid

```tsx
<div className="grid grid-cols-4 grid-rows-3 gap-4 h-screen p-6">
  <div className="col-span-2 row-span-2 bg-gradient-to-br from-purple-500 to-pink-500 rounded-3xl p-8">
    {/* Main feature */}
  </div>
  <div className="col-span-1 row-span-1 bg-gradient-to-br from-cyan-500 to-blue-500 rounded-2xl p-6">
    {/* Small card */}
  </div>
  <div className="col-span-1 row-span-2 bg-gradient-to-br from-orange-500 to-red-500 rounded-2xl p-6">
    {/* Vertical card */}
  </div>
  <div className="col-span-2 row-span-1 bg-gradient-to-br from-green-500 to-teal-500 rounded-2xl p-6">
    {/* Horizontal card */}
  </div>
</div>
```

### 4.2 Diagonal Sections

```tsx
<section className="relative">
  <div className="
    absolute inset-0 bg-gradient-to-br from-purple-600 to-pink-600
    transform -skew-y-6 origin-top-left
  "/>
  <div className="relative z-10 py-20 px-6">
    {/* Content */}
  </div>
</section>
```

### 4.3 Overlapping Elements

```tsx
<div className="relative">
  <div className="absolute -top-10 -left-10 w-40 h-40 bg-purple-500 rounded-full opacity-50 blur-xl"/>
  <div className="absolute -bottom-10 -right-10 w-40 h-40 bg-pink-500 rounded-full opacity-50 blur-xl"/>
  <div className="relative bg-white/10 backdrop-blur-md rounded-2xl p-8">
    {/* Main content */}
  </div>
</div>
```

## 5. Animation & Motion

### 5.1 Entrance Animations

```css
@keyframes slide-up-fade {
  from {
    opacity: 0;
    transform: translateY(40px) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

@keyframes rotate-in {
  from {
    opacity: 0;
    transform: rotate(-180deg) scale(0.5);
  }
  to {
    opacity: 1;
    transform: rotate(0) scale(1);
  }
}

/* Stagger children */
.stagger > * {
  animation: slide-up-fade 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  opacity: 0;
}
.stagger > *:nth-child(1) { animation-delay: 0ms; }
.stagger > *:nth-child(2) { animation-delay: 100ms; }
.stagger > *:nth-child(3) { animation-delay: 200ms; }
```

### 5.2 Hover Effects

```css
/* Magnetic hover */
.magnetic:hover {
  transform: scale(1.05);
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

/* Tilt on hover */
.tilt:hover {
  transform: perspective(1000px) rotateX(10deg) rotateY(-10deg);
}

/* Glow pulse */
@keyframes glow-pulse {
  0%, 100% { box-shadow: 0 0 20px rgba(168, 85, 247, 0.5); }
  50% { box-shadow: 0 0 40px rgba(168, 85, 247, 0.8); }
}
.glow:hover {
  animation: glow-pulse 1.5s infinite;
}
```

## 6. Background Effects

### 6.1 Animated Gradients

```css
.animated-gradient {
  background: linear-gradient(-45deg, #ee7752, #e73c7e, #23a6d5, #23d5ab);
  background-size: 400% 400%;
  animation: gradient-shift 15s ease infinite;
}

@keyframes gradient-shift {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}
```

### 6.2 Particle Effects

```css
.particles {
  position: relative;
}

.particles::before {
  content: '';
  position: absolute;
  inset: 0;
  background-image:
    radial-gradient(circle at 20% 80%, white 0%, transparent 50%),
    radial-gradient(circle at 80% 20%, white 0%, transparent 50%),
    radial-gradient(circle at 40% 40%, white 0%, transparent 50%);
  background-size: 100% 100%, 100% 100%, 100% 100%;
  opacity: 0.1;
  animation: float 20s infinite;
}

@keyframes float {
  0%, 100% { transform: translateY(0) rotate(0deg); }
  33% { transform: translateY(-10px) rotate(120deg); }
  66% { transform: translateY(10px) rotate(240deg); }
}
```

## 7. Responsive Design

### 7.1 Fluid Typography

```css
/* Clamp for responsive sizing */
h1 {
  font-size: clamp(2rem, 5vw + 1rem, 6rem);
}

p {
  font-size: clamp(1rem, 2vw, 1.25rem);
}
```

### 7.2 Container Queries

```css
@container (min-width: 400px) {
  .card {
    grid-template-columns: 150px 1fr;
  }
}
```

## 8. Dark Mode Excellence

```tsx
// Smart dark mode with system preference
<div className="
  bg-white dark:bg-gray-900
  text-gray-900 dark:text-gray-100
  transition-colors duration-300
">
  <h1 className="
    bg-gradient-to-r
    from-purple-600 to-pink-600
    dark:from-purple-400 dark:to-pink-400
    bg-clip-text text-transparent
  ">
    Adaptive Gradients
  </h1>
</div>
```

## 9. Accessibility with Style

```tsx
// Beautiful focus states
<button className="
  focus:outline-none
  focus:ring-4 focus:ring-purple-500/50
  focus:shadow-[0_0_20px_rgba(168,85,247,0.5)]
">
  Accessible & Beautiful
</button>

// Skip links with style
<a className="
  sr-only focus:not-sr-only
  focus:absolute focus:top-4 focus:left-4
  bg-purple-600 text-white px-4 py-2 rounded-lg
  focus:shadow-lg
">
  Skip to content
</a>
```

## 10. Production Checklist

### DO's ✅
- Use vibrant color palettes
- Create dramatic typography scales
- Add motion and micro-interactions
- Use gradients and shadows
- Break conventional layouts
- Add personality to every component

### DON'Ts ❌
- Use default gray color schemes
- Stick to Inter/Roboto fonts
- Create flat, shadowless designs
- Use centered, symmetrical layouts only
- Skip hover/focus states
- Forget about dark mode

## Auto-Detection & Suggestions

When detecting generic patterns, suggest improvements:

```markdown
[DESIGN SYSTEM] Enhancement Suggestions

❌ Generic Pattern Detected:
   - Gray color palette
   - Inter font family
   - Basic card with 1px border

✅ Suggested Improvements:
   - Use vibrant gradient: from-purple-500 to-pink-500
   - Switch to Space Grotesk or Playfair Display
   - Add shadow-xl and hover effects
   - Consider glassmorphism or brutalist style

Applied Enhancement:
```

## Remember

**Your goal: Create interfaces people remember, not another generic template**

- Be bold with colors
- Use dramatic contrasts
- Add delightful animations
- Break the grid
- Make it memorable