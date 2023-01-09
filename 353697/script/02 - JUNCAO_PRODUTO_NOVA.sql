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
group by 1,2,3
having count(distinct p.produto)  > 1
order by count(distinct p.produto) , p.codigo
--limit 20
			)
  loop
    cont = cont + 1;
    raise notice '% Juntando Estab %, Produto %', cont, rec_produtos.cod_estab, rec_produtos.cod_prod;

	while exists(select e.codigo as cod_estab,
					   ec.estabelecimento, 
					   --p.codigodebarras, 
					   p.codigo as cod_prod, 
					   count(distinct p.produto) 
				from estoque.produtos p
				inner join ns.conjuntosprodutos cp on cp.registro = p.produto
				inner join ns.estabelecimentosconjuntos ec on ec.conjunto = cp.conjunto
				inner join ns.estabelecimentos e on e.estabelecimento = ec.estabelecimento and e.codigo = '002'
				where p.codigo = rec_produtos.cod_prod
				group by 1,2,3
				having count(distinct p.produto)  > 1
				order by count(distinct p.produto) , p.codigo)
	loop		
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
			--perform conversor.fun_juncao_produto_v2(id_produto_manter::uuid, id_produto_excluir::uuid);
		exception when others then
		  raise notice '% %', SQLERRM, SQLSTATE;
		end;
	end loop;
  end loop;
end;
$$
