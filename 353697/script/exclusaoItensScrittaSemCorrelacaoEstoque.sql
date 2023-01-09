-- Exclusão de itens (scritta) que não possuem correspondencia no estoque.

delete from estoque.saldosestabelecimentos
where item in (
	select id from estoque.itens 
	where item not in (select codigo from estoque.produtos));

delete from estoque.saldosempresas 
where item in (
	select id from estoque.itens where item not in (select codigo from estoque.produtos));

delete from estoque.saldoslocaisdeestoques 
where item in (
	select id from estoque.itens where item not in (select codigo from estoque.produtos));

delete from estoque.inv_itens 
where id_item in (
	select id from estoque.itens where item not in (select codigo from estoque.produtos));

delete from scritta.lanaju 
where id_item in (
	select id from estoque.itens where item not in (select codigo from estoque.produtos));

delete from ns.bens 
where item in ( 
	select id from estoque.itens where item not in (select codigo from estoque.produtos));

delete from ns.df_itens
where id_item in
	(select id from estoque.itens where item not in (select codigo from estoque.produtos));

delete from scritta.lf_itens
where id_item in (
	select id from estoque.itens where item not in (select codigo from estoque.produtos));

delete from ns.df_linhas
where id_item in (
	select id from estoque.itens where item not in (select codigo from estoque.produtos));

delete from estoque.itens
where item not in (
	select codigo from estoque.produtos)
and id not in (
	select id_item from ns.df_itens di
	join ns.df_docfis df on (df.id = di.id_docfis)
	join ns.estabelecimentos e on (e.estabelecimento = df.id_estabelecimento)
	where df.id_estabelecimento in (
		select estabelecimento from ns.estabelecimentos)
	);