-- ============================================================================
-- Análise 2 — Açúcar por categoria de produto (a "armadilha" do açúcar)
-- Pergunta: que categorias de marketing "saudável" escondem mais açúcar?
-- Fonte: Open Food Facts (Portugal), tabela dados_portugal.produtos_pt_v2
--
-- Decisões metodológicas (o que mudou face à versão anterior):
--  * '%Cereals%' apanhava a categoria-mãe "Cereals and potatoes" (pão, arroz,
--    massa, batatas fritas). O grupo "Cereais de Pequeno-Almoço" passa a usar
--    só 'breakfast cereals', 'mueslis' e 'granola' (248 produtos, antes 908).
--  * '%Bars%' misturava barras de chocolate, gelados e proteicas. Passa a haver
--    "Barras de cereais" ('cereal bars') e "Barras proteicas" ('protein bars').
--  * 'Bebidas vegetais' usava '%Plant-based beverages%', que inclui sumos e chás.
--    Passa a usar 'milk substitutes' (leites vegetais).
--  * 'Iogurtes' exclui iogurtes líquidos ('drinkable-yogurts').
--  * Denominador = produtos COM açúcar preenchido. Antes dividia-se por todas as
--    linhas, o que subestimava a percentagem quando o açúcar é nulo.
--  * Limiar de referência: modelo de perfil nutricional da DGS (julho de 2019), criado
--    ao abrigo da Lei n.º 30/2019 para restringir a publicidade de alimentos a menores
--    de 16 anos. NÃO é um limite de composição: indica que o produto não deve ser
--    publicitado a crianças. Açúcares totais por 100 g (sólidos) ou 100 ml (líquidos):
--      barras 5 | cereais de pequeno-almoço 15 | iogurtes e leites fermentados 10 |
--      sumos 2,5 | bebidas vegetais 2,5.
--    (Valores lidos do documento da DGS; confirmar na tabela do PDF antes de publicar.)
--  * Mantém-se também o corte descritivo de 15 g/100 g (sem estatuto oficial).
--  * As bebidas são medidas em g/100 g no dataset; trata-se 1 g ≈ 1 ml (aproximação).
--  * Mínimo de 30 produtos com açúcar por grupo.
-- ============================================================================
WITH base AS (
  SELECT
    TRIM(REPLACE(product_name, '&quot;', '')) AS nome_produto,
    LOWER(categories_en) AS categoria,
    sugars_100g AS acucares,
    fiber_100g AS fibra
  FROM `dados_portugal.produtos_pt_v2`
  WHERE product_name IS NOT NULL
    AND product_name NOT IN ('null', '', ' ')
),

classificada AS (
  SELECT
    *,
    CASE
      WHEN categoria LIKE '%cereal bars%' THEN 'Barras de cereais'
      WHEN categoria LIKE '%protein bars%' THEN 'Barras proteicas'
      WHEN categoria LIKE '%breakfast cereals%' OR categoria LIKE '%mueslis%'
        OR categoria LIKE '%granola%' THEN 'Cereais de pequeno-almoço'
      WHEN categoria LIKE '%yogurts%' AND categoria NOT LIKE '%drinkable-yogurts%' THEN 'Iogurtes'
      WHEN categoria LIKE '%fruit juices%' OR categoria LIKE '%fruit nectars%' THEN 'Sumos e néctares de fruta'
      WHEN categoria LIKE '%milk substitutes%' THEN 'Bebidas vegetais (leites vegetais)'
      ELSE NULL
    END AS grupo
  FROM base
),

com_limiar AS (
  SELECT
    *,
    -- Limiar DGS de açúcares totais (g/100 g ou g/100 ml)
    CASE grupo
      WHEN 'Barras de cereais' THEN 5.0
      WHEN 'Barras proteicas' THEN 5.0
      WHEN 'Cereais de pequeno-almoço' THEN 15.0
      WHEN 'Iogurtes' THEN 10.0
      WHEN 'Sumos e néctares de fruta' THEN 2.5
      WHEN 'Bebidas vegetais (leites vegetais)' THEN 2.5
    END AS limiar_dgs
  FROM classificada
  WHERE grupo IS NOT NULL
)

SELECT
  grupo,
  COUNT(*) AS n_total,
  COUNT(acucares) AS n_com_acucar,
  ROUND(AVG(acucares), 2) AS media_acucar,
  ROUND(APPROX_QUANTILES(acucares, 100)[OFFSET(50)], 2) AS mediana_acucar,
  ROUND(AVG(fibra), 2) AS media_fibra,
  COUNTIF(acucares > 15) AS qtd_acima_15g,
  ROUND(100 * COUNTIF(acucares > 15) / COUNT(acucares), 1) AS pct_acima_15g,
  MAX(limiar_dgs) AS limiar_dgs_g_100,
  ROUND(100 * COUNTIF(acucares > limiar_dgs) / COUNT(acucares), 1) AS pct_acima_limiar_dgs
FROM com_limiar
GROUP BY grupo
HAVING COUNT(acucares) >= 30
ORDER BY media_acucar DESC;
