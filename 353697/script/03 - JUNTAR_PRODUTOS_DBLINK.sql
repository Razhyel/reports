--drop view  nsview.vw_faturamento_itens;
--drop view  nsview.vw_faturamento;

ALTER TABLE ns.conjuntosclientes DISABLE TRIGGER ALL;
ALTER TABLE ns.conjuntosfichas DISABLE TRIGGER ALL;
ALTER TABLE ns.conjuntosfornecedores DISABLE TRIGGER ALL;
ALTER TABLE ns.pessoas DISABLE TRIGGER ALL;
ALTER TABLE ns.enderecos DISABLE TRIGGER ALL;
ALTER TABLE ns.telefones DISABLE TRIGGER ALL;
ALTER TABLE ns.contatos DISABLE TRIGGER ALL;
ALTER TABLE financas.titulos DISABLE TRIGGER ALL;
ALTER TABLE financas.baixas DISABLE TRIGGER ALL;
ALTER TABLE financas.lancamentoscontas DISABLE TRIGGER ALL;
ALTER TABLE financas.documentosrateados DISABLE TRIGGER ALL;
ALTER TABLE financas.rateiosfinanceiros DISABLE TRIGGER ALL;
ALTER TABLE importacao.participante_v1 DISABLE TRIGGER ALL;
ALTER TABLE importacao.cliente_v1 DISABLE TRIGGER ALL;
ALTER TABLE importacao.fornecedor_v1 DISABLE TRIGGER ALL;
ALTER TABLE importacao.titulo_v1 DISABLE TRIGGER ALL;
ALTER TABLE importacao.titulo_a_receber_v1 DISABLE TRIGGER ALL;
ALTER TABLE importacao.titulo_a_pagar_v1 DISABLE TRIGGER ALL;
ALTER TABLE importacao.baixa_v1 DISABLE TRIGGER ALL;
ALTER TABLE importacao.baixa_recebimento_v1 DISABLE TRIGGER ALL;
ALTER TABLE importacao.baixa_pagamento_v1 DISABLE TRIGGER ALL;
ALTER TABLE ns.df_docfis DISABLE TRIGGER ALL;

CREATE OR REPLACE FUNCTION conversor.fun_juncao_produto_v2(a_produto_juncao uuid, a_produto_exclusao uuid)
  RETURNS integer AS
$BODY$
BEGIN
  SET SESSION "SISTEMA.ATIVA_RASTRO" = FALSE;

  perform conversor.fun_juncao_produto(a_produto_juncao, a_produto_exclusao);

  return 1;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION conversor.fun_juncao_produto_v2(uuid, uuid)
  OWNER TO group_nasajon;



