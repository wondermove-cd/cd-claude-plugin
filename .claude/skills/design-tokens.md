---
activation-keywords:
  - design token
  - design system
  - CSS variables
  - theme
  - 테마
  - 디자인 토큰
  - color palette
  - spacing
  - typography scale
---

# Design Tokens System

## What Are Design Tokens?

Design tokens are the **single source of truth** for design decisions. They're the atomic design decisions that create consistency across all platforms.

```
Design Decision → Token → Implementation
"Primary Blue" → --color-primary → #0066CC
```

## Token Architecture

### 1. Global Tokens (Primitives)
Raw values without semantic meaning:

```css
:root {
  /* Color Primitives */
  --purple-50: #faf5ff;
  --purple-100: #f3e8ff;
  --purple-200: #e9d5ff;
  --purple-300: #d8b4fe;
  --purple-400: #c084fc;
  --purple-500: #a855f7;
  --purple-600: #9333ea;
  --purple-700: #7e22ce;
  --purple-800: #6b21a8;
  --purple-900: #581c87;

  /* Spacing Primitives */
  --space-0: 0;
  --space-1: 0.25rem;  /* 4px */
  --space-2: 0.5rem;   /* 8px */
  --space-3: 0.75rem;  /* 12px */
  --space-4: 1rem;     /* 16px */
  --space-5: 1.25rem;  /* 20px */
  --space-6: 1.5rem;   /* 24px */
  --space-8: 2rem;     /* 32px */
  --space-10: 2.5rem;  /* 40px */
  --space-12: 3rem;    /* 48px */
  --space-16: 4rem;    /* 64px */
  --space-20: 5rem;    /* 80px */
  --space-24: 6rem;    /* 96px */

  /* Type Scale Primitives */
  --font-size-xs: 0.75rem;    /* 12px */
  --font-size-sm: 0.875rem;   /* 14px */
  --font-size-md: 1rem;       /* 16px */
  --font-size-lg: 1.125rem;   /* 18px */
  --font-size-xl: 1.25rem;    /* 20px */
  --font-size-2xl: 1.5rem;    /* 24px */
  --font-size-3xl: 1.875rem;  /* 30px */
  --font-size-4xl: 2.25rem;   /* 36px */
  --font-size-5xl: 3rem;      /* 48px */
  --font-size-6xl: 3.75rem;   /* 60px */
  --font-size-7xl: 4.5rem;    /* 72px */
}
```

### 2. Semantic Tokens (Aliases)
Tokens with meaning and intent:

```css
:root {
  /* Semantic Colors */
  --color-primary: var(--purple-600);
  --color-primary-hover: var(--purple-700);
  --color-primary-active: var(--purple-800);

  --color-secondary: var(--cyan-600);
  --color-accent: var(--amber-500);

  --color-success: var(--green-600);
  --color-warning: var(--yellow-500);
  --color-danger: var(--red-600);
  --color-info: var(--blue-600);

  /* Semantic Backgrounds */
  --bg-primary: var(--gray-50);
  --bg-secondary: var(--gray-100);
  --bg-tertiary: var(--gray-200);
  --bg-inverse: var(--gray-900);

  /* Semantic Text */
  --text-primary: var(--gray-900);
  --text-secondary: var(--gray-700);
  --text-muted: var(--gray-500);
  --text-inverse: var(--gray-50);

  /* Semantic Borders */
  --border-light: var(--gray-200);
  --border-default: var(--gray-300);
  --border-heavy: var(--gray-400);
}
```

### 3. Component Tokens
Specific to components:

```css
:root {
  /* Button Tokens */
  --button-padding-x: var(--space-4);
  --button-padding-y: var(--space-2);
  --button-border-radius: var(--radius-md);
  --button-font-weight: var(--font-weight-medium);
  --button-font-size: var(--font-size-md);

  /* Card Tokens */
  --card-padding: var(--space-6);
  --card-border-radius: var(--radius-lg);
  --card-shadow: var(--shadow-md);
  --card-background: var(--bg-primary);
  --card-border: var(--border-light);

  /* Input Tokens */
  --input-height: 2.5rem;
  --input-padding-x: var(--space-3);
  --input-border-radius: var(--radius-md);
  --input-border-color: var(--border-default);
  --input-focus-ring: var(--color-primary);
}
```

## Advanced Token Systems

