# Análise de Dados, BI e IA — NAVØR
| Script | O que tem nele | Etapa |
|---|---|---|
| `sql/7-Consultas_gerenciais.sql` | 8 consultas que respondem perguntas do dia a dia da gestão | 18 |
| `sql/8-Consultas_auditoria.sql` | 14 consultas que apontam situações que precisam ser conferidas | 19 |
| `sql/6-Aplicacoes_ia.sql` | 8 consultas que preparam os dados para BI e IA | 21 |
## 1. Consultas gerenciais (Etapa 18)
Para montar estas consultas, começamos pela pergunta e só depois escrevemos o SQL. As perguntas vieram dos relatórios que o próprio projeto já previa no **RF27** (faturamento, comissões, estoque e atendimentos por período, profissional e serviço) e dos indicadores que listamos no documento *Inovação e Valor Agregado*.
| Código | Pergunta | Tabelas usadas |
|---|---|---|
| G1 | Quais serviços são mais procurados e quanto cada um fatura por mês? | `ITEM_ATENDIMENTO`, `ATENDIMENTO`, `SERVICO` |
| G2 | Quais produtos vendem mais e quais saem mais nos atendimentos? | `ITEM_VENDA`, `ATENDIMENTO_PRODUTO`, `PRODUTO` |
| G3 | Quanto vendemos e atendemos em cada mês, e quanto disso já entrou no caixa? | `CONTA_RECEBER` |
| G4 | Quem são os clientes que mais gastam com a gente? | `CONTA_RECEBER`, `ATENDIMENTO`, `VENDA`, `CLIENTE` |
| G5 | Quais produtos chegaram no estoque mínimo? | `MOVIMENTACAO_ESTOQUE`, `PRODUTO` |
| G6 | Como cada profissional está indo mês a mês? | `ATENDIMENTO`, `FUNCIONARIO` |
| G7 | Quanto de comissão cada profissional gerou no mês? | `COMISSAO`, `ITEM_ATENDIMENTO` |
| G8 | Como os clientes preferem pagar? | `PAGAMENTO`, `FORMA_PAGAMENTO` |
## 2. Consultas de auditoria (Etapa 19)
| Código | O que a consulta verifica | Regra | O que esperamos ver |
|---|---|---|---|
| A1 | Contas a receber que continuam em aberto, há quantos dias e se já venceram | RF30, RN24 | Lista para cobrança |
| A2 | Contas a pagar com saldo e pagamentos a fornecedor ainda pendentes | RF31 | Lista para pagamento |
| A3 | Pagamentos recusados ou estornados, e como a conta ficou depois disso | RN24 | Lista para conferência |
| A4 | Cancelamentos e estornos que não foram registrados na auditoria | RNF11 | Nenhuma linha |
| A5 | Quem fez inclusões, alterações e exclusões no sistema | RNF11, RP04 | Resumo por usuário |
| A6 | Serviços cobrados por um valor diferente do preço atual, e se existe registro da mudança de preço | RN08, RNF11 | Diferenças com explicação |
| A7 | Atendimentos em que os serviços feitos foram diferentes dos agendados | RN07 | Lista para conferência |
| A8 | Comissões que entraram em apuração por causa de alteração ou estorno | Fluxograma 9 | Lista para revisão |
| A9 | Perdas e ajustes de estoque | RF22, RNF11 | Lista para conferência |
| A10 | Compras que chegaram incompletas, foram recusadas ou ainda estão a caminho | RN13, RF04 | Lista para cobrar o fornecedor |
| A11 | Movimentações de caixa que ainda não foram conciliadas ou que apresentaram diferença | RF33 | Lista para conferência |
| A12 | Agendamentos com data passada que continuam pendentes ou confirmados | RF15, RF16 | Nenhuma linha |
| A13 | Cadastros incompletos: pessoa sem papel, profissional sem serviço ou jornada, usuário ativo de funcionário que não está ativo, atendimento ou venda sem conta | RN23, RF07, RP04, RF30 | Nenhuma linha |
| A14 | Possíveis cadastros duplicados por e-mail, telefone ou nome de fornecedor | RF01 | Nenhuma linha |
Nas consultas em que esperamos **"Nenhuma linha"**, o resultado vazio é o sinal de que está tudo certo.
## 3. Pensando como gestores (Etapa 20)
| Consulta | Dado | Informação | Decisão |
|---|---|---|---|
| G1 | Serviços realizados | Quais serviços têm mais procura e quanto cada um rende | Escolher o que divulgar, rever preços e repensar serviços pouco procurados |
| G2 | Vendas e consumo de produtos | Produtos que mais saem no balcão e nos atendimentos | Ajustar o que comprar e em que quantidade |
| G3 | Contas a receber | Movimento e valores de cada mês | Acompanhar o crescimento e definir metas para os próximos meses |
| G4 | Atendimentos e vendas por cliente | Clientes que mais gastam | Dar atenção especial a esses clientes, por exemplo no NAVØR CLUB |
| G5 | Movimentações de estoque | Produtos no limite mínimo | Repor antes que o produto falte durante um atendimento (RN14) |
| G6 | Atendimentos por profissional | Quantidade, faturamento e ticket médio de cada um | Organizar a escala e ver quem precisa de mais horários ou de apoio |
| G7 | Comissões | Quanto cada profissional tem a receber no mês | Conferir o fechamento e se planejar para esse gasto |
| G8 | Pagamentos confirmados | Peso de cada forma de pagamento | Avaliar as taxas da maquininha e estimular as formas mais baratas |
| A1 e A2 | Contas em aberto | O que temos a receber e a pagar, vencido ou não | Cobrar os clientes e organizar os pagamentos aos fornecedores |
| A10 | Itens de compra | Produtos pagos que não chegaram | Cobrar o fornecedor ou pensar em trocar de fornecedor |
| A11 | Caixa e conciliação | Valores não conferidos ou com diferença | Conferir com o extrato e entender diferenças, como a taxa da operadora |
### 4.0 Possibilidades de BI
| Pergunta | Dados | Possibilidade |
|---|---|---|
| Como o faturamento e os atendimentos evoluíram nos últimos meses? | `ATENDIMENTO` + `ITEM_ATENDIMENTO` + `SERVICO` + `VENDA` + `ITEM_VENDA` + datas | Painel com a evolução do faturamento por mês, serviço e profissional (G1, G3, G6 e IA 2) |
| Quanto da agenda está sendo usado e quanto perdemos com cancelamentos? | `AGENDAMENTO` + `ATENDIMENTO` + `JORNADA_FUNCIONARIO` | Painel de ocupação e cancelamentos por profissional (IA 7) |
| Quais produtos giram mais e quais estão acabando? | `MOVIMENTACAO_ESTOQUE` + `PRODUTO` + `ITEM_COMPRA` | Painel de estoque com alerta de reposição (G2, G5 e IA 5) |
| Como está a saúde financeira da barbearia? | `CONTA_RECEBER` + `CONTA_PAGAR` + `PAGAMENTO` + `MOVIMENTACAO_CAIXA` + `CONCILIACAO_FINANCEIRA` | Painel financeiro com recebimentos, contas em aberto e conciliação (G8, A1, A2 e A11) |
### 4.1 Possibilidades de IA
Seguimos o caminho que o manual pede: **problema → dados → análise → possível benefício**.
#### Prever a procura na agenda
- **Problema:** hoje não dá para saber com antecedência quais dias e horários vão lotar, o que dificulta montar a escala e abrir espaço para encaixes.
- **Dados:** data e hora dos atendimentos (`ATENDIMENTO`), horários já marcados (`AGENDAMENTO`) e valores cobrados (`ITEM_ATENDIMENTO`).
- **Análise:** a consulta IA 1 calcula a média de atendimentos por dia da semana e turno, e a IA 2 mostra a expectativa do faturamento semanal.
- **Possível benefício:** menos horários vazios nos dias tranquilos e menos clientes sem vaga nos dias cheios (RF26, RN18).
#### Prever a reposição do estoque
- **Problema:** a reposição hoje depende de alguém perceber que o produto está acabando.
- **Dados:** saídas por venda, consumo e perda (`MOVIMENTACAO_ESTOQUE`), estoque mínimo (`PRODUTO`) e produtos já pedidos (`ITEM_COMPRA`).
- **Análise:** a consulta IA 5 calcula quanto de cada produto sai por dia, por quantos dias o estoque ainda dura, quando ele deve acabar e quanto seria bom comprar.
- **Possível benefício:** comprar na hora certa, sem faltar produto e sem dinheiro parado em estoque (RF23, RN14).
#### Manter os clientes voltando
- **Problema:** é difícil perceber quando um cliente que vinha sempre parou de aparecer.
- **Dados:** datas do serviço e profissional que atendeu (`ATENDIMENTO`), compras (`VENDA`) e valores (`CONTA_RECEBER`).
- **Análise:** a consulta IA 3 separa os clientes por frequência e valor (RFM), e a IA 4 calcula de quanto em quanto tempo cada um costuma voltar e quando deveria ser a próxima vez que viria.
- **Possível benefício:** chamar o cliente no momento certo, já sugerindo o profissional com quem ele mais se atende (RF14, RN17).
#### NAVØR CLUB (evolução futura)
- **Problema:** incentivar o cliente a voltar, como sugerimos no documento *Inovação e Valor Agregado*.
- **Dados:** pagamentos confirmados (`PAGAMENTO`), contas a receber (`CONTA_RECEBER`) e atendimentos (`ATENDIMENTO`).
- **Análise:** a consulta IA 8 simula quantos pontos cada cliente teria hoje, seguindo as regras que definimos (1 ponto a cada R$ 1,00 pago em serviços, contado depois da confirmação do pagamento e válido por 12 meses).
- **Possível benefício:** ver o efeito do cupom antes de colocá-lo em prática.
### 4.2 O que ainda limita essas análises
- Nossa massa de teste tem dois meses. Para uma previsão confiável, seria preciso juntar pelo menos um ano de dados reais.
- O banco não guarda o **motivo do cancelamento** de um agendamento.
-  Hoje, quando alguém altera um registro, a `REGISTRO_AUDITORIA` anota o que foi mexido em um único campo de texto.
