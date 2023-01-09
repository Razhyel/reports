-- Exclusão de itens do Scritta sem Especificação e sem correlação com Produtos no Estoque

delete from estoque.inv_itens where id_item in (select id from estoque.itens where especificacao is null and item not in (select codigo from estoque.produtos));
delete from scritta.lanaju where id_item in  (select id from estoque.itens where especificacao is null and item not in (select codigo from estoque.produtos));
delete from ns.bens where item in  (select id from estoque.itens where especificacao is null and item not in (select codigo from estoque.produtos));
delete from ns.df_itens where id_item in  (select id from estoque.itens where especificacao is null and item not in (select codigo from estoque.produtos));
delete from scritta.lf_itens where id_item in  (select id from estoque.itens where especificacao is null and item not in (select codigo from estoque.produtos));
delete from estoque.itens where especificacao is null and item not in (select codigo from estoque.produtos);
