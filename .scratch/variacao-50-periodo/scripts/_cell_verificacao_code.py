# ==============================================================================
# 3.8.1 VERIFICAÇÃO DA REGRA DE VARIAÇÃO MENSAL COM AMOSTRA SINTÉTICA
# ==============================================================================
# Exercita os casos de fronteira do método contra a função pura, sem banco, sem
# SharePoint e sem dado real de cliente (AGENTS.md: "prefira amostras sintéticas
# e pequenas"). Verifica comportamento externo observável - os valores e
# categorias que saem da função -, não como as colunas foram montadas internamente.
# ==============================================================================

def _amostra_sintetica_variacao_mensal():
    """Monta um DataFrame mensal sintético cobrindo os casos de fronteira do spec."""
    MES = lambda ano, mes: pd.Timestamp(year=ano, month=mes, day=1)

    linhas = []

    def adicionar(id_property, ano, mes, valor, consultor="Consultor A", nome=None):
        linhas.append({
            "id_property": id_property,
            "property_name": nome or id_property,
            "property_entrepreneur_label": f"{nome or id_property} - Produtor {id_property}",
            "labor_rural_code": f"LR-{id_property}",
            "reference_month": MES(ano, mes),
            "consultant_name": consultor,
            "total_cows": valor,
        })

    # --- Razão exatamente 1,5 e exatamente 0,5: NÃO marca -----------------------
    adicionar("SONDA-LIM-SUP", 2026, 1, 1.0)
    adicionar("SONDA-LIM-SUP", 2026, 2, 1.5)                              # razão == 1,5 exato
    adicionar("SONDA-LIM-INF", 2026, 1, 1.0)
    adicionar("SONDA-LIM-INF", 2026, 2, 0.5)                              # razão == 0,5 exato

    # --- Menor incremento além de cada limite: marca -----------------------------
    adicionar("SONDA-FORA-SUP", 2026, 1, 1.0)
    adicionar("SONDA-FORA-SUP", 2026, 2, np.nextafter(1.5, np.inf))       # razão > 1,5
    adicionar("SONDA-FORA-INF", 2026, 1, 1.0)
    adicionar("SONDA-FORA-INF", 2026, 2, np.nextafter(0.5, -np.inf))      # razão < 0,5

    # --- Entrada (0 -> positivo) e Saída (positivo -> 0) -------------------------
    adicionar("SONDA-ENTRADA", 2026, 1, 0)
    adicionar("SONDA-ENTRADA", 2026, 2, 50)
    adicionar("SONDA-SAIDA", 2026, 1, 50)
    adicionar("SONDA-SAIDA", 2026, 2, 0)

    # --- 0 -> 0 e nulo: Não avaliado ---------------------------------------------
    adicionar("SONDA-ZERO-ZERO", 2026, 1, 0)
    adicionar("SONDA-ZERO-ZERO", 2026, 2, 0)
    adicionar("SONDA-NULO", 2026, 1, 100)
    adicionar("SONDA-NULO", 2026, 2, np.nan)
    adicionar("SONDA-NULO", 2026, 3, 100)                                  # mês seguinte ao nulo

    # --- Lacuna de mês: Não avaliado, NUNCA comparação atravessando o buraco -----
    # jan -> mar pulando fev; se a lacuna vazasse, 100 -> 400 marcaria Aumento.
    adicionar("SONDA-LACUNA", 2026, 1, 100)
    adicionar("SONDA-LACUNA", 2026, 3, 400)

    # --- Primeira linha da fazenda: Não avaliado (fazenda com um único mês) ------
    adicionar("SONDA-PRIMEIRA", 2026, 1, 100)

    # --- Fazenda com dois consultores: aparece nos dois no resumo, sem duplicar
    #     a linha de variação em si (mensal agrega consultor em uma string única).
    adicionar("SONDA-DUPLA", 2026, 1, 100, consultor="Consultor B, Consultor C")
    adicionar("SONDA-DUPLA", 2026, 2, 250, consultor="Consultor B, Consultor C")  # razão 2,5 -> Aumento

    # --- Caso normal, de controle: variação pequena não marca ---------------------
    adicionar("SONDA-NORMAL", 2026, 1, 100)
    adicionar("SONDA-NORMAL", 2026, 2, 110)

    return pd.DataFrame(linhas)


INDICADORES_TESTE_VARIACAO = {
    "total_cows": ("Total de Vacas", "cabeças", ".0f"),
}


