-- JÁ APLICADO no Supabase em 04/11/2026 (migrações seguranca_acesso_por_perfil e
-- seguranca_funcoes_em_schema_privado). Fica aqui como registro e para recriar o banco.
--
-- O QUE FAZ: só acessa os dados quem tem perfil em Configuração → Usuários, e só
-- Administradores podem criar, alterar ou remover usuários. Uma conta criada por fora
-- (cadastro público do Supabase) não enxerga nada.

-- 1) Funções de verificação, num schema interno que não fica exposto na API
CREATE SCHEMA IF NOT EXISTS privado;
REVOKE ALL ON SCHEMA privado FROM PUBLIC;
GRANT USAGE ON SCHEMA privado TO authenticated;

CREATE OR REPLACE FUNCTION privado.eh_membro() RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid());
$$;
CREATE OR REPLACE FUNCTION privado.eh_admin() RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'gerencial');
$$;
REVOKE ALL ON FUNCTION privado.eh_membro(), privado.eh_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION privado.eh_membro(), privado.eh_admin() TO authenticated;

-- 2) Remove as regras anteriores das tabelas do sistema
DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public'
    AND tablename IN ('profiles','produtos','clientes','pedidos','contas_receber','contas_pagar','lancamentos','vendas','metas')
  LOOP EXECUTE format('DROP POLICY %I ON public.%I', r.policyname, r.tablename); END LOOP;
END $$;

-- 3) Dados da empresa: só usuários com perfil no sistema
DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['produtos','clientes','pedidos','contas_receber','contas_pagar','lancamentos','vendas','metas'] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('CREATE POLICY membros ON public.%I FOR ALL TO authenticated USING (privado.eh_membro()) WITH CHECK (privado.eh_membro())', t);
  END LOOP;
END $$;

-- 4) Usuários: todos com perfil veem a lista; só Administradores criam, alteram ou removem
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY perfis_ler   ON public.profiles FOR SELECT TO authenticated USING (privado.eh_membro());
CREATE POLICY perfis_admin ON public.profiles FOR ALL    TO authenticated USING (privado.eh_admin()) WITH CHECK (privado.eh_admin());

-- ─────────────────────────────────────────────────────────────────────────────
-- PARA DESFAZER (volta ao acesso livre anterior). Só rode se algo der errado:
--
-- DO $$ DECLARE r record; BEGIN
--   FOR r IN SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public'
--     AND tablename IN ('profiles','produtos','clientes','pedidos','contas_receber','contas_pagar','lancamentos','vendas','metas')
--   LOOP EXECUTE format('DROP POLICY %I ON public.%I', r.policyname, r.tablename); END LOOP;
-- END $$;
-- DO $$ DECLARE t text; BEGIN
--   FOREACH t IN ARRAY ARRAY['profiles','produtos','clientes','pedidos','contas_receber','contas_pagar','lancamentos','vendas','metas'] LOOP
--     EXECUTE format('CREATE POLICY auth_all ON public.%I FOR ALL TO authenticated USING (true) WITH CHECK (true)', t);
--   END LOOP;
-- END $$;
