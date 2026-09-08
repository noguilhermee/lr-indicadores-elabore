# 📊 elabore-views

Pipeline analítico da **Labor Rural** para extração, consolidação e exportação de indicadores gerenciais de fazendas a partir do sistema **Elabore**.

---

## 🎯 Objetivo

Transformar os dados brutos do Elabore em indicadores estruturados por propriedade e período, entregues em arquivos Excel para análise interna.

Os produtos principais são:

- 📅 **Indicadores mensais** — por propriedade × mês de referência
- 📆 **Indicadores anuais** — por propriedade × ano
- 📁 **Arquivos Excel** — para análise e uso interno

---

## 📁 Estrutura do Projeto

```text
elabore-views/
│
├── app/
│   └── Elabore Indicadores.ipynb       # Fluxo principal: ETL + exportação
│   └── backup/                         # Versões antigas (referência apenas)
│
├── functions/
│   └── sharepoint_utils.py             # Utilitários SharePoint, banco e Excel
│
└── data/
    ├── views/
    │   └── queries/
    │       ├── analytics_int/          # Views intermediárias (integração)
    │       ├── analytics_mart/         # Views prontas para consumo analítico
    │       └── materialized/           # Materialized views
    │   └── queries_old/                # Consultas antigas (somente referência)
    ├── outputs/
    │   ├── monthly/                    # Exportações mensais
    │   └── annual/                     # Exportações anuais
    └── tables/
```

---

## 🔄 Fluxo de Dados

```
PostgreSQL (Elabore)
        │
        ▼
analytics_int  ──▶  analytics_mart  ──▶  Materialized Views
                                               │
                          SharePoint ──────────┤
                                               ▼
                              Elabore Indicadores.ipynb
                                               │
                      ┌────────────────────────┤
                      ▼                        ▼
              outputs/monthly/         outputs/annual/
              (Excel mensal)           (Excel anual)
```

---

## 🗄️ Camada SQL

As views são organizadas em três camadas com responsabilidades distintas.

### `analytics_int` — Integração (4 views)

Camada intermediária com dimensões cadastrais e relacionamentos entre entidades.

| View | Descrição |
|------|-----------|
| `vw_dim_property_base` | Dimensão consolidada das propriedades: nome, empreendedor, agroindústria, localização, valor da terra e status cadastral |
| `vw_bridge_property_agroindustry` | Ligação propriedade × agroindústria |
| `vw_bridge_property_consultant` | Ligação propriedade × consultor |
| `vw_bridge_property_entrepreneur` | Ligação propriedade × empresário |

### `analytics_mart` — Consumo Analítico (9 views)

Views prontas para consumo, com granularidade de **uma linha por propriedade × mês**.

| View | Descrição |
|------|-----------|
| `vw_expense` | Despesas mensais categorizadas: alimentação animal, sanidade, arrendamento, energia, mão de obra, reprodução, etc. |
| `vw_revenue` | Receitas mensais por fonte |
| `vw_feeding` | Gastos com alimentação do rebanho |
| `vw_cattle` | Composição e movimentação do rebanho bovino |
| `vw_labor` | Custos de mão de obra |
| `vw_own_milk` | Leite próprio consumido na propriedade |
| `vw_asset_capital_stock` | Estoque de capital e depreciação de ativos |
| `vw_dairy_production_system_monthly` | Sistema predominante de produção de leite (Compost Barn, Free Stall, Semi-confinado, Pastagem, MIXED) |
| `dim_consultor_propriedade` | Dimensão consultor × propriedade |

### `materialized` — Views Materializadas (3)

| View | Descrição |
|------|-----------|
| `mvw_area_land_summary` | Resumo de área e uso da terra por propriedade |
| `mvw_asset_capital_stock` | Estoque de capital materializado para consulta eficiente |
| `mvw_asset_payment_history` | Histórico de pagamentos de ativos |

---

## 🐍 Camada Python

### `app/Elabore Indicadores.ipynb`

Notebook principal executável em sequência. Responsável por:

1. Conectar ao PostgreSQL via SQLAlchemy/psycopg2
2. Consultar as views do `analytics_mart`
3. Integrar dados complementares do SharePoint (via Microsoft Graph API)
4. Aplicar transformações e consolidações com pandas
5. Calcular indicadores mensais e anuais por propriedade
6. Exportar arquivos Excel formatados com openpyxl

### `functions/sharepoint_utils.py`

Biblioteca interna com utilitários para:

- 🔐 Autenticação OAuth2 no Microsoft Graph (Client Credentials)
- 📥 Extração de listas do SharePoint com paginação automática e carga incremental
- 🐼 Conversão de JSON → pandas DataFrame por tipo de lista
- 💾 Checkpoints de ETL para reaproveitamento de execuções anteriores
- ❌ Tratamento de erros, logs e validações

