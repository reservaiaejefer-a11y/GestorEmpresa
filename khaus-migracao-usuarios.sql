-- Execute no SQL Editor do Supabase (adicionar ao banco existente)
-- Necessário para a nova aba Configuração → Usuários

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS email TEXT;
