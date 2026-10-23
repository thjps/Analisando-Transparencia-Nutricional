-- ============================================================================
-- Análise 1 — Marcas de distribuidor (MDD) vs outras marcas
-- Pergunta: nos snacks e sobremesas, as marcas dos supermercados têm um perfil
--           nutricional pior, igual ou melhor do que as restantes marcas?
-- Fonte: Open Food Facts (Portugal), tabela dados_portugal.produtos_pt_v2
--
-- Decisões metodológicas (o que mudou face à versão anterior):
--  * Compara-se DENTRO de cada subcategoria (bolachas com bolachas, iogurtes com
--    iogurtes). Antes misturava-se tudo e o resultado dependia de quantos iogurtes
--    ou bolachas cada grupo tinha.
--  * O filtro '%Desserts%' apanha iogurtes e sobremesas lácteas: passam a ser
--    uma subcategoria própria, em vez de ficarem escondidos no total.
--  * 'Outras marcas' substitui 'Marcas Líderes': o grupo inclui qualquer marca que
--    não seja de distribuidor; não se pode chamar "líderes" sem dados de vendas.
--  * Produtos sem marca registada ficam num grupo à parte (não contaminam a comparação).
--  * Marcas por token exato (SPLIT por vírgula) para marcas curtas ('dia', 'aldi'),
--    porque LIKE '%dia%' apanharia "média", "comédia", etc.
--  * Só entram produtos com açúcar preenchido (acucares IS NOT NULL).
--  * Reporta-se média E mediana, sempre com n.
--
-- Classificação MDD (verificada):
--   Pingo Doce, Continente (inclui 'Sonae'), Lidl (inclui 'Milbona'),
--   Mercadona (inclui 'Hacendado'), Auchan, Dia, Aldi, Minipreço,
--   Intermarché/Porsi (marca própria da Intermarché), Amanhecer (rede de supermercados).
--   NÃO classificadas (origem não confirmada): ex. 'Cem Porcento' -> ficam em 'Outras marcas'.
-- ============================================================================
CREATE TEMP FUNCTION tem_token(marca STRING, lista ARRAY<STRING>) AS (
  EXISTS(SELECT 1 FROM UNNEST(SPLIT(LOWER(marca), ',')) t WHERE TRIM(t) IN UNNEST(lista))
);

WITH base AS (
  SELECT
    TRIM(REPLACE(product_name, '&quot;', '')) AS nome_produto,
    COALESCE(TRIM(brands), 'Marca Não Registada') AS marca,
    LOWER(categories_en) AS categoria,
    sugars_100g AS acucares,
    saturated_fat_100g AS gordura_sat,
    proteins_100g AS proteina
  FROM `dados_portugal.produtos_pt_v2`
  WHERE product_name IS NOT NULL
    AND product_name NOT IN ('null', '', ' ')
    AND sugars_100g IS NOT NULL
    AND (categories_en LIKE '%Snacks%' OR categories_en LIKE '%Desserts%'
      OR categories_en LIKE '%Biscuits%' OR categories_en LIKE '%Confectionery%')
),

classificada AS (
  SELECT
    *,
    -- Subcategoria (exclusiva, da mais específica para a mais geral)
    CASE
      WHEN categoria LIKE '%ice cream%' THEN 'Gelados'
      WHEN categoria LIKE '%yogurts%' OR categoria LIKE '%dairy desserts%'
        OR categoria LIKE '%fermented milk%' THEN 'Iogurtes e sobremesas lácteas'
      WHEN categoria LIKE '%biscuits%' OR categoria LIKE '%cakes%'
        OR categoria LIKE '%wafers%' THEN 'Bolachas e bolos'
      WHEN categoria LIKE '%chocolates%' OR categoria LIKE '%confectioneries%'
        OR categoria LIKE '%cocoa%' THEN 'Chocolates e confeitaria'
      WHEN categoria LIKE '%salty snacks%' OR categoria LIKE '%crisps%'
        OR categoria LIKE '%chips%' THEN 'Snacks salgados'
      ELSE 'Outros'
    END AS subcategoria,
    -- Insígnia (NULL se não for MDD)
    CASE
      WHEN LOWER(marca) LIKE '%pingo doce%' THEN 'Pingo Doce'
      WHEN LOWER(marca) LIKE '%continente%' OR tem_token(marca, ['sonae']) THEN 'Continente'
      WHEN LOWER(marca) LIKE '%lidl%' OR tem_token(marca, ['milbona']) THEN 'Lidl'
      WHEN LOWER(marca) LIKE '%mercadona%' OR tem_token(marca, ['hacendado']) THEN 'Mercadona'
      WHEN LOWER(marca) LIKE '%intermarch%'
        OR tem_token(marca, ['auchan', 'dia', 'aldi', 'minipreço', 'porsi', 'amanhecer'])
        THEN 'Outras insígnias'
      ELSE NULL
    END AS insignia
  FROM base
),

final AS (
  SELECT
    *,
    CASE
      WHEN marca = 'Marca Não Registada' THEN 'Sem marca registada'
      WHEN insignia IS NOT NULL THEN 'MDD'
      ELSE 'Outras marcas'
    END AS tipo_marca
  FROM classificada
)

-- ---------------------------------------------------------------------------
-- RESULTADO A: MDD vs outras marcas, por subcategoria (a comparação principal)
-- ---------------------------------------------------------------------------
SELECT
  subcategoria,
  tipo_marca,
  COUNT(*) AS n,
  ROUND(AVG(acucares), 2) AS media_acucar,
  ROUND(APPROX_QUANTILES(acucares, 100)[OFFSET(50)], 2) AS mediana_acucar,
  ROUND(AVG(gordura_sat), 2) AS media_gordura_sat,
  ROUND(AVG(proteina), 2) AS media_proteina
FROM final
GROUP BY subcategoria, tipo_marca
ORDER BY subcategoria, tipo_marca;

-- ---------------------------------------------------------------------------
-- RESULTADO B: por insígnia (correr em separado, trocando o SELECT final acima)
-- Atenção: Lidl (n~25) e Mercadona (n~13) são amostras pequenas -> só descritivo.
-- ---------------------------------------------------------------------------
-- SELECT
--   insignia,
--   COUNT(*) AS n,
--   ROUND(AVG(acucares), 2) AS media_acucar,
--   ROUND(APPROX_QUANTILES(acucares, 100)[OFFSET(50)], 2) AS mediana_acucar
-- FROM final
-- WHERE insignia IS NOT NULL
-- GROUP BY insignia
-- ORDER BY media_acucar DESC;
