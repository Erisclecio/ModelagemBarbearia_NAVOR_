SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE master;
GO

-- Apaga o banco caso ele já exista
IF DB_ID('NavorBarbearia') IS NOT NULL
BEGIN
    ALTER DATABASE NavorBarbearia SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE NavorBarbearia;
END
GO

CREATE DATABASE NavorBarbearia;
GO

USE NavorBarbearia;
GO

/* 1. PESSOAS, CLIENTES E FUNCIONÁRIOS */

CREATE TABLE PESSOA (
    cpf             CHAR(11)     NOT NULL,
    id_pessoa       INT          IDENTITY(1,1) NOT NULL,
    nome            VARCHAR(80)  NOT NULL,
    email           VARCHAR(70)  NOT NULL,
    data_cadastro   DATETIME     NOT NULL CONSTRAINT DF_PESSOA_data_cadastro DEFAULT GETDATE(),

    CONSTRAINT PK_PESSOA PRIMARY KEY (cpf),
    CONSTRAINT UQ_PESSOA_id_pessoa UNIQUE (id_pessoa),
    CONSTRAINT CK_PESSOA_cpf CHECK (LEN(cpf) = 11 AND cpf NOT LIKE '%[^0-9]%')
);
GO

CREATE TABLE PESSOA_TELEFONE (
    id_pessoa   INT       NOT NULL,
    telefone    CHAR(11)  NOT NULL,

    CONSTRAINT PK_PESSOA_TELEFONE PRIMARY KEY (id_pessoa, telefone),
    CONSTRAINT FK_PESSOA_TELEFONE_PESSOA FOREIGN KEY (id_pessoa) REFERENCES PESSOA (id_pessoa),
    CONSTRAINT CK_PESSOA_TELEFONE_telefone CHECK (LEN(telefone) = 11 AND telefone NOT LIKE '%[^0-9]%')
);
GO

CREATE TABLE CLIENTE (
    id_cliente  INT  IDENTITY(1,1) NOT NULL,
    id_pessoa   INT  NOT NULL,

    CONSTRAINT PK_CLIENTE PRIMARY KEY (id_cliente),
    CONSTRAINT UQ_CLIENTE_id_pessoa UNIQUE (id_pessoa),
    CONSTRAINT FK_CLIENTE_PESSOA FOREIGN KEY (id_pessoa) REFERENCES PESSOA (id_pessoa)
);
GO

CREATE TABLE FUNCIONARIO (
    id_funcionario  INT          IDENTITY(1,1) NOT NULL,
    id_pessoa       INT          NOT NULL,
    funcao          VARCHAR(40)  NOT NULL,
    presta_servico  BIT          NOT NULL CONSTRAINT DF_FUNCIONARIO_presta_servico DEFAULT 0,
    situacao        VARCHAR(10)  NOT NULL CONSTRAINT DF_FUNCIONARIO_situacao DEFAULT 'ATIVO',
    comissionado    BIT          NOT NULL CONSTRAINT DF_FUNCIONARIO_comissionado DEFAULT 0,

    CONSTRAINT PK_FUNCIONARIO PRIMARY KEY (id_funcionario),
    CONSTRAINT UQ_FUNCIONARIO_id_pessoa UNIQUE (id_pessoa),
    CONSTRAINT FK_FUNCIONARIO_PESSOA FOREIGN KEY (id_pessoa) REFERENCES PESSOA (id_pessoa),
    CONSTRAINT CK_FUNCIONARIO_situacao CHECK (situacao IN ('ATIVO', 'INATIVO', 'AFASTADO', 'FERIAS'))
);
GO

CREATE TABLE PREFERENCIA (
    id_cliente                   INT           NOT NULL,
    horario_preferido            TIME          NOT NULL,
    corte_preferido              VARCHAR(15)   NOT NULL,
    id_funcionario_preferencial  INT           NULL,
    observacao_preferencia       VARCHAR(MAX)  NULL,

    CONSTRAINT PK_PREFERENCIA PRIMARY KEY (id_cliente),
    CONSTRAINT FK_PREFERENCIA_CLIENTE FOREIGN KEY (id_cliente) REFERENCES CLIENTE (id_cliente),
    CONSTRAINT FK_PREFERENCIA_FUNCIONARIO FOREIGN KEY (id_funcionario_preferencial) REFERENCES FUNCIONARIO (id_funcionario)
);
GO

/* 2. USUÁRIOS E CONTROLE DE ACESSO */

CREATE TABLE PERFIL_ACESSO (
    id_perfil         INT           IDENTITY(1,1) NOT NULL,
    nome_perfil       VARCHAR(20)   NOT NULL,
    descricao_perfil  VARCHAR(MAX)  NOT NULL,
    situacao_perfil   VARCHAR(10)   NOT NULL CONSTRAINT DF_PERFIL_ACESSO_situacao DEFAULT 'ATIVO',

    CONSTRAINT PK_PERFIL_ACESSO PRIMARY KEY (id_perfil),
    CONSTRAINT UQ_PERFIL_ACESSO_nome UNIQUE (nome_perfil),
    CONSTRAINT CK_PERFIL_ACESSO_situacao CHECK (situacao_perfil IN ('ATIVO', 'INATIVO', 'BLOQUEADO'))
);
GO

