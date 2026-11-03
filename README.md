# NAVØR

### Estrutura de dados para uma gestão integrada de barbearias

A **NAVØR** é uma solução de modelagem e implementação de banco de dados voltada à organização das operações de uma barbearia. Sua estrutura conecta o atendimento ao cliente aos processos de agenda, serviços, vendas, estoque e controle financeiro, permitindo que informações de diferentes áreas sejam consultadas de forma consistente.

O repositório reúne o **modelo de dados**, a **implementação em Microsoft SQL Server**, uma massa de dados demonstrativa e consultas de análise e validação. Essa estrutura constitui a base para a evolução de um sistema de gestão (ERP), sem depender de uma interface para que o banco e as consultas sejam explorados.

**Tecnologias:** Microsoft SQL Server · T-SQL · SQL Server Management Studio (SSMS) · DBML  
**Estrutura:** 32 tabelas · 46 chaves estrangeiras declaradas · normalização documentada até a 3FN

---

## Visão geral

A rotina de uma barbearia envolve muito mais do que o agendamento de horários. Cada serviço pode envolver um profissional, diferentes produtos, cobrança, comissão e movimentações financeiras. Quando essas informações são mantidas separadamente, surgem dificuldades para acompanhar o histórico das operações e tomar decisões com base em dados confiáveis.

A NAVØR organiza essas informações em um modelo relacional, com vínculos definidos entre os registros e regras de integridade para reduzir inconsistências. O objetivo é sustentar processos operacionais e oferecer uma visão mais clara do negócio.

## O que a solução oferece

| Área | Recursos contemplados no modelo de dados |
|---|---|
| **Clientes e equipe** | Cadastro de pessoas, contatos, clientes, funcionários, usuários e perfis de acesso; registro opcional de preferências de atendimento. |
| **Agenda** | Agendamentos com profissional responsável, serviços selecionados, quantidades, duração prevista e situação da reserva. |
| **Atendimentos** | Registro de serviços efetivamente realizados, inclusive encaixes, com manutenção dos preços praticados no histórico. |
| **Comissões** | Apuração vinculada aos serviços realizados, com percentual aplicado, valor, competência e situação registrados individualmente. |
| **Produtos e estoque** | Cadastro de produtos, entradas e saídas, consumo nos atendimentos, compras, vendas e rastreabilidade das movimentações. |
| **Financeiro** | Contas a receber e a pagar, pagamentos de clientes e fornecedores, movimentações de caixa e conciliação financeira. |
| **Gestão e análise** | Consultas para conferência de integridade, acompanhamento de operações e identificação de indicadores relevantes. |

Esses recursos representam as **estruturas e regras do banco de dados**. O repositório não contém uma aplicação web ou desktop pronta para operar esses processos por meio de telas.

## Como os processos se conectam

A integração acontece por meio dos relacionamentos entre as tabelas. Alguns exemplos:

**Atendimento ao cliente**  
`CLIENTE → AGENDAMENTO → ATENDIMENTO → ITEM_ATENDIMENTO → CONTA_RECEBER → PAGAMENTO`

Uma reserva registra o cliente titular e os serviços previstos. Ao realizar o atendimento, o banco permite armazenar os serviços realmente executados, os valores correspondentes e os recebimentos associados. Atendimentos por encaixe podem ser registrados sem agendamento prévio.

**Produtos e abastecimento**  
`FORNECEDOR → COMPRA → ITEM_COMPRA → MOVIMENTACAO_ESTOQUE → PRODUTO`

O registro da compra é separado do recebimento dos itens. A movimentação de estoque mantém a origem da operação e permite relacionar entradas e saídas às compras, vendas ou ao consumo durante os atendimentos.

**Controle financeiro**  
`ATENDIMENTO / VENDA → CONTA_RECEBER → PAGAMENTO → MOVIMENTACAO_CAIXA → CONCILIACAO_FINANCEIRA`

O modelo permite acompanhar valores devidos, pagamentos registrados e confirmados, lançamentos de caixa e conferências financeiras. Também contempla contas e pagamentos relacionados aos fornecedores.

## Arquitetura e decisões de modelagem

O banco foi estruturado com **32 tabelas**, relacionamentos definidos por chaves primárias e estrangeiras e restrições de domínio e obrigatoriedade. A documentação descreve a análise de **1FN, 2FN e 3FN**.

Algumas decisões importantes:

- **Identidade sem duplicação:** `PESSOA` utiliza o CPF como chave primária e mantém um identificador interno único. A mesma pessoa pode assumir os papéis de cliente e funcionário.
- **Relacionamentos N:N:** associações como venda–produto e atendimento–serviço são representadas por tabelas específicas, preservando quantidades e valores praticados.
- **Histórico de comissões:** `COMISSAO` mantém o percentual e o valor aplicados a cada serviço, separados do cadastro do funcionário. A política de referência da NAVØR prevê **40%** para profissionais comissionados.
- **Preferências opcionais:** o cliente pode possuir ou não um registro de preferências, sem que isso impeça a realização de atendimentos.
- **Pagamentos rastreáveis:** cada pagamento de cliente está associado a uma conta a receber, cuja origem é um atendimento **ou** uma venda.
- **Agendamento com múltiplas execuções:** a quantidade de cada serviço é registrada em `AGENDAMENTO_SERVICO`, compondo o cálculo da duração prevista.

### Diagramas e documentação

