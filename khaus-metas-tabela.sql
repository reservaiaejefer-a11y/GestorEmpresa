-- Execute no SQL Editor do Supabase (adicionar ao banco existente)
CREATE TABLE IF NOT EXISTS public.metas (
  id   UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  ano  INTEGER NOT NULL,
  mes  INTEGER NOT NULL CHECK (mes BETWEEN 1 AND 12),
  valor DECIMAL(10,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(ano, mes)
);
ALTER TABLE public.metas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "auth_all" ON public.metas
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
