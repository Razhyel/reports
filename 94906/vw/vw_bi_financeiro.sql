/*
View: vw_anacouto_bi_financeiro

Campos:
- Classificação Financeira
- Centro de Custo
- Projeto
- Data de Competência
- Data da Baixa
- Valor
- Valor da Baixa
- Situação do título
- Tipo (pagar/receber)
- Número do título
- Nome do Participante
- Estabelecimento
- Razão Social do Participante
- Discriminação do Rateio
- Nome do Projeto
- Observação
*/

-- View: nsview.vw_anacouto_bi_financeiro

-- DROP VIEW nsview.vw_anacouto_bi_financeiro;

CREATE OR REPLACE VIEW nsview.vw_anacouto_bi_financeiro AS 
 SELECT
    t.numero as "Número do Título",
    CASE
            WHEN t.sinal = 0 THEN 'Receber'
            ELSE 'Pagar'
    END::character varying AS "Tipo",
    --t."Tipo",
    --t."Tipo de Título",
    financas.get_situacaotitulo(t.situacao) AS "Situação do Título",
    --t."Situação do Título",
    --t."Título Provisório",
    t.emissao as "Data de Emissão",
    --t."Ano/Mês da Emissão",
    --t."Ano da Emissão",
    --t."Mês da Emissão",
    --t."Dia da Emissão",
    p.pessoa as "Participante",
    p.nome as "Razão Social do Participante",
    p.nomefantasia as "Nome do Participante",
    c.codigo as "Conta",
    c.nome as "Nome da Conta",
    COALESCE(rf.valor, 0) AS "Valor",
    COALESCE(
        CASE
            WHEN t.documentorateado IS NULL THEN t.valorbruto::double precision
            ELSE round((rf.valor * (b.valor / t.valorbruto)), 2)
        END, 0) AS "Valor da Baixa",
    e.codigo as "Estabelecimento",
    e.nomefantasia as "Nome do Estabelecimento",
    --t."Empresa",
    --t."Nome da Empresa",
    --t."Grupo Empresarial",
    --t."Nome do Grupo Empresarial",
    t.vencimento as "Data do Vencimento",
    --t."Ano/Mês do Vencimento",
    --t."Ano do Vencimento",
    --t."Mês do Vencimento",
    --t."Dia do Vencimento",
    --t."Data Previsão do Vencimento",
    --t."Ano/Mês da Previsão Venc.",
    --t."Ano da Previsão Venc.",
    --t."Mês da Previsão Venc.",
    --t."Dia da Previsão Venc.",
    b.data as "Data da Baixa",
    --t."Ano/Mês da Baixa",
    --t."Ano da Baixa",
    --t."Mês da Baixa",
    --t."Dia da Baixa",
    t.datacompetencia as "Data da Competência",
    --t."Ano/Mês da Competência",
    --t."Ano da Competência",
    --t."Mês da Competência",
    --t."Dia da Competência",
    --t."Origem",
    --cc."Ident. do CCusto",
    cc.codigo as "Centro de Custo",
    cc.descricao as "Descrição do CCusto",
    --cc."Código Contábil do CCusto",
    --cc."Resumo do CCusto",
    --cc."Grupo Empresarial do CCusto",
    --cc."Pai do CCusto",
    --cc."Pai Centro de Custo",
    --cc."Pai Descrição do CCusto",
    --cc."Pai Código Contábil do CCusto",
    --cc."Pai Resumo do CCusto",
    --cf."Ident. da Clas. Fin.",
    cf.codigo as "Classificação Financeira",
    cf.descricao as "Descrição da Class. Fin.",
    --cf."Código Contábil da Clas. Fin.",
    --cf."Resumo da Clas. Fin.",
    --cf."Pai da Clas. Fin.",
    --cf."Grupo Empresarial da Clas. Fin.",
    --p."Ident. do Projeto",
    prj.codigo as "Projeto",
    prj.nome as "Nome do Projeto",
    --p."Projeto Finalizado?",
    --p."Data Início do Projeto",
    --p."Data Fim do Projeto",
    --p."Grupo Empresarial do Projeto",
    rf.discriminacao AS "Discriminação do Rateio",
    t.observacao AS "Observação"
    --t."Valor Líquido",
    --t."Número Documentos",
    --t."Número Nota",
    --t."CNPJ/CPF do Estabelecimento",
    --t."CNPJ/CPF do Fornecedor",
    --t."Forma de Pagamento",
    --t."Desc. da Forma de Pagamento",
    --t."Semana do Pagamento",
    --cpfornecedor.codigo AS "Tipo de Fornecedor Código",
    --cpfornecedor.descricao AS "Tipo de Fornecedor Descrição",
    --cpcliente.codigo AS "Tipo de Cliente Código",
    --cpcliente.descricao AS "Tipo de Cliente Descrição",
    /*COALESCE(
        CASE
            WHEN t."Tipo"::text = 'Pagar'::text THEN COALESCE(rf.valor::double precision * (- 1::double precision), 0::double precision)
            ELSE COALESCE(rf.valor::double precision, 0::double precision)
        END, 0::double precision) AS "Valor - Sinal"
    */

    from financas.titulos t
    join ns.pessoas p on (p.id = t.id_pessoa)
    join ns.estabelecimentos e on (e.estabelecimento = t.id_estabelecimento)
    join financas.contas c on (c.conta = t.conta)
    left join financas.baixas b on (b.id_titulo = t.id)
    left join financas.rateiosfinanceiros rf ON (rf.documentorateado = t.documentorateado)
    left join financas.centroscustos cc on (cc.centrocusto = rf.centrocusto)
    left join financas.classificacoesfinanceiras cf on (cf.classificacaofinanceira = rf.classificacaofinanceira)
    left join financas.projetos prj on (prj.projeto = rf.projeto)


    --LEFT JOIN nsview.vw_centro_de_custo_financeiro cc ON cc."Ident. do CCusto" = rf.centrocusto
    --LEFT JOIN nsview.vw_classificacao_financeira cf ON cf."Ident. da Clas. Fin." = rf.classificacaofinanceira
    --LEFT JOIN nsview.vw_projeto p ON p."Ident. do Projeto" = rf.projeto
    --LEFT JOIN ns.pessoas pessoas ON t.id_pessoa = pessoas.id
    -- LEFT JOIN ns.clapes cpfornecedor ON pessoas.idclasspessoafornecedor = cpfornecedor.id
    -- LEFT JOIN ns.clapes cpcliente ON pessoas.idclasspessoacliente = cpcliente.id
  ORDER BY t.emissao, t.numero;

ALTER TABLE nsview.vw_anacouto_bi_financeiro
  OWNER TO group_nasajon;
GRANT ALL ON TABLE nsview.vw_anacouto_bi_financeiro TO group_nasajon;

select nsview.public_register_nsview
('vw_anacouto_bi_financeiro', 4, 10, '', NULL);
