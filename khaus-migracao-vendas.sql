-- Execute no SQL Editor do Supabase (adicionar ao banco existente)
-- Necessário para a nova aba "Vendas do Dia"

CREATE TABLE IF NOT EXISTS public.vendas (
  id            UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  item          TEXT NOT NULL,
  quantidade    DECIMAL(10,2) NOT NULL DEFAULT 1,
  valor_unitario DECIMAL(10,2) NOT NULL DEFAULT 0,
  valor_total   DECIMAL(10,2) NOT NULL DEFAULT 0,
  data          DATE NOT NULL DEFAULT CURRENT_DATE,
  vendedor_nome TEXT,
  vendedor_id   UUID,
  lancamento_id UUID,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.vendas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "auth_all" ON public.vendas
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