---

## 🛡️ Regras de Consistência e Qualidade dos Dados

Durante o processamento mensal, cada registro é avaliado contra **13 critérios de consistência técnica e econômica**.

### 📊 Critérios Avaliados:

| Categoria | Critério / Coluna | Faixa / Limite de Consistência |
| :--- | :--- | :--- |
| **Qualidade do Leite** | `cons_ccs` | Contagem de células somáticas **> 50** |
| | `cons_cpp` | Contagem padrão em placas **> 1** |
| | `cons_fat` | Percentual de gordura entre **2,5% e 5,5%** |
| | `cons_protein` | Percentual de proteína entre **2,4% e 4,5%** |
| **Estrutura do Rebanho** | `cons_lactating_cows_total_cows` | Vacas em lactação / Total de vacas entre **20% e 99%** |
| | `cons_lactating_cows_total_cattle` | Vacas em lactação / Rebanho total entre **15% e 99%** |
| **Produtividade e MDO** | `cons_milk_lactating_cow_day` | Produção diária por vaca em lactação entre **3 e 45 L/vaca/dia** |
| | `cons_milk_total_labor_day` | Produção diária por MDO entre **20 e 1.500 L/trabalhador/dia** |
| | `cons_lactating_cows_total_labor` | Vacas em lactação por MDO entre **0 e 70 vacas/trabalhador** |
| **Alimentação e Custos** | `cons_feeding_cost_milk_price` | Custo de alimentação / Preço do leite entre **15% e 150%** |
| | `cons_voluminous_cost_liter` | Custo de volumoso **< R$ 3,00/L** |
| | `cons_concentrate_mineral_cost_liter` | Custo de concentrado e minerais entre **R$ 0,30/L e R$ 3,50/L** |
| | `cons_hired_labor_cost_liter` | Custo da mão de obra contratada **< R$ 1,00/L** |

### 🏷️ Colunas Geradas no Relatório:

- `consistency_status`: **Consistente** (0 violações) ou **Inconsistente** (1 ou mais violações).
- `consistency_id`: Identificador numérico (`0` para Consistente, `1` para Inconsistente).
- `total_consistency_criteria_ok` / `total_consistency_criteria_violated`: Contagem de critérios atendidos e violados.
- `violated_consistency_criteria`: Relação textual dos critérios violados (ex: `Alimentação/Preço do leite; Custo de concentrado`).
- `violated_consistency_details`: Detalhamento dos motivos e valores calculados que provocaram a violação (ex: `Alimentação/Preço do leite (Acima do máx >150%: 185.4%)`).

---

## ⚙️ Configuração

Crie o arquivo `.env` na raiz do projeto com as credenciais necessárias:

```env
# Banco de dados
DB_HOST=
DB_PORT=
DB_NAME=
DB_USER=
DB_PASSWORD=

# Microsoft Graph / SharePoint
TENANT_ID=
CLIENT_ID=
CLIENT_SECRET=
SITE_ID=
```

> ⚠️ O arquivo `.env` é local e **nunca deve ser versionado**.

---

## 📦 Dependências

```bash
pip install pandas sqlalchemy psycopg2-binary openpyxl requests python-dotenv
```

---

## 🧰 Tecnologias

| Camada | Tecnologia |
|--------|------------|
| Banco de dados | PostgreSQL |
| Queries analíticas | SQL (Views e Materialized Views) |
| Conexão ao banco | SQLAlchemy / psycopg2 |
| Transformação de dados | Python + pandas |
| Integração externa | Microsoft Graph API + SharePoint Online |
| Exportação | openpyxl (Excel) |
| Orquestração | Jupyter Notebook |
| Credenciais | python-dotenv |

---

## 📌 Convenções

- Granularidade mensal: chave `id_property` + `reference_month` (normalizada para o 1º dia do mês)
- Granularidade anual: agregação por `id_property` + ano, após os tratamentos mensais
- Merges com `validate=` sempre que a cardinalidade for conhecida
- Nenhuma divisão por zero sem tratamento explícito
- Exportações históricas não são sobrescritas sem solicitação explícita

---

## 👨‍💻 Autor

**Guilherme Henrique Fonseca Nogueira**

- 🎓 Mestre em Economia Aplicada (PPGEA/UFV)
- 🎓 Bacharel em Ciências Econômicas (UFSJ)
- 📊 Cientista de Dados (Escola DNC)

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat-square&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/noguilhermee/)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat-square&logo=github&logoColor=white)](https://github.com/noguilhermee)
[![Lattes](https://img.shields.io/badge/Currículo_Lattes-104E8B?style=flat-square&logo=google-scholar&logoColor=white)](http://lattes.cnpq.br/9226285374070081)