CREATE TABLE USUARIO (
    id_usuario      INT           IDENTITY(1,1) NOT NULL,
    id_funcionario  INT           NOT NULL,
    id_perfil       INT           NOT NULL,
    login           VARCHAR(12)   NOT NULL,
    senha           VARCHAR(255)  NOT NULL,
    status          VARCHAR(10)   NOT NULL CONSTRAINT DF_USUARIO_status DEFAULT 'ATIVO',

    CONSTRAINT PK_USUARIO PRIMARY KEY (id_usuario),
    CONSTRAINT UQ_USUARIO_id_funcionario UNIQUE (id_funcionario),
    CONSTRAINT UQ_USUARIO_login UNIQUE (login),
    CONSTRAINT FK_USUARIO_FUNCIONARIO FOREIGN KEY (id_funcionario) REFERENCES FUNCIONARIO (id_funcionario),
    CONSTRAINT FK_USUARIO_PERFIL_ACESSO FOREIGN KEY (id_perfil) REFERENCES PERFIL_ACESSO (id_perfil),
    CONSTRAINT CK_USUARIO_status CHECK (status IN ('ATIVO', 'INATIVO', 'BLOQUEADO'))
);
GO

/* 3. SERVIÇOS, PRODUTOS E FORNECEDORES */

CREATE TABLE SERVICO (
    id_servico        INT            IDENTITY(1,1) NOT NULL,
    nome              VARCHAR(60)    NOT NULL,
    duracao_estimada  INT            NOT NULL,
    preco_atual       DECIMAL(10,2)  NOT NULL,
    situacao          VARCHAR(10)    NOT NULL CONSTRAINT DF_SERVICO_situacao DEFAULT 'ATIVO',

    CONSTRAINT PK_SERVICO PRIMARY KEY (id_servico),
    CONSTRAINT CK_SERVICO_duracao CHECK (duracao_estimada > 0),
    CONSTRAINT CK_SERVICO_preco CHECK (preco_atual >= 0),
    CONSTRAINT CK_SERVICO_situacao CHECK (situacao IN ('ATIVO', 'INATIVO'))
);
GO

CREATE TABLE PRODUTO (
    id_produto      INT            IDENTITY(1,1) NOT NULL,
    nome            VARCHAR(50)    NOT NULL,
    descricao       VARCHAR(MAX)   NOT NULL,
    preco_venda     DECIMAL(10,2)  NOT NULL,
    estoque_minimo  INT            NOT NULL CONSTRAINT DF_PRODUTO_estoque_minimo DEFAULT 0,
    situacao        VARCHAR(10)    NOT NULL CONSTRAINT DF_PRODUTO_situacao DEFAULT 'ATIVO',

    CONSTRAINT PK_PRODUTO PRIMARY KEY (id_produto),
    CONSTRAINT CK_PRODUTO_preco CHECK (preco_venda >= 0),
    CONSTRAINT CK_PRODUTO_estoque_minimo CHECK (estoque_minimo >= 0),
    CONSTRAINT CK_PRODUTO_situacao CHECK (situacao IN ('ATIVO', 'INATIVO'))
);
GO

CREATE TABLE FORNECEDOR (
    id_fornecedor     INT           IDENTITY(1,1) NOT NULL,
    tipo_documento    VARCHAR(4)    NOT NULL,
    numero_documento  VARCHAR(14)   NOT NULL,
    nome              VARCHAR(120)  NOT NULL,
    email             VARCHAR(120)  NOT NULL,
    status            VARCHAR(10)   NOT NULL CONSTRAINT DF_FORNECEDOR_status DEFAULT 'ATIVO',

    CONSTRAINT PK_FORNECEDOR PRIMARY KEY (id_fornecedor),
    CONSTRAINT UQ_FORNECEDOR_documento UNIQUE (numero_documento),
    CONSTRAINT CK_FORNECEDOR_tipo_documento CHECK (tipo_documento IN ('CPF', 'CNPJ')),
    CONSTRAINT CK_FORNECEDOR_documento CHECK (
        numero_documento NOT LIKE '%[^0-9]%'
        AND ( (tipo_documento = 'CPF'  AND LEN(numero_documento) = 11)
           OR (tipo_documento = 'CNPJ' AND LEN(numero_documento) = 14) )
    ),
    CONSTRAINT CK_FORNECEDOR_status CHECK (status IN ('ATIVO', 'INATIVO'))
);
GO

CREATE TABLE FORNECEDOR_TELEFONE (
    id_fornecedor  INT       NOT NULL,
    telefone       CHAR(11)  NOT NULL,

    CONSTRAINT PK_FORNECEDOR_TELEFONE PRIMARY KEY (id_fornecedor, telefone),
    CONSTRAINT FK_FORNECEDOR_TELEFONE_FORNECEDOR FOREIGN KEY (id_fornecedor) REFERENCES FORNECEDOR (id_fornecedor),
    CONSTRAINT CK_FORNECEDOR_TELEFONE_telefone CHECK (LEN(telefone) = 11 AND telefone NOT LIKE '%[^0-9]%')
);
GO

