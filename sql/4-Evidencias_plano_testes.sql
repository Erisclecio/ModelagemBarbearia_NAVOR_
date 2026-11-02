USE NavorBarbearia;
GO

SELECT p.nome, p.cpf, c.id_cliente, f.id_funcionario, f.funcao
FROM PESSOA p
JOIN CLIENTE c     ON c.id_pessoa = p.id_pessoa
JOIN FUNCIONARIO f ON f.id_pessoa = p.id_pessoa;
GO

SELECT a.id_atendimento, a.data_hora_atendimento, pf.nome AS profissional, pc.nome AS cliente, a.valor_total
FROM ATENDIMENTO a
JOIN FUNCIONARIO f ON f.id_funcionario = a.id_funcionario
JOIN PESSOA pf     ON pf.id_pessoa = f.id_pessoa
JOIN CLIENTE c     ON c.id_cliente = a.id_cliente
JOIN PESSOA pc     ON pc.id_pessoa = c.id_pessoa
WHERE a.id_agendamento IS NULL
ORDER BY a.data_hora_atendimento;
GO

SELECT pf.nome AS profissional, f.comissionado,
       COUNT(i.id_item_atendimento) AS servicos_realizados,
       SUM(i.preco_praticado)       AS valor_servicos,
       COUNT(c.id_comissao)         AS comissoes_geradas,
       COALESCE(SUM(c.valor_comissao), 0) AS valor_comissoes
FROM ITEM_ATENDIMENTO i
JOIN ATENDIMENTO a  ON a.id_atendimento = i.id_atendimento
JOIN FUNCIONARIO f  ON f.id_funcionario = a.id_funcionario
JOIN PESSOA pf      ON pf.id_pessoa = f.id_pessoa
LEFT JOIN COMISSAO c ON c.id_item_atendimento = i.id_item_atendimento
GROUP BY pf.nome, f.comissionado
ORDER BY pf.nome;
GO

SELECT c.id_compra, c.situacao_recebimento, pr.nome AS produto, i.qtd_compra, i.qtd_recebida,
       COALESCE((SELECT SUM(m.quantidade) FROM MOVIMENTACAO_ESTOQUE m
                  WHERE m.id_compra = i.id_compra AND m.id_produto = i.id_produto), 0) AS entrada_no_estoque
FROM COMPRA c
JOIN ITEM_COMPRA i ON i.id_compra = c.id_compra
JOIN PRODUTO pr    ON pr.id_produto = i.id_produto
WHERE c.situacao_recebimento <> 'ENTREGUE'
ORDER BY c.id_compra;
GO

SELECT cr.id_conta_receber, cr.valor_original, cr.situacao, cr.saldo_pendente,
       fp.nome AS forma, p.valor, p.situacao_pagamento
FROM CONTA_RECEBER cr
JOIN PAGAMENTO p        ON p.id_conta_receber = cr.id_conta_receber
JOIN FORMA_PAGAMENTO fp ON fp.id_forma_pagamento = p.id_forma_pagamento
WHERE cr.id_conta_receber IN (SELECT id_conta_receber FROM PAGAMENTO GROUP BY id_conta_receber HAVING COUNT(*) > 1)
ORDER BY cr.id_conta_receber, p.id_pagamento;
GO

SELECT CONVERT(CHAR(7), a.data_hora_atendimento, 126) AS mes, s.preco_atual,
       MIN(i.preco_praticado) AS menor_preco_praticado, MAX(i.preco_praticado) AS maior_preco_praticado,
       COUNT(*) AS cortes
FROM ITEM_ATENDIMENTO i
JOIN ATENDIMENTO a ON a.id_atendimento = i.id_atendimento
JOIN SERVICO s     ON s.id_servico = i.id_servico
WHERE s.nome = 'Corte de cabelo'
GROUP BY CONVERT(CHAR(7), a.data_hora_atendimento, 126), s.preco_atual
ORDER BY mes;
GO

SELECT a.id_atendimento, a.data_hora_atendimento, COUNT(*) AS servicos, a.valor_total
FROM ATENDIMENTO a
JOIN ITEM_ATENDIMENTO i ON i.id_atendimento = a.id_atendimento
GROUP BY a.id_atendimento, a.data_hora_atendimento, a.valor_total
HAVING COUNT(*) >= 2
ORDER BY a.data_hora_atendimento;
GO