do
$$
declare rec_produtos record;
declare id_produto_manter uuid;
declare id_produto_excluir uuid;
declare rowUsuario ns.usuarios%rowtype;
declare nomeBanco text;
declare porta text;
declare ConStr text;
declare cont integer;
begin
  cont = 0;
  select * from ns.usuarios where login = 'MESTRE' into rowUsuario;  
  select current_database() into nomeBanco;
  select inet_server_port() into porta;
  ConStr = 'host=localhost port='||porta||' user='||lower(nomeBanco||'_'||rowUsuario.login)||' password='||rowUsuario.senha||' dbname='||nomeBanco;

  for rec_produtos in (select e.codigo as cod_estab,
       ec.estabelecimento, 
       --p.codigodebarras, 
       p.codigo as cod_prod, 
       count(distinct p.produto) 
from estoque.produtos p
inner join ns.conjuntosprodutos cp on cp.registro = p.produto
inner join ns.estabelecimentosconjuntos ec on ec.conjunto = cp.conjunto
inner join ns.estabelecimentos e on e.estabelecimento = ec.estabelecimento and e.codigo = '002'
where p.codigo in (

select distinct p.codigo
from ns.df_docfis df
inner join ns.df_itens di on di.id_docfis = df.id
inner join estoque.itens i on i.id = di.id_item
inner join estoque.produtos p on p.produto = i.produto
--where df.lancamento >= '2018-11-01'


)
group by 1,2,3
having count(distinct p.produto)  > 1
order by count(distinct p.produto) , p.codigo
			)
  loop
    cont = cont + 1;
    raise notice '% Juntando Estab %, Produto %', cont, rec_produtos.cod_estab, rec_produtos.cod_prod;

	select p.produto
	from estoque.produtos p
	inner join ns.conjuntosprodutos cp on cp.registro = p.produto
	inner join ns.estabelecimentosconjuntos ec on ec.conjunto = cp.conjunto
	where ec.estabelecimento = rec_produtos.estabelecimento and
	  p.codigo = rec_produtos.cod_prod /*and
	  p.codigodebarras = rec_produtos.codigodebarras*/
	order by coalesce(p.codigodebarras,'') <> '' desc ,coalesce(p.precovenda,0) desc, coalesce(p.tipi,'') <> '' desc,
	         familia is not null desc , categoriadeproduto is not null desc
	limit 1 
	into id_produto_manter;

	select p.produto
	from estoque.produtos p
	inner join ns.conjuntosprodutos cp on cp.registro = p.produto
	inner join ns.estabelecimentosconjuntos ec on ec.conjunto = cp.conjunto
	where ec.estabelecimento = rec_produtos.estabelecimento and
	  p.codigo = rec_produtos.cod_prod and
	  --p.codigodebarras = rec_produtos.codigodebarras and
	  p.produto <> id_produto_manter
	order by coalesce(p.codigodebarras,'') <> '' desc ,coalesce(p.precovenda,0) desc, coalesce(p.tipi,'') <> '' desc
	limit 1 
	into id_produto_excluir;        
	
	raise notice 'executando juncao %    %', id_produto_manter, id_produto_excluir;

	begin
		perform * from dblink(ConStr,'select conversor.fun_juncao_produto_v2('''||id_produto_manter||'''::uuid, '''||id_produto_excluir||'''::uuid)') as teste(a integer);  
	exception when others then
	  raise notice '% %', SQLERRM, SQLSTATE;
	end;
  end loop;
end;
$$

ALTER TABLE ns.conjuntosclientes ENABLE TRIGGER ALL;
ALTER TABLE ns.conjuntosfichas ENABLE TRIGGER ALL;
ALTER TABLE ns.conjuntosfornecedores ENABLE TRIGGER ALL;
ALTER TABLE ns.pessoas ENABLE TRIGGER ALL;
ALTER TABLE ns.enderecos ENABLE TRIGGER ALL;
ALTER TABLE ns.telefones ENABLE TRIGGER ALL;
ALTER TABLE ns.contatos ENABLE TRIGGER ALL;
ALTER TABLE financas.titulos ENABLE TRIGGER ALL;
ALTER TABLE financas.baixas ENABLE TRIGGER ALL;
ALTER TABLE financas.lancamentoscontas ENABLE TRIGGER ALL;
ALTER TABLE financas.documentosrateados ENABLE TRIGGER ALL;
ALTER TABLE financas.rateiosfinanceiros ENABLE TRIGGER ALL;
ALTER TABLE importacao.participante_v1 ENABLE TRIGGER ALL;
ALTER TABLE importacao.cliente_v1 ENABLE TRIGGER ALL;
ALTER TABLE importacao.fornecedor_v1 ENABLE TRIGGER ALL;
ALTER TABLE importacao.titulo_v1 ENABLE TRIGGER ALL;
ALTER TABLE importacao.titulo_a_receber_v1 ENABLE TRIGGER ALL;
ALTER TABLE importacao.titulo_a_pagar_v1 ENABLE TRIGGER ALL;
ALTER TABLE importacao.baixa_v1 ENABLE TRIGGER ALL;
ALTER TABLE importacao.baixa_recebimento_v1 ENABLE TRIGGER ALL;
ALTER TABLE importacao.baixa_pagamento_v1 ENABLE TRIGGER ALL;
ALTER TABLE ns.df_docfis ENABLE TRIGGER ALL;

/*
4721
select count(*)
from(
select e.codigo as cod_estab,
       ec.estabelecimento, 
       --p.codigodebarras, 
       p.codigo as cod_prod, 
       count(distinct p.produto) 
from estoque.produtos p
inner join ns.conjuntosprodutos cp on cp.registro = p.produto
inner join ns.estabelecimentosconjuntos ec on ec.conjunto = cp.conjunto
inner join ns.estabelecimentos e on e.estabelecimento = ec.estabelecimento and e.codigo = '05'
where p.codigo in (

select distinct p.codigo
from ns.df_docfis df
inner join ns.df_itens di on di.id_docfis = df.id
inner join estoque.itens i on i.id = di.id_item
inner join estoque.produtos p on p.produto = i.produto
where df.lancamento >= '2018-11-01'


)
group by 1,2,3
having count(distinct p.produto)  > 1
)s
*/

/*
-- View: nsview.vw_faturamento
-- DROP VIEW nsview.vw_faturamento;

CREATE OR REPLACE VIEW nsview.vw_faturamento AS 
 SELECT df_docfis.id AS "Identificador Documento",
    df_docfis.documentorateado AS "Identificador Documento Rateado",
    estabelecimentos.estabelecimento AS "Identificador Estabelecimento",
    estabelecimentos.codigo AS "Estabelecimento",
    estabelecimentos.nomefantasia AS "Nome do Estabelecimento",
        CASE df_docfis.origem
            WHEN 0 THEN 'Manual'::text
            WHEN 1 THEN 'Ordem de Serviço'::text
            WHEN 2 THEN
            CASE
                WHEN (( SELECT financas.getperfilcontrato(s.titulo) AS getperfilcontrato
                   FROM ns.df_servicos s
                  WHERE s.id_docfis = df_docfis.id
                 LIMIT 1)) = 'L'::bpchar THEN 'Contrato de Locação'::text
                ELSE 'Contrato de Serviço'::text
            END
            ELSE '<Não Informado>'::text
        END AS "Origem do Documento",
    df_docfis.numero AS "Número Documento",
    df_docfis.emissao AS "Data de Emissão",
    pessoas.id AS "Identificador Cliente",
    pessoas.pessoa AS "Cliente",
    pessoas.nome AS "Nome do Cliente",
    pessoas.cnpj AS "Documento do Cliente",
    df_docfis.valor AS "Valor Documento",
    'Nota Fiscal de Serviço (NFS-e)'::text AS "Tipo do Documento",
    NULL::uuid AS "Identificador Operação",
    NULL::character varying(30) AS "Código da Operação",
    NULL::character varying(150) AS "Descrição da Operação"
   FROM ns.df_docfis
     JOIN ns.pessoas ON pessoas.id = df_docfis.id_pessoa
     JOIN ns.estabelecimentos ON estabelecimentos.estabelecimento = df_docfis.id_estabelecimento
  WHERE df_docfis.tipo = 5 AND df_docfis.modelo::text = 'NES'::text AND (df_docfis.statusrps = ANY (ARRAY[4, 6])) AND (EXISTS ( SELECT titulos.id
           FROM financas.titulos
          WHERE titulos.id_docfis = df_docfis.id AND titulos.sinal = 0 AND titulos.situacao <> 3
         LIMIT 1))
UNION
 SELECT titulos.id AS "Identificador Documento",
    titulos.documentorateado AS "Identificador Documento Rateado",
    estabelecimentos.estabelecimento AS "Identificador Estabelecimento",
    estabelecimentos.codigo AS "Estabelecimento",
    estabelecimentos.nomefantasia AS "Nome do Estabelecimento",
    'Contrato de Locação'::text AS "Origem do Documento",
    titulos.numero AS "Número Documento",
    titulos.emissao AS "Data de Emissão",
    pessoas.id AS "Identificador Cliente",
    pessoas.pessoa AS "Cliente",
    pessoas.nome AS "Nome do Cliente",
    pessoas.cnpj AS "Documento do Cliente",
    titulos.valor AS "Valor Documento",
    'Fatura'::text AS "Tipo do Documento",
    NULL::uuid AS "Identificador Operação",
    NULL::character varying(30) AS "Código da Operação",
    NULL::character varying(150) AS "Descrição da Operação"
   FROM financas.titulos
     JOIN ns.pessoas ON pessoas.id = titulos.id_pessoa
     JOIN ns.estabelecimentos ON estabelecimentos.estabelecimento = titulos.id_estabelecimento
  WHERE (titulos.situacao <> ANY (ARRAY[3])) AND financas.getperfilcontrato(titulos.id) = 'L'::bpchar
UNION
 SELECT df_docfis.id AS "Identificador Documento",
    df_docfis.documentorateado AS "Identificador Documento Rateado",
    estabelecimentos.estabelecimento AS "Identificador Estabelecimento",
    estabelecimentos.codigo AS "Estabelecimento",
    estabelecimentos.nomefantasia AS "Nome do Estabelecimento",
    'Manual'::text AS "Origem do Documento",
    df_docfis.numero AS "Número Documento",
    df_docfis.emissao AS "Data de Emissão",
    pessoas.id AS "Identificador Cliente",
    pessoas.pessoa AS "Cliente",
    pessoas.nome AS "Nome do Cliente",
    pessoas.cnpj AS "Documento do Cliente",
    df_docfis.valor AS "Valor Documento",
    'Nota Fiscal de Mercadoria (NF-e)'::text AS "Tipo do Documento",
    operacoes.operacao AS "Identificador Operação",
    operacoes.codigo AS "Código da Operação",
    operacoes.descricao AS "Descrição da Operação"
   FROM ns.df_docfis
     JOIN ns.pessoas ON pessoas.id = df_docfis.id_pessoa
     JOIN ns.estabelecimentos ON estabelecimentos.estabelecimento = df_docfis.id_estabelecimento
     JOIN estoque.operacoes ON operacoes.operacao = df_docfis.documento_operacao
  WHERE df_docfis.tipo = 0 AND df_docfis.modelo::text = 'NE'::text AND df_docfis.sinal = 0 AND (df_docfis.situacao = ANY (ARRAY[2])) AND (EXISTS ( SELECT titulos.id
           FROM financas.titulos
          WHERE titulos.id_docfis = df_docfis.id AND titulos.sinal = 0 AND titulos.situacao <> 3
         LIMIT 1))
UNION
 SELECT df_docfis.id AS "Identificador Documento",
    df_docfis.documentorateado AS "Identificador Documento Rateado",
    estabelecimentos.estabelecimento AS "Identificador Estabelecimento",
    estabelecimentos.codigo AS "Estabelecimento",
    estabelecimentos.nomefantasia AS "Nome do Estabelecimento",
    'Manual'::text AS "Origem do Documento",
    df_docfis.numero AS "Número Documento",
    df_docfis.emissao AS "Data de Emissão",
    pessoas.id AS "Identificador Cliente",
    pessoas.pessoa AS "Cliente",
    pessoas.nome AS "Nome do Cliente",
    pessoas.cnpj AS "Documento do Cliente",
    df_docfis.valor AS "Valor Documento",
    'Cupom Fisical(SAT)'::text AS "Tipo do Documento",
    operacoes.operacao AS "Identificador Operação",
    operacoes.codigo AS "Código da Operação",
    operacoes.descricao AS "Descrição da Operação"
   FROM ns.df_docfis
     LEFT JOIN ns.pessoas ON pessoas.id = df_docfis.id_pessoa
     JOIN ns.estabelecimentos ON estabelecimentos.estabelecimento = df_docfis.id_estabelecimento
     JOIN estoque.operacoes ON operacoes.operacao = df_docfis.documento_operacao
  WHERE (df_docfis.tipo = 0 OR df_docfis.tipo = 13) AND df_docfis.modelo::text = 'SAT'::text AND df_docfis.sinal = 0 AND (df_docfis.situacao = ANY (ARRAY[2])) AND (EXISTS ( SELECT titulos.id
           FROM financas.titulos
          WHERE titulos.id_docfis = df_docfis.id AND titulos.sinal = 0 AND titulos.situacao <> 3
         LIMIT 1))
UNION
 SELECT df_docfis.id AS "Identificador Documento",
    df_docfis.documentorateado AS "Identificador Documento Rateado",
    estabelecimentos.estabelecimento AS "Identificador Estabelecimento",
    estabelecimentos.codigo AS "Estabelecimento",
    estabelecimentos.nomefantasia AS "Nome do Estabelecimento",
    'Manual'::text AS "Origem do Documento",
    df_docfis.numero AS "Número Documento",
    df_docfis.emissao AS "Data de Emissão",
    pessoas.id AS "Identificador Cliente",
    pessoas.pessoa AS "Cliente",
    pessoas.nome AS "Nome do Cliente",
    pessoas.cnpj AS "Documento do Cliente",
    df_docfis.valor AS "Valor Documento",
    'Nota Fiscal de Consumidor(NFC-e)'::text AS "Tipo do Documento",
    operacoes.operacao AS "Identificador Operação",
    operacoes.codigo AS "Código da Operação",
    operacoes.descricao AS "Descrição da Operação"
   FROM ns.df_docfis
     LEFT JOIN ns.pessoas ON pessoas.id = df_docfis.id_pessoa
     JOIN ns.estabelecimentos ON estabelecimentos.estabelecimento = df_docfis.id_estabelecimento
     JOIN estoque.operacoes ON operacoes.operacao = df_docfis.documento_operacao
  WHERE df_docfis.tipo = 0 AND df_docfis.modelo::text = 'NCE'::text AND df_docfis.sinal = 0 AND (df_docfis.situacao = ANY (ARRAY[2])) AND (EXISTS ( SELECT titulos.id
           FROM financas.titulos
          WHERE titulos.id_docfis = df_docfis.id AND titulos.sinal = 0 AND titulos.situacao <> 3
         LIMIT 1));

ALTER TABLE nsview.vw_faturamento
  OWNER TO group_nasajon;
GRANT ALL ON TABLE nsview.vw_faturamento TO group_nasajon;

-- View: nsview.vw_faturamento_itens
-- DROP VIEW nsview.vw_faturamento_itens;

CREATE OR REPLACE VIEW nsview.vw_faturamento_itens AS 
 SELECT fat."Identificador Documento", 
    fat."Identificador Documento Rateado", 
    fat."Identificador Estabelecimento", 
    fat."Estabelecimento", 
    fat."Nome do Estabelecimento", 
    fat."Origem do Documento", 
    fat."Número Documento", 
    fat."Data de Emissão", 
    fat."Identificador Cliente", 
    fat."Cliente", 
    fat."Nome do Cliente", 
    fat."Documento do Cliente", 
    fat."Valor Documento", 
    fat."Tipo do Documento", 
    fat."Identificador Operação", 
    fat."Código da Operação", 
    fat."Descrição da Operação", 
    date_part('Month'::text, fat."Data de Emissão")::integer AS "Mês", 
    date_part('Year'::text, fat."Data de Emissão")::integer AS "Ano", 
        CASE
            WHEN fat."Tipo do Documento" = ANY (ARRAY['Nota Fiscal de Mercadoria (NF-e)'::text, 'Cupom Fisical(SAT)'::text, 'Nota Fiscal de Consumidor(NFC-e)'::text]) THEN i.especificacao
            ELSE s.descricao
        END AS "Item", 
        CASE
            WHEN fat."Tipo do Documento" = ANY (ARRAY['Nota Fiscal de Mercadoria (NF-e)'::text, 'Cupom Fisical(SAT)'::text, 'Nota Fiscal de Consumidor(NFC-e)'::text]) THEN i.valor
            WHEN fat."Tipo do Documento" = 'Nota Fiscal de Serviço (NFS-e)'::text THEN s.valor
            ELSE fat."Valor Documento"
        END AS "Item - Valor"
   FROM nsview.vw_faturamento fat
   LEFT JOIN ns.df_itens i ON fat."Identificador Documento" = i.id_docfis
   LEFT JOIN ns.df_servicos s ON fat."Identificador Documento" = s.id_docfis
  ORDER BY fat."Data de Emissão", fat."Identificador Documento";

ALTER TABLE nsview.vw_faturamento_itens
  OWNER TO postgres;

*/