CREATE TABLE FORMA_PAGAMENTO (
    id_forma_pagamento  INT          IDENTITY(1,1) NOT NULL,
    nome                VARCHAR(30)  NOT NULL,
    situacao            VARCHAR(10)  NOT NULL CONSTRAINT DF_FORMA_PAGAMENTO_situacao DEFAULT 'ATIVO',

    CONSTRAINT PK_FORMA_PAGAMENTO PRIMARY KEY (id_forma_pagamento),
    CONSTRAINT UQ_FORMA_PAGAMENTO_nome UNIQUE (nome),
    CONSTRAINT CK_FORMA_PAGAMENTO_situacao CHECK (situacao IN ('ATIVO', 'INATIVO'))
);
GO

/* 4. JORNADA, HABILITAÇÃO E AGENDA*/

CREATE TABLE JORNADA_FUNCIONARIO (
    id_funcionario  INT          NOT NULL,
    dia_semana      VARCHAR(7)   NOT NULL,
    hora_inicio     TIME         NOT NULL,
    hora_fim        TIME         NOT NULL,
    tipo_periodo    VARCHAR(9)   NOT NULL,

    CONSTRAINT PK_JORNADA_FUNCIONARIO PRIMARY KEY (id_funcionario, dia_semana, hora_inicio),
    CONSTRAINT FK_JORNADA_FUNCIONARIO_FUNCIONARIO FOREIGN KEY (id_funcionario) REFERENCES FUNCIONARIO (id_funcionario),
    CONSTRAINT CK_JORNADA_dia_semana CHECK (dia_semana IN ('SEGUNDA', 'TERCA', 'QUARTA', 'QUINTA', 'SEXTA', 'SABADO')),
    CONSTRAINT CK_JORNADA_tipo_periodo CHECK (tipo_periodo IN ('TRABALHO', 'INTERVALO', 'FOLGA')),
    CONSTRAINT CK_JORNADA_horario CHECK (hora_fim > hora_inicio)
);
GO

CREATE TABLE FUNCIONARIO_SERVICO (
    id_funcionario  INT  NOT NULL,
    id_servico      INT  NOT NULL,

    CONSTRAINT PK_FUNCIONARIO_SERVICO PRIMARY KEY (id_funcionario, id_servico),
    CONSTRAINT FK_FUNCIONARIO_SERVICO_FUNCIONARIO FOREIGN KEY (id_funcionario) REFERENCES FUNCIONARIO (id_funcionario),
    CONSTRAINT FK_FUNCIONARIO_SERVICO_SERVICO FOREIGN KEY (id_servico) REFERENCES SERVICO (id_servico)
);
GO

CREATE TABLE AGENDAMENTO (
    id_agendamento    INT          IDENTITY(1,1) NOT NULL,
    id_cliente        INT          NOT NULL,
    id_funcionario    INT          NOT NULL,
    data_hora_inicio  DATETIME     NOT NULL,
    duracao_prevista  INT          NOT NULL,
    status            VARCHAR(11)  NOT NULL CONSTRAINT DF_AGENDAMENTO_status DEFAULT 'PENDENTE',

    CONSTRAINT PK_AGENDAMENTO PRIMARY KEY (id_agendamento),
    CONSTRAINT FK_AGENDAMENTO_CLIENTE FOREIGN KEY (id_cliente) REFERENCES CLIENTE (id_cliente),
    CONSTRAINT FK_AGENDAMENTO_FUNCIONARIO FOREIGN KEY (id_funcionario) REFERENCES FUNCIONARIO (id_funcionario),
    CONSTRAINT CK_AGENDAMENTO_duracao CHECK (duracao_prevista > 0),
    CONSTRAINT CK_AGENDAMENTO_status CHECK (status IN ('PENDENTE', 'CONFIRMADO', 'EM_EXECUCAO', 'FINALIZADO', 'CANCELADO'))
);
GO

CREATE TABLE AGENDAMENTO_SERVICO (
    id_agendamento  INT  NOT NULL,
    id_servico      INT  NOT NULL,
    qtd_servico     INT  NOT NULL CONSTRAINT DF_AGENDAMENTO_SERVICO_qtd DEFAULT 1,

    CONSTRAINT PK_AGENDAMENTO_SERVICO PRIMARY KEY (id_agendamento, id_servico),
    CONSTRAINT FK_AGENDAMENTO_SERVICO_AGENDAMENTO FOREIGN KEY (id_agendamento) REFERENCES AGENDAMENTO (id_agendamento),
    CONSTRAINT FK_AGENDAMENTO_SERVICO_SERVICO FOREIGN KEY (id_servico) REFERENCES SERVICO (id_servico),
    CONSTRAINT CK_AGENDAMENTO_SERVICO_qtd CHECK (qtd_servico >= 1)
);
GO

