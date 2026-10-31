# Normalização do Banco de Dados — NAVØR

Esta etapa apresenta a normalização do modelo lógico relacional da **NAVØR – Barber • Lounge**, desenvolvido para organizar os dados de clientes, funcionários, serviços, vendas, compras, estoque e financeiro.

O modelo foi revisado até a **Terceira Forma Normal (3FN)**, considerando as regras de negócio do projeto.

## 1. Primeira Forma Normal (1FN)

O modelo conceitual permitia vários telefones para uma mesma pessoa ou fornecedor. Para representar esses contatos sem repetir dados cadastrais, o atributo `telefone` foi retirado das tabelas principais.

| Antes | Depois |
|---|---|
| `PESSOA` com `telefone` | `PESSOA` + `PESSOA_TELEFONE` |
| `FORNECEDOR` com `telefone` | `FORNECEDOR` + `FORNECEDOR_TELEFONE` |

As novas tabelas usam chaves primárias compostas:

- `PESSOA_TELEFONE`: (`id_pessoa`, `telefone`)
- `FORNECEDOR_TELEFONE`: (`id_fornecedor`, `telefone`)

Dessa forma, cada telefone fica em um registro próprio, vinculado ao cadastro correspondente.

## 2. Segunda Forma Normal (2FN)

Foram analisadas as oito tabelas com chaves primárias compostas. Verificamos se os atributos não chave dependem da **combinação completa** dos campos da chave.

Na tabela `ITEM_VENDA`, por exemplo:

```text
(id_venda, id_produto) → qtd_venda, preco_unitario_praticado
```

A quantidade e o preço praticado pertencem a um produto **em uma venda específica**. O mesmo produto pode aparecer em vendas diferentes, com quantidades e preços distintos.

Também foram verificadas `ITEM_COMPRA`, `AGENDAMENTO_SERVICO`, `ATENDIMENTO_PRODUTO`, `JORNADA_FUNCIONARIO`, `FUNCIONARIO_SERVICO` e as duas tabelas de telefones.

**Resultado:** não foram identificadas dependências parciais que exigissem novas divisões de tabelas.

## 3. Terceira Forma Normal (3FN)

A análise buscou atributos que dependessem de outros atributos não chave, em vez de depender diretamente da chave da própria tabela.

Um exemplo de separação já presente no modelo é a relação entre `PAGAMENTO` e `FORMA_PAGAMENTO`: `PAGAMENTO` armazena `id_forma_pagamento`, enquanto o nome e a situação da forma de pagamento ficam em `FORMA_PAGAMENTO`. Assim, essas informações não são repetidas em cada pagamento.

Também foi revisada a tabela `CONCILIACAO_FINANCEIRA`. O atributo `diferenca_valor`, classificado como derivado no projeto, foi removido do modelo lógico. Seu cálculo será feito quando necessário, a partir do valor conferido e do valor da movimentação financeira relacionada.

> A remoção de `diferenca_valor` é uma decisão para evitar redundância de um resultado calculado; não corresponde à correção de uma dependência transitiva.

**Resultado:** não foram encontradas dependências transitivas que justificassem novas decomposições.

## 4. Resultado da normalização

| Indicador | Resultado |
|---|---:|
| Tabelas antes da 1FN | 30 |
| Tabelas após a normalização | **32** |
| Relacionamentos após a normalização | **46** |
| Novas tabelas | `PESSOA_TELEFONE` e `FORNECEDOR_TELEFONE` |
| Atributo derivado retirado | `CONCILIACAO_FINANCEIRA.diferenca_valor` |

As alterações mantiveram os processos e as regras de negócio definidos para a NAVØR. A definição detalhada das restrições de integridade e os testes SQL fazem parte das próximas etapas do projeto.

## 5. Arquivos relacionados

- [Diagrama do modelo lógico](../diagramas/Modelo_Relacional.svg)

