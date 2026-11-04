USE NavorBarbearia;
GO

SELECT cr.id_conta_receber,
       CASE WHEN cr.id_atendimento IS NOT NULL THEN 'Atendimento' ELSE 'Venda' END AS origem,
       COALESCE(cr.id_atendimento, cr.id_venda) AS id_origem,
       p.nome AS cliente, cr.data_emissao, cr.data_vencimento, cr.saldo_pendente,
       DATEDIFF(DAY, cr.data_emissao, '2026-11-02') AS dias_em_aberto,
       CASE WHEN cr.data_vencimento < '2026-11-02' THEN 'Vencida' ELSE 'A vencer' END AS prazo
FROM CONTA_RECEBER cr
LEFT JOIN ATENDIMENTO a ON a.id_atendimento = cr.id_atendimento
LEFT JOIN VENDA v       ON v.id_venda = cr.id_venda
JOIN CLIENTE c          ON c.id_cliente = COALESCE(a.id_cliente, v.id_cliente)
JOIN PESSOA p           ON p.id_pessoa = c.id_pessoa
WHERE cr.situacao = 'EM_ABERTO'
ORDER BY cr.data_vencimento;
GO

SELECT cp.id_conta_pagar, cp.id_compra, f.nome AS fornecedor,
       cp.data_vencimento_compra, cp.valor_original_compra, cp.saldo_pendente_compra,
       CASE WHEN cp.data_vencimento_compra < '2026-11-02' THEN 'Vencida' ELSE 'A vencer' END AS prazo,
       (SELECT COUNT(*) FROM PAGAMENTO_FORNECEDOR pf
         WHERE pf.id_conta_pagar = cp.id_conta_pagar AND pf.situacao_pagamento = 'PENDENTE') AS pagamentos_pendentes
FROM CONTA_PAGAR cp
JOIN COMPRA c     ON c.id_compra = cp.id_compra
JOIN FORNECEDOR f ON f.id_fornecedor = c.id_fornecedor
WHERE cp.situacao_compra = 'EM_ABERTO'
ORDER BY cp.data_vencimento_compra;
GO

SELECT pg.id_pagamento, pg.situacao_pagamento, fp.nome AS forma, pg.valor,
       pg.data_hora_pagamento, pg.data_hora_estorno,
       cr.id_conta_receber, cr.situacao AS situacao_da_conta, cr.saldo_pendente
FROM PAGAMENTO pg
JOIN FORMA_PAGAMENTO fp ON fp.id_forma_pagamento = pg.id_forma_pagamento
JOIN CONTA_RECEBER cr   ON cr.id_conta_receber = pg.id_conta_receber
WHERE pg.situacao_pagamento IN ('RECUSADO', 'ESTORNADO')
ORDER BY pg.data_hora_pagamento;
GO

SELECT 'Agendamento cancelado' AS operacao, g.id_agendamento AS id_registro, g.data_hora_inicio AS data_referencia
FROM AGENDAMENTO g
WHERE g.status = 'CANCELADO'
  AND NOT EXISTS (SELECT 1 FROM REGISTRO_AUDITORIA r
                   WHERE r.objeto_afetado LIKE CONCAT('AGENDAMENTO #', g.id_agendamento, ' %'))
UNION ALL
SELECT 'Pagamento estornado', pg.id_pagamento, pg.data_hora_estorno
FROM PAGAMENTO pg
WHERE pg.situacao_pagamento = 'ESTORNADO'
  AND NOT EXISTS (SELECT 1 FROM REGISTRO_AUDITORIA r
                   WHERE r.objeto_afetado LIKE CONCAT('PAGAMENTO #', pg.id_pagamento, ' %'));
GO

SELECT pe.nome AS usuario, pa.nome_perfil AS perfil, r.operacao,
       COUNT(*) AS quantidade,
       MIN(r.data_hora_auditoria) AS primeira, MAX(r.data_hora_auditoria) AS ultima
FROM REGISTRO_AUDITORIA r
JOIN USUARIO u        ON u.id_usuario = r.id_usuario
JOIN PERFIL_ACESSO pa ON pa.id_perfil = u.id_perfil
JOIN FUNCIONARIO f    ON f.id_funcionario = u.id_funcionario
JOIN PESSOA pe        ON pe.id_pessoa = f.id_pessoa
GROUP BY pe.nome, pa.nome_perfil, r.operacao
ORDER BY pe.nome, r.operacao;
GO

