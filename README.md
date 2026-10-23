<div align="center">

# Transparência Nutricional em Supermercados Portugueses
**Quatro perguntas, respondidas com SQL (BigQuery), sobre o que os rótulos e as categorias dos produtos realmente mostram.**

![SQL](https://img.shields.io/badge/SQL-BigQuery-blue?style=for-the-badge&logo=google-cloud)
![Open Food Facts](https://img.shields.io/badge/Dataset-Open_Food_Facts-orange?style=for-the-badge)

</div>

---

## Sobre o projeto

**As escolhas no supermercado baseiam-se em factos ou em marketing?** Com os dados do [Open Food Facts](https://world.openfoodfacts.org/) para Portugal (16.403 produtos, dos quais cerca de 31% têm os nutrientes preenchidos), respondi a quatro perguntas concretas sobre açúcar, sal, proteína e marcas próprias.

Este projeto **não avalia o algoritmo do Nutri-Score**. Usa os valores nutricionais declarados nos produtos e compara-os com referências oficiais portuguesas quando elas existem.

> **Nota sobre a versão.** Esta é uma revisão do projeto original. Ao reproduzir as queries encontrei problemas de classificação e de método (categorias demasiado largas, um grupo de controlo contaminado, limiares sem fonte). Corrigi-os e retirei uma das análises originais, cuja definição era circular. As alterações estão descritas no fim.

---

## Duas referências que não se podem confundir

| Referência | O que é | Exemplo |
|---|---|---|
| **Limite legal** | Obrigatório por lei | Pão: máximo de **1,4 g de sal por 100 g**, medido após cozedura ([Lei n.º 75/2009](https://www.dgav.pt/alimentos/conteudo/generos-alimenticios/regras-especificas-por-tipo-de-alimentos/pao/), segundo a DGAV) |
| **Perfil nutricional da DGS** | Critério da [Direção-Geral da Saúde (2019)](https://alimentacaosaudavel.dgs.pt/wp-content/uploads/2020/04/Perfil-Nutricional-Restricoes-a-publicidade-alimentar-dirigida-a-criancas.pdf), ao abrigo da Lei n.º 30/2019, que define que alimentos **não podem ser publicitados a menores de 16 anos** | Pão: 1,0 g de sal; cereais de pequeno-almoço: 15 g de açúcar |

Estar acima de um limiar da DGS **não torna um produto ilegal nem "mau"**: significa que não é elegível para publicidade dirigida a crianças. Só o pão tem, neste projeto, um limite legal.

---

## Resultados

### 1. Marcas de distribuidor (MDD) vs outras marcas
**Pergunta:** os produtos das marcas dos supermercados têm um perfil nutricional pior do que o das restantes marcas?

**Método:** comparação **dentro de cada subcategoria** (bolachas com bolachas, iogurtes com iogurtes), para que a mistura de produtos de cada grupo não distorça a média. Produtos sem marca registada ficam à parte. Cobre snacks, sobremesas, bolachas e confeitaria com açúcar preenchido (1.812 produtos).

**Resultado:** em quatro das cinco subcategorias o perfil é praticamente igual (diferenças inferiores a 2 g de açúcar). **A exceção são as bolachas e bolos**: as marcas de distribuidor têm mais açúcar (24,4 contra 19,7 g/100 g), mais gordura saturada (7,7 contra 6,5 g) e um pouco menos proteína. A diferença no açúcar é estatisticamente significativa (teste de Mann-Whitney, p < 0,001).

![MDD vs outras marcas](<Gráficos/01_mdd_vs_outras_marcas.png>)

**Limites:** a classificação das marcas é feita pelo nome registado no Open Food Facts. Lidl (25 produtos) e Mercadona (13) têm amostras pequenas e não são analisados individualmente. A análise não tem preços, por isso não diz nada sobre custo.

---

### 2. A "armadilha" do açúcar por categoria
**Pergunta:** que categorias de produtos concentram mais açúcar acima do limiar da DGS?

**Método:** seis grupos de produtos exclusivos (barras de cereais, barras proteicas, cereais de pequeno-almoço, iogurtes, sumos e néctares, leites vegetais), com o limiar de açúcar da DGS de cada categoria. Só produtos com açúcar preenchido.

**Resultado:**
* **Todas as 30 barras de cereais** com dados excedem o limiar da DGS (5 g/100 g), e **27 em 30 (90%)** têm mais de 15 g de açúcar por 100 g.
* **58%** dos cereais de pequeno-almoço (n=240) excedem o limiar de 15 g.
* **97%** dos sumos e néctares excedem 2,5 g/100 ml. O critério da DGS é muito exigente para sumos e não distingue açúcar natural de adicionado: o resultado mostra que quase nenhum sumo é elegível para publicidade infantil, não que "todos os sumos são prejudiciais".
* Os sumos têm também muito pouca fibra (média de 0,45 g/100 g).

![Açúcar por categoria](<Gráficos/02_acucar_por_categoria.png>)

**Limites:** as barras de cereais têm apenas 30 produtos com dados. As bebidas estão em g/100 g no dataset e tratei 1 g como 1 ml.

---

### 3. Eficiência proteica
**Pergunta:** que tipo de alimento dá mais proteína por cada 100 kcal?

**Método:** seis grupos exclusivos definidos pela categoria do produto (e não pela proteína, para não ser circular), mínimo de 30 produtos por grupo. Reporta-se a média e a mediana.

**Resultado:** o **peixe e marisco lidera** (13,1 g de proteína por 100 kcal), seguido da carne e aves não processadas (10,8) e da charcutaria (10,5). As alternativas vegetais (8,4), as leguminosas (7,4) e os iogurtes (6,7) ficam atrás. Só 3,4% dos iogurtes atingem 10 g de proteína por 100 g.

![Eficiência proteica](<Gráficos/03_eficiencia_proteica.png>)

**Limites:** a métrica mede só proteína por energia. As leguminosas têm fibra e os iogurtes têm cálcio, que não entram aqui. Nas leguminosas, 61% (44 de 72) são conservas já cozidas, o que explica a média de 142 kcal/100 g. Sem dados de preço, não é possível falar de custo-benefício.

---

### 4. O desafio do sal: pão e snacks
**Pergunta:** que percentagem dos produtos excede os limiares de sal?

**Método:** pão (81 produtos, excluindo panados, tostas, pão de leite e pães especiais) comparado com o **limite legal** (1,4 g) e com o **limiar da DGS** (1,0 g). Snacks salgados em três subgrupos, comparados com o limiar da DGS (0,3 g), pois não existe limite legal para eles. Valores de sal iguais ou superiores a 10 g/100 g foram excluídos como provável erro.

**Resultado:**
* **Pão:** 42% excedem o limiar da DGS (1,0 g), mas só **9% (7 produtos) excedem o limite legal** (1,4 g).
* **Snacks salgados:** 86% a 97% excedem o limiar da DGS de 0,3 g. Os crackers têm uma mediana de 1,4 g de sal por 100 g.

![Sal](<Gráficos/04_sal_pao_e_snacks.png>)

**Limites:** o limite legal refere-se ao pão após cozedura e o dataset tem produto embalado, por isso a comparação é aproximada. A lei foi alterada pelo [artigo 5.º do Decreto-Lei n.º 9/2021](https://www.dgav.pt/alimentos/conteudo/generos-alimenticios/regras-especificas-por-tipo-de-alimentos/pao/); não confirmei o conteúdo dessa alteração. Alguns valores extremos (por exemplo, 5,0 g num pão doce) são provavelmente erros de preenchimento da base de dados.

---

## Conclusões

1. **As marcas próprias não são nutricionalmente piores, com uma exceção:** nas bolachas e bolos têm mais açúcar e gordura saturada do que as outras marcas.
2. **As categorias que se apresentam como "saudáveis" merecem leitura atenta:** todas as barras de cereais com dados excedem o limiar de açúcar da DGS e mais de metade dos cereais de pequeno-almoço também.
3. **O pão embalado cumpre, na grande maioria, o limite legal de sal** (91%), mas quase metade excede o critério mais exigente da DGS.
4. **Distinguir "limite legal" de "critério de saúde pública" muda as conclusões.** O mesmo pão aparece com 9% ou 42% de incumprimento conforme a referência.

---

## Limitações

* O Open Food Facts é de contribuição voluntária: a cobertura não é uniforme e há erros de preenchimento.
* Só cerca de 31% dos produtos têm todos os nutrientes preenchidos. As análises usam os produtos com os campos necessários, por isso representam o que está registado e não o mercado inteiro.
* O dataset não tem preços, ingredientes, vendas nem alegações de saúde. Nada neste projeto fala de custo, de "ultraprocessados" nem de marketing.
* A classificação por categoria e por marca baseia-se em texto das etiquetas do Open Food Facts e pode ter erros residuais.

---

## Como reproduzir

1. Carregar `Dataset/openfoodfacts_portugal_final.csv` no BigQuery como tabela `dados_portugal.produtos_pt_v2`.
2. Executar os ficheiros de `Query/` (cada um tem o método e as decisões no cabeçalho).
3. Comparar com `Resultados/` (resultados exportados do BigQuery).

A pasta `Data/` documenta o dataset e a limpeza aplicada.

---

## Estrutura do repositório

```
├── README.md
├── Data/              Documentação do dataset
├── Dataset/           CSV usado nas queries
├── Query/             4 queries SQL (BigQuery)
├── Resultados/        Resultados exportados do BigQuery (CSV)
└── Gráficos/          Gráficos incluídos neste README
```

## Tecnologias
Google BigQuery · SQL (CTEs, funções de janela, `APPROX_QUANTILES`, `REGEXP_CONTAINS`) · Open Food Facts · Python/matplotlib (gráficos)

---

## O que mudou face à versão original

* **Análise 5 retirada** ("ultraprocessados saudáveis"): os grupos eram definidos pelo próprio açúcar e gordura saturada, por isso o resultado era verdadeiro por construção, e o dataset não tem ingredientes.
* **Análise 1:** o grupo "marcas líderes" incluía produtos sem marca e outras marcas de distribuidor; passou a comparar-se por subcategoria.
* **Análise 2:** "cereais de pequeno-almoço" incluía pão, arroz e massa (908 produtos); agora são 248 produtos. As barras de chocolate e proteicas deixaram de se misturar com as barras de cereais.
* **Análise 3:** a query estava cortada no repositório; foi refeita com grupos exclusivos. Retirei as afirmações sobre custo-benefício, sem dados de preço.
* **Análise 4:** o grupo do pão incluía panados e a referência de 1,0 g era chamada "limite"; passou a distinguir-se o limite legal (1,4 g) do critério da DGS (1,0 g).

---

<div align="center">

Desenvolvido por Thiago Pordeus · 2026

Dados: © Open Food Facts contributors, licença [ODbL](https://opendatacommons.org/licenses/odbl/1-0/)

</div>
