-- ============================================================================
-- Análise 4 — O desafio do sal: pão e snacks salgados
-- Pergunta: que percentagem dos produtos excede um limite de sal de referência?
-- Fonte: Open Food Facts (Portugal), tabela dados_portugal.produtos_pt_v2
--
-- Referências (duas coisas diferentes, não confundir):
--  * LIMITE LEGAL (só o pão): 1,4 g de sal por 100 g de pão, medido após cozedura
--    (Lei n.º 75/2009, de 12 de agosto, segundo a DGAV). Não se aplica a produtos
--    tradicionais com nome protegido. A lei foi alterada pelo art. 5.º do
--    Decreto-Lei n.º 9/2021; o conteúdo dessa alteração NÃO foi confirmado
--    -> confirmar no Diário da República.
--  * PERFIL NUTRICIONAL DA DGS (julho de 2019, Lei n.º 30/2019): critério para restringir
--    a publicidade a menores de 16 anos, NÃO um limite de composição. Sal por 100 g:
--      pão e tostas 1,0 | snacks salgados e crackers 0,3.
--    (Valores lidos do documento da DGS; confirmar na tabela do PDF antes de publicar.)
--
-- Decisões metodológicas (o que mudou face à versão anterior):
--  * O 1,0 g do pão é o limiar DGS (publicidade a crianças), não o limite legal (1,4 g);
--    a query mostra agora as duas medidas, claramente separadas.
--  * A categoria 'breads' é comparada como etiqueta EXATA (regex): '%breads%' apanhava
--    'gingerbreads' (um biscoito de gengibre entrou no grupo do pão). Excluem-se também,
--    pelo nome, tostas, torradas e pão crocante, que não têm etiqueta própria.
--  * '%Bread%' apanhava produtos panados (nuggets, peixe panado), tostas, torradas,
--    croutons, viennoiserie e "pães especiais". Ficam de fora; o grupo passa de 206
--    para 81 produtos e corresponde melhor ao "pão" a que a lei se refere.
--  * '%Crackers%' + '%Chips%' misturavam bolachas doces e batatas fritas congeladas.
--    Passa a haver 3 subgrupos de snacks salgados.
--  * Sal >= 10 g/100 g excluído como provável erro de preenchimento (mantido da
--    versão anterior; afeta 132 de 8.718 produtos com sal).
--  * Reporta-se média, mediana, máximo e a percentagem acima do limiar, com n.
--  * Mínimo de 30 produtos por grupo.
-- ============================================================================
WITH base AS (
  SELECT
    TRIM(REPLACE(product_name, '&quot;', '')) AS nome_produto,
    LOWER(categories_en) AS categoria,
    salt_100g AS sal
  FROM `dados_portugal.produtos_pt_v2`
  WHERE product_name IS NOT NULL
    AND product_name NOT IN ('null', '', ' ')
    AND salt_100g IS NOT NULL
    AND salt_100g < 10.0
),

classificada AS (
  SELECT
    *,
    CASE
      WHEN REGEXP_CONTAINS(categoria, r'(^|,)\s*(breads|baguettes)\s*(,|$)')
        AND NOT REGEXP_CONTAINS(LOWER(nome_produto), r'tost|torrad|crocant')
        AND categoria NOT LIKE '%breaded%' AND categoria NOT LIKE '%special breads%'
        AND categoria NOT LIKE '%toasts%' AND categoria NOT LIKE '%rusks%'
        AND categoria NOT LIKE '%croutons%' AND categoria NOT LIKE '%viennoiseries%'
        AND categoria NOT LIKE '%sweet pastries%' AND categoria NOT LIKE '%milk bread%'
        AND categoria NOT LIKE '%flatbreads%' AND categoria NOT LIKE '%gluten-free breads%'
        AND categoria NOT LIKE '%breadcrumbs%'
        THEN 'Pão'
      WHEN categoria LIKE '%crisps%' OR categoria LIKE '%corn chips%' OR categoria LIKE '%tortilla chips%'
        THEN 'Batatas fritas de pacote e snacks de milho'
      WHEN categoria LIKE '%crackers (appetizers)%'
        OR (categoria LIKE '%crackers%' AND categoria NOT LIKE '%biscuits and crackers%')
        THEN 'Crackers'
      WHEN categoria LIKE '%salty snacks%' THEN 'Outros snacks salgados (frutos secos, pipocas, etc.)'
      ELSE NULL
    END AS grupo
  FROM base
)

SELECT
  grupo,
  IF(grupo = 'Pão', 1.0, 0.3) AS limiar_dgs_g_100g,
  COUNT(*) AS n,
  ROUND(AVG(sal), 2) AS media_sal,
  ROUND(APPROX_QUANTILES(sal, 100)[OFFSET(50)], 2) AS mediana_sal,
  ROUND(MAX(sal), 2) AS max_sal,
  ROUND(100 * COUNTIF(sal > IF(grupo = 'Pão', 1.0, 0.3)) / COUNT(*), 1) AS pct_acima_limiar_dgs,
  -- Limite legal: só definido para o pão (NULL nos restantes grupos)
  IF(grupo = 'Pão', COUNTIF(sal > 1.4), NULL) AS qtd_acima_limite_legal,
  IF(grupo = 'Pão', ROUND(100 * COUNTIF(sal > 1.4) / COUNT(*), 1), NULL) AS pct_acima_limite_legal
FROM classificada
WHERE grupo IS NOT NULL
GROUP BY grupo
HAVING COUNT(*) >= 30
ORDER BY pct_acima_limiar_dgs DESC;
