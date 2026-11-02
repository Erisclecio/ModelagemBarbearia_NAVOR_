USE NavorBarbearia;
GO

WITH historico AS (
    SELECT CAST(data_hora_atendimento AS DATE) AS dia,
           DATEDIFF(DAY, '19000101', CAST(data_hora_atendimento AS DATE)) % 7 AS dia_semana,
           CASE WHEN CAST(data_hora_atendimento AS TIME) < '13:00' THEN '1-Manhã'
                WHEN CAST(data_hora_atendimento AS TIME) < '18:00' THEN '2-Tarde'
                ELSE '3-Noite' END AS periodo
    FROM ATENDIMENTO
    WHERE data_hora_atendimento < '2026-11-01'
),
dias_abertos AS (
    SELECT dia_semana, COUNT(DISTINCT dia) AS qtd_dias
    FROM historico
    GROUP BY dia_semana
),
agenda_futura AS (
    SELECT DATEDIFF(DAY, '19000101', CAST(data_hora_inicio AS DATE)) % 7 AS dia_semana,
           CASE WHEN CAST(data_hora_inicio AS TIME) < '13:00' THEN '1-Manhã'
                WHEN CAST(data_hora_inicio AS TIME) < '18:00' THEN '2-Tarde'
                ELSE '3-Noite' END AS periodo,
           COUNT(*) AS ja_agendados
    FROM AGENDAMENTO
    WHERE status IN ('CONFIRMADO', 'PENDENTE')
      AND data_hora_inicio >= '2026-11-03' AND data_hora_inicio < '2026-11-08'
    GROUP BY DATEDIFF(DAY, '19000101', CAST(data_hora_inicio AS DATE)) % 7,
             CASE WHEN CAST(data_hora_inicio AS TIME) < '13:00' THEN '1-Manhã'
                  WHEN CAST(data_hora_inicio AS TIME) < '18:00' THEN '2-Tarde'
                  ELSE '3-Noite' END
)
SELECT CASE h.dia_semana WHEN 1 THEN '1-Terça' WHEN 2 THEN '2-Quarta' WHEN 3 THEN '3-Quinta'
                         WHEN 4 THEN '4-Sexta' WHEN 5 THEN '5-Sábado' END AS dia_semana,
       h.periodo,
       COUNT(*) AS atendimentos_no_historico,
       CAST(1.0 * COUNT(*) / d.qtd_dias AS DECIMAL(5,1)) AS demanda_prevista,
       COALESCE(MAX(f.ja_agendados), 0) AS ja_agendados_proxima_semana,
       CAST(1.0 * COUNT(*) / d.qtd_dias - COALESCE(MAX(f.ja_agendados), 0) AS DECIMAL(5,1)) AS demanda_ainda_esperada
