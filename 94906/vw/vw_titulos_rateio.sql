-- View: nsview.vw_titulos_rateio

-- DROP VIEW nsview.vw_titulos_rateio;

CREATE OR REPLACE VIEW nsview.vw_titulos_rateio AS 
 SELECT tit."Número do Título",
    tit."Tipo",
    tit."Tipo de Título",
    tit."Situação do Título",
    tit."Título Provisório",
    tit."Data de Emissão",
    tit."Ano/Mês da Emissão",
    tit."Ano da Emissão",
    tit."Mês da Emissão",
    tit."Dia da Emissão",
    tit."Participante",
    tit."Razão Social do Participante",
    tit."Nome do Participante",
    tit."Conta",
    tit."Nome da Conta",
    COALESCE(rf.valor::double precision, 0::double precision) AS "Valor",
    COALESCE(
        CASE
            WHEN tit."Documento Rateado" IS NULL THEN tit."Valor"::double precision
            ELSE round((rf.valor::double precision * (tit."Valor da Baixa" / tit."Valor")::double precision)::numeric, 2)::double precision
        END, 0::double precision) AS "Valor da Baixa",
    COALESCE(
        CASE
            WHEN tit."Documento Rateado" IS NULL THEN tit."Saldo do Adiantamento"::double precision
            ELSE rf.valor::double precision
        END, 0::double precision) AS "Saldo Adiantamento",
    tit."Estabelecimento",
    tit."Nome do Estabelecimento",
    tit."Empresa",
    tit."Nome da Empresa",
    tit."Grupo Empresarial",
    tit."Nome do Grupo Empresarial",
    tit."Data do Vencimento",
    tit."Ano/Mês do Vencimento",
    tit."Ano do Vencimento",
    tit."Mês do Vencimento",
    tit."Dia do Vencimento",
    tit."Data Previsão do Vencimento",
    tit."Ano/Mês da Previsão Venc.",
    tit."Ano da Previsão Venc.",
    tit."Mês da Previsão Venc.",
    tit."Dia da Previsão Venc.",
    tit."Data da Baixa",
    tit."Ano/Mês da Baixa",
    tit."Ano da Baixa",
    tit."Mês da Baixa",
    tit."Dia da Baixa",
    tit."Data da Competência",
    tit."Ano/Mês da Competência",
    tit."Ano da Competência",
    tit."Mês da Competência",
    tit."Dia da Competência",
    tit."Origem",
    cc."Ident. do CCusto",
    cc."Centro de Custo",
    cc."Descrição do CCusto",
    cc."Código Contábil do CCusto",
    cc."Resumo do CCusto",
    cc."Grupo Empresarial do CCusto",
    cc."Pai do CCusto",
    cc."Pai Centro de Custo",
    cc."Pai Descrição do CCusto",
    cc."Pai Código Contábil do CCusto",
    cc."Pai Resumo do CCusto",
    cf."Ident. da Clas. Fin.",
    cf."Classificação Financeira",
    cf."Descrição da Clas. Fin.",
    cf."Código Contábil da Clas. Fin.",
    cf."Resumo da Clas. Fin.",
    cf."Pai da Clas. Fin.",
    cf."Grupo Empresarial da Clas. Fin.",
    p."Ident. do Projeto",
    p."Projeto",
    p."Nome do Projeto",
    p."Projeto Finalizado?",
    p."Data Início do Projeto",
    p."Data Fim do Projeto",
    p."Grupo Empresarial do Projeto",
    rf.discriminacao AS "Discriminação do Rateio",
    tit.observacao AS "Observação",
    tit."Valor Líquido",
    tit."Número Documentos",
    tit."Número Nota",
    tit."CNPJ/CPF do Estabelecimento",
    tit."CNPJ/CPF do Fornecedor",
    tit."Forma de Pagamento",
    tit."Desc. da Forma de Pagamento",
    tit."Semana do Pagamento",
    cpfornecedor.codigo AS "Tipo de Fornecedor Código",
    cpfornecedor.descricao AS "Tipo de Fornecedor Descrição",
    cpcliente.codigo AS "Tipo de Cliente Código",
    cpcliente.descricao AS "Tipo de Cliente Descrição",
    COALESCE(
        CASE
            WHEN tit."Tipo"::text = 'Pagar'::text THEN COALESCE(rf.valor::double precision * (- 1::double precision), 0::double precision)
            ELSE COALESCE(rf.valor::double precision, 0::double precision)
        END, 0::double precision) AS "Valor - Sinal"
   FROM nsview.vw_titulos_pagar_receber tit
     LEFT JOIN financas.rateiosfinanceiros rf ON rf.documentorateado = tit."Documento Rateado"
     LEFT JOIN nsview.vw_centro_de_custo_financeiro cc ON cc."Ident. do CCusto" = rf.centrocusto
     LEFT JOIN nsview.vw_classificacao_financeira cf ON cf."Ident. da Clas. Fin." = rf.classificacaofinanceira
     LEFT JOIN nsview.vw_projeto p ON p."Ident. do Projeto" = rf.projeto
     LEFT JOIN ns.pessoas pessoas ON tit.id_pessoa = pessoas.id
     LEFT JOIN ns.clapes cpfornecedor ON pessoas.idclasspessoafornecedor = cpfornecedor.id
     LEFT JOIN ns.clapes cpcliente ON pessoas.idclasspessoacliente = cpcliente.id
  ORDER BY tit."Data de Emissão", tit."Número do Título";

ALTER TABLE nsview.vw_titulos_rateio
  OWNER TO group_nasajon;
GRANT ALL ON TABLE nsview.vw_titulos_rateio TO group_nasajon;
