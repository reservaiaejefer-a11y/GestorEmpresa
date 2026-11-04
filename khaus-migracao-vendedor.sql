-- Execute no SQL Editor do Supabase ANTES de subir o novo index.html
-- Dashboard > SQL Editor > New Query > cole tudo > Run

-- Vendedor responsável por cada pedido (alimenta o quadro de vendedores do Dashboard)
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS vendedor_nome TEXT;

-- Marca dos pedidos concluídos automaticamente na limpeza: guarda o status original
-- para poder voltar (botão "Voltar para..." na aba Pedidos)
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS status_anterior TEXT;

-- Faz a API do Supabase enxergar as colunas novas na hora
NOTIFY pgrst, 'reload schema';

-- ─────────────────────────────────────────────────────────────────────────────
-- PARA DESFAZER A LIMPEZA DE UMA VEZ (todos os pedidos concluídos automaticamente
-- voltam ao status que tinham antes). Só rode se precisar:
--
-- UPDATE public.pedidos
--   SET status = status_anterior,
--       progresso = CASE status_anterior WHEN 'Produção' THEN 50 WHEN 'Entrega' THEN 85 ELSE 0 END,
--       status_anterior = NULL
-- WHERE status_anterior IS NOT NULL;