### 1. Responsive Tokens
```css
:root {
  /* Fluid Typography */
  --font-size-fluid-sm: clamp(0.875rem, 2vw, 1rem);
  --font-size-fluid-md: clamp(1rem, 2.5vw, 1.25rem);
  --font-size-fluid-lg: clamp(1.25rem, 3vw, 1.75rem);
  --font-size-fluid-xl: clamp(1.5rem, 4vw, 2.5rem);
  --font-size-fluid-2xl: clamp(2rem, 5vw, 4rem);
  --font-size-fluid-3xl: clamp(2.5rem, 6vw, 6rem);

  /* Responsive Spacing */
  --space-dynamic-sm: clamp(1rem, 2vw, 1.5rem);
  --space-dynamic-md: clamp(1.5rem, 3vw, 2.5rem);
  --space-dynamic-lg: clamp(2rem, 4vw, 4rem);
  --space-dynamic-xl: clamp(3rem, 6vw, 8rem);
}
```

### 2. Color System with OKLCH
```css
:root {
  /* OKLCH for better color manipulation */
  --color-primary-oklch: oklch(60% 0.15 265);
  --color-primary: oklch(var(--color-primary-oklch));

  /* Generate variations */
  --color-primary-lighter: oklch(from var(--color-primary) calc(l + 0.1) c h);
  --color-primary-darker: oklch(from var(--color-primary) calc(l - 0.1) c h);
  --color-primary-muted: oklch(from var(--color-primary) l calc(c * 0.5) h);
}
```

### 3. Motion Tokens
```css
:root {
  /* Duration */
  --duration-instant: 0ms;
  --duration-fast: 150ms;
  --duration-normal: 300ms;
  --duration-slow: 450ms;
  --duration-slower: 600ms;

  /* Easing */
  --ease-in: cubic-bezier(0.4, 0, 1, 1);
  --ease-out: cubic-bezier(0, 0, 0.2, 1);
  --ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);
  --ease-bounce: cubic-bezier(0.68, -0.55, 0.265, 1.55);
  --ease-spring: cubic-bezier(0.175, 0.885, 0.32, 1.275);
}
```

## Tailwind Integration

### tailwind.config.js with Design Tokens
```javascript
module.exports = {
  theme: {
    extend: {
      colors: {
        primary: {
          50: 'var(--purple-50)',
          100: 'var(--purple-100)',
          200: 'var(--purple-200)',
          300: 'var(--purple-300)',
          400: 'var(--purple-400)',
          500: 'var(--purple-500)',
          600: 'var(--purple-600)',
          700: 'var(--purple-700)',
          800: 'var(--purple-800)',
          900: 'var(--purple-900)',
        },
        semantic: {
          primary: 'var(--color-primary)',
          secondary: 'var(--color-secondary)',
          success: 'var(--color-success)',
          warning: 'var(--color-warning)',
          danger: 'var(--color-danger)',
        }
      },
      spacing: {
        'dynamic-sm': 'var(--space-dynamic-sm)',
        'dynamic-md': 'var(--space-dynamic-md)',
        'dynamic-lg': 'var(--space-dynamic-lg)',
      },
      fontSize: {
        'fluid-sm': 'var(--font-size-fluid-sm)',
        'fluid-md': 'var(--font-size-fluid-md)',
        'fluid-lg': 'var(--font-size-fluid-lg)',
      },
      animation: {
        'fade-in': 'fade-in var(--duration-normal) var(--ease-out)',
        'slide-up': 'slide-up var(--duration-normal) var(--ease-spring)',
        'scale-in': 'scale-in var(--duration-fast) var(--ease-bounce)',
      }
    }
  }
}
```

## Dark Mode Tokens

### Automatic Dark Mode
```css
:root {
  --bg-primary: #ffffff;
  --text-primary: #0a0a0a;
  --border-default: #e5e5e5;
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg-primary: #0a0a0a;
    --text-primary: #fafafa;
    --border-default: #262626;
  }
}

/* Or with class-based toggle */
.dark {
  --bg-primary: #0a0a0a;
  --text-primary: #fafafa;
  --border-default: #262626;
}
```

