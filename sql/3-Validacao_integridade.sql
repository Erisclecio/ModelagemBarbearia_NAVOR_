USE NavorBarbearia;
GO

SELECT verificacao, regra, problemas,
       CASE WHEN problemas = 0 THEN 'OK' ELSE 'VERIFICAR' END AS resultado
FROM (
    SELECT 'Itens de venda sem venda correspondente' AS verificacao, 'FK' AS regra,
           (SELECT COUNT(*) FROM ITEM_VENDA i LEFT JOIN VENDA v ON v.id_venda = i.id_venda WHERE v.id_venda IS NULL) AS problemas
    UNION ALL
    SELECT 'Comissões sem serviço realizado', 'FK',
           (SELECT COUNT(*) FROM COMISSAO c LEFT JOIN ITEM_ATENDIMENTO i ON i.id_item_atendimento = c.id_item_atendimento WHERE i.id_item_atendimento IS NULL)
    UNION ALL
    SELECT 'Pagamentos sem conta a receber', 'FK / RN16',
           (SELECT COUNT(*) FROM PAGAMENTO p LEFT JOIN CONTA_RECEBER c ON c.id_conta_receber = p.id_conta_receber WHERE c.id_conta_receber IS NULL)
    UNION ALL
    SELECT 'Cliente atendido antes da data de cadastro', 'Coerência de datas',
           (SELECT COUNT(*) FROM ATENDIMENTO a
              JOIN CLIENTE c ON c.id_cliente = a.id_cliente
              JOIN PESSOA p  ON p.id_pessoa = c.id_pessoa
             WHERE a.data_hora_atendimento < p.data_cadastro)
    UNION ALL
    SELECT 'Atendimento com cliente diferente do agendamento', 'RN06',
           (SELECT COUNT(*) FROM ATENDIMENTO a JOIN AGENDAMENTO g ON g.id_agendamento = a.id_agendamento
             WHERE a.id_cliente <> g.id_cliente OR g.status <> 'FINALIZADO')

    UNION ALL
    SELECT 'Atendimento sem nenhum serviço', 'RN19',
           (SELECT COUNT(*) FROM ATENDIMENTO a WHERE NOT EXISTS (SELECT 1 FROM ITEM_ATENDIMENTO i WHERE i.id_atendimento = a.id_atendimento))
    UNION ALL
    SELECT 'Venda sem nenhum produto', 'RN20',
           (SELECT COUNT(*) FROM VENDA v WHERE NOT EXISTS (SELECT 1 FROM ITEM_VENDA i WHERE i.id_venda = v.id_venda))
    UNION ALL
    SELECT 'Compra sem nenhum produto', 'RN21',
           (SELECT COUNT(*) FROM COMPRA c WHERE NOT EXISTS (SELECT 1 FROM ITEM_COMPRA i WHERE i.id_compra = c.id_compra))

    UNION ALL
    SELECT 'Valor do atendimento diferente da soma dos serviços', 'RF20',
           (SELECT COUNT(*) FROM ATENDIMENTO a
             WHERE a.valor_total <> (SELECT SUM(i.preco_praticado) FROM ITEM_ATENDIMENTO i WHERE i.id_atendimento = a.id_atendimento))
    UNION ALL
    SELECT 'Valor da venda diferente da soma dos itens', 'Coerência de valores',
           (SELECT COUNT(*) FROM VENDA v
             WHERE v.valor_total <> (SELECT SUM(i.qtd_venda * i.preco_unitario_praticado) FROM ITEM_VENDA i WHERE i.id_venda = v.id_venda))
    UNION ALL
    SELECT 'Valor da compra diferente da soma dos itens', 'Coerência de valores',
           (SELECT COUNT(*) FROM COMPRA c
             WHERE c.valor_total <> (SELECT SUM(i.qtd_compra * i.custo_unitario) FROM ITEM_COMPRA i WHERE i.id_compra = c.id_compra))
    UNION ALL
    SELECT 'Duração prevista diferente da soma dos serviços', 'RN05',
           (SELECT COUNT(*) FROM AGENDAMENTO g
             WHERE g.duracao_prevista <> (SELECT SUM(s.duracao_estimada * x.qtd_servico)
                                            FROM AGENDAMENTO_SERVICO x JOIN SERVICO s ON s.id_servico = x.id_servico
                                           WHERE x.id_agendamento = g.id_agendamento))
    UNION ALL
    SELECT 'Conta a receber com valor diferente da origem', 'RN16',
           (SELECT COUNT(*) FROM CONTA_RECEBER c
              LEFT JOIN ATENDIMENTO a ON a.id_atendimento = c.id_atendimento
              LEFT JOIN VENDA v       ON v.id_venda = c.id_venda
             WHERE c.valor_original <> COALESCE(a.valor_total, v.valor_total))

    UNION ALL
    SELECT 'Comissão para profissional não comissionado', 'RN15 / RP03',
           (SELECT COUNT(*) FROM COMISSAO c
              JOIN ITEM_ATENDIMENTO i ON i.id_item_atendimento = c.id_item_atendimento
              JOIN ATENDIMENTO a      ON a.id_atendimento = i.id_atendimento
              JOIN FUNCIONARIO f      ON f.id_funcionario = a.id_funcionario
             WHERE f.comissionado = 0)
    UNION ALL
    SELECT 'Serviço de comissionado sem comissão registrada', 'RF24',
           (SELECT COUNT(*) FROM ITEM_ATENDIMENTO i
              JOIN ATENDIMENTO a ON a.id_atendimento = i.id_atendimento
              JOIN FUNCIONARIO f ON f.id_funcionario = a.id_funcionario
             WHERE f.comissionado = 1
               AND NOT EXISTS (SELECT 1 FROM COMISSAO c WHERE c.id_item_atendimento = i.id_item_atendimento))
    UNION ALL
    SELECT 'Valor da comissão diferente do percentual aplicado', 'RP03',
           (SELECT COUNT(*) FROM COMISSAO c JOIN ITEM_ATENDIMENTO i ON i.id_item_atendimento = c.id_item_atendimento
             WHERE c.valor_comissao <> ROUND(i.preco_praticado * c.percentual_aplicado / 100, 2))
    UNION ALL
    SELECT 'Mês da comissão diferente do mês do atendimento', 'Coerência de datas',
           (SELECT COUNT(*) FROM COMISSAO c
              JOIN ITEM_ATENDIMENTO i ON i.id_item_atendimento = c.id_item_atendimento
              JOIN ATENDIMENTO a      ON a.id_atendimento = i.id_atendimento
             WHERE c.mes_ano_comissao <> CONVERT(CHAR(7), a.data_hora_atendimento, 126))

    UNION ALL
    SELECT 'Agendamentos ativos sobrepostos para o mesmo profissional', 'RN02',
           (SELECT COUNT(*) FROM AGENDAMENTO a
              JOIN AGENDAMENTO b ON b.id_funcionario = a.id_funcionario AND b.id_agendamento > a.id_agendamento
             WHERE a.status <> 'CANCELADO' AND b.status <> 'CANCELADO'
               AND a.data_hora_inicio < DATEADD(MINUTE, b.duracao_prevista, b.data_hora_inicio)
               AND b.data_hora_inicio < DATEADD(MINUTE, a.duracao_prevista, a.data_hora_inicio))
    UNION ALL
    SELECT 'Atendimentos sobrepostos para o mesmo profissional', 'RN18',
           (SELECT COUNT(*) FROM
              (SELECT a.id_atendimento, a.id_funcionario, a.data_hora_atendimento AS inicio,
                      DATEADD(MINUTE, d.minutos, a.data_hora_atendimento) AS fim
                 FROM ATENDIMENTO a
                 JOIN (SELECT i.id_atendimento, SUM(s.duracao_estimada) AS minutos
                         FROM ITEM_ATENDIMENTO i JOIN SERVICO s ON s.id_servico = i.id_servico
                        GROUP BY i.id_atendimento) d ON d.id_atendimento = a.id_atendimento) x
              JOIN
              (SELECT a.id_atendimento, a.id_funcionario, a.data_hora_atendimento AS inicio,
                      DATEADD(MINUTE, d.minutos, a.data_hora_atendimento) AS fim
                 FROM ATENDIMENTO a
                 JOIN (SELECT i.id_atendimento, SUM(s.duracao_estimada) AS minutos
                         FROM ITEM_ATENDIMENTO i JOIN SERVICO s ON s.id_servico = i.id_servico
                        GROUP BY i.id_atendimento) d ON d.id_atendimento = a.id_atendimento) y
                ON y.id_funcionario = x.id_funcionario AND y.id_atendimento > x.id_atendimento
             WHERE x.inicio < y.fim AND y.inicio < x.fim)
    UNION ALL
    SELECT 'Agendamento fora da jornada de trabalho do profissional', 'RP01 / RF07',
           (SELECT COUNT(*) FROM AGENDAMENTO g
             WHERE g.status <> 'CANCELADO'
               AND NOT EXISTS (
                   SELECT 1 FROM JORNADA_FUNCIONARIO j
                    WHERE j.id_funcionario = g.id_funcionario
                      AND j.tipo_periodo = 'TRABALHO'
                      AND j.dia_semana = CASE DATEDIFF(DAY, '19000101', CAST(g.data_hora_inicio AS DATE)) % 7
                                              WHEN 0 THEN 'SEGUNDA' WHEN 1 THEN 'TERCA' WHEN 2 THEN 'QUARTA'
                                              WHEN 3 THEN 'QUINTA'  WHEN 4 THEN 'SEXTA' WHEN 5 THEN 'SABADO' END
                      AND CAST(g.data_hora_inicio AS TIME) >= j.hora_inicio
                      AND CAST(DATEADD(MINUTE, g.duracao_prevista, g.data_hora_inicio) AS TIME) <= j.hora_fim))
    UNION ALL
    SELECT 'Serviço inativo em agendamento ou atendimento', 'RN04',
           (SELECT COUNT(*) FROM AGENDAMENTO_SERVICO x JOIN SERVICO s ON s.id_servico = x.id_servico WHERE s.situacao = 'INATIVO')
         + (SELECT COUNT(*) FROM ITEM_ATENDIMENTO i JOIN SERVICO s ON s.id_servico = i.id_servico WHERE s.situacao = 'INATIVO')
    UNION ALL
    SELECT 'Serviço feito por profissional não habilitado', 'FUNCIONARIO_SERVICO',
           (SELECT COUNT(*) FROM ITEM_ATENDIMENTO i JOIN ATENDIMENTO a ON a.id_atendimento = i.id_atendimento
             WHERE NOT EXISTS (SELECT 1 FROM FUNCIONARIO_SERVICO h WHERE h.id_funcionario = a.id_funcionario AND h.id_servico = i.id_servico))
    UNION ALL
    SELECT 'Profissional preferido que não presta serviço', 'RN17',
           (SELECT COUNT(*) FROM PREFERENCIA p JOIN FUNCIONARIO f ON f.id_funcionario = p.id_funcionario_preferencial
             WHERE f.presta_servico = 0)

    UNION ALL
    SELECT 'Produto inativo vendido ou consumido', 'RN11',
           (SELECT COUNT(*) FROM ITEM_VENDA i JOIN PRODUTO p ON p.id_produto = i.id_produto WHERE p.situacao = 'INATIVO')
         + (SELECT COUNT(*) FROM ATENDIMENTO_PRODUTO i JOIN PRODUTO p ON p.id_produto = i.id_produto WHERE p.situacao = 'INATIVO')
    UNION ALL
    SELECT 'Saldo de estoque negativo em algum momento', 'RN12',
           (SELECT COUNT(*) FROM
              (SELECT SUM(CASE WHEN tipo_movimentacao = 'ENTRADA' THEN quantidade ELSE -quantidade END)
                        OVER (PARTITION BY id_produto ORDER BY data_hora_movimentacao, id_movimentacao
                              ROWS UNBOUNDED PRECEDING) AS saldo
                 FROM MOVIMENTACAO_ESTOQUE) s
             WHERE s.saldo < 0)
    UNION ALL
    SELECT 'Entrada de estoque diferente da quantidade recebida', 'RN13 / RF04',
           (SELECT COUNT(*) FROM ITEM_COMPRA i
             WHERE i.qtd_recebida <> COALESCE((SELECT SUM(m.quantidade) FROM MOVIMENTACAO_ESTOQUE m
                                                WHERE m.id_compra = i.id_compra AND m.id_produto = i.id_produto), 0))
    UNION ALL
    SELECT 'Item vendido sem saída de estoque', 'RN10 / RF22',
           (SELECT COUNT(*) FROM ITEM_VENDA i
             WHERE NOT EXISTS (SELECT 1 FROM MOVIMENTACAO_ESTOQUE m WHERE m.id_venda = i.id_venda AND m.id_produto = i.id_produto))
    UNION ALL
    SELECT 'Produto consumido sem saída de estoque', 'RN09 / RF22',
           (SELECT COUNT(*) FROM ATENDIMENTO_PRODUTO i
             WHERE NOT EXISTS (SELECT 1 FROM MOVIMENTACAO_ESTOQUE m WHERE m.id_atendimento = i.id_atendimento AND m.id_produto = i.id_produto))
    UNION ALL
    SELECT 'Compra marcada como entregue com item faltando', 'RN13',
           (SELECT COUNT(*) FROM COMPRA c
             WHERE c.situacao_recebimento = 'ENTREGUE'
               AND EXISTS (SELECT 1 FROM ITEM_COMPRA i WHERE i.id_compra = c.id_compra AND i.qtd_recebida < i.qtd_compra))

    UNION ALL
    SELECT 'Saldo da conta a receber diferente dos pagamentos confirmados', 'RF30 / RN24',
           (SELECT COUNT(*) FROM CONTA_RECEBER c
             WHERE c.situacao <> 'ESTORNADO'
               AND c.saldo_pendente <> c.valor_original - COALESCE((SELECT SUM(p.valor) FROM PAGAMENTO p
                                                                     WHERE p.id_conta_receber = c.id_conta_receber
                                                                       AND p.situacao_pagamento = 'CONFIRMADO'), 0))
    UNION ALL
    SELECT 'Conta marcada como paga com saldo pendente', 'RN24',
           (SELECT COUNT(*) FROM CONTA_RECEBER WHERE situacao = 'PAGO' AND saldo_pendente > 0)
    UNION ALL
    SELECT 'Saldo da conta a pagar diferente dos pagamentos confirmados', 'RF31',
           (SELECT COUNT(*) FROM CONTA_PAGAR c
             WHERE c.saldo_pendente_compra <> c.valor_original_compra
                   - COALESCE((SELECT SUM(p.valor_pago) FROM PAGAMENTO_FORNECEDOR p
                                WHERE p.id_conta_pagar = c.id_conta_pagar AND p.situacao_pagamento = 'CONFIRMADO'), 0))
    UNION ALL
    SELECT 'Pagamento confirmado sem movimentação no caixa', 'RF32',
           (SELECT COUNT(*) FROM PAGAMENTO p
             WHERE p.situacao_pagamento IN ('CONFIRMADO', 'ESTORNADO')
               AND NOT EXISTS (SELECT 1 FROM MOVIMENTACAO_CAIXA m WHERE m.id_pagamento = p.id_pagamento))
         + (SELECT COUNT(*) FROM PAGAMENTO_FORNECEDOR p
             WHERE p.situacao_pagamento = 'CONFIRMADO'
               AND NOT EXISTS (SELECT 1 FROM MOVIMENTACAO_CAIXA m WHERE m.id_pagamento_fornecedor = p.id_pagamento_fornecedor))
    UNION ALL
    SELECT 'Valor do caixa diferente do pagamento de origem', 'RF32',
           (SELECT COUNT(*) FROM MOVIMENTACAO_CAIXA m JOIN PAGAMENTO p ON p.id_pagamento = m.id_pagamento
             WHERE m.valor_movimentacao <> p.valor)
    UNION ALL
    SELECT 'Conciliação divergente sem diferença de valor (ou o contrário)', 'RF33',
           (SELECT COUNT(*) FROM CONCILIACAO_FINANCEIRA c
              JOIN MOVIMENTACAO_CAIXA m ON m.id_movimentacao_caixa = c.id_movimentacao_caixa
             WHERE (c.situacao_conciliacao = 'DIVERGENTE' AND c.valor_conferido_conciliacao = m.valor_movimentacao)
                OR (c.situacao_conciliacao = 'CONCILIADA' AND c.valor_conferido_conciliacao <> m.valor_movimentacao))
) v;
GO
