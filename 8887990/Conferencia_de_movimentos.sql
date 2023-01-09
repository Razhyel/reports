/*
Entradas e Saídas
Versão: 1.1
*/
select
		--e.codigo,
		--e.nomefantasia,
		i.item,
		i.especificacao,
		--coalesce((select saldo from financas.fu_saldoscontas_conciliados('01-03-2021'::date - 1, c.conta)),0.00)::numeric(20,2) as "Saldo Anterior Conciliado", 
		coalesce((
			select sum (m.quantidade)::numeric(20,2) 
			from estoque.itens_mov m
			where 
				m.id_item = i.id
				and m.sinal = 1
				and m.slot = 'FISCAL'
				and m.data between '01-03-2020' and '10-05-2021' -- :DataInicial and :DataFinal
			group by m.id_item
		), 0.00)
		 as "Entradas",
		 coalesce((
			select sum (m.quantidade)::numeric(20,2) 
			from estoque.itens_mov m
			where 
				m.id_item = i.id
				and m.sinal = 0
				and m.slot = 'FISCAL'
				and m.data between '01-03-2020' and '10-05-2021' -- :DataInicial and :DataFinal
			group by m.id_item
		), 0.00)
		 as "Saídas"
		 --coalesce((select saldo from financas.fu_saldoscontas_conciliados('10-05-2021'::date, c.conta)),0.00)::numeric(20,2) as "Saldo Atual Conciliado",
		 --coalesce((select saldo from financas.fu_saldoscontas_nao_conciliados('10-05-2021'::date, c.conta)),0.00)::numeric(20,2) as "Saldo Atual Pendente",
		 --coalesce((select saldo from financas.fu_saldoscontas('10-05-2021'::date, c.conta)),0.00)::numeric(20,2) as "Saldo Atual Financeiro",
		 --coalesce((select saldo from financas.fu_saldoscontas_disponivel('10-05-2021'::date, c.conta)),0.00)::numeric(20,2) as "Saldo Disponível"	 
		
	from estoque.itens i
	join estoque.itens_mov m on (m.id_item = i.id)
	join ns.estabelecimentos e on (e.estabelecimento = m.id_estabelecimento)
	where
		e.codigo = '002'
		and i.item = '1037'
	group by e.codigo, e.estabelecimento, i.id
	
	order by i.item