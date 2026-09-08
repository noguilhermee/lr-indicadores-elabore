# ==============================================================================
# 3.8 VERIFICAÇÃO DE VARIAÇÃO >±50% ENTRE PERÍODOS CONSECUTIVOS (MENSAL)
# ==============================================================================
# Diagnóstico RELATIVO e ADITIVO, mesmo espírito da 4.4: marca todo indicador que
# variou mais de +50% ou menos de -50% em relação ao mês calendário imediatamente
# anterior (M-1) da própria fazenda.
#
# Nada de consistência muda aqui: consistency_id e consistency_status são apenas
# LIDOS. A célula lê df_consistencia (cópia defensiva) e devolve três DataFrames
# novos - NÃO altera df_consistencia, que segue intocado para a 3.9. As colunas
# "_var_" que entram na aba "Indicadores Mensais" chegam no ticket 04
# (.scratch/variacao-50-periodo/); a aba "Variações por Consultor", no ticket 05.
# ==============================================================================
LIMITE_VARIACAO_PERCENTUAL = 50

# Lista final aprovada na re-medição sobre a base de 18/08 (ticket 02 de
# .scratch/variacao-50-periodo/, tabela documentada na spec): estruturais + custos
# agregados, todos abaixo do corte de 10% de linhas marcadas. Mesmo shape de
# INDICADORES_OUTLIER (4.4): coluna técnica -> (rótulo em português, unidade, formato).
INDICADORES_VARIACAO_MENSAL = {
    "total_cows":           ("Total de Vacas", "cabeças", ".0f"),
    "milk_unit_price":      ("Preço Unitário do Leite", "R$/litro", ".2f"),
    "hectares_total":       ("Área Total da Propriedade", "ha", ".1f"),
    "milk_produced":        ("Produção Total de Leite", "litros", ".0f"),
    "total_capital_stock":  ("Estoque de Capital Total", "R$", ".2f"),
    "total_labor_expenses": ("Custo Total Mão de Obra", "R$", ".2f"),
    "feeding_cost":         ("Custo Total com Alimentação", "R$", ".2f"),
}

# Helpers no mesmo padrão da 4.4 (formatação numérica brasileira, renomeação do
# consolidado, aviso do resumo por consultor). A 3.8 roda ANTES da 4.4 na ordem
# do notebook, então não há como importar os objetos de lá - ficam redefinidos
# aqui com o MESMO conteúdo. Se um dia isso for extraído para um lugar comum
# (fora de functions/, que fica fora de escopo desta spec), os dois pontos de
# definição colapsam em um só.
def _formatar_br(valor, formato):
    """Formata um número no padrão brasileiro (vírgula decimal, ponto de milhar)."""
    if valor is None or pd.isna(valor):
        return "-"
    texto = f"{valor:{formato}}"
    return texto.replace(",", "\x00").replace(".", ",").replace("\x00", ".")


RENOMEAR_CONSOLIDADO = {
    "id_property": "IDFazenda",
    "property_entrepreneur_label": "Fazenda - Produtor",
    "property_name": "Fazenda",
    "labor_rural_code": "Código LR",
    "consultant_name": "Consultor",
}

AVISO_SOMA_CONSULTOR = (
    "ATENÇÃO: cada vínculo conta - fazenda com mais de um consultor aparece "
    "para todos eles, logo a soma desta coluna EXCEDE o total de fazendas distintas"
)


