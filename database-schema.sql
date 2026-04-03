-- ============================================================
-- ITCM EMPRENDE - Esquema de Base de Datos para Supabase
-- Marketplace C2C del Instituto Tecnológico de Ciudad Madero
-- ============================================================

-- ========== 1. TABLA DE CATEGORÍAS ==========
CREATE TABLE categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  icon TEXT, -- emoji o nombre de ícono
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Categorías iniciales
INSERT INTO categories (name, description, icon) VALUES
  ('Alimentos y Bebidas', 'Comida casera, repostería, snacks, bebidas', '🍔'),
  ('Material Escolar', 'Apuntes, calculadoras, libros, papelería', '📚'),
  ('Tecnología', 'Reparaciones, accesorios, gadgets', '💻'),
  ('Servicios Académicos', 'Tutorías, asesorías, diseño gráfico', '🎓'),
  ('Ropa y Accesorios', 'Uniformes, playeras, accesorios', '👕'),
  ('Arte y Manualidades', 'Artesanías, stickers, productos personalizados', '🎨'),
  ('Otros', 'Productos y servicios varios', '📦');

-- ========== 2. TABLA DE PERFILES DE USUARIO ==========
-- Se vincula con auth.users de Supabase
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  phone TEXT, -- número de WhatsApp
  role TEXT NOT NULL DEFAULT 'client' CHECK (role IN ('superadmin', 'vendor', 'client')),
  control_number TEXT, -- número de control extraído del correo
  enrollment_year INT, -- año de ingreso extraído del número de control
  career TEXT, -- carrera del estudiante (ej: 'Ingeniería en Sistemas Computacionales')
  is_active BOOLEAN DEFAULT true,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ========== 3. TABLA DE SOLICITUDES DE VENDEDOR ==========
CREATE TABLE vendor_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  applicant_name TEXT NOT NULL,
  applicant_email TEXT NOT NULL, -- correo institucional del solicitante
  applicant_phone TEXT NOT NULL, -- WhatsApp del solicitante
  business_name TEXT NOT NULL, -- nombre del negocio/emprendimiento
  business_description TEXT NOT NULL,
  category_id UUID REFERENCES categories(id),
  product_photos TEXT[] DEFAULT '{}', -- URLs de fotos en Supabase Storage
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  rejection_reason TEXT,
  -- Credenciales generadas por el Comité al aprobar
  generated_username TEXT,
  generated_email TEXT, -- correo de vendedor generado por el comité
  reviewed_by UUID REFERENCES profiles(id),
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ========== 4. TABLA DE PRODUCTOS ==========
CREATE TABLE products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  vendor_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  category_id UUID REFERENCES categories(id) NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
  image_url TEXT, -- URL de imagen en Supabase Storage
  is_available BOOLEAN DEFAULT true,
  stock INT DEFAULT -1, -- -1 = ilimitado
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ========== 5. TABLA DE PEDIDOS ==========
CREATE TABLE orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  client_id UUID REFERENCES profiles(id) NOT NULL,
  vendor_id UUID REFERENCES profiles(id) NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent_whatsapp', 'completed', 'cancelled')),
  total DECIMAL(10,2) NOT NULL,
  whatsapp_message TEXT, -- mensaje generado para WhatsApp
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ========== 6. TABLA DE ITEMS DEL PEDIDO ==========
CREATE TABLE order_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES products(id) NOT NULL,
  product_name TEXT NOT NULL, -- snapshot del nombre al momento del pedido
  quantity INT NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL
);

-- ========== 7. TABLA DE SOPORTE ==========
CREATE TABLE support_tickets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  requester_id UUID REFERENCES profiles(id),
  requester_email TEXT NOT NULL,
  subject TEXT NOT NULL,
  description TEXT NOT NULL,
  ticket_type TEXT DEFAULT 'general' CHECK (ticket_type IN ('password_reset', 'account_recovery', 'report', 'general')),
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
  resolved_by UUID REFERENCES profiles(id),
  resolution_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ========== ÍNDICES PARA RENDIMIENTO ==========
CREATE INDEX idx_products_vendor ON products(vendor_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_available ON products(is_available);
CREATE INDEX idx_orders_client ON orders(client_id);
CREATE INDEX idx_orders_vendor ON orders(vendor_id);
CREATE INDEX idx_vendor_requests_status ON vendor_requests(status);
CREATE INDEX idx_profiles_role ON profiles(role);

-- ========== ROW LEVEL SECURITY (RLS) ==========
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

-- Políticas de Categorías (lectura pública)
CREATE POLICY "categories_read" ON categories FOR SELECT USING (true);
CREATE POLICY "categories_admin" ON categories FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'superadmin'));

-- Políticas de Perfiles
CREATE POLICY "profiles_read_own" ON profiles FOR SELECT
  USING (id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'superadmin'));
CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE USING (id = auth.uid());
CREATE POLICY "profiles_admin_all" ON profiles FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'superadmin'));

-- Políticas de Productos (lectura pública, escritura solo vendedor dueño)
CREATE POLICY "products_read" ON products FOR SELECT USING (true);
CREATE POLICY "products_vendor_insert" ON products FOR INSERT
  WITH CHECK (vendor_id = auth.uid() AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'vendor'));
CREATE POLICY "products_vendor_update" ON products FOR UPDATE
  USING (vendor_id = auth.uid());
CREATE POLICY "products_vendor_delete" ON products FOR DELETE
  USING (vendor_id = auth.uid());
CREATE POLICY "products_admin" ON products FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'superadmin'));

-- Políticas de Pedidos
CREATE POLICY "orders_client_read" ON orders FOR SELECT
  USING (client_id = auth.uid() OR vendor_id = auth.uid());
CREATE POLICY "orders_client_insert" ON orders FOR INSERT
  WITH CHECK (client_id = auth.uid());
CREATE POLICY "orders_admin" ON orders FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'superadmin'));

-- Políticas de Items de Pedido
CREATE POLICY "order_items_read" ON order_items FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM orders WHERE orders.id = order_items.order_id
    AND (orders.client_id = auth.uid() OR orders.vendor_id = auth.uid())
  ));
CREATE POLICY "order_items_insert" ON order_items FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.client_id = auth.uid()
  ));

-- Políticas de Solicitudes de Vendedor
CREATE POLICY "vendor_requests_insert" ON vendor_requests FOR INSERT WITH CHECK (true);
CREATE POLICY "vendor_requests_read_own" ON vendor_requests FOR SELECT
  USING (applicant_email = (SELECT email FROM profiles WHERE id = auth.uid())
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'superadmin'));
CREATE POLICY "vendor_requests_admin" ON vendor_requests FOR UPDATE
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'superadmin'));

-- Políticas de Soporte
CREATE POLICY "support_read" ON support_tickets FOR SELECT
  USING (requester_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'superadmin'));
CREATE POLICY "support_insert" ON support_tickets FOR INSERT WITH CHECK (true);
CREATE POLICY "support_admin" ON support_tickets FOR UPDATE
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'superadmin'));

-- ========== FUNCIÓN: Crear perfil automáticamente al registrarse ==========
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Usuario'),
    COALESCE(NEW.raw_user_meta_data->>'role', 'client')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ========== STORAGE BUCKETS (ejecutar desde Dashboard) ==========
-- Crear bucket: product-images (público)
-- Crear bucket: request-photos (privado, solo superadmin puede leer)
