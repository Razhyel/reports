-- Function: conversor.fun_juncao_produto(uuid, uuid);
-- DROP FUNCTION conversor.fun_juncao_produto(uuid, uuid);

CREATE OR REPLACE FUNCTION conversor.fun_juncao_produto(
    a_produto_juncao uuid,
    a_produto_exclusao uuid)
  RETURNS void AS
$BODY$

DECLARE

	REG_FKS  RECORD;	
	REG_ITENS RECORD;
	VAR_TABELA TEXT;
	VAR_ITEM_JUNCAO UUID; 
	VAR_ITEM_EXCLUSAO UUID;
	REG_MOVIMENTO_INICIAL RECORD; 
	VAR_COUNT_ITENS_JUNCAO INTEGER;
    VAR_COUNT_ITENS_EXCLUSAO INTEGER;    
	
BEGIN
	set session "contabilizacao.trg_docfis_ativa" = 'false';

	delete 
	from estoque.produtosconvunidades cu
	where produto = a_produto_exclusao 
	and exists(select * 
			   from estoque.produtosconvunidades cv
			   where cv.produto = a_produto_juncao
				 and cv.unidade = cu.unidade and cv.unidadepadrao = cu.unidadepadrao);   
				 
	delete 
	from estoque.produtos_precos_custos_estabelecimentos cu
	where produto = a_produto_exclusao
	and exists(select * 
			   from estoque.produtos_precos_custos_estabelecimentos cv
			   where cv.produto = a_produto_juncao
				 and cv.estabelecimento = cu.estabelecimento);   				 

	VAR_COUNT_ITENS_JUNCAO := COALESCE((SELECT count(1) FROM estoque.itens i WHERE i.produto =  a_produto_juncao), 0);
	VAR_COUNT_ITENS_EXCLUSAO := COALESCE((SELECT count(1) FROM estoque.itens i WHERE i.produto =  a_produto_exclusao), 0);
	
	IF (VAR_COUNT_ITENS_JUNCAO = 0) AND (VAR_COUNT_ITENS_EXCLUSAO = 0) THEN
	  RAISE EXCEPTION 'Não foi localizado nenhum item no produto de destino nem no produto de origem';
	END IF;

    IF VAR_COUNT_ITENS_EXCLUSAO > 1 THEN
	  RAISE EXCEPTION 'O produto a ser descartado possui mais de um item relacionado.';
	END IF;

	IF (VAR_COUNT_ITENS_JUNCAO = 0) OR ((VAR_COUNT_ITENS_EXCLUSAO = 1) AND (VAR_COUNT_ITENS_JUNCAO > 1)) THEN
	  SELECT id FROM estoque.itens WHERE produto = a_produto_exclusao INTO VAR_ITEM_EXCLUSAO;
	  
	  UPDATE estoque.itens 
	  SET produto = a_produto_juncao 
	  WHERE produto = a_produto_exclusao;
	  
	  UPDATE ns.df_docfis SET  reconstruirxml = true WHERE id IN (SELECT DISTINCT id_docfis FROM ns.df_itens WHERE id_item = VAR_ITEM_EXCLUSAO); 
	END IF;
	
	IF (VAR_COUNT_ITENS_EXCLUSAO = 1) AND (VAR_COUNT_ITENS_JUNCAO = 1) THEN	
	  SELECT id FROM estoque.itens WHERE produto = a_produto_juncao INTO VAR_ITEM_JUNCAO;
	  
	  FOR REG_ITENS IN (SELECT id FROM estoque.itens WHERE produto = a_produto_exclusao) LOOP
		/* Atualizar a DocEngine */ 
		UPDATE ns.df_docfis SET  reconstruirxml = true 
		WHERE id IN (SELECT DISTINCT id_docfis FROM ns.df_itens WHERE id_item = REG_ITENS.id); 

		/* Atualizar as referencias - Itens */ 
		FOR REG_FKS IN ( SELECT 	
							origem_constraint, origem_schema, origem_table, origem_coluna, 
							destino_schema, destino_table, destino_field 
						FROM 
							ns.viewfk
						WHERE 
							destino_schema = 'estoque' AND destino_table = 'itens' AND destino_field = 'id' )
		LOOP
			BEGIN	
				VAR_TABELA = (REG_FKS.origem_schema ||'.'|| REG_FKS.origem_table);   
			
				EXECUTE 'UPDATE ' || VAR_TABELA || ' SET ' || REG_FKS.origem_coluna || ' = ' || '''' || VAR_ITEM_JUNCAO::text || '''' || ' WHERE ' || REG_FKS.origem_coluna || ' = ' || '''' || REG_ITENS.id::text || '''';          

			EXCEPTION
				WHEN unique_violation THEN
					CONTINUE;
					
				WHEN others THEN 
					RAISE EXCEPTION 'Erro ao Atulizar Tabela - %', VAR_TABELA;
			END; 
		END LOOP; 


		/* Remove os Registros */
		DELETE FROM estoque.itens WHERE id = REG_ITENS.id; 
		DELETE FROM ns.conjuntosprodutos WHERE registro = REG_ITENS.id;
	  END LOOP;
	END IF;
	
	/* Atualizar as referencias - PRODUTOS */ 

	DELETE FROM estoque.produtosenderecos WHERE produto = a_produto_exclusao;

	
	FOR REG_FKS IN ( SELECT 	
						origem_constraint, origem_schema, origem_table, origem_coluna, 
						destino_schema, destino_table, destino_field 
					FROM 
						ns.view_fk
		    WHERE 
						destino_schema = 'estoque' AND destino_table = 'produtos' AND destino_field = 'produto' )
	LOOP
		VAR_TABELA = (REG_FKS.origem_schema ||'.'|| REG_FKS.origem_table);   
		EXECUTE 'UPDATE ' || VAR_TABELA || ' SET ' || REG_FKS.origem_coluna || ' = ' || '''' || a_produto_juncao::text || '''' || ' WHERE ' || REG_FKS.origem_coluna || ' = ' || '''' || a_produto_exclusao::text || '''';          
		
	END LOOP;
	
	DELETE FROM estoque.produtos WHERE produto = a_produto_exclusao;
	DELETE FROM ns.conjuntosprodutos WHERE registro = a_produto_exclusao;
	
	IF (VAR_COUNT_ITENS_EXCLUSAO = 1) AND (VAR_COUNT_ITENS_JUNCAO = 1) THEN
	  -- RECALCULAR SALDO DO ITEM EM TODOS OS ESTABELECIMENTOS
	  FOR REG_MOVIMENTO_INICIAL IN (SELECT id_estabelecimento, MIN(data) AS data
									FROM ESTOQUE.ITENS_MOV 
									WHERE id_item = VAR_ITEM_JUNCAO
									GROUP BY id_estabelecimento)
	  LOOP
		PERFORM estoque.refazer_saldos_item(VAR_ITEM_JUNCAO, REG_MOVIMENTO_INICIAL.id_estabelecimento, REG_MOVIMENTO_INICIAL.data);
	  END LOOP;
	END IF;	
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION conversor.fun_juncao_produto(uuid, uuid)
  OWNER TO group_nasajon;
GRANT EXECUTE ON FUNCTION conversor.fun_juncao_produto(uuid, uuid) TO public;
GRANT EXECUTE ON FUNCTION conversor.fun_juncao_produto(uuid, uuid) TO group_nasajon;
