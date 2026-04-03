# ITCM Emprende — Tu Mercado Académico en un Click

PWA Marketplace C2C para el Instituto Tecnológico de Ciudad Madero.  
React 18 + Vite + Tailwind CSS + Supabase + Netlify.

## Inicio rápido

```bash
npm install
# Editar src/lib/supabase.js con tus credenciales
npm run dev
```

## Estructura

```
src/
├── lib/           → supabase.js, validation.js, cart.js
├── hooks/         → useAuth.jsx, useCart.jsx
├── components/    → AppShell (header + nav)
├── pages/         → AuthPage, Catalog, Cart, Orders, Vendor*, Admin*
└── styles/        → globals.css (Tailwind)
```

## Roles

| Rol | Acceso | Rutas |
|-----|--------|-------|
| Cliente | Correo institucional | `/`, `/carrito`, `/pedidos` |
| Vendedor | Credenciales del Comité | `/vendedor/*` |
| Comité | Login exclusivo | `/admin/*` |

## Deploy

```bash
npm run build   # Genera /dist
# Subir a Netlify (auto con netlify.toml)
```

## Equipo

Alonso Palafox, Alvarado Isidro, Mata Barcenas, Dávila Hernández  
ISC · ITCM · Ene–Jun 2026
