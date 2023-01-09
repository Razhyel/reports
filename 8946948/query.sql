select 
	df.numero,
	df.serie,
	df.sinal,
	df.emissao,
	df.cfop,
	df.chavene,
	i.item,
	dfi.quantidade,
	p.pessoa,
	p.nome,
	df2.numero,
	df2.serie,
	df2.sinal,
	df2.emissao,
	df2.cfop,
	i2.item,
	dfi2.quantidade
from ns.df_docfis df
join ns.df_itens dfi on (dfi.id_docfis = df.id)
join estoque.itens i on (i.id = dfi.id_item)
join ns.pessoas p on (df.id_pessoa =p.id)

join ns.df_referencias dfr on (dfr.chavene = df.chavene)
join ns.df_docfis df2 on (df2.id = dfr.id_docfis)
join ns.df_itens dfi2 on (dfi2.id_docfis = df2.id)
join estoque.itens i2 on (i2.id = dfi2.id_item and i2.id = dfi.id_item)

where df.sinal = 1 and df.tipo = 0
order by df.numero, df2.numero

/*
select df1.numero nf1, df1.sinal, df2.numero nf2, df2.sinal, df2.chavene, dfr.*
from ns.df_docfis df1
join ns.df_referencias dfr on (df1.id = dfr.id_docfis)
join ns.df_docfis df2 on (df2.chavene = dfr.chavene)
where df1.numero like '%9746%'
order by df1.numero

--select * from ns.df_docfis where chavene= '35211057507626000459550010000984421809382324'
select * from ns.df_itens limit 100
*/

-- NF Entrada = 519 NF Saida = 9749
-- NF Entrada = 000004540 / NF Saidas = 80 e 81

/*
select 
	i.item,
	--ai.id_linhadocreferenciado,
	df.numero,
        --ai.id_linhadocorigem,
        df2.numero,
        l1.quantidadecomercial,
        ai.quantidade
from compras.associacoesitensnotas ai
join ns.df_linhas l1 on(l1.df_linha = ai.id_linhadocreferenciado)
join ns.df_linhas l2 on (l2.df_linha = ai.id_linhadocorigem)
join ns.df_docfis df on (df.id = l1.id_docfis)
join ns.df_docfis df2 on (df2.id= l2.id_docfis)
join estoque.itens i on (i.id = l1.id_item and i.id = l2.id_item)

where df.numero in ('000000737', '000000769')
*/


/*

select 
	df.numero,
	df2.numero,
	i2.item,
	l2.quantidadecomercial,
	ai.*
from ns.df_docfis df
join ns.df_itens dfi on (dfi.id_docfis = df.id)
join compras.associacoesitensnotas ai on (ai.id_docreferenciado = df.id) 
join ns.df_docfis df2 on (df2.id = ai.id_docorigem)
join ns.df_linhas l2 on (l2.df_linha = ai.id_linhadocorigem)
join estoque.itens i2 on (i2.id = l2.id_item)

where
	df.sinal = 1
	and df.tipo = 0
	and df.numero = '000000737'
	and l2.tipolinha = 1

*/

/* original

select 
	df.numero,
	df.serie,
	df.sinal,
	df.emissao,
	df.cfop,
	current_date - df.emissao as dias,
	df.chavene,
	i.item,
	dfi.quantidade,
	p.pessoa,
	p.nome,
	
	df2.numero,
	df2.serie,
	df2.sinal,
	df2.emissao,
	df2.cfop,
	current_date - df2.emissao as dias,
	i2.item,
	dfi2.quantidade * -1 as quantidade
	
from ns.df_docfis df
join ns.df_itens dfi on (dfi.id_docfis = df.id)
join estoque.itens i on (i.id = dfi.id_item)
join ns.pessoas p on (df.id_pessoa =p.id)

join ns.df_referencias dfr on (dfr.chavene = df.chavene)
join ns.df_docfis df2 on (df2.id = dfr.id_docfis)
join ns.df_itens dfi2 on (dfi2.id_docfis = df2.id)
join estoque.itens i2 on (i2.id = dfi2.id_item and i2.id = dfi.id_item)

where df.sinal = 1 and df.tipo = 0 and df.numero in ('000000737', '000000769')
order by df.numero, df2.numero

/*
select df1.numero nf1, df1.sinal, df2.numero nf2, df2.sinal, df2.chavene, dfr.*
from ns.df_docfis df1
join ns.df_referencias dfr on (df1.id = dfr.id_docfis)
join ns.df_docfis df2 on (df2.chavene = dfr.chavene)
where df1.numero like '%9746%'
order by df1.numero

--select * from ns.df_docfis where chavene= '35211057507626000459550010000984421809382324'
select * from ns.df_itens limit 100


-- NF Entrada = 519 NF Saida = 9749
-- NF Entrada = 000004540 / NF Saidas = 80 e 81

*/