def calcular_variacao_periodo(
    df,
    indicadores=None,
    coluna_chave="id_property",
    coluna_ordem="reference_month",
    limite_percentual=LIMITE_VARIACAO_PERCENTUAL,
    prefixo="variacao",
    colunas_informativas=None,
):
    """
    Marca variação >+-limite_percentual% entre meses calendário CONSECUTIVOS da
    mesma fazenda (comparação contra M-1, nunca atravessando uma lacuna).

    Função pura: faz cópia defensiva do DataFrame de entrada, não faz I/O, não
    acessa banco/SharePoint e não usa estado global além da configuração recebida
    por parâmetro. Nasce parametrizada (coluna-chave, coluna de ordem, limite,
    prefixo) para poder ser reaproveitada por uma extensão anual futura sem
    reescrita, embora hoje só o mensal seja chamado.

    No grão mensal, `consultant_name` é uma string com os nomes separados por
    ", " quando a fazenda tem mais de um consultor vinculado (agregação feita na
    3.6, para não duplicar linha por consultor no mensal - só o anual duplica de
    propósito). O resumo por consultor abaixo separa (`str.split`) essa string
    para que cada consultor veja a fazenda na própria carteira, sem duplicar a
    linha correspondente na aba "Variações".

    Parâmetros
    ----------
    df : DataFrame com uma linha por fazenda-mês. Precisa de `coluna_chave`,
        `coluna_ordem` (data/timestamp) e as colunas de indicador.
    indicadores : dict {coluna: (rótulo, unidade, formato)}. Default
        INDICADORES_VARIACAO_MENSAL.
    coluna_chave : coluna que identifica a fazenda.
    coluna_ordem : coluna de data usada para ordenar e checar consecutividade
        (mês calendário com passo de exatamente 1).
    limite_percentual : limiar de variação (50 -> razão > 1,5 ou < 0,5 marca).
    prefixo : prefixo das colunas de categoria anexadas ao DataFrame anotado.
    colunas_informativas : colunas de identificação copiadas para a aba
        "Variações". Default: id_property, property_entrepreneur_label,
        property_name, labor_rural_code, consultant_name (as que existirem).

    Retorna
    -------
    (df_anotado, df_consolidado, df_por_consultor)
    """
    indicadores = INDICADORES_VARIACAO_MENSAL if indicadores is None else indicadores
    if colunas_informativas is None:
        colunas_informativas = [
            "id_property", "property_entrepreneur_label", "property_name",
            "labor_rural_code", "consultant_name",
        ]

    df_anotado = df.copy(deep=True)

    colunas_indicador = [c for c in indicadores if c in df_anotado.columns]
    if not colunas_indicador:
        raise KeyError("Nenhuma coluna de indicador de variação encontrada no DataFrame.")

    limite_superior = 1 + (limite_percentual / 100.0)   # 1,5 para 50%
    limite_inferior = 1 - (limite_percentual / 100.0)   # 0,5 para 50%

    # --------------------------------------------------------------------------
    # 1. CONTINUIDADE: mês calendário consecutivo (passo de exatamente 1) dentro
    #    da mesma fazenda. Lacuna de mês -> a comparação simplesmente não roda.
    # --------------------------------------------------------------------------
    df_anotado = df_anotado.sort_values([coluna_chave, coluna_ordem]).copy()

    periodo_dt = pd.to_datetime(df_anotado[coluna_ordem], errors="coerce")
    ordem_num = periodo_dt.dt.year * 12 + periodo_dt.dt.month

    mesma_fazenda = df_anotado[coluna_chave].eq(df_anotado[coluna_chave].shift(1))
    passo = ordem_num - ordem_num.shift(1)
    consecutivo = (mesma_fazenda & passo.eq(1) & ordem_num.notna()).to_numpy()

    # --------------------------------------------------------------------------
    # 2. CLASSIFICAÇÃO POR INDICADOR (todas as linhas)
    # --------------------------------------------------------------------------
    marcado_por_coluna = {}
    for coluna in colunas_indicador:
        valores = pd.to_numeric(df_anotado[coluna], errors="coerce").to_numpy(dtype=float)
        valor_anterior = np.roll(valores, 1)
        valor_anterior[0] = np.nan
        valor_anterior = np.where(consecutivo, valor_anterior, np.nan)
        valor_atual = np.where(consecutivo, valores, np.nan)

        ambos_validos = np.isfinite(valor_anterior) & np.isfinite(valor_atual)
        ambos_zero = ambos_validos & (valor_anterior == 0) & (valor_atual == 0)
        entrada = ambos_validos & (valor_anterior == 0) & (valor_atual > 0)
        saida = ambos_validos & (valor_anterior > 0) & (valor_atual == 0)

        with np.errstate(divide="ignore", invalid="ignore"):
            razao = valor_atual / valor_anterior
        avaliavel = ambos_validos & ~ambos_zero & ~entrada & ~saida & np.isfinite(razao)
        aumento = avaliavel & (razao > limite_superior)
        reducao = avaliavel & (razao < limite_inferior)

        # Exatamente no limite (1,5 ou 0,5) NÃO marca; imediatamente fora dele marca.
        categoria = np.full(len(df_anotado), "Não avaliado", dtype=object)
        categoria[avaliavel] = "Normal"
        categoria[entrada] = "Entrada"
        categoria[saida] = "Saída"
        categoria[aumento] = "Aumento"
        categoria[reducao] = "Redução"

        df_anotado[f"{prefixo}_{coluna}"] = categoria

        marcado_por_coluna[coluna] = {
            "marcado": aumento | reducao,
            "lado": categoria,
            "valor_anterior": valor_anterior,
            "valor_atual": valor_atual,
            "variacao_pct": (razao - 1) * 100,
        }

    df_anotado = df_anotado.copy()  # desfragmenta após as inserções (mesmo cuidado da 4.2/4.4)

    # --------------------------------------------------------------------------
    # 3. ABA "VARIAÇÕES": série inteira, uma linha por fazenda x indicador x mês
    #    marcado (só Aumento/Redução), do mês mais recente para o mais antigo.
    # --------------------------------------------------------------------------
    colunas_id_presentes = [c for c in colunas_informativas if c in df_anotado.columns]
    linhas_consolidado = []
    for coluna in colunas_indicador:
        rotulo, _unidade, _formato = indicadores[coluna]
        dados = marcado_por_coluna[coluna]
        indices_marcados = np.flatnonzero(dados["marcado"])
        if indices_marcados.size == 0:
            continue
        recorte = df_anotado.iloc[indices_marcados]
        registro = pd.DataFrame(index=recorte.index)
        for c in colunas_id_presentes:
            registro[c] = recorte[c].values
        registro["_periodo"] = recorte[coluna_ordem].values
        registro["Indicador"] = rotulo
        registro["Valor Anterior"] = dados["valor_anterior"][indices_marcados]
        registro["Valor Atual"] = dados["valor_atual"][indices_marcados]
        registro["Variação (%)"] = dados["variacao_pct"][indices_marcados]
        registro["Lado"] = dados["lado"][indices_marcados]
        linhas_consolidado.append(registro)

    colunas_saida_consolidado = (
        [RENOMEAR_CONSOLIDADO.get(c, c) for c in colunas_id_presentes]
        + ["Indicador", "Período", "Valor Anterior", "Valor Atual", "Variação (%)", "Lado"]
    )

    if linhas_consolidado:
        df_consolidado = pd.concat(linhas_consolidado, ignore_index=True)
        df_consolidado = df_consolidado.rename(columns=RENOMEAR_CONSOLIDADO)
        df_consolidado = df_consolidado.rename(columns={"_periodo": "Período"})
        df_consolidado = df_consolidado.sort_values(
            ["Período", "Indicador"], ascending=[False, True]
        ).reset_index(drop=True)
        df_consolidado = df_consolidado[
            [c for c in colunas_saida_consolidado if c in df_consolidado.columns]
        ]
    else:
        df_consolidado = pd.DataFrame(columns=colunas_saida_consolidado)

    # --------------------------------------------------------------------------
    # 4. RESUMO POR CONSULTOR (ocorrência mais recente de cada fazenda). Cada
    #    vínculo conta: consultant_name é dividida em nomes individuais, e cada
    #    um vê a fazenda na própria carteira - sem duplicar linha na 3.
    # --------------------------------------------------------------------------
    if coluna_chave in df_anotado.columns and coluna_ordem in df_anotado.columns:
        ultima_ocorrencia = df_anotado.groupby(coluna_chave)[coluna_ordem].transform("max")
        df_ultima = df_anotado.loc[df_anotado[coluna_ordem].eq(ultima_ocorrencia)].copy()
    else:
        df_ultima = df_anotado.iloc[0:0].copy()

    if "consultant_name" in df_ultima.columns:
        df_ultima["consultant_name"] = df_ultima["consultant_name"].fillna("(Sem consultor)")
    else:
        df_ultima["consultant_name"] = "(Sem consultor)"

    df_ultima["_consultor_individual"] = (
        df_ultima["consultant_name"].astype(str).str.split(",")
    )
    df_ultima = df_ultima.explode("_consultor_individual")
    df_ultima["_consultor_individual"] = df_ultima["_consultor_individual"].str.strip()

    linhas_consultor = []
    for consultor, grupo in df_ultima.groupby("_consultor_individual", sort=True):
        atendidas = grupo[coluna_chave].nunique()
        marcado_geral = pd.Series(False, index=grupo.index)
        registro = {
            "Consultor": consultor,
            f"Fazendas atendidas [{AVISO_SOMA_CONSULTOR}]": atendidas,
        }
        for coluna in colunas_indicador:
            rotulo, _unidade, _formato = indicadores[coluna]
            marcado_coluna = grupo[f"{prefixo}_{coluna}"].isin(["Aumento", "Redução"])
            marcado_geral = marcado_geral | marcado_coluna
            registro[rotulo] = grupo.loc[marcado_coluna, coluna_chave].nunique()
        registro["Fazendas marcadas"] = grupo.loc[marcado_geral, coluna_chave].nunique()
        registro["% de fazendas marcadas"] = (
            100.0 * registro["Fazendas marcadas"] / atendidas if atendidas else np.nan
        )
        linhas_consultor.append(registro)

    df_por_consultor = pd.DataFrame(linhas_consultor)
    if not df_por_consultor.empty:
        colunas_ordem_consultor = (
            ["Consultor", f"Fazendas atendidas [{AVISO_SOMA_CONSULTOR}]", "Fazendas marcadas",
             "% de fazendas marcadas"]
            + [rotulo for _coluna, (rotulo, _u, _f) in indicadores.items()]
        )
        df_por_consultor = df_por_consultor[
            [c for c in colunas_ordem_consultor if c in df_por_consultor.columns]
        ].sort_values("Fazendas marcadas", ascending=False).reset_index(drop=True)

    return df_anotado, df_consolidado, df_por_consultor


# ==============================================================================
# EXECUÇÃO SOBRE OS INDICADORES MENSAIS JÁ CONSOLIDADOS
# ==============================================================================
# Só LÊ df_consistencia (cópia defensiva dentro da função) - a 3.9 continua
# recebendo df_consistencia exatamente como saiu da 3.7.
(
    df_variacao_anotado_mensal,
    df_variacoes,
    df_variacoes_por_consultor,
) = calcular_variacao_periodo(df_consistencia, INDICADORES_VARIACAO_MENSAL)

_total_linhas_mensal = len(df_consistencia)

print("=" * 78)
print(f"VERIFICAÇÃO DE VARIAÇÃO >±{LIMITE_VARIACAO_PERCENTUAL}% ENTRE MESES CONSECUTIVOS (MENSAL)")
print("=" * 78)
print(f"Base: {_total_linhas_mensal:,} linhas | "
      f"{df_consistencia['id_property'].nunique():,} fazendas distintas")
print()
print("Linhas marcadas (Aumento/Redução) por indicador:")
for _coluna, (_rotulo, _unidade, _formato) in INDICADORES_VARIACAO_MENSAL.items():
    _col_categoria = f"variacao_{_coluna}"
    if _col_categoria not in df_variacao_anotado_mensal.columns:
        continue
    _marcadas = int(df_variacao_anotado_mensal[_col_categoria].isin(["Aumento", "Redução"]).sum())
    _taxa = 100.0 * _marcadas / _total_linhas_mensal if _total_linhas_mensal else 0.0
    print(f"  {_rotulo:<32} {_marcadas:>5,}  ({_formatar_br(_taxa, '.2f')}%)")
print()
print(f"Aba 'Variações': {len(df_variacoes):,} linhas (série inteira, mês mais recente primeiro)")
print(f"Aba 'Variações por Consultor': {len(df_variacoes_por_consultor):,} consultores")

display(df_variacoes.head())
display(df_variacoes_por_consultor.head())
