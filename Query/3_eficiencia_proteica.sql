-- ============================================================================
-- Análise 3 — Eficiência proteica por tipo de alimento
-- Pergunta: quanta proteína se obtém por cada 100 kcal, em cada grupo de alimentos?
-- Fonte: Open Food Facts (Portugal), tabela dados_portugal.produtos_pt_v2
--
-- Decisões metodológicas:
--  * Grupos mutuamente exclusivos: cada produto cai num só grupo, pela ordem do CASE
--    (do mais específico para o mais geral).
--  * Os grupos NÃO são definidos pela proteína (evita raciocínio circular).
--  * kcal_100g >= 20 para evitar rácios inflacionados por produtos quase sem energia.
--  * Mínimo de 30 produtos por grupo para reportar resultados (HAVING).
--  * Reportam-se média E mediana: a mediana é mais robusta a outliers.
--  * Sem dados de preço: nenhuma conclusão de "custo-benefício" é possível.
--  * 'pct_marca_propria' = marcas que contêm Pingo Doce, Continente, Lidl ou Mercadona
--    (correspondência por nome; não inclui Auchan, Dia, etc.).
-- Atenção: as categorias vêm em minúsculas com LOWER() para evitar falhas de LIKE.
-- Atenção: NÃO excluir '%beverages%' — está na categoria-mãe "Plant-based foods and beverages".
-- ============================================================================
WITH produtos_nutritivos AS (
  SELECT
    TRIM(REPLACE(product_name, '&quot;', '')) AS nome_produto,
    COALESCE(TRIM(brands), 'Marca Não Registada') AS marca,
    LOWER(categories_en) AS categoria,
    ROUND(energy_100g / 4.184, 2) AS kcal_100g,
    proteins_100g AS proteina
  FROM dados_portugal.produtos_pt_v2
  WHERE product_name IS NOT NULL
    AND energy_100g / 4.184 >= 20
    AND proteins_100g IS NOT NULL
),

classificados AS (
  SELECT
    *,
    CASE
      WHEN categoria LIKE '%yogurts%' OR categoria LIKE '%quark%'
        THEN 'Iogurtes e Quarks'
      WHEN categoria LIKE '%meat alternatives%' OR categoria LIKE '%meat analogues%'
        OR categoria LIKE '%tofu%' OR categoria LIKE '%tempeh%' OR categoria LIKE '%seitan%'
        THEN 'Alternativas vegetais à carne'
      WHEN (categoria LIKE '%pulses%' OR categoria LIKE '%canned legumes%' OR categoria LIKE '%legume seeds%')
        AND categoria NOT LIKE '%spreads%' AND categoria NOT LIKE '%milk substitutes%'
        AND categoria NOT LIKE '%drinks%' AND categoria NOT LIKE '%nuts%' AND categoria NOT LIKE '%peanuts%'
        THEN 'Leguminosas (grão, feijão, lentilha)'
      WHEN categoria LIKE '%fishes%' OR categoria LIKE '%seafood%'
        THEN 'Peixes e Marisco'
      WHEN categoria LIKE '%prepared meats%' OR categoria LIKE '%sausages%' OR categoria LIKE '%hams%'
        OR categoria LIKE '%cured%' OR categoria LIKE '%bacon%' OR categoria LIKE '%chorizo%'
        OR categoria LIKE '%cold cuts%'
        THEN 'Charcutaria e Enchidos'
      WHEN categoria LIKE '%meats%' OR categoria LIKE '%poultry%'
        THEN 'Carnes e Aves (não processadas)'
      ELSE NULL
    END AS grupo,
    SAFE_DIVIDE(proteina, kcal_100g) * 100 AS proteina_por_100kcal,
    (LOWER(marca) LIKE '%pingo doce%' OR LOWER(marca) LIKE '%continente%'
      OR LOWER(marca) LIKE '%lidl%' OR LOWER(marca) LIKE '%mercadona%') AS e_marca_propria
  FROM produtos_nutritivos
),

com_mediana AS (
  SELECT
    grupo, kcal_100g, proteina, proteina_por_100kcal, e_marca_propria,
    PERCENTILE_CONT(proteina_por_100kcal, 0.5) OVER (PARTITION BY grupo) AS mediana_prot_100kcal
  FROM classificados
  WHERE grupo IS NOT NULL
)

SELECT
  grupo,
  COUNT(*) AS total_produtos,
  ROUND(AVG(kcal_100g), 1) AS media_kcal,
  ROUND(AVG(proteina), 2) AS media_proteina_100g,
  ROUND(AVG(proteina_por_100kcal), 2) AS media_g_proteina_por_100kcal,
  ROUND(ANY_VALUE(mediana_prot_100kcal), 2) AS mediana_g_proteina_por_100kcal,
  ROUND(100 * COUNTIF(proteina >= 10) / COUNT(*), 1) AS pct_com_10g_proteina,
  ROUND(100 * COUNTIF(e_marca_propria) / COUNT(*), 1) AS pct_marca_propria
FROM com_mediana
GROUP BY grupo
HAVING COUNT(*) >= 30
ORDER BY media_g_proteina_por_100kcal DESC;