- [DER — visão conceitual](docs/diagramas/DER_navor.png) · [Versão SVG](docs/diagramas/DER_navor.svg)
- [Modelo lógico relacional — SVG](docs/diagramas/modelo_logico.svg) · [Código DBML](docs/diagramas/modelo_logico.dbml)
- [Dicionário de dados](docs/dicionario_dados/dicionario_dados_.xlsx)
- [Documentação técnica consolidada](docs/documentacao_empresa/NAVOR_Barbearia_FINAL.pdf)
- [Normalização do banco de dados](docs/normalizacao/normalizacao.md)
- [Fluxogramas dos processos](docs/img_e_fluxogramas/)

## Instalação e execução

### Pré-requisitos

- Uma instância do **Microsoft SQL Server** disponível para conexão.
- **SQL Server Management Studio (SSMS)** para executar os scripts T-SQL.
- Acesso aos arquivos deste repositório, obtidos por clone ou download.

### 1. Obtenha o projeto

```bash
git clone https://github.com/Erisclecio/ModelagemBarbearia_NAVOR_.git
cd ModelagemBarbearia_NAVOR_
```

### 2. Crie o banco de dados

Abra o SSMS, conecte-se à instância do SQL Server e execute o arquivo [`sql/1-DDL_Criacao.sql`](sql/1-DDL_Criacao.sql). Ele cria o banco **`NavorBarbearia`**, suas tabelas e as restrições de integridade.

> **Atenção:** o script de criação **exclui e recria `NavorBarbearia` caso o banco já exista**. Utilize uma instância de testes e faça backup antes de executá-lo sobre qualquer base com dados a preservar.

### 3. Insira os dados de demonstração

Execute [`sql/2-Massa_de_dados.sql`](sql/2-Massa_de_dados.sql). O arquivo contém os registros de exemplo necessários para explorar os relacionamentos e diferentes situações do negócio.

### 4. Valide a estrutura e explore as consultas

Execute os arquivos a seguir **nesta ordem**, observando as mensagens e os resultados apresentados pelo SSMS:

| Arquivo | Utilização |
|---|---|
| [`3-Validacao_integridade.sql`](sql/3-Validacao_integridade.sql) | Confere vínculos, valores, situações financeiras, agenda e estoque. |
| [`4-Evidencias_plano_testes.sql`](sql/4-Evidencias_plano_testes.sql) | Consulta cenários relacionados ao plano de testes. |
| [`5-Testes_restricoes.sql`](sql/5-Testes_restricoes.sql) | Executa tentativas controladas de operações inválidas para verificar as restrições do banco. |
| [`6-Aplicacoes_ia.sql`](sql/6-Aplicacoes_ia.sql) | Explora padrões de utilização, demanda, recorrência e oportunidades de análise. |

O script de testes de restrições utiliza transações e tratamento de erros para observar o comportamento do banco diante de operações que devem ser rejeitadas. O [plano de testes](evidencias/Plano_de_Testes_BI_NAVOR.docx) complementa as consultas.

### 5. Faça sua primeira consulta

Com o banco criado e a massa de dados inserida, execute no SSMS:

```sql
USE NavorBarbearia;
GO

SELECT TOP (10)
    s.nome AS servico,
    COUNT(*) AS quantidade_registros,
    SUM(i.preco_praticado) AS valor_total
FROM ITEM_ATENDIMENTO AS i
INNER JOIN SERVICO AS s ON s.id_servico = i.id_servico
GROUP BY s.nome
ORDER BY quantidade_registros DESC;
```

Essa consulta apresenta os serviços mais frequentes **nos itens de atendimento registrados**, acompanhados da soma dos valores praticados. Para investigar outros processos, utilize as consultas disponíveis na pasta [`sql/`](sql/).

## Estrutura do repositório

```text
ModelagemBarbearia_NAVOR_/
├── README.md
├── docs/
│   ├── diagramas/              # DER, modelo lógico e DBML
│   ├── dicionario_dados/        # Descrição dos dados e atributos
│   ├── documentacao_empresa/   # Documento técnico e histórico de alterações
│   ├── img_e_fluxogramas/      # Fluxogramas dos processos
│   └── normalizacao/           # Análise das formas normais
├── sql/
│   ├── 1-DDL_Criacao.sql
│   ├── 2-Massa_de_dados.sql
│   ├── 3-Validacao_integridade.sql
│   ├── 4-Evidencias_plano_testes.sql
│   ├── 5-Testes_restricoes.sql
│   └── 6-Aplicacoes_ia.sql
└── evidencias/                  # Plano de testes e cenários de análise
```

## Indicadores e possibilidades de evolução

A base relacional permite construir análises sobre **procura por serviços, desempenho operacional, ocupação da equipe, faturamento, estoque, pagamentos e recorrência dos clientes**. O arquivo de consultas analíticas apresenta exemplos de exploração desses dados.

Como evolução da solução, essa estrutura poderá servir a uma interface de gestão, painéis de indicadores e funcionalidades de relacionamento com clientes. Uma possibilidade documentada é o **NAVØR CLUB**, programa de fidelidade planejado para uma etapa futura, mas não implementado no modelo atual.

## Escopo

Este repositório disponibiliza a **camada de dados de uma solução de gestão**, incluindo modelagem, implementação SQL, dados demonstrativos e consultas. Não inclui uma interface operacional do ERP, serviços de API ou automações de negócio em produção. Algumas regras dependem de uma futura camada de aplicação, além das restrições já definidas no banco.

A evolução da modelagem e as justificativas das principais alterações podem ser consultadas no [histórico de mudanças](docs/documentacao_empresa/registro_alteracao/alteracoes_modbd.md) e no [histórico de commits](https://github.com/Erisclecio/ModelagemBarbearia_NAVOR_/commits/main).