/* 5. ATENDIMENTO E COMISSÃO */

CREATE TABLE ATENDIMENTO (
    id_atendimento         INT            IDENTITY(1,1) NOT NULL,
    id_agendamento         INT            NULL,
    id_cliente             INT            NOT NULL,
    id_funcionario         INT            NOT NULL,
    data_hora_atendimento  DATETIME       NOT NULL,
    valor_total            DECIMAL(10,2)  NOT NULL,

    CONSTRAINT PK_ATENDIMENTO PRIMARY KEY (id_atendimento),
    CONSTRAINT FK_ATENDIMENTO_AGENDAMENTO FOREIGN KEY (id_agendamento) REFERENCES AGENDAMENTO (id_agendamento),
    CONSTRAINT FK_ATENDIMENTO_CLIENTE FOREIGN KEY (id_cliente) REFERENCES CLIENTE (id_cliente),
    CONSTRAINT FK_ATENDIMENTO_FUNCIONARIO FOREIGN KEY (id_funcionario) REFERENCES FUNCIONARIO (id_funcionario),
    CONSTRAINT CK_ATENDIMENTO_valor CHECK (valor_total >= 0)
);
GO

CREATE UNIQUE INDEX UQ_ATENDIMENTO_id_agendamento
    ON ATENDIMENTO (id_agendamento) WHERE id_agendamento IS NOT NULL;
GO

CREATE TABLE ITEM_ATENDIMENTO (
    id_item_atendimento  INT            IDENTITY(1,1) NOT NULL,
    id_atendimento       INT            NOT NULL,
    id_servico           INT            NOT NULL,
    preco_praticado      DECIMAL(10,2)  NOT NULL,

    CONSTRAINT PK_ITEM_ATENDIMENTO PRIMARY KEY (id_item_atendimento),
    CONSTRAINT FK_ITEM_ATENDIMENTO_ATENDIMENTO FOREIGN KEY (id_atendimento) REFERENCES ATENDIMENTO (id_atendimento),
    CONSTRAINT FK_ITEM_ATENDIMENTO_SERVICO FOREIGN KEY (id_servico) REFERENCES SERVICO (id_servico),
    CONSTRAINT CK_ITEM_ATENDIMENTO_preco CHECK (preco_praticado >= 0)
);
GO

CREATE TABLE COMISSAO (
    id_comissao          INT            IDENTITY(1,1) NOT NULL,
    id_item_atendimento  INT            NOT NULL,
    percentual_aplicado  DECIMAL(10,2)  NOT NULL,
    valor_comissao       DECIMAL(10,2)  NOT NULL,
    situacao_comissao    VARCHAR(20)    NOT NULL CONSTRAINT DF_COMISSAO_situacao DEFAULT 'REGISTRADA',
    mes_ano_comissao     VARCHAR(7)     NOT NULL,

    CONSTRAINT PK_COMISSAO PRIMARY KEY (id_comissao),
    CONSTRAINT UQ_COMISSAO_id_item_atendimento UNIQUE (id_item_atendimento),
    CONSTRAINT FK_COMISSAO_ITEM_ATENDIMENTO FOREIGN KEY (id_item_atendimento) REFERENCES ITEM_ATENDIMENTO (id_item_atendimento),
    CONSTRAINT CK_COMISSAO_percentual CHECK (percentual_aplicado > 0 AND percentual_aplicado <= 100),
    CONSTRAINT CK_COMISSAO_valor CHECK (valor_comissao >= 0),
    CONSTRAINT CK_COMISSAO_situacao CHECK (situacao_comissao IN ('REGISTRADA', 'EM_APURACAO')),
    CONSTRAINT CK_COMISSAO_mes_ano CHECK (
        mes_ano_comissao LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]'
        AND SUBSTRING(mes_ano_comissao, 6, 2) BETWEEN '01' AND '12'
    )
);
GO

CREATE TABLE ATENDIMENTO_PRODUTO (
    id_atendimento  INT  NOT NULL,
    id_produto      INT  NOT NULL,
    qtd_consumida   INT  NOT NULL,

    CONSTRAINT PK_ATENDIMENTO_PRODUTO PRIMARY KEY (id_atendimento, id_produto),
    CONSTRAINT FK_ATENDIMENTO_PRODUTO_ATENDIMENTO FOREIGN KEY (id_atendimento) REFERENCES ATENDIMENTO (id_atendimento),
    CONSTRAINT FK_ATENDIMENTO_PRODUTO_PRODUTO FOREIGN KEY (id_produto) REFERENCES PRODUTO (id_produto),
    CONSTRAINT CK_ATENDIMENTO_PRODUTO_qtd CHECK (qtd_consumida > 0)
);
GO

/* 6. VENDAS E COMPRAS */