FROM historico h
JOIN dias_abertos d       ON d.dia_semana = h.dia_semana
LEFT JOIN agenda_futura f ON f.dia_semana = h.dia_semana AND f.periodo = h.periodo
GROUP BY h.dia_semana, h.periodo, d.qtd_dias
ORDER BY 1, 2;
GO

   WITH semanas AS (
    SELECT DATEADD(DAY, -(DATEDIFF(DAY, '19000101', CAST(a.data_hora_atendimento AS DATE)) % 7),
                   CAST(a.data_hora_atendimento AS DATE)) AS semana,
           COUNT(DISTINCT a.id_atendimento) AS atendimentos,
           SUM(i.preco_praticado) AS faturamento_servicos
    FROM ATENDIMENTO a
    JOIN ITEM_ATENDIMENTO i ON i.id_atendimento = a.id_atendimento
    WHERE a.data_hora_atendimento < '2026-11-01'
    GROUP BY DATEADD(DAY, -(DATEDIFF(DAY, '19000101', CAST(a.data_hora_atendimento AS DATE)) % 7),
                     CAST(a.data_hora_atendimento AS DATE))
)
SELECT semana AS semana_iniciada_em,
       atendimentos,
       faturamento_servicos,
       CAST(AVG(1.0 * faturamento_servicos) OVER (ORDER BY semana ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS DECIMAL(10,2))
           AS media_movel_4_semanas,
       CAST(faturamento_servicos - LAG(faturamento_servicos) OVER (ORDER BY semana) AS DECIMAL(10,2))
           AS variacao_semana_anterior
FROM semanas
ORDER BY semana;
GO

WITH movimento AS (
    SELECT a.id_cliente, CAST(a.data_hora_atendimento AS DATE) AS dia, a.valor_total AS valor, 1 AS visita
    FROM ATENDIMENTO a
    JOIN CONTA_RECEBER c ON c.id_atendimento = a.id_atendimento
    WHERE c.situacao <> 'ESTORNADO'
    UNION ALL
    SELECT v.id_cliente, CAST(v.data_hora_venda AS DATE), v.valor_total, 0
    FROM VENDA v
    JOIN CONTA_RECEBER c ON c.id_venda = v.id_venda
    WHERE c.situacao <> 'ESTORNADO'
),
rfm AS (
    SELECT id_cliente,
           DATEDIFF(DAY, MAX(CASE WHEN visita = 1 THEN dia END), '2026-11-02') AS recencia_dias,
           SUM(visita) AS frequencia,
           SUM(valor)  AS valor_total
    FROM movimento
    GROUP BY id_cliente
    HAVING SUM(visita) > 0
),
notas AS (
    SELECT rfm.*,
           NTILE(3) OVER (ORDER BY recencia_dias DESC) AS nota_r,
           NTILE(3) OVER (ORDER BY frequencia)         AS nota_f,
           NTILE(3) OVER (ORDER BY valor_total)        AS nota_v
    FROM rfm
)
SELECT p.nome AS cliente, n.recencia_dias, n.frequencia, n.valor_total,
       CONCAT(n.nota_r, n.nota_f, n.nota_v) AS nota_rfm,
       CASE WHEN n.nota_r = 3 AND n.nota_f = 3                 THEN 'Fiel'
            WHEN n.nota_r = 1 AND n.nota_f >= 2                THEN 'Em risco - era frequente e sumiu'
            WHEN n.nota_r = 1                                  THEN 'Inativo'
            WHEN n.nota_f = 1 AND n.nota_r = 3                 THEN 'Novo ou ocasional recente'
            WHEN n.nota_v = 3                                  THEN 'Alto valor'
            ELSE 'Regular' END AS segmento
FROM notas n
JOIN CLIENTE c ON c.id_cliente = n.id_cliente
JOIN PESSOA p  ON p.id_pessoa = c.id_pessoa
ORDER BY segmento, n.valor_total DESC;
GO

WITH visitas AS (
    SELECT id_cliente, id_funcionario, CAST(data_hora_atendimento AS DATE) AS dia,
           LAG(CAST(data_hora_atendimento AS DATE)) OVER (PARTITION BY id_cliente ORDER BY data_hora_atendimento) AS visita_anterior
    FROM ATENDIMENTO
),
resumo AS (
    SELECT id_cliente,
           COUNT(*) AS visitas,
           MAX(dia) AS ultima_visita,
           AVG(1.0 * DATEDIFF(DAY, visita_anterior, dia)) AS intervalo_medio
    FROM visitas
    GROUP BY id_cliente
    HAVING COUNT(*) >= 2
),
profissional_preferido AS (
    SELECT id_cliente, id_funcionario,
           ROW_NUMBER() OVER (PARTITION BY id_cliente ORDER BY COUNT(*) DESC, MAX(dia) DESC) AS ordem
    FROM visitas
    GROUP BY id_cliente, id_funcionario
),
previsao AS (
    SELECT r.*, DATEADD(DAY, CAST(ROUND(r.intervalo_medio, 0) AS INT), r.ultima_visita) AS retorno_previsto
    FROM resumo r
)
SELECT pc.nome AS cliente, pv.visitas, pv.ultima_visita,
       CAST(pv.intervalo_medio AS DECIMAL(5,1)) AS intervalo_medio_dias,
       pv.retorno_previsto,
       pf.nome AS profissional_mais_frequente,
       CASE WHEN EXISTS (SELECT 1 FROM AGENDAMENTO g WHERE g.id_cliente = pv.id_cliente
                                                    AND g.status IN ('CONFIRMADO', 'PENDENTE'))
                 THEN 'Já tem horário marcado'
            WHEN DATEDIFF(DAY, pv.retorno_previsto, '2026-11-02') > 7 THEN 'Atrasado - enviar convite'
            WHEN DATEDIFF(DAY, pv.retorno_previsto, '2026-11-02') >= -7 THEN 'Retorno esperado nesta semana'
            ELSE 'Em dia' END AS situacao
FROM previsao pv
JOIN CLIENTE c  ON c.id_cliente = pv.id_cliente
JOIN PESSOA pc  ON pc.id_pessoa = c.id_pessoa
JOIN profissional_preferido pp ON pp.id_cliente = pv.id_cliente AND pp.ordem = 1
JOIN FUNCIONARIO f ON f.id_funcionario = pp.id_funcionario
JOIN PESSOA pf  ON pf.id_pessoa = f.id_pessoa
ORDER BY situacao, pv.retorno_previsto;
GO

WITH saldo AS (
    SELECT id_produto,
           SUM(CASE WHEN tipo_movimentacao = 'ENTRADA' THEN quantidade ELSE -quantidade END) AS saldo_atual,
           SUM(CASE WHEN tipo_movimentacao = 'SAIDA' AND data_hora_movimentacao >= DATEADD(DAY, -60, CAST('2026-11-02' AS DATE))
                    THEN quantidade ELSE 0 END) AS saidas_60_dias
    FROM MOVIMENTACAO_ESTOQUE
    GROUP BY id_produto
),
a_caminho AS (
    SELECT i.id_produto, SUM(i.qtd_compra - i.qtd_recebida) AS quantidade
    FROM ITEM_COMPRA i
    JOIN COMPRA c ON c.id_compra = i.id_compra
    WHERE c.situacao_recebimento IN ('EM_TRANSITO', 'ENTREGUE_PARCIAL')
    GROUP BY i.id_produto
),
calculo AS (
    SELECT p.id_produto, p.nome, p.estoque_minimo, s.saldo_atual,
           CAST(s.saidas_60_dias / 60.0 AS DECIMAL(10,2)) AS consumo_diario,
           COALESCE(ac.quantidade, 0) AS a_caminho
    FROM PRODUTO p
    JOIN saldo s           ON s.id_produto = p.id_produto
    LEFT JOIN a_caminho ac ON ac.id_produto = p.id_produto
    WHERE p.situacao = 'ATIVO'
)
SELECT nome AS produto, saldo_atual, estoque_minimo, consumo_diario, a_caminho,
       CASE WHEN consumo_diario > 0 THEN CAST(saldo_atual / consumo_diario AS DECIMAL(10,1)) END AS dias_de_cobertura,
       CASE WHEN consumo_diario > 0
            THEN DATEADD(DAY, CAST(FLOOR(saldo_atual / consumo_diario) AS INT), CAST('2026-11-02' AS DATE)) END AS previsao_de_acabar,
       CASE WHEN saldo_atual <= estoque_minimo THEN '1-Repor agora (no mínimo ou abaixo)'
            WHEN consumo_diario = 0 THEN '3-Estoque confortável'
            WHEN saldo_atual / consumo_diario < 15 THEN '2-Repor nos próximos dias'
            ELSE '3-Estoque confortável' END AS alerta,
       CASE WHEN CEILING(consumo_diario * 30) + estoque_minimo - saldo_atual - a_caminho > 0
            THEN CAST(CEILING(consumo_diario * 30) + estoque_minimo - saldo_atual - a_caminho AS INT)
            ELSE 0 END AS sugestao_de_compra_30_dias
FROM calculo
ORDER BY alerta, dias_de_cobertura;
GO

WITH servico_dia AS (
    SELECT DISTINCT a.id_cliente, CAST(a.data_hora_atendimento AS DATE) AS dia, i.id_servico
    FROM ATENDIMENTO a
    JOIN ITEM_ATENDIMENTO i ON i.id_atendimento = a.id_atendimento
),
compra_dia AS (
    SELECT DISTINCT v.id_cliente, CAST(v.data_hora_venda AS DATE) AS dia, iv.id_produto
    FROM VENDA v
    JOIN ITEM_VENDA iv ON iv.id_venda = v.id_venda
),
total_servico AS (
    SELECT id_servico, COUNT(*) AS vezes FROM servico_dia GROUP BY id_servico
),
combinacao AS (
    SELECT sd.id_servico, cd.id_produto, COUNT(*) AS vezes_juntos
    FROM servico_dia sd
    JOIN compra_dia cd ON cd.id_cliente = sd.id_cliente AND cd.dia = sd.dia
    GROUP BY sd.id_servico, cd.id_produto
),
ranking AS (
    SELECT c.*, ROW_NUMBER() OVER (PARTITION BY c.id_servico ORDER BY c.vezes_juntos DESC, c.id_produto) AS posicao
    FROM combinacao c
)
SELECT s.nome AS servico, r.posicao, p.nome AS produto_recomendado, r.vezes_juntos,
       CAST(100.0 * r.vezes_juntos / t.vezes AS DECIMAL(5,1)) AS percentual_de_clientes
FROM ranking r
JOIN SERVICO s       ON s.id_servico = r.id_servico
JOIN PRODUTO p       ON p.id_produto = r.id_produto
JOIN total_servico t ON t.id_servico = r.id_servico
WHERE r.posicao <= 3
ORDER BY s.nome, r.posicao;
GO

WITH calendario AS (
    SELECT CAST('2026-09-01' AS DATE) AS dia
    UNION ALL
    SELECT DATEADD(DAY, 1, dia) FROM calendario WHERE dia < '2026-10-31'
),
disponivel AS (
    SELECT j.id_funcionario,
           SUM(DATEDIFF(MINUTE, j.hora_inicio, j.hora_fim)) AS minutos_disponiveis
    FROM calendario c
    JOIN JORNADA_FUNCIONARIO j
      ON j.dia_semana = CASE DATEDIFF(DAY, '19000101', c.dia) % 7
                             WHEN 0 THEN 'SEGUNDA' WHEN 1 THEN 'TERCA' WHEN 2 THEN 'QUARTA'
                             WHEN 3 THEN 'QUINTA'  WHEN 4 THEN 'SEXTA' WHEN 5 THEN 'SABADO' END
     AND j.tipo_periodo = 'TRABALHO'
    GROUP BY j.id_funcionario
),
trabalhado AS (
    SELECT a.id_funcionario, SUM(s.duracao_estimada) AS minutos_atendendo, COUNT(DISTINCT a.id_atendimento) AS atendimentos
    FROM ATENDIMENTO a
    JOIN ITEM_ATENDIMENTO i ON i.id_atendimento = a.id_atendimento
    JOIN SERVICO s          ON s.id_servico = i.id_servico
    WHERE a.data_hora_atendimento < '2026-11-01'
    GROUP BY a.id_funcionario
),
cancelamentos AS (
    SELECT id_funcionario,
           COUNT(*) AS agendamentos,
           SUM(CASE WHEN status = 'CANCELADO' THEN 1 ELSE 0 END) AS cancelados
    FROM AGENDAMENTO
    WHERE data_hora_inicio < '2026-11-01'
    GROUP BY id_funcionario
)
SELECT p.nome AS profissional, f.funcao, t.atendimentos,
       t.minutos_atendendo, d.minutos_disponiveis,
       CAST(100.0 * t.minutos_atendendo / d.minutos_disponiveis AS DECIMAL(5,1)) AS ocupacao_percentual,
       c.cancelados,
       CAST(100.0 * c.cancelados / c.agendamentos AS DECIMAL(5,1)) AS taxa_cancelamento_percentual
FROM disponivel d
JOIN FUNCIONARIO f   ON f.id_funcionario = d.id_funcionario
JOIN PESSOA p        ON p.id_pessoa = f.id_pessoa
JOIN trabalhado t    ON t.id_funcionario = d.id_funcionario
JOIN cancelamentos c ON c.id_funcionario = d.id_funcionario
ORDER BY ocupacao_percentual DESC;
GO

WITH pontos AS (
    SELECT a.id_cliente, CAST(FLOOR(SUM(pg.valor)) AS INT) AS pontos
    FROM PAGAMENTO pg
    JOIN CONTA_RECEBER cr ON cr.id_conta_receber = pg.id_conta_receber
    JOIN ATENDIMENTO a    ON a.id_atendimento = cr.id_atendimento
    WHERE pg.situacao_pagamento = 'CONFIRMADO'
      AND pg.data_hora_confirmacao >= DATEADD(MONTH, -12, CAST('2026-11-02' AS DATETIME))
    GROUP BY a.id_cliente
)
SELECT p.nome AS cliente, pt.pontos,
       CASE WHEN pt.pontos >= 400 THEN 'Finalização ou tratamento simples'
            WHEN pt.pontos >= 300 THEN 'R$ 15 de desconto'
            WHEN pt.pontos >= 200 THEN 'R$ 10 de desconto'
            WHEN pt.pontos >= 100 THEN 'R$ 5 de desconto'
            ELSE 'Ainda sem benefício' END AS beneficio_disponivel
FROM pontos pt
JOIN CLIENTE c ON c.id_cliente = pt.id_cliente
JOIN PESSOA p  ON p.id_pessoa = c.id_pessoa
ORDER BY pt.pontos DESC;
GO
