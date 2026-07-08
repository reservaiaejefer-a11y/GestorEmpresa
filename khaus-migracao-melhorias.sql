-- Execute no SQL Editor do Supabase (adicionar ao banco existente)
-- Adiciona campo de custo ao pedido, para calcular margem de lucro

ALTER TABLE public.pedidos
  ADD COLUMN IF NOT EXISTS custo_total DECIMAL(10,2) DEFAULT 0;