CREATE TABLE VENDA (
    id_venda         INT            IDENTITY(1,1) NOT NULL,
    id_cliente       INT            NOT NULL,
    data_hora_venda  DATETIME       NOT NULL CONSTRAINT DF_VENDA_data_hora DEFAULT GETDATE(),
    valor_total      DECIMAL(10,2)  NOT NULL,

    CONSTRAINT PK_VENDA PRIMARY KEY (id_venda),
    CONSTRAINT FK_VENDA_CLIENTE FOREIGN KEY (id_cliente) REFERENCES CLIENTE (id_cliente),
    CONSTRAINT CK_VENDA_valor CHECK (valor_total >= 0)
);
GO

CREATE TABLE ITEM_VENDA (
    id_venda                  INT            NOT NULL,
    id_produto                INT            NOT NULL,
    qtd_venda                 INT            NOT NULL,
    preco_unitario_praticado  DECIMAL(10,2)  NOT NULL,

    CONSTRAINT PK_ITEM_VENDA PRIMARY KEY (id_venda, id_produto),
    CONSTRAINT FK_ITEM_VENDA_VENDA FOREIGN KEY (id_venda) REFERENCES VENDA (id_venda),
    CONSTRAINT FK_ITEM_VENDA_PRODUTO FOREIGN KEY (id_produto) REFERENCES PRODUTO (id_produto),
    CONSTRAINT CK_ITEM_VENDA_qtd CHECK (qtd_venda > 0),
    CONSTRAINT CK_ITEM_VENDA_preco CHECK (preco_unitario_praticado >= 0)
);
GO

CREATE TABLE COMPRA (
    id_compra             INT            IDENTITY(1,1) NOT NULL,
    id_fornecedor         INT            NOT NULL,
    data_compra           DATE           NOT NULL,
    situacao_recebimento  VARCHAR(16)    NOT NULL CONSTRAINT DF_COMPRA_situacao DEFAULT 'EM_TRANSITO',
    valor_total           DECIMAL(10,2)  NOT NULL,

    CONSTRAINT PK_COMPRA PRIMARY KEY (id_compra),
    CONSTRAINT FK_COMPRA_FORNECEDOR FOREIGN KEY (id_fornecedor) REFERENCES FORNECEDOR (id_fornecedor),
    CONSTRAINT CK_COMPRA_situacao CHECK (situacao_recebimento IN ('EM_TRANSITO', 'ENTREGUE', 'ENTREGUE_PARCIAL', 'RECUSADA')),
    CONSTRAINT CK_COMPRA_valor CHECK (valor_total >= 0)
);
GO

CREATE TABLE ITEM_COMPRA (
    id_compra       INT            NOT NULL,
    id_produto      INT            NOT NULL,
    qtd_compra      INT            NOT NULL,
    qtd_recebida    INT            NOT NULL CONSTRAINT DF_ITEM_COMPRA_qtd_recebida DEFAULT 0,
    custo_unitario  DECIMAL(10,2)  NOT NULL,

    CONSTRAINT PK_ITEM_COMPRA PRIMARY KEY (id_compra, id_produto),
    CONSTRAINT FK_ITEM_COMPRA_COMPRA FOREIGN KEY (id_compra) REFERENCES COMPRA (id_compra),
    CONSTRAINT FK_ITEM_COMPRA_PRODUTO FOREIGN KEY (id_produto) REFERENCES PRODUTO (id_produto),
    CONSTRAINT CK_ITEM_COMPRA_qtd CHECK (qtd_compra > 0),
    CONSTRAINT CK_ITEM_COMPRA_qtd_recebida CHECK (qtd_recebida >= 0 AND qtd_recebida <= qtd_compra),
    CONSTRAINT CK_ITEM_COMPRA_custo CHECK (custo_unitario >= 0)
);
GO

/* 7. ESTOQUE */

