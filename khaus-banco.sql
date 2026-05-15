-- =============================================
--  KHAUS BRINDES CORPORATIVOS
--  Script de criação do banco de dados
--  Execute no SQL Editor do Supabase
--  Dashboard > SQL Editor > New Query
-- =============================================

-- ── 1. EXTENSÃO UUID ─────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── 2. PERFIS DE USUÁRIO ─────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id      UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  nome    TEXT NOT NULL,
  role    TEXT NOT NULL CHECK (role IN ('gerencial', 'administrativo')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 3. PRODUTOS / ESTOQUE ────────────────────
CREATE TABLE IF NOT EXISTS public.produtos (
  id             UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  nome           TEXT NOT NULL,
  categoria      TEXT NOT NULL DEFAULT 'Geral',
  quantidade     INTEGER NOT NULL DEFAULT 0,
  estoque_minimo INTEGER NOT NULL DEFAULT 0,
  custo          DECIMAL(10,2) NOT NULL DEFAULT 0,
  preco          DECIMAL(10,2) NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ── 4. CLIENTES ───────────────────────────────
CREATE TABLE IF NOT EXISTS public.clientes (
  id         UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  nome       TEXT NOT NULL,
  setor      TEXT DEFAULT '',
  email      TEXT DEFAULT '',
  telefone   TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 5. PEDIDOS ────────────────────────────────
CREATE TABLE IF NOT EXISTS public.pedidos (
  id               UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  codigo           TEXT UNIQUE NOT NULL,
  cliente_nome     TEXT NOT NULL,
  valor_total      DECIMAL(10,2) NOT NULL DEFAULT 0,
  quantidade_itens INTEGER NOT NULL DEFAULT 0,
  prazo            DATE,
  status           TEXT NOT NULL DEFAULT 'Orçamento'
    CHECK (status IN ('Orçamento','Aprovação','Arte','Produção','Entrega','Concluído')),
  progresso        INTEGER NOT NULL DEFAULT 0 CHECK (progresso BETWEEN 0 AND 100),
  observacoes      TEXT DEFAULT '',
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ── 6. CONTAS A RECEBER ───────────────────────
CREATE TABLE IF NOT EXISTS public.contas_receber (
  id           UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  cliente_nome TEXT NOT NULL,
  vencimento   DATE NOT NULL,
  valor        DECIMAL(10,2) NOT NULL,
  status       TEXT NOT NULL DEFAULT 'A vencer'
    CHECK (status IN ('A vencer','Vencido','Pago')),
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── 7. CONTAS A PAGAR ─────────────────────────
CREATE TABLE IF NOT EXISTS public.contas_pagar (
  id         UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  fornecedor TEXT NOT NULL,
  vencimento DATE NOT NULL,
  valor      DECIMAL(10,2) NOT NULL,
  categoria  TEXT NOT NULL DEFAULT 'Outros',
  status     TEXT NOT NULL DEFAULT 'Pendente'
    CHECK (status IN ('Pendente','Pago')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 8. LANÇAMENTOS FINANCEIROS ────────────────
CREATE TABLE IF NOT EXISTS public.lancamentos (
  id         UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  tipo       TEXT NOT NULL CHECK (tipo IN ('receita','despesa')),
  descricao  TEXT NOT NULL,
  valor      DECIMAL(10,2) NOT NULL,
  data       DATE NOT NULL,
  categoria  TEXT DEFAULT 'Geral',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 9. SEGURANÇA (RLS) ────────────────────────
ALTER TABLE public.profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produtos       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contas_receber ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contas_pagar   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lancamentos    ENABLE ROW LEVEL SECURITY;

-- Usuários autenticados têm acesso total às tabelas
CREATE POLICY "auth_all" ON public.profiles      FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON public.produtos       FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON public.clientes       FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON public.pedidos        FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON public.contas_receber FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON public.contas_pagar   FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON public.lancamentos    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ── 10. DADOS DE EXEMPLO ──────────────────────
INSERT INTO public.clientes (nome, setor, email, telefone) VALUES
  ('Banco Meridian S.A.',  'Financeiro',  'compras@meridian.com.br',   '(11) 3000-1234'),
  ('TechCorp Brasil',      'Tecnologia',  'marketing@techcorp.com.br', '(11) 9800-5678'),
  ('Construtora Ômega',    'Construção',  'rh@omega.com.br',           '(21) 2500-9012'),
  ('Farmácias Viva+',      'Saúde',       'brindes@vivamais.com.br',   '(31) 3400-3456'),
  ('Seguradora Atlas',     'Seguros',     'eventos@atlas.com.br',      '(11) 4500-7890');

INSERT INTO public.produtos (nome, categoria, quantidade, estoque_minimo, custo, preco) VALUES
  ('Caneta Executiva Twist', 'Escrita',    850, 200, 4.50,  15.00),
  ('Mochila Executiva 20L',  'Bolsas',     42,  50,  65.00, 140.00),
  ('Squeeze Inox 500ml',     'Bebidas',    310, 100, 8.00,  15.00),
  ('Caderno Capa Dura A5',   'Escritório', 28,  50,  12.00, 25.00),
  ('Camiseta Dryfit P/M/G',  'Vestuário',  180, 100, 14.00, 25.00),
  ('Caneca Cerâmica 300ml',  'Bebidas',    95,  80,  7.50,  18.00),
  ('Power Bank 10000mAh',    'Tecnologia', 15,  30,  45.00, 90.00),
  ('Agenda 2025 Couché',     'Escritório', 120, 100, 22.00, 45.00);

INSERT INTO public.pedidos (codigo, cliente_nome, valor_total, quantidade_itens, prazo, status, progresso) VALUES
  ('PED-2025-0482', 'Banco Meridian S.A.',  18500, 500, NOW() + INTERVAL '4 days',  'Produção',   65),
  ('PED-2025-0483', 'TechCorp Brasil',       7200,  120, NOW() + INTERVAL '7 days',  'Arte',        30),
  ('PED-2025-0484', 'Construtora Ômega',    32000, 800, NOW() + INTERVAL '11 days', 'Aprovação',   15),
  ('PED-2025-0485', 'Farmácias Viva+',       4500,  200, NOW() + INTERVAL '3 days',  'Entrega',     90),
  ('PED-2025-0486', 'Seguradora Atlas',     22000, 600, NOW() + INTERVAL '9 days',  'Produção',    50);

INSERT INTO public.contas_receber (cliente_nome, vencimento, valor, status) VALUES
  ('Banco Meridian S.A.', NOW() + INTERVAL '1 day',  18500, 'A vencer'),
  ('TechCorp Brasil',      NOW() - INTERVAL '3 days', 7200,  'Vencido'),
  ('Farmácias Viva+',      NOW() + INTERVAL '3 days', 4500,  'A vencer'),
  ('Seguradora Atlas',     NOW() + INTERVAL '9 days', 22000, 'A vencer');

INSERT INTO public.contas_pagar (fornecedor, vencimento, valor, categoria) VALUES
  ('Gráfica Pronto Print',  NOW() + INTERVAL '2 days',  4200,  'Fornecedor'),
  ('Aluguel Galpão',        NOW() + INTERVAL '4 days',  3800,  'Fixo'),
  ('Importadora Flash',     NOW() + INTERVAL '7 days',  12000, 'Fornecedor'),
  ('Salários + Encargos',   NOW() - INTERVAL '6 days',  18500, 'RH'),
  ('Marketing Digital',     NOW() + INTERVAL '9 days',  2500,  'Marketing');

INSERT INTO public.lancamentos (tipo, descricao, valor, data, categoria) VALUES
  ('receita',  'Pedido Banco Meridian', 18500, CURRENT_DATE - 5,  'Venda'),
  ('receita',  'Pedido TechCorp',        7200,  CURRENT_DATE - 3,  'Venda'),
  ('despesa',  'Gráfica Pronto Print',   4200,  CURRENT_DATE - 2,  'Fornecedor'),
  ('despesa',  'Aluguel Galpão',         3800,  CURRENT_DATE - 1,  'Fixo'),
  ('receita',  'Pedido Farmácias Viva+', 4500,  CURRENT_DATE,      'Venda'),
  ('despesa',  'Salários',              18500,  CURRENT_DATE - 10, 'RH');

-- =============================================
-- PRÓXIMO PASSO: Crie os usuários no Supabase
-- Dashboard > Authentication > Users > Add User
-- Depois insira aqui:
--
-- INSERT INTO public.profiles (id, nome, role) VALUES
--   ('<id-do-usuario>', 'Nome do Gerente', 'gerencial'),
--   ('<id-do-usuario>', 'Nome do Admin',   'administrativo');
-- =============================================
