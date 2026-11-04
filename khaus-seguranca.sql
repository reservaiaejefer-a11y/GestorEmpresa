-- Execute no SQL Editor do Supabase (depois que o sistema novo estiver funcionando)
-- Dashboard > SQL Editor > New Query > cole tudo > Run
--
-- O QUE MUDA: hoje qualquer conta criada no Supabase (inclusive alguém de fora que
-- se cadastre sozinho usando o endereço do sistema) consegue ler e alterar tudo.
-- Depois deste script, só acessa os dados quem tem perfil em Configuração → Usuários,
-- e só Administradores podem criar ou remover usuários.

-- 1) Funções que verificam se quem está logado tem perfil / é administrador
CREATE OR REPLACE FUNCTION public.eh_membro() RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid());
$$;

CREATE OR REPLACE FUNCTION public.eh_admin() RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'gerencial');
$$;

-- 2) Remove as regras atuais, que liberam tudo para qualquer conta logada
DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public'
    AND tablename IN ('profiles','produtos','clientes','pedidos','contas_receber','contas_pagar','lancamentos','vendas','metas')
  LOOP EXECUTE format('DROP POLICY %I ON public.%I', r.policyname, r.tablename); END LOOP;
END $$;

-- 3) Dados da empresa: só usuários com perfil no sistema
DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['produtos','clientes','pedidos','contas_receber','contas_pagar','lancamentos','vendas','metas'] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('CREATE POLICY membros ON public.%I FOR ALL TO authenticated USING (public.eh_membro()) WITH CHECK (public.eh_membro())', t);
  END LOOP;
END $$;

-- 4) Usuários: todos com perfil podem ver a lista; só Administradores criam, alteram ou removem
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY perfis_ler   ON public.profiles FOR SELECT TO authenticated USING (public.eh_membro());
CREATE POLICY perfis_admin ON public.profiles FOR ALL    TO authenticated USING (public.eh_admin()) WITH CHECK (public.eh_admin());

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