CREATE TABLE MOVIMENTACAO_ESTOQUE (
    id_movimentacao              INT          IDENTITY(1,1) NOT NULL,
    id_produto                   INT          NOT NULL,
    tipo_movimentacao            VARCHAR(7)   NOT NULL,
    quantidade                   INT          NOT NULL,
    origem_movimentacao          VARCHAR(19)  NOT NULL,
    data_hora_movimentacao       DATETIME     NOT NULL,
    id_compra                    INT          NULL,
    id_venda                     INT          NULL,
    id_atendimento               INT          NULL,
    id_movimentacao_relacionada  INT          NULL,

    CONSTRAINT PK_MOVIMENTACAO_ESTOQUE PRIMARY KEY (id_movimentacao),
    CONSTRAINT FK_MOV_ESTOQUE_PRODUTO FOREIGN KEY (id_produto) REFERENCES PRODUTO (id_produto),
    CONSTRAINT FK_MOV_ESTOQUE_ITEM_COMPRA FOREIGN KEY (id_compra, id_produto) REFERENCES ITEM_COMPRA (id_compra, id_produto),
    CONSTRAINT FK_MOV_ESTOQUE_ITEM_VENDA FOREIGN KEY (id_venda, id_produto) REFERENCES ITEM_VENDA (id_venda, id_produto),
    CONSTRAINT FK_MOV_ESTOQUE_ATENDIMENTO_PRODUTO FOREIGN KEY (id_atendimento, id_produto) REFERENCES ATENDIMENTO_PRODUTO (id_atendimento, id_produto),
    CONSTRAINT FK_MOV_ESTOQUE_RELACIONADA FOREIGN KEY (id_movimentacao_relacionada) REFERENCES MOVIMENTACAO_ESTOQUE (id_movimentacao),
    CONSTRAINT CK_MOV_ESTOQUE_tipo CHECK (tipo_movimentacao IN ('ENTRADA', 'SAIDA')),
    CONSTRAINT CK_MOV_ESTOQUE_origem CHECK (origem_movimentacao IN ('COMPRA', 'VENDA', 'CONSUMO_ATENDIMENTO', 'PERDA', 'AJUSTE')),
    CONSTRAINT CK_MOV_ESTOQUE_quantidade CHECK (quantidade > 0),
    CONSTRAINT CK_MOV_ESTOQUE_coerencia CHECK (
            (origem_movimentacao <> 'COMPRA'              OR (id_compra IS NOT NULL      AND tipo_movimentacao = 'ENTRADA'))
        AND (origem_movimentacao <> 'VENDA'               OR (id_venda IS NOT NULL       AND tipo_movimentacao = 'SAIDA'))
        AND (origem_movimentacao <> 'CONSUMO_ATENDIMENTO' OR (id_atendimento IS NOT NULL AND tipo_movimentacao = 'SAIDA'))
    ),
    CONSTRAINT CK_MOV_ESTOQUE_relacionada CHECK (id_movimentacao_relacionada <> id_movimentacao)
);
GO

CREATE UNIQUE INDEX UQ_MOV_ESTOQUE_venda_produto
    ON MOVIMENTACAO_ESTOQUE (id_venda, id_produto) WHERE id_venda IS NOT NULL;
GO
CREATE UNIQUE INDEX UQ_MOV_ESTOQUE_atendimento_produto
    ON MOVIMENTACAO_ESTOQUE (id_atendimento, id_produto) WHERE id_atendimento IS NOT NULL;
GO

/* 8. FINANCEIRO – CONTAS A RECEBER E PAGAMENTOS */

CREATE TABLE CONTA_RECEBER (
    id_conta_receber  INT            IDENTITY(1,1) NOT NULL,
    id_atendimento    INT            NULL,
    id_venda          INT            NULL,
    valor_original    DECIMAL(10,2)  NOT NULL,
    data_emissao      DATE           NOT NULL,
    data_vencimento   DATE           NOT NULL,
    situacao          VARCHAR(9)     NOT NULL CONSTRAINT DF_CONTA_RECEBER_situacao DEFAULT 'EM_ABERTO',
    saldo_pendente    DECIMAL(10,2)  NOT NULL,

    CONSTRAINT PK_CONTA_RECEBER PRIMARY KEY (id_conta_receber),
    CONSTRAINT FK_CONTA_RECEBER_ATENDIMENTO FOREIGN KEY (id_atendimento) REFERENCES ATENDIMENTO (id_atendimento),
    CONSTRAINT FK_CONTA_RECEBER_VENDA FOREIGN KEY (id_venda) REFERENCES VENDA (id_venda),
    CONSTRAINT CK_CONTA_RECEBER_origem CHECK (
           (id_atendimento IS NOT NULL AND id_venda IS NULL)
        OR (id_atendimento IS NULL     AND id_venda IS NOT NULL)
    ),
    CONSTRAINT CK_CONTA_RECEBER_valor CHECK (valor_original > 0),
    CONSTRAINT CK_CONTA_RECEBER_saldo CHECK (saldo_pendente >= 0 AND saldo_pendente <= valor_original),
    CONSTRAINT CK_CONTA_RECEBER_vencimento CHECK (data_vencimento >= data_emissao),
    CONSTRAINT CK_CONTA_RECEBER_situacao CHECK (situacao IN ('EM_ABERTO', 'PAGO', 'CANCELADO', 'ESTORNADO'))
);
GO

CREATE UNIQUE INDEX UQ_CONTA_RECEBER_id_atendimento
    ON CONTA_RECEBER (id_atendimento) WHERE id_atendimento IS NOT NULL;
GO
CREATE UNIQUE INDEX UQ_CONTA_RECEBER_id_venda
    ON CONTA_RECEBER (id_venda) WHERE id_venda IS NOT NULL;
GO

