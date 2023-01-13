/*
Autor: Andre Maia
*/

-- View: nsview.vw_titulos_pagar_receber

-- DROP VIEW nsview.vw_titulos_pagar_receber;

CREATE OR REPLACE VIEW nsview.vw_titulos_pagar_receber AS 
 SELECT tit.numero AS "Número do Título",
        CASE
            WHEN tit.adiantamento THEN 'Adiantamento'::text
            ELSE 'Normal'::text
        END::character varying AS "Tipo de Título",
    financas.get_situacaotitulo(tit.situacao) AS "Situação do Título",
        CASE
            WHEN tit.dataprovisoria OR tit.valorprovisorio THEN 'Sim'::text
            ELSE 'Não'::text
        END::character varying AS "Título Provisório",
    tit.emissao AS "Data de Emissão",
    to_char(tit.emissao::timestamp with time zone, 'YYYY/MM'::text) AS "Ano/Mês da Emissão",
    date_part('YEAR'::text, tit.emissao) AS "Ano da Emissão",
    lpad(date_part('MONTH'::text, tit.emissao)::text, 2, '0'::text) AS "Mês da Emissão",
    date_part('DAY'::text, tit.emissao) AS "Dia da Emissão",
    tit.pessoa AS "Participante",
    tit.razaosocial AS "Razão Social do Participante",
    pessoas.nomefantasia AS "Nome do Participante",
    c.codigo AS "Conta",
    c.nome AS "Nome da Conta",
    tit.valorbruto AS "Valor",
    tit.valorsemimpostos AS "Valor Líquido",
    b.valor AS "Valor da Baixa",
        CASE
            WHEN tit.sinal = 1 THEN ('-'::text || b.valor::character varying::text)::character varying
            ELSE b.valor::character varying
        END AS "Valor da Baixa Convertido",
    tit.saldoadiantamento AS "Saldo do Adiantamento",
    est.codigo AS "Estabelecimento",
    est.nomefantasia AS "Nome do Estabelecimento",
    emp.codigo AS "Empresa",
    emp.descricao AS "Nome da Empresa",
    ge.codigo AS "Grupo Empresarial",
    ge.descricao AS "Nome do Grupo Empresarial",
    tit.datacompetencia AS "Data da Competência",
    to_char(tit.datacompetencia::timestamp with time zone, 'YYYY/MM'::text) AS "Ano/Mês da Competência",
    date_part('YEAR'::text, tit.datacompetencia) AS "Ano da Competência",
    date_part('MONTH'::text, tit.datacompetencia) AS "Mês da Competência",
    date_part('DAY'::text, tit.datacompetencia) AS "Dia da Competência",
    tit.vencimento AS "Data do Vencimento",
    to_char(tit.vencimento::timestamp with time zone, 'YYYY/MM'::text) AS "Ano/Mês do Vencimento",
    date_part('YEAR'::text, tit.vencimento) AS "Ano do Vencimento",
    date_part('MONTH'::text, tit.vencimento) AS "Mês do Vencimento",
    date_part('DAY'::text, tit.vencimento) AS "Dia do Vencimento",
    tit.previsaovencimento AS "Data Previsão do Vencimento",
    to_char(tit.previsaovencimento::timestamp with time zone, 'YYYY/MM'::text) AS "Ano/Mês da Previsão Venc.",
    date_part('YEAR'::text, tit.previsaovencimento) AS "Ano da Previsão Venc.",
    date_part('MONTH'::text, tit.previsaovencimento) AS "Mês da Previsão Venc.",
    date_part('DAY'::text, tit.previsaovencimento) AS "Dia da Previsão Venc.",
    b.data AS "Data da Baixa",
    to_char(b.data::timestamp with time zone, 'YYYY/MM'::text) AS "Ano/Mês da Baixa",
    date_part('YEAR'::text, b.data) AS "Ano da Baixa",
    date_part('MONTH'::text, b.data) AS "Mês da Baixa",
    date_part('DAY'::text, b.data) AS "Dia da Baixa",
    tit.percentualdesconto,
    tit.percentualmulta,
    tit.percentualjurosdiario,
    tit.observacao,
    COALESCE(tit.pisretido, 0::numeric) AS pisretido,
    COALESCE(tit.cofinsretido, 0::numeric) AS cofinsretido,
    COALESCE(tit.csllretido, 0::numeric) AS csllretido,
    COALESCE(tit.irretido, 0::numeric) AS irretido,
    financas.get_origemtexto(tit.origem) AS "Origem",
    COALESCE(tit.inssretido, 0::numeric) AS "INSS Retido",
    tit.aliquotaiss AS "Aliquota ISS",
    COALESCE(tit.issretido, 0::numeric) AS "ISS Retido",
    tit.nossonumero AS "Nosso número",
    tit.irretidonf AS "IRRF Retido na Nota",
    tit.inssretidonf AS "INSS Retido na Nota",
    tit.parcela AS "Parcela",
    tit.totalparcelas AS "Total de Parcelas",
    tit.desconto AS "Desconto",
    tit.juros AS "Juros",
    tit.multa AS "Multa",
    tit.outrosacrescimos AS "Outros Acrescimos",
    tit.documentorateado AS "Documento Rateado",
    tit.numeronota AS "Número Nota",
        CASE financas.getperfilcontrato(tit.id)
            WHEN 'L'::bpchar THEN 'Locação'::text
            ELSE
            CASE
                WHEN tit.origem = 0 THEN 'Manutenção'::text
                WHEN tit.origem = 1 THEN 'Pedido'::text
                WHEN tit.origem = 2 THEN 'RPS'::text
                WHEN tit.origem = 3 THEN 'Contrato'::text
                WHEN tit.origem = 4 THEN 'Scritta'::text
                WHEN tit.origem = 5 THEN 'Nota Fiscal Serviço'::text
                WHEN tit.origem = 6 THEN 'Nota Fiscal Eletrônica'::text
                WHEN tit.origem = 7 THEN 'Lançamento Fiscal'::text
                WHEN tit.origem = 8 THEN 'Documentos'::text
                WHEN tit.origem = 9 THEN 'Nota Serviços Publicos'::text
                WHEN tit.origem = 10 THEN 'Nota Prestação Serviços'::text
                WHEN tit.origem = 11 THEN 'Conhecimento Transporte'::text
                WHEN tit.origem = 12 THEN 'GR ICMS'::text
                WHEN tit.origem = 13 THEN 'GR ISS'::text
                WHEN tit.origem = 14 THEN 'GNRE'::text
                WHEN tit.origem = 15 THEN 'DARF'::text
                WHEN tit.origem = 16 THEN 'GPS'::text
                WHEN tit.origem = 17 THEN 'Outros Documentos'::text
                WHEN tit.origem = 18 THEN 'Folha Persona'::text
                WHEN tit.origem = 19 THEN 'Pagamento Persona'::text
                WHEN tit.origem = 20 THEN 'Guia Persona'::text
                WHEN tit.origem = 21 THEN 'Nota Controller'::text
                WHEN tit.origem = 22 THEN 'Importação'::text
                WHEN tit.origem = 23 THEN 'Previsão'::text
                WHEN tit.origem = 24 THEN 'Fatura'::text
                ELSE NULL::text
            END
        END::character varying AS "Origem com locação",
        CASE
            WHEN df.numero IS NULL OR df.numero::text = '-'::text THEN tit.numero
            ELSE df.numero
        END AS "Número Documentos",
        CASE
            WHEN est.raizcnpj IS NOT NULL THEN (est.raizcnpj::text || est.ordemcnpj::text)::character varying
            ELSE COALESCE(est.cpf, NULL::character varying)
        END AS "CNPJ/CPF do Estabelecimento",
    pessoas.cnpj AS "CNPJ/CPF do Fornecedor",
    tit.id_pessoa,
        CASE
            WHEN tit.sinal = 0 THEN 'Receber'::text
            ELSE 'Pagar'::text
        END::character varying AS "Tipo",
    ( SELECT financas.getvendoresportitulo(tit.id) AS getvendoresportitulo) AS "Vendedores",
    tit.formapagamento_codigo AS "Forma de Pagamento",
    tit.formapagamento_descricao AS "Desc. da Forma de Pagamento",
    date_part('week'::text, b.data) AS "Semana do Pagamento",
    enderecos.uf AS "Cliente UF",
    centroscustos.codigo AS "Cliente Centro de Custo",
    centroscustos.descricao AS "Cliente Cent. Custo Descrição",
    reptecnico.pessoa AS "Representante Técnico",
    reptecnico.nomefantasia AS "Nome Representante Técnico",
    reptecnico.nome AS "Razão Social Repres. Técnico",
    repcomercial.pessoa AS "Representante Comercial",
    repcomercial.nomefantasia AS "Nome Representante Comercial",
    repcomercial.nome AS "Razão Social Repres. Comercial",
    pessoas.email AS "Cliente E-mail Principal",
    pessoas.emailcobranca AS "Cliente E-mail Cobrança",
    tit.razaosocialfactoring,
    tit.numerodocumentofactoring,
    tit.razaosocialgps,
    tit.numerodocumentogps
   FROM financas.vwtitulos tit
     JOIN ns.estabelecimentos est ON est.estabelecimento = tit.id_estabelecimento
     JOIN ns.empresas emp ON emp.empresa = est.empresa
     JOIN ns.gruposempresariais ge ON emp.grupoempresarial = ge.grupoempresarial
     JOIN ns.pessoas pessoas ON tit.id_pessoa = pessoas.id
     LEFT JOIN ns.pessoas reptecnico ON pessoas.representante_tecnico = reptecnico.id
     LEFT JOIN ns.pessoas repcomercial ON pessoas.representante = repcomercial.id
     LEFT JOIN financas.baixas b ON b.id_titulo = tit.id
     LEFT JOIN financas.contas c ON c.conta = tit.conta
     LEFT JOIN ns.df_docfis df ON df.id = COALESCE(tit.id_rps, tit.id_docfis)
     LEFT JOIN ns.enderecos enderecos ON enderecos.id_pessoa = pessoas.id
     LEFT JOIN financas.centroscustos centroscustos ON centroscustos.centrocusto = pessoas.centrocusto
  WHERE enderecos.tipoendereco = 0
  ORDER BY tit.emissao, tit.numero;

ALTER TABLE nsview.vw_titulos_pagar_receber
  OWNER TO group_nasajon;
GRANT ALL ON TABLE nsview.vw_titulos_pagar_receber TO group_nasajon;
