# 🛠️ Guía Paso a Paso: Configurar Supabase para ITCM Emprende

## Paso 1: Crear cuenta y proyecto en Supabase

1. Ve a **https://supabase.com** y crea una cuenta (puedes usar GitHub).
2. Haz clic en **"New Project"**.
3. Configura:
   - **Organization**: Crea una o usa la que te aparece.
   - **Project name**: `itcm-emprende`
   - **Database Password**: Genera una contraseña segura y **guárdala**.
   - **Region**: `South America (São Paulo)` (la más cercana a México).
   - **Plan**: Free (suficiente para desarrollo y pruebas).
4. Espera ~2 minutos a que se cree el proyecto.

## Paso 2: Obtener tus credenciales

1. Ve a **Settings → API** en el menú lateral izquierdo.
2. Copia estos dos valores (los necesitarás en el código):
   - **Project URL**: `https://TU_ID.supabase.co`
   - **anon public key**: `eyJhbGciOiJI...` (la clave larga)
3. Abre el archivo `src/lib/supabase.js` del proyecto y pega estos valores.

## Paso 3: Ejecutar el esquema SQL

1. Ve a **SQL Editor** en el menú lateral.
2. Haz clic en **"New query"**.
3. Abre el archivo `database/schema.sql` de este proyecto.
4. Copia TODO el contenido y pégalo en el editor SQL.
5. Haz clic en **"Run"** (el botón verde).
6. Deberías ver "Success. No rows returned" — eso está bien.

## Paso 4: Configurar Storage (para fotos de productos)

1. Ve a **Storage** en el menú lateral.
2. Haz clic en **"New bucket"**.
3. Crea el primer bucket:
   - **Name**: `product-images`
   - **Public bucket**: ✅ Activado
   - Clic en "Create bucket"
4. Crea el segundo bucket:
   - **Name**: `request-photos`
   - **Public bucket**: ❌ Desactivado
   - Clic en "Create bucket"

### Políticas de Storage para product-images:
1. Entra al bucket `product-images`.
2. Ve a **Policies** → **New Policy** → **For full customization**.
3. Crear política de LECTURA:
   - Policy name: `Public Read`
   - Allowed operation: `SELECT`
   - Target roles: `anon, authenticated`
   - Policy definition: `true`
4. Crear política de ESCRITURA:
   - Policy name: `Vendor Upload`
   - Allowed operation: `INSERT`
   - Target roles: `authenticated`
   - Policy definition: `true`

## Paso 5: Configurar Autenticación

1. Ve a **Authentication → Providers** en el menú lateral.
2. El proveedor **Email** ya debe estar habilitado por defecto.
3. En **Authentication → URL Configuration**:
   - **Site URL**: `https://tu-sitio.netlify.app` (lo actualizarás después de subir a Netlify)
   - **Redirect URLs**: Agrega `https://tu-sitio.netlify.app/**`

## Paso 6: Crear la cuenta SuperAdmin (Comité)

⚠️ IMPORTANTE: Esta cuenta se crea manualmente como dice el protocolo.

1. Ve a **Authentication → Users** → **Add user** → **Create new user**.
2. Escribe:
   - Email: `comite@itcmemprende.com` (o el que decidan)
   - Password: Una contraseña segura
   - Marca "Auto Confirm User"
3. Una vez creado, copia el **User UID** que aparece.
4. Ve a **SQL Editor** y ejecuta:

```sql
UPDATE profiles
SET role = 'superadmin', full_name = 'Comité Estudiantil ITCM'
WHERE id = 'PEGA_EL_UID_AQUÍ';
```

5. ¡Listo! Ya tienes tu cuenta de SuperAdmin.

## Paso 7: Desplegar en Netlify

1. Sube los archivos del proyecto a un repositorio de GitHub.
2. Ve a **https://app.netlify.com** → **Add new site** → **Import from Git**.
3. Conecta tu repositorio de GitHub.
4. Configuración de build:
   - **Build command**: `npm run build`
   - **Publish directory**: `dist`
5. Haz clic en **Deploy**.
6. Una vez desplegado, copia la URL (ej: `https://itcm-emprende.netlify.app`).
7. Regresa a Supabase → **Authentication → URL Configuration** y actualiza la **Site URL** con tu URL de Netlify.

### Nota: Si prefieres hacer build local
```bash
npm install
npm run build
# Sube la carpeta "dist" generada a Netlify (drag & drop)
```

## ✅ Checklist final

- [ ] Proyecto de Supabase creado
- [ ] Credenciales copiadas en `js/config.js`
- [ ] Esquema SQL ejecutado sin errores
- [ ] Buckets de Storage creados con sus políticas
- [ ] Cuenta SuperAdmin creada y role actualizado
- [ ] Proyecto subido a GitHub
- [ ] Desplegado en Netlify
- [ ] URLs de autenticación actualizadas
