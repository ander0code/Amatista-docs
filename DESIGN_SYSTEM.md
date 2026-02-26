# Amatista — Design System

> Guía de referencia de marca y UI. Usar este documento antes de implementar cualquier cambio visual.

---

## Logo

El logo de **AMATISTA** consta de:
- Símbolo floral con tipografía serif elegante para "AMATISTA" y sans-serif espaciada para "DETALLES QUE ENAMORAN".
- Archivos disponibles en `/Amatista-docs/`:
  - `AMATISTA-LOGO-SVG.svg` — versión principal (sobre fondos claros)
  - `AMATISTA-LOGO-INVERTIDO-SVG.svg` — versión invertida (sobre fondos oscuros/degradado)
  - `AMATISTA-LOGO-JPG.png` — versión raster para uso general

---

## Paleta de Colores

| Token             | Nombre              | Hex       | Uso principal                                              |
|-------------------|---------------------|-----------|------------------------------------------------------------|
| `primary`         | Púrpura Amatista    | `#8E338A` | Botón principal (CTA), links activos, tabs seleccionados   |
| `primary-hover`   | Púrpura Oscuro      | `#72287E` | Hover del botón principal (10% más oscuro)                 |
| `accent-orange`   | Naranja Atardecer   | `#F28E2B` | Parte superior del degradado, alertas, estados activos     |
| `accent-pink`     | Rosa Vibrante       | `#D81B60` | Transición central del degradado, botones secundarios      |
| `brand-surface`   | Rosa Nude           | `#FFF5F7` | Fondo del panel izquierdo (login), áreas de contenido      |
| `brand-white`     | Blanco Puro         | `#FFFFFF` | Fondo de inputs, tarjetas flotantes                        |
| `brand-border`    | Gris Suave          | `#E0E0E0` | Bordes de inputs, tarjetas, divisores de sección           |
| `brand-placeholder`| Gris Medio         | `#B0B0B0` | Placeholders y textos de ayuda                             |
| `brand-dark`      | Negro Suave         | `#1A1A2E` | Títulos H1/H2, textos de alto contraste                    |
| `brand-body`      | Gris Pizarra        | `#555555` | Descripciones, labels de formulario, textos secundarios    |

### Degradado de marca (panel derecho del login y elementos destacados)

```
Inicio   (top):    #F28E2B  — Naranja Atardecer
Medio    (center): #D81B60  — Rosa Vibrante
Fin      (bottom): #8E338A  — Púrpura Amatista
```

```css
background: linear-gradient(180deg, #F28E2B 0%, #D81B60 50%, #8E338A 100%);
```

### Variables CSS (implementadas en `themes.css`)

```css
--color-primary:          #8E338A;   /* Púrpura Amatista — CTA principal */
--color-primary-hover:    #72287E;   /* Púrpura Oscuro — hover */
--color-accent-orange:    #F28E2B;   /* Naranja Atardecer — degradado top */
--color-accent-pink:      #D81B60;   /* Rosa Vibrante — degradado mid */
--color-brand-surface:    #FFF5F7;   /* Rosa Nude — fondo suave */
--color-brand-white:      #FFFFFF;   /* Blanco Puro — inputs */
--color-brand-border:     #E0E0E0;   /* Gris Suave — bordes */
--color-brand-placeholder:#B0B0B0;   /* Gris Medio — placeholders */
--color-brand-dark:       #1A1A2E;   /* Negro Suave — títulos */
--color-brand-body:       #555555;   /* Gris Pizarra — cuerpo */
```

---

## Tipografía

| Rol               | Familia              | Peso(s)        | Uso                                               |
|-------------------|----------------------|----------------|---------------------------------------------------|
| Títulos (H1–H3)   | **Playfair Display** | 600, 700       | Nombre de empresa, encabezados de sección         |
| Cuerpo y UI       | **Montserrat**       | 400, 500, 600  | Párrafos, labels, botones, navegación, inputs     |

### Importación en `style.css`

```css
@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=Montserrat:wght@400;500;600&display=swap');
```

### Variables CSS

```css
--font-heading: 'Playfair Display', Georgia, serif;
--font-body:    'Montserrat', system-ui, sans-serif;
```

---

## Escala de uso de color primario

- **Botón de acción principal**: `bg-primary text-white` → Púrpura Amatista sólido
- **Hover de botón**: `#72287E` (10% más oscuro)
- **Links activos / tabs seleccionados**: `text-primary`
- **Bordes de focus en inputs**: `border-primary`
- **Badges / chips**: `bg-primary/10 text-primary`

---

## Fondo de página

- Light mode: `#FFF5F7` (Rosa Nude)
- Panel con degradado (login derecho, banners): `linear-gradient(180deg, #F28E2B, #D81B60, #8E338A)`

---

## Efectos visuales

- **Border-radius botones**: `8px` (look moderno y amigable)
- **Glassmorphism** (tarjetas sobre el degradado):
  ```css
  background: rgba(255, 255, 255, 0.20);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.30);
  border-radius: 16px;
  ```

---

## Notas de implementación

1. El `primary` en `tailwind.config.ts` y `themes.css` pasa de `#3b82f6` (azul) a `#8E338A` (púrpura).
2. El `body-bg` en light mode pasa de blanco/crema a `#FFF5F7` (rosa nude).
3. Los colores `default-*` de zinc se conservan para los grises del sistema; solo se sobreescribe `primary` y `body-bg`.
4. La fuente `Inter`/`DM Sans` del template original se reemplaza por `Montserrat` en el cuerpo.
5. `Playfair Display` se usa exclusivamente en headings H1–H3 de marca.
6. El degradado `#F28E2B → #D81B60 → #8E338A` se aplica al panel derecho del login y elementos hero.
