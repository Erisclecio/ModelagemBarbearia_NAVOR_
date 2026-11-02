USE NavorBarbearia;
GO

SET XACT_ABORT OFF;
DECLARE @teste TABLE (codigo VARCHAR(10), tentativa VARCHAR(120), resultado VARCHAR(400));

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO PESSOA (cpf, nome, email) SELECT cpf, 'Cadastro repetido', 'repetido@email.com' FROM PESSOA WHERE id_pessoa = 7;
    ROLLBACK;
    INSERT INTO @teste VALUES ('T09', 'Cadastrar uma pessoa com CPF já existente', 'FALHOU: o banco aceitou');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    INSERT INTO @teste VALUES ('T09', 'Cadastrar uma pessoa com CPF já existente', CONCAT('OK: bloqueado - ', ERROR_MESSAGE()));
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO CONTA_RECEBER (id_atendimento, id_venda, valor_original, data_emissao, data_vencimento, saldo_pendente)
    VALUES (NULL, NULL, 100.00, '2026-11-02', '2026-11-02', 100.00);
    ROLLBACK;
    INSERT INTO @teste VALUES ('T14', 'Conta a receber sem origem', 'FALHOU: o banco aceitou');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    INSERT INTO @teste VALUES ('T14', 'Conta a receber sem origem', CONCAT('OK: bloqueado - ', ERROR_MESSAGE()));
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO ATENDIMENTO (id_agendamento, id_cliente, id_funcionario, data_hora_atendimento, valor_total)
    VALUES (NULL, 1, 2, '2026-11-02T10:00:00', 55.00);
    INSERT INTO VENDA (id_cliente, data_hora_venda, valor_total) VALUES (1, '2026-11-02T10:30:00', 45.00);
    INSERT INTO CONTA_RECEBER (id_atendimento, id_venda, valor_original, data_emissao, data_vencimento, saldo_pendente)
    SELECT (SELECT MAX(id_atendimento) FROM ATENDIMENTO), (SELECT MAX(id_venda) FROM VENDA), 100.00, '2026-11-02', '2026-11-02', 100.00;
    ROLLBACK;
    INSERT INTO @teste VALUES ('T14', 'Conta a receber com atendimento e venda ao mesmo tempo', 'FALHOU: o banco aceitou');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    INSERT INTO @teste VALUES ('T14', 'Conta a receber com atendimento e venda ao mesmo tempo', CONCAT('OK: bloqueado - ', ERROR_MESSAGE()));
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO ITEM_VENDA (id_venda, id_produto, qtd_venda, preco_unitario_praticado)
    SELECT MAX(id_venda), 10, 0, 40.00 FROM VENDA;
    ROLLBACK;
    INSERT INTO @teste VALUES ('CK', 'Item de venda com quantidade zero', 'FALHOU: o banco aceitou');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    INSERT INTO @teste VALUES ('CK', 'Item de venda com quantidade zero', CONCAT('OK: bloqueado - ', ERROR_MESSAGE()));
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE ITEM_COMPRA SET qtd_recebida = qtd_compra + 1 WHERE id_compra = 1 AND id_produto = 1;
    ROLLBACK;
    INSERT INTO @teste VALUES ('RN13', 'Receber mais do que foi comprado', 'FALHOU: o banco aceitou');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    INSERT INTO @teste VALUES ('RN13', 'Receber mais do que foi comprado', CONCAT('OK: bloqueado - ', ERROR_MESSAGE()));
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE PAGAMENTO SET data_hora_confirmacao = NULL WHERE id_pagamento = (SELECT MIN(id_pagamento) FROM PAGAMENTO WHERE situacao_pagamento = 'CONFIRMADO');
    ROLLBACK;
    INSERT INTO @teste VALUES ('CK', 'Pagamento confirmado sem data de confirmação', 'FALHOU: o banco aceitou');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    INSERT INTO @teste VALUES ('CK', 'Pagamento confirmado sem data de confirmação', CONCAT('OK: bloqueado - ', ERROR_MESSAGE()));
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE COMISSAO SET situacao_comissao = 'PAGA' WHERE id_comissao = 1;
    ROLLBACK;
    INSERT INTO @teste VALUES ('CK', 'Comissão com situação PAGA', 'FALHOU: o banco aceitou');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    INSERT INTO @teste VALUES ('CK', 'Comissão com situação PAGA', CONCAT('OK: bloqueado - ', ERROR_MESSAGE()));
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE COMISSAO SET mes_ano_comissao = '10/2026' WHERE id_comissao = 1;
    ROLLBACK;
    INSERT INTO @teste VALUES ('CK', 'Mês da comissão no formato MM/AAAA', 'FALHOU: o banco aceitou');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    INSERT INTO @teste VALUES ('CK', 'Mês da comissão no formato MM/AAAA', CONCAT('OK: bloqueado - ', ERROR_MESSAGE()));
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    DELETE FROM CLIENTE WHERE id_cliente = 1;
    ROLLBACK;
    INSERT INTO @teste VALUES ('FK', 'Excluir cliente que já tem atendimentos', 'FALHOU: o banco aceitou');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    INSERT INTO @teste VALUES ('FK', 'Excluir cliente que já tem atendimentos', CONCAT('OK: bloqueado - ', ERROR_MESSAGE()));
END CATCH;

SELECT codigo, tentativa, resultado FROM @teste;
SET XACT_ABORT ON;
GO