SELECT s.id_servico, s.nome AS servico, s.preco_atual, i.preco_praticado,
       COUNT(*) AS vezes_cobrado,
       MIN(a.data_hora_atendimento) AS de, MAX(a.data_hora_atendimento) AS ate,
       CASE WHEN EXISTS (SELECT 1 FROM REGISTRO_AUDITORIA r
                          WHERE r.operacao = 'ALTERACAO'
                            AND r.objeto_afetado LIKE CONCAT('SERVICO #', s.id_servico, ' %'))
            THEN 'Alteração de preço registrada' ELSE 'Sem registro - verificar' END AS conferencia
FROM ITEM_ATENDIMENTO i
JOIN ATENDIMENTO a ON a.id_atendimento = i.id_atendimento
JOIN SERVICO s     ON s.id_servico = i.id_servico
WHERE i.preco_praticado <> s.preco_atual
GROUP BY s.id_servico, s.nome, s.preco_atual, i.preco_praticado
ORDER BY s.nome;
GO

SELECT a.id_atendimento, a.id_agendamento, a.data_hora_atendimento,
       (SELECT STRING_AGG(s.nome, ', ') FROM AGENDAMENTO_SERVICO x JOIN SERVICO s ON s.id_servico = x.id_servico
         WHERE x.id_agendamento = a.id_agendamento) AS servicos_agendados,
       (SELECT STRING_AGG(s.nome, ', ') FROM ITEM_ATENDIMENTO i JOIN SERVICO s ON s.id_servico = i.id_servico
         WHERE i.id_atendimento = a.id_atendimento) AS servicos_realizados
FROM ATENDIMENTO a
WHERE a.id_agendamento IS NOT NULL
  AND (EXISTS (SELECT x.id_servico FROM AGENDAMENTO_SERVICO x WHERE x.id_agendamento = a.id_agendamento
               EXCEPT
               SELECT i.id_servico FROM ITEM_ATENDIMENTO i WHERE i.id_atendimento = a.id_atendimento)
    OR EXISTS (SELECT i.id_servico FROM ITEM_ATENDIMENTO i WHERE i.id_atendimento = a.id_atendimento
               EXCEPT
               SELECT x.id_servico FROM AGENDAMENTO_SERVICO x WHERE x.id_agendamento = a.id_agendamento))
ORDER BY a.data_hora_atendimento;
GO

SELECT c.id_comissao, c.mes_ano_comissao, pe.nome AS profissional,
       a.id_atendimento, a.data_hora_atendimento, i.preco_praticado, c.valor_comissao,
       cr.situacao AS situacao_da_conta
FROM COMISSAO c
JOIN ITEM_ATENDIMENTO i ON i.id_item_atendimento = c.id_item_atendimento
JOIN ATENDIMENTO a      ON a.id_atendimento = i.id_atendimento
JOIN FUNCIONARIO f      ON f.id_funcionario = a.id_funcionario
JOIN PESSOA pe          ON pe.id_pessoa = f.id_pessoa
LEFT JOIN CONTA_RECEBER cr ON cr.id_atendimento = a.id_atendimento
WHERE c.situacao_comissao = 'EM_APURACAO';
GO

SELECT m.id_movimentacao, m.data_hora_movimentacao, p.nome AS produto,
       m.origem_movimentacao, m.tipo_movimentacao, m.quantidade,
       m.id_movimentacao_relacionada
FROM MOVIMENTACAO_ESTOQUE m
JOIN PRODUTO p ON p.id_produto = m.id_produto
WHERE m.origem_movimentacao IN ('PERDA', 'AJUSTE')
ORDER BY m.data_hora_movimentacao;
GO

SELECT c.id_compra, f.nome AS fornecedor, c.data_compra, c.situacao_recebimento,
       DATEDIFF(DAY, c.data_compra, '2026-11-02') AS dias_desde_a_compra,
       p.nome AS produto, i.qtd_compra, i.qtd_recebida, i.qtd_compra - i.qtd_recebida AS faltam
FROM COMPRA c
JOIN FORNECEDOR f  ON f.id_fornecedor = c.id_fornecedor
JOIN ITEM_COMPRA i ON i.id_compra = c.id_compra
JOIN PRODUTO p     ON p.id_produto = i.id_produto
WHERE i.qtd_recebida < i.qtd_compra
ORDER BY c.data_compra;
GO

