# Documentação do dataset: Open Food Facts (Portugal)

## Origem
Os dados vêm do **Open Food Facts**, uma base de dados aberta, colaborativa e mundial de produtos alimentares, filtrada para produtos comercializados em **Portugal**.

* **Fonte:** [Open Food Facts Data](https://world.openfoodfacts.org/data)
* **Licença:** ODbL (Open Database License). Atribuição: © Open Food Facts contributors.
* **Ficheiro:** `Dataset/openfoodfacts_portugal_final.csv` (16.403 linhas, 13 colunas)
* **Preparação inicial:** Excel / Power Query
* **Análise:** carregado no BigQuery como tabela `dados_portugal.produtos_pt_v2`

## Dicionário de dados

Valores nutricionais por 100 g (ou 100 ml, para bebidas).

| Coluna | Descrição | Usada em |
| :--- | :--- | :--- |
| `code` | Código de barras | Identificação |
| `product_name` | Nome do produto | Limpeza (remoção de nulos e de `&quot;`) |
| `brands` | Marca(s), separadas por vírgula | Análise 1 |
| `categories_en` | Etiquetas de categoria, separadas por vírgula | Todas as análises |
| `countries_en` | País(es) de venda | Filtro de origem |
| `energy_100g` | Energia em **kJ** | Análise 3 (convertida para kcal: kJ ÷ 4,184) |
| `saturated_fat_100g` | Gordura saturada (g) | Análise 1 |
| `sugars_100g` | Açúcares (g) | Análises 1 e 2 |
| `fiber_100g` | Fibra (g) | Análise 2 |
| `proteins_100g` | Proteína (g) | Análises 1 e 3 |
| `salt_100g` | Sal (g) | Análise 4 |
| `sodium_100g` | Sódio (g) | Verificação de consistência com o sal |
| `fruits-vegetables-nuts-estimate-from-ingredients_100g` | Estimativa de fruta, legumes e frutos secos | Não usada |

## Regras de limpeza efetivamente aplicadas nas queries

1. **Nomes:** removem-se produtos sem nome ou com nome `null`; `&quot;` é removido do texto.
2. **Nulos:** cada análise usa só os produtos que têm preenchidos os campos de que precisa (por exemplo, açúcar na análise 2). O `n` de cada grupo é sempre reportado.
3. **Energia:** `energy_100g` está em kJ e é convertida para kcal. Na análise 3 excluem-se produtos com menos de 20 kcal/100 g, para evitar rácios inflacionados.
4. **Sal (análise 4):** excluem-se valores iguais ou superiores a 10 g/100 g, por serem provavelmente erros de preenchimento (132 de 8.718 produtos com sal).
5. **Marcas (análise 1):** as marcas de distribuidor são identificadas pelo nome da insígnia e por marcas conhecidas dessa insígnia (Milbona, Hacendado, Sonae, Porsi, etc.). Marcas curtas (por exemplo, "Dia") são comparadas como palavra inteira. Marcas cuja origem não foi confirmada ficam em "Outras marcas".
6. **Categorias:** os grupos de produtos são exclusivos (cada produto pertence a um só grupo) e definem-se por etiquetas de categoria, nunca pelo valor nutricional que se vai analisar.

## Referências usadas nos limiares

| Referência | Natureza | Onde se usa |
| :--- | :--- | :--- |
| [DGAV: Pão](https://www.dgav.pt/alimentos/conteudo/generos-alimenticios/regras-especificas-por-tipo-de-alimentos/pao/) (Lei n.º 75/2009) | **Limite legal**: 1,4 g de sal por 100 g de pão, após cozedura | Análise 4 |
| [DGS: Perfil nutricional, restrições à publicidade alimentar dirigida a crianças (2019)](https://alimentacaosaudavel.dgs.pt/wp-content/uploads/2020/04/Perfil-Nutricional-Restricoes-a-publicidade-alimentar-dirigida-a-criancas.pdf) (Lei n.º 30/2019) | **Critério de publicidade a menores de 16 anos**, não um limite de composição | Análises 2 e 4 |

Limiares da DGS usados (por 100 g ou 100 ml): açúcar: barras 5 g, cereais de pequeno-almoço 15 g, iogurtes 10 g, sumos 2,5 g, bebidas vegetais 2,5 g. Sal: pão 1,0 g, snacks salgados e crackers 0,3 g.

## Limitações

* Os dados dependem do preenchimento voluntário dos utilizadores do Open Food Facts: há erros (por exemplo, um pão doce com 5 g de sal) e a cobertura não é uniforme.
* Só cerca de 31% das linhas têm todos os nutrientes preenchidos.
* O dataset **não** tem preços, ingredientes, vendas nem alegações de saúde, pelo que nenhuma análise pode falar de custo, de grau de processamento ou de marketing.
* Alguns produtos podem ter informação desatualizada face a reformulações recentes.
* As bebidas estão em g/100 g no dataset; nas análises trata-se 1 g como 1 ml.
* A lei do pão foi alterada pelo artigo 5.º do Decreto-Lei n.º 9/2021; o conteúdo dessa alteração não foi confirmado.
