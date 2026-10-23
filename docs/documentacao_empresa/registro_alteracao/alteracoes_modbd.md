# Registro das Principais Alterações — NAVØR

Este registro apresenta as principais alterações realizadas na modelagem de dados da **NAVØR Barbearia** entre a primeira entrega e a documentação revisada do projeto.

As mudanças buscam melhorar a representação dos relacionamentos, a integridade dos dados e a rastreabilidade dos processos, conforme as orientações da entrega final.

## Alterações realizadas

| O que foi alterado? | Como era? | Como ficou? | Por que alteramos? |
|---|---|---|---|
| **Relacionamentos N:N** | Seis relacionamentos eram representados diretamente entre as entidades. | Foram definidas seis entidades associativas: `FUNCIONARIO_SERVICO`, `AGENDAMENTO_SERVICO`, `ITEM_ATENDIMENTO`, `ATENDIMENTO_PRODUTO`, `ITEM_VENDA` e `ITEM_COMPRA`. | Representar adequadamente as associações e preparar sua conversão para o modelo lógico relacional. |
| **Controle de comissões** | O percentual de comissão estava associado a `FUNCIONARIO`, e o valor da comissão era atributo do relacionamento entre atendimento e serviço. | Foi criada a entidade `COMISSAO`, vinculada a `ITEM_ATENDIMENTO`, com percentual aplicado, valor calculado e informações de acompanhamento. | Preservar o histórico das comissões e identificar os valores aplicados aos serviços realizados. |
| **Origem dos pagamentos** | `PAGAMENTO` possuía referências diretas para `ATENDIMENTO` e `VENDA`. | `PAGAMENTO` passou a referenciar `CONTA_RECEBER`, cuja origem corresponde exclusivamente a um atendimento ou a uma venda. | Evitar associações contraditórias e melhorar a rastreabilidade dos recebimentos. |
| **Controle financeiro** | O modelo não possuía entidades específicas para contas a receber, contas a pagar, pagamentos aos fornecedores, movimentações de caixa e conciliação financeira. | Foram acrescentadas `CONTA_RECEBER`, `CONTA_PAGAR`, `PAGAMENTO_FORNECEDOR`, `MOVIMENTACAO_CAIXA` e `CONCILIACAO_FINANCEIRA`. | Representar os controles financeiros previstos nos requisitos revisados e permitir o acompanhamento das obrigações e movimentações. |
| **Rastreabilidade do estoque** | `MOVIMENTACAO_ESTOQUE` identificava o produto e a origem por meio de um atributo descritivo, sem referências às operações correspondentes. | Foram acrescentadas referências a `COMPRA`, `VENDA`, `ATENDIMENTO` e à movimentação relacionada, além dos relacionamentos com os respectivos itens. | Permitir identificar as operações responsáveis pelas movimentações e melhorar o controle do estoque. |
| **Quantidade de serviços no agendamento** | A associação entre `AGENDAMENTO` e `SERVICO` não possuía atributo de quantidade. | `AGENDAMENTO_SERVICO` passou a possuir `qtd_servico`, considerando a quantidade no cálculo da duração prevista. | Permitir selecionar o mesmo serviço mais de uma vez no mesmo agendamento, sem sobreposição de horários. |
| **Identificação de pessoas** | `id_pessoa` era classificado como atributo simples em `PESSOA`, e as referências de `CLIENTE` e `FUNCIONARIO` não apresentavam explicitamente a restrição de unicidade. | `cpf` permaneceu como chave primária de `PESSOA`, enquanto `id_pessoa` e as referências correspondentes passaram a possuir restrições `UNIQUE`. | Reforçar a identificação individual e evitar cadastros duplicados para o mesmo papel, permitindo que uma pessoa seja cliente e funcionário. |

## Considerações

As alterações preservam a caracterização e as regras de negócio definidas para a NAVØR. Este documento registra **decisões de modelagem**; ele não indica que o banco de dados ou o ERP já tenham sido implementados.

A conversão para o modelo lógico, a demonstração da 1FN, 2FN e 3FN e a implementação em SQL serão documentadas separadamente, conforme o Manual da Entrega Final.