SELECT m.id_movimentacao_caixa, m.data_hora_movimentacao, m.tipo_movimentacao, m.valor_movimentacao,
       m.descricao_movimentacao,
       COALESCE(cf.situacao_conciliacao, 'SEM CONCILIAÇÃO') AS situacao,
       cf.valor_conferido_conciliacao,
       m.valor_movimentacao - cf.valor_conferido_conciliacao AS diferenca,
       cf.observacao_divergencia
FROM MOVIMENTACAO_CAIXA m
LEFT JOIN CONCILIACAO_FINANCEIRA cf ON cf.id_movimentacao_caixa = m.id_movimentacao_caixa
WHERE cf.id_conciliacao IS NULL OR cf.situacao_conciliacao <> 'CONCILIADA'
ORDER BY CASE WHEN cf.situacao_conciliacao = 'DIVERGENTE' THEN 0 ELSE 1 END, m.data_hora_movimentacao;
GO

SELECT g.id_agendamento, g.data_hora_inicio, g.status, g.id_cliente, g.id_funcionario
FROM AGENDAMENTO g
WHERE g.status IN ('PENDENTE', 'CONFIRMADO', 'EM_EXECUCAO')
  AND g.data_hora_inicio < '2026-11-02'
  AND NOT EXISTS (SELECT 1 FROM ATENDIMENTO a WHERE a.id_agendamento = g.id_agendamento);
GO

SELECT 'Pessoa sem papel de cliente nem de funcionário' AS situacao, CAST(p.id_pessoa AS VARCHAR(20)) AS registro, p.nome AS descricao
FROM PESSOA p
WHERE NOT EXISTS (SELECT 1 FROM CLIENTE c WHERE c.id_pessoa = p.id_pessoa)
  AND NOT EXISTS (SELECT 1 FROM FUNCIONARIO f WHERE f.id_pessoa = p.id_pessoa)
UNION ALL
SELECT 'Profissional ativo sem serviço habilitado', CAST(f.id_funcionario AS VARCHAR(20)), pe.nome
FROM FUNCIONARIO f JOIN PESSOA pe ON pe.id_pessoa = f.id_pessoa
WHERE f.presta_servico = 1 AND f.situacao = 'ATIVO'
  AND NOT EXISTS (SELECT 1 FROM FUNCIONARIO_SERVICO h WHERE h.id_funcionario = f.id_funcionario)
UNION ALL
SELECT 'Profissional ativo sem jornada cadastrada', CAST(f.id_funcionario AS VARCHAR(20)), pe.nome
FROM FUNCIONARIO f JOIN PESSOA pe ON pe.id_pessoa = f.id_pessoa
WHERE f.presta_servico = 1 AND f.situacao = 'ATIVO'
  AND NOT EXISTS (SELECT 1 FROM JORNADA_FUNCIONARIO j WHERE j.id_funcionario = f.id_funcionario)
UNION ALL
SELECT 'Usuário ativo de funcionário que não está ativo', CAST(u.id_usuario AS VARCHAR(20)), u.login
FROM USUARIO u JOIN FUNCIONARIO f ON f.id_funcionario = u.id_funcionario
WHERE u.status = 'ATIVO' AND f.situacao <> 'ATIVO'
UNION ALL
SELECT 'Atendimento ou venda sem conta a receber', CAST(a.id_atendimento AS VARCHAR(20)), 'Atendimento'
FROM ATENDIMENTO a
WHERE NOT EXISTS (SELECT 1 FROM CONTA_RECEBER cr WHERE cr.id_atendimento = a.id_atendimento)
UNION ALL
SELECT 'Atendimento ou venda sem conta a receber', CAST(v.id_venda AS VARCHAR(20)), 'Venda'
FROM VENDA v
WHERE NOT EXISTS (SELECT 1 FROM CONTA_RECEBER cr WHERE cr.id_venda = v.id_venda);
GO

SELECT 'E-mail repetido' AS situacao, email AS valor, COUNT(*) AS cadastros
FROM PESSOA GROUP BY email HAVING COUNT(*) > 1
UNION ALL
SELECT 'Telefone em mais de uma pessoa', telefone, COUNT(DISTINCT id_pessoa)
FROM PESSOA_TELEFONE GROUP BY telefone HAVING COUNT(DISTINCT id_pessoa) > 1
UNION ALL
SELECT 'Fornecedor com mesmo nome', nome, COUNT(*)
FROM FORNECEDOR GROUP BY nome HAVING COUNT(*) > 1;
GO
