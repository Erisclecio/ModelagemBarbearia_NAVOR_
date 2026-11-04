USE NavorBarbearia;
GO

SELECT CONVERT(CHAR(7), a.data_hora_atendimento, 126) AS mes,
       s.nome AS servico,
       COUNT(*) AS vezes_realizado,
       SUM(i.preco_praticado) AS faturamento,
       CAST(AVG(i.preco_praticado) AS DECIMAL(10,2)) AS preco_medio
FROM ITEM_ATENDIMENTO i
JOIN ATENDIMENTO a ON a.id_atendimento = i.id_atendimento
JOIN SERVICO s     ON s.id_servico = i.id_servico
GROUP BY CONVERT(CHAR(7), a.data_hora_atendimento, 126), s.nome
ORDER BY mes, faturamento DESC;
GO

SELECT p.nome AS produto,
       COALESCE(v.unidades_vendidas, 0) AS unidades_vendidas,
       COALESCE(v.valor_vendido, 0)     AS valor_vendido,
       COALESCE(c.unidades_usadas, 0)   AS unidades_usadas_nos_atendimentos
FROM PRODUTO p
LEFT JOIN (SELECT id_produto, SUM(qtd_venda) AS unidades_vendidas,
                  SUM(qtd_venda * preco_unitario_praticado) AS valor_vendido
             FROM ITEM_VENDA GROUP BY id_produto) v ON v.id_produto = p.id_produto
LEFT JOIN (SELECT id_produto, SUM(qtd_consumida) AS unidades_usadas
             FROM ATENDIMENTO_PRODUTO GROUP BY id_produto) c ON c.id_produto = p.id_produto
WHERE v.id_produto IS NOT NULL OR c.id_produto IS NOT NULL
ORDER BY valor_vendido DESC, unidades_usadas_nos_atendimentos DESC;
GO

SELECT CONVERT(CHAR(7), cr.data_emissao, 126) AS mes,
       SUM(CASE WHEN cr.id_atendimento IS NOT NULL THEN 1 ELSE 0 END) AS atendimentos,
       SUM(CASE WHEN cr.id_venda IS NOT NULL THEN 1 ELSE 0 END)       AS vendas,
       SUM(CASE WHEN cr.id_atendimento IS NOT NULL THEN cr.valor_original ELSE 0 END) AS valor_servicos,
       SUM(CASE WHEN cr.id_venda IS NOT NULL THEN cr.valor_original ELSE 0 END)       AS valor_produtos,
       SUM(cr.valor_original) AS valor_total,
       SUM(cr.valor_original - cr.saldo_pendente) AS valor_recebido,
       SUM(cr.saldo_pendente) AS valor_em_aberto
FROM CONTA_RECEBER cr
WHERE cr.situacao <> 'ESTORNADO'
GROUP BY CONVERT(CHAR(7), cr.data_emissao, 126)
ORDER BY mes;
GO

SELECT p.nome AS cliente,
       SUM(CASE WHEN cr.id_atendimento IS NOT NULL THEN 1 ELSE 0 END) AS atendimentos,
       SUM(CASE WHEN cr.id_venda IS NOT NULL THEN 1 ELSE 0 END)       AS compras_de_produtos,
       SUM(cr.valor_original) AS valor_total
FROM CONTA_RECEBER cr
LEFT JOIN ATENDIMENTO a ON a.id_atendimento = cr.id_atendimento
LEFT JOIN VENDA v       ON v.id_venda = cr.id_venda
JOIN CLIENTE c          ON c.id_cliente = COALESCE(a.id_cliente, v.id_cliente)
JOIN PESSOA p           ON p.id_pessoa = c.id_pessoa
WHERE cr.situacao <> 'ESTORNADO'
GROUP BY p.nome
ORDER BY valor_total DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
GO

SELECT p.nome AS produto, p.estoque_minimo,
       SUM(CASE WHEN m.tipo_movimentacao = 'ENTRADA' THEN m.quantidade ELSE -m.quantidade END) AS saldo_atual
FROM PRODUTO p
JOIN MOVIMENTACAO_ESTOQUE m ON m.id_produto = p.id_produto
WHERE p.situacao = 'ATIVO'
GROUP BY p.nome, p.estoque_minimo
HAVING SUM(CASE WHEN m.tipo_movimentacao = 'ENTRADA' THEN m.quantidade ELSE -m.quantidade END) <= p.estoque_minimo
ORDER BY saldo_atual;
GO

SELECT CONVERT(CHAR(7), a.data_hora_atendimento, 126) AS mes,
       pe.nome AS profissional,
       COUNT(*) AS atendimentos,
       SUM(a.valor_total) AS faturamento,
       CAST(AVG(a.valor_total) AS DECIMAL(10,2)) AS ticket_medio
FROM ATENDIMENTO a
JOIN FUNCIONARIO f ON f.id_funcionario = a.id_funcionario
JOIN PESSOA pe     ON pe.id_pessoa = f.id_pessoa
GROUP BY CONVERT(CHAR(7), a.data_hora_atendimento, 126), pe.nome
ORDER BY mes, faturamento DESC;
GO

SELECT c.mes_ano_comissao AS mes,
       pe.nome AS profissional,
       COUNT(*) AS servicos_comissionados,
       SUM(CASE WHEN c.situacao_comissao = 'REGISTRADA'  THEN c.valor_comissao ELSE 0 END) AS comissao_registrada,
       SUM(CASE WHEN c.situacao_comissao = 'EM_APURACAO' THEN c.valor_comissao ELSE 0 END) AS comissao_em_apuracao
FROM COMISSAO c
JOIN ITEM_ATENDIMENTO i ON i.id_item_atendimento = c.id_item_atendimento
JOIN ATENDIMENTO a      ON a.id_atendimento = i.id_atendimento
JOIN FUNCIONARIO f      ON f.id_funcionario = a.id_funcionario
JOIN PESSOA pe          ON pe.id_pessoa = f.id_pessoa
GROUP BY c.mes_ano_comissao, pe.nome
ORDER BY mes, pe.nome;
GO

SELECT fp.nome AS forma_pagamento,
       COUNT(*) AS pagamentos_confirmados,
       SUM(p.valor) AS valor_recebido,
       CAST(100.0 * SUM(p.valor) / (SELECT SUM(valor) FROM PAGAMENTO WHERE situacao_pagamento = 'CONFIRMADO') AS DECIMAL(5,1)) AS percentual_do_valor
FROM PAGAMENTO p
JOIN FORMA_PAGAMENTO fp ON fp.id_forma_pagamento = p.id_forma_pagamento
WHERE p.situacao_pagamento = 'CONFIRMADO'
GROUP BY fp.nome
ORDER BY valor_recebido DESC;
GO