CREATE TABLE PAGAMENTO (
    id_pagamento           INT            IDENTITY(1,1) NOT NULL,
    id_conta_receber       INT            NOT NULL,
    id_forma_pagamento     INT            NOT NULL,
    valor                  DECIMAL(10,2)  NOT NULL,
    situacao_pagamento     VARCHAR(10)    NOT NULL CONSTRAINT DF_PAGAMENTO_situacao DEFAULT 'PENDENTE',
    data_hora_confirmacao  DATETIME       NULL,
    data_hora_estorno      DATETIME       NULL,
    data_hora_pagamento    DATETIME       NOT NULL,

    CONSTRAINT PK_PAGAMENTO PRIMARY KEY (id_pagamento),
    CONSTRAINT FK_PAGAMENTO_CONTA_RECEBER FOREIGN KEY (id_conta_receber) REFERENCES CONTA_RECEBER (id_conta_receber),
    CONSTRAINT FK_PAGAMENTO_FORMA_PAGAMENTO FOREIGN KEY (id_forma_pagamento) REFERENCES FORMA_PAGAMENTO (id_forma_pagamento),
    CONSTRAINT CK_PAGAMENTO_valor CHECK (valor > 0),
    CONSTRAINT CK_PAGAMENTO_situacao CHECK (situacao_pagamento IN ('PENDENTE', 'CONFIRMADO', 'RECUSADO', 'ESTORNADO')),
    CONSTRAINT CK_PAGAMENTO_datas CHECK (
            (situacao_pagamento <> 'CONFIRMADO' OR data_hora_confirmacao IS NOT NULL)
        AND (situacao_pagamento <> 'ESTORNADO'  OR data_hora_estorno IS NOT NULL)
    )
);
GO

/* 9. FINANCEIRO – CONTAS A PAGAR E PAGAMENTOS A FORNECEDORES */

CREATE TABLE CONTA_PAGAR (
    id_conta_pagar          INT            IDENTITY(1,1) NOT NULL,
    id_compra               INT            NOT NULL,
    valor_original_compra   DECIMAL(10,2)  NOT NULL,
    data_emissao_compra     DATE           NOT NULL,
    data_vencimento_compra  DATE           NOT NULL,
    situacao_compra         VARCHAR(9)     NOT NULL CONSTRAINT DF_CONTA_PAGAR_situacao DEFAULT 'EM_ABERTO',
    saldo_pendente_compra   DECIMAL(10,2)  NOT NULL,

    CONSTRAINT PK_CONTA_PAGAR PRIMARY KEY (id_conta_pagar),
    CONSTRAINT UQ_CONTA_PAGAR_id_compra UNIQUE (id_compra),
    CONSTRAINT FK_CONTA_PAGAR_COMPRA FOREIGN KEY (id_compra) REFERENCES COMPRA (id_compra),
    CONSTRAINT CK_CONTA_PAGAR_valor CHECK (valor_original_compra > 0),
    CONSTRAINT CK_CONTA_PAGAR_saldo CHECK (saldo_pendente_compra >= 0 AND saldo_pendente_compra <= valor_original_compra),
    CONSTRAINT CK_CONTA_PAGAR_vencimento CHECK (data_vencimento_compra >= data_emissao_compra),
    CONSTRAINT CK_CONTA_PAGAR_situacao CHECK (situacao_compra IN ('EM_ABERTO', 'PAGO', 'CANCELADO', 'ESTORNADO'))
);
GO

CREATE TABLE PAGAMENTO_FORNECEDOR (
    id_pagamento_fornecedor  INT            IDENTITY(1,1) NOT NULL,
    id_conta_pagar           INT            NOT NULL,
    valor_pago               DECIMAL(10,2)  NOT NULL,
    data_hora_pagamento      DATETIME       NOT NULL,
    meio_pagamento           VARCHAR(13)    NOT NULL,
    situacao_pagamento       VARCHAR(10)    NOT NULL CONSTRAINT DF_PAGAMENTO_FORNECEDOR_situacao DEFAULT 'PENDENTE',
    referencia_comprovante   VARCHAR(MAX)   NULL,
    data_hora_confirmacao    DATETIME       NULL,

    CONSTRAINT PK_PAGAMENTO_FORNECEDOR PRIMARY KEY (id_pagamento_fornecedor),
    CONSTRAINT FK_PAGAMENTO_FORNECEDOR_CONTA_PAGAR FOREIGN KEY (id_conta_pagar) REFERENCES CONTA_PAGAR (id_conta_pagar),
    CONSTRAINT CK_PAGAMENTO_FORNECEDOR_valor CHECK (valor_pago > 0),
    CONSTRAINT CK_PAGAMENTO_FORNECEDOR_meio CHECK (meio_pagamento IN ('PIX', 'BOLETO', 'TRANSFERENCIA', 'DINHEIRO', 'CARTAO')),
    CONSTRAINT CK_PAGAMENTO_FORNECEDOR_situacao CHECK (situacao_pagamento IN ('PENDENTE', 'CONFIRMADO', 'CANCELADO', 'ESTORNADO')),
    CONSTRAINT CK_PAGAMENTO_FORNECEDOR_confirmacao CHECK (situacao_pagamento <> 'CONFIRMADO' OR data_hora_confirmacao IS NOT NULL)
);
GO

/* 10. FINANCEIRO – CAIXA E CONCILIAÇÃO */