### Smart Color Inversion
```css
:root {
  /* Light mode uses HSL lightness 20% for text */
  --text-primary: hsl(0 0% 20%);
  /* Borders at lightness 80% */
  --border-default: hsl(0 0% 80%);
}

.dark {
  /* Dark mode inverts: 20% → 90% */
  --text-primary: hsl(0 0% 90%);
  /* Borders: 80% → 20% */
  --border-default: hsl(0 0% 20%);
}
```

## Token Organization

### File Structure
```
design-tokens/
├── primitives/
│   ├── colors.css
│   ├── spacing.css
│   ├── typography.css
│   └── motion.css
├── semantic/
│   ├── colors.css
│   ├── backgrounds.css
│   ├── borders.css
│   └── shadows.css
├── components/
│   ├── button.css
│   ├── card.css
│   ├── input.css
│   └── modal.css
└── themes/
    ├── light.css
    ├── dark.css
    └── contrast.css
```

### JSON Format for Multi-Platform
```json
{
  "color": {
    "primary": {
      "value": "#9333ea",
      "type": "color",
      "description": "Primary brand color"
    },
    "text": {
      "primary": {
        "value": "{color.gray.900}",
        "type": "color",
        "description": "Primary text color"
      }
    }
  },
  "spacing": {
    "sm": {
      "value": "8px",
      "type": "spacing"
    },
    "md": {
      "value": "16px",
      "type": "spacing"
    }
  }
}
```

## Token Usage Examples

### Component Implementation
```tsx
// Using tokens in styled-components
const Button = styled.button`
  padding: var(--button-padding-y) var(--button-padding-x);
  background: var(--color-primary);
  color: var(--text-inverse);
  border-radius: var(--button-border-radius);
  font-weight: var(--button-font-weight);
  transition: all var(--duration-fast) var(--ease-out);

  &:hover {
    background: var(--color-primary-hover);
    transform: translateY(-2px);
  }
`;

// Or with Tailwind
<button className="
  px-[var(--button-padding-x)]
  py-[var(--button-padding-y)]
  bg-semantic-primary
  text-white
  rounded-[var(--button-border-radius)]
  transition-all
  duration-[var(--duration-fast)]
  hover:-translate-y-0.5
">
  Click Me
</button>
```

## Token Generation Tools

### Style Dictionary Config
```javascript
// style-dictionary.config.js
module.exports = {
  source: ['tokens/**/*.json'],
  platforms: {
    css: {
      transformGroup: 'css',
      buildPath: 'dist/',
      files: [{
        destination: 'tokens.css',
        format: 'css/variables'
      }]
    },
    js: {
      transformGroup: 'js',
      buildPath: 'dist/',
      files: [{
        destination: 'tokens.js',
        format: 'javascript/es6'
      }]
    },
    scss: {
      transformGroup: 'scss',
      buildPath: 'dist/',
      files: [{
        destination: 'tokens.scss',
        format: 'scss/variables'
      }]
    }
  }
};
```

## Token Best Practices

### DO's ✅
- Use semantic naming (--color-primary not --color-purple)
- Create token hierarchies (primitive → semantic → component)
- Document token purpose and usage
- Version your tokens
- Test tokens across themes
- Use design token tools for consistency
- Keep tokens platform-agnostic

### DON'Ts ❌
- Don't hardcode values in components
- Don't create tokens for one-off values
- Don't mix concerns (--button-primary-background-hover is too specific)
- Don't forget fallback values
- Don't ignore accessibility (contrast ratios)

## Token Testing

### Contrast Checking
```javascript
function checkContrast(fg, bg) {
  const contrast = getContrastRatio(fg, bg);
  return {
    AA: contrast >= 4.5,
    AAA: contrast >= 7,
    largeAA: contrast >= 3,
    largeAAA: contrast >= 4.5
  };
}

// Test all combinations
const textColors = ['--text-primary', '--text-secondary'];
const bgColors = ['--bg-primary', '--bg-secondary'];

textColors.forEach(text => {
  bgColors.forEach(bg => {
    const result = checkContrast(
      getCSSVariable(text),
      getCSSVariable(bg)
    );
    console.log(`${text} on ${bg}:`, result);
  });
});
```

## Remember

**Design tokens are your design DNA. They ensure consistency, enable theming, and bridge design and development.**

Well-architected tokens make your design system:
- Maintainable
- Scalable
- Platform-agnostic
- Theme-able
- Accessible

항상 토큰을 통해 디자인 결정을 구현하세요!