def verificar_variacao_periodo_com_amostra_sintetica():
    """Roda a função pura contra a amostra sintética e confere os casos de fronteira."""
    df_sintetico = _amostra_sintetica_variacao_mensal()
    colunas_antes = list(df_sintetico.columns)
    snapshot_antes = df_sintetico.copy(deep=True)

    df_anotado, df_cons, df_por_cons = calcular_variacao_periodo(
        df_sintetico, INDICADORES_TESTE_VARIACAO,
    )

    falhas = []

    def conferir(descricao, condicao, obtido=""):
        if condicao:
            print(f"  OK   {descricao}")
        else:
            falhas.append(f"{descricao} -> {obtido}")
            print(f"  FALHA {descricao} -> {obtido}")

    def categoria(id_property, ano, mes):
        linha = df_anotado.loc[
            df_anotado["id_property"].eq(id_property)
            & df_anotado["reference_month"].eq(pd.Timestamp(year=ano, month=mes, day=1))
        ]
        return linha["variacao_total_cows"].iloc[0]

    # 1. Razão exatamente 1,5 e 0,5: NÃO marca (fica Normal).
    conferir("razão exatamente 1,5 NÃO marca", categoria("SONDA-LIM-SUP", 2026, 2) == "Normal",
             categoria("SONDA-LIM-SUP", 2026, 2))
    conferir("razão exatamente 0,5 NÃO marca", categoria("SONDA-LIM-INF", 2026, 2) == "Normal",
             categoria("SONDA-LIM-INF", 2026, 2))

    # 2. Menor incremento além de cada limite: marca.
    conferir("razão logo acima de 1,5 marca Aumento", categoria("SONDA-FORA-SUP", 2026, 2) == "Aumento",
             categoria("SONDA-FORA-SUP", 2026, 2))
    conferir("razão logo abaixo de 0,5 marca Redução", categoria("SONDA-FORA-INF", 2026, 2) == "Redução",
             categoria("SONDA-FORA-INF", 2026, 2))

    # 3. Entrada e Saída.
    conferir("0 -> positivo = Entrada", categoria("SONDA-ENTRADA", 2026, 2) == "Entrada",
             categoria("SONDA-ENTRADA", 2026, 2))
    conferir("positivo -> 0 = Saída", categoria("SONDA-SAIDA", 2026, 2) == "Saída",
             categoria("SONDA-SAIDA", 2026, 2))

    # 4. 0 -> 0 e nulo: Não avaliado.
    conferir("0 -> 0 = Não avaliado", categoria("SONDA-ZERO-ZERO", 2026, 2) == "Não avaliado",
             categoria("SONDA-ZERO-ZERO", 2026, 2))
    conferir("valor nulo = Não avaliado", categoria("SONDA-NULO", 2026, 2) == "Não avaliado",
             categoria("SONDA-NULO", 2026, 2))
    conferir("mês seguinte a um nulo (sem M-1 válido) = Não avaliado",
             categoria("SONDA-NULO", 2026, 3) == "Não avaliado", categoria("SONDA-NULO", 2026, 3))

    # 5. Lacuna de mês: Não avaliado, nunca comparação atravessando o buraco.
    conferir("lacuna de mês (jan -> mar) = Não avaliado, não compara 100 -> 400",
             categoria("SONDA-LACUNA", 2026, 3) == "Não avaliado", categoria("SONDA-LACUNA", 2026, 3))

    # 6. Primeira linha da fazenda: Não avaliado.
    conferir("primeira (e única) linha da fazenda = Não avaliado",
             categoria("SONDA-PRIMEIRA", 2026, 1) == "Não avaliado", categoria("SONDA-PRIMEIRA", 2026, 1))

    # 7. Fazenda com dois consultores: aparece nos dois no resumo por consultor,
    #    sem duplicar a linha de variação em si na aba "Variações".
    linhas_dupla_consolidado = df_cons.loc[df_cons["IDFazenda"].eq("SONDA-DUPLA")]
    conferir("SONDA-DUPLA gera UMA única linha na aba Variações (não duplica por consultor)",
             len(linhas_dupla_consolidado) == 1, len(linhas_dupla_consolidado))
    resumo = df_por_cons.set_index("Consultor")
    conferir("SONDA-DUPLA marcada aparece para os DOIS consultores no resumo",
             "Consultor B" in resumo.index and "Consultor C" in resumo.index
             and int(resumo.loc["Consultor B", "Fazendas marcadas"]) >= 1
             and int(resumo.loc["Consultor C", "Fazendas marcadas"]) >= 1,
             resumo.index.tolist() if "Consultor B" not in resumo.index or "Consultor C" not in resumo.index
             else {c: int(resumo.loc[c, "Fazendas marcadas"]) for c in ("Consultor B", "Consultor C")})

    # 8. Caso normal: variação pequena não entra na aba Variações.
    conferir("SONDA-NORMAL (variação de 10%) não marca e não aparece na aba Variações",
             categoria("SONDA-NORMAL", 2026, 2) == "Normal"
             and df_cons.loc[df_cons["IDFazenda"].eq("SONDA-NORMAL")].empty)

    # 9. A aba "Variações" só contém Aumento/Redução (nunca Entrada/Saída/Normal/Não avaliado).
    conferir("aba Variações só contém linhas Aumento/Redução",
             df_cons["Lado"].isin(["Aumento", "Redução"]).all(), df_cons["Lado"].unique().tolist())

    # 10. Pureza: a função não altera o DataFrame de entrada.
    conferir("a função não altera o DataFrame de entrada (mesmas colunas)",
             list(df_sintetico.columns) == colunas_antes)
    conferir("a função não altera os valores do DataFrame de entrada",
             df_sintetico.equals(snapshot_antes))

    if falhas:
        raise AssertionError(
            f"{len(falhas)} verificação(ões) da amostra sintética falharam:\n  - "
            + "\n  - ".join(falhas)
        )
    print(f"\nAmostra sintética: {len(df_sintetico):,} linhas, "
          f"{df_sintetico['id_property'].nunique()} fazendas - todas as verificações passaram.")


verificar_variacao_periodo_com_amostra_sintetica()