CREATE TABLE MOVIMENTACAO_CAIXA (
    id_movimentacao_caixa      INT            IDENTITY(1,1) NOT NULL,
    id_pagamento               INT            NULL,
    id_pagamento_fornecedor    INT            NULL,
    tipo_movimentacao          VARCHAR(7)     NOT NULL,
    valor_movimentacao         DECIMAL(10,2)  NOT NULL,
    data_hora_movimentacao     DATETIME       NOT NULL,
    descricao_movimentacao     VARCHAR(100)   NULL,
    id_movimentacao_estornada  INT            NULL,

    CONSTRAINT PK_MOVIMENTACAO_CAIXA PRIMARY KEY (id_movimentacao_caixa),
    CONSTRAINT FK_MOV_CAIXA_PAGAMENTO FOREIGN KEY (id_pagamento) REFERENCES PAGAMENTO (id_pagamento),
    CONSTRAINT FK_MOV_CAIXA_PAGAMENTO_FORNECEDOR FOREIGN KEY (id_pagamento_fornecedor) REFERENCES PAGAMENTO_FORNECEDOR (id_pagamento_fornecedor),
    CONSTRAINT FK_MOV_CAIXA_ESTORNADA FOREIGN KEY (id_movimentacao_estornada) REFERENCES MOVIMENTACAO_CAIXA (id_movimentacao_caixa),
    CONSTRAINT CK_MOV_CAIXA_tipo CHECK (tipo_movimentacao IN ('ENTRADA', 'SAIDA')),
    CONSTRAINT CK_MOV_CAIXA_valor CHECK (valor_movimentacao > 0),
    CONSTRAINT CK_MOV_CAIXA_origem CHECK (
            NOT (id_pagamento IS NOT NULL AND id_pagamento_fornecedor IS NOT NULL)
        AND (id_pagamento IS NOT NULL OR id_pagamento_fornecedor IS NOT NULL OR id_movimentacao_estornada IS NOT NULL)
    ),
    CONSTRAINT CK_MOV_CAIXA_estornada CHECK (id_movimentacao_estornada <> id_movimentacao_caixa)
);
GO

CREATE UNIQUE INDEX UQ_MOV_CAIXA_id_pagamento
    ON MOVIMENTACAO_CAIXA (id_pagamento) WHERE id_pagamento IS NOT NULL;
GO
CREATE UNIQUE INDEX UQ_MOV_CAIXA_id_pagamento_fornecedor
    ON MOVIMENTACAO_CAIXA (id_pagamento_fornecedor) WHERE id_pagamento_fornecedor IS NOT NULL;
GO

CREATE TABLE CONCILIACAO_FINANCEIRA (
    id_conciliacao               INT            IDENTITY(1,1) NOT NULL,
    id_movimentacao_caixa        INT            NOT NULL,
    id_usuario                   INT            NOT NULL,
    data_conciliacao             DATE           NOT NULL,
    referencia_conciliacao       VARCHAR(100)   NOT NULL,
    valor_conferido_conciliacao  DECIMAL(10,2)  NOT NULL,
    situacao_conciliacao         VARCHAR(10)    NOT NULL CONSTRAINT DF_CONCILIACAO_situacao DEFAULT 'PENDENTE',
    observacao_divergencia       VARCHAR(MAX)   NULL,

    CONSTRAINT PK_CONCILIACAO_FINANCEIRA PRIMARY KEY (id_conciliacao),
    CONSTRAINT FK_CONCILIACAO_MOV_CAIXA FOREIGN KEY (id_movimentacao_caixa) REFERENCES MOVIMENTACAO_CAIXA (id_movimentacao_caixa),
    CONSTRAINT FK_CONCILIACAO_USUARIO FOREIGN KEY (id_usuario) REFERENCES USUARIO (id_usuario),
    CONSTRAINT CK_CONCILIACAO_valor CHECK (valor_conferido_conciliacao >= 0),
    CONSTRAINT CK_CONCILIACAO_situacao CHECK (situacao_conciliacao IN ('PENDENTE', 'CONCILIADA', 'DIVERGENTE')),
    CONSTRAINT CK_CONCILIACAO_divergencia CHECK (situacao_conciliacao <> 'DIVERGENTE' OR observacao_divergencia IS NOT NULL)
);
GO

/* 11. AUDITORIA */

CREATE TABLE REGISTRO_AUDITORIA (
    id_registro          INT          IDENTITY(1,1) NOT NULL,
    id_usuario           INT          NOT NULL,
    data_hora_auditoria  DATETIME     NOT NULL CONSTRAINT DF_REGISTRO_AUDITORIA_data_hora DEFAULT GETDATE(),
    operacao             VARCHAR(9)   NOT NULL,
    objeto_afetado       VARCHAR(30)  NOT NULL,

    CONSTRAINT PK_REGISTRO_AUDITORIA PRIMARY KEY (id_registro),
    CONSTRAINT FK_REGISTRO_AUDITORIA_USUARIO FOREIGN KEY (id_usuario) REFERENCES USUARIO (id_usuario),
    CONSTRAINT CK_REGISTRO_AUDITORIA_operacao CHECK (operacao IN ('INCLUSAO', 'ALTERACAO', 'EXCLUSAO'))
);
GO

/* Conferência final: lista as tabelas criadas (devem ser 32) */
SELECT COUNT(*) AS total_tabelas
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';
GO
