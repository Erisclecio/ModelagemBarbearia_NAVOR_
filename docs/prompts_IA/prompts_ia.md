# Uso de IA na geração da massa de dados — NAVØR

Este registro atende à **Etapa 17 do Manual da Entrega Final**: os prompts usados para gerar a massa de dados em escala precisam estar documentados.

## Ferramenta utilizada

Claude (Anthropic), usado como assistente para montar o script `2-Massa_de_dados.sql` a partir do DER, do modelo lógico, do dicionário de dados e do script `1-DDL_Criacao.sql` do projeto.

## Prompts utilizados

| # | Prompt | Objetivo |
|---|---|---|
| 1 | "Para fazer a massa de dados, o que será necessário agora?" | Levantar o que precisava estar pronto antes de gerar os dados. |
| 2 | "Pode gerar os realistas, e nós validamos antes de incluir." | Gerar uma primeira versão com preços, durações e cadastros realistas, para validação do grupo. |
| 3 | Prompt completo abaixo. | Gerar a versão final em um único arquivo: massa de dados, validação e aplicações de IA. |

**Prompt 3 (na íntegra):**

> Estou trabalhando nas etapas 16 e 17 do projeto NAVØR Barbearia e preciso que você analise o projeto e gere um arquivo SQL contendo a massa de dados para o nosso banco.
> Antes de começar, dê uma olhada na estrutura existente, principalmente no DER, no modelo lógico, no dicionário de dados e nos scripts SQL. Quero que você utilize exatamente a estrutura do projeto, sem inventar tabelas, campos ou relacionamentos.
> Gere uma quantidade de dados suficiente para testar o banco e representar situações reais de uma barbearia, envolvendo clientes, funcionários, serviços, agendamentos, produtos, vendas e demais informações que existirem no nosso modelo.
> Tenha bastante cuidado com a integridade dos dados. É fundamental que:
> - Todas as PKs sejam respeitadas, sem duplicidades.
> - Todas as FKs apontem para registros existentes.
> - As constraints sejam respeitadas.
> - Os dados façam sentido dentro do funcionamento de uma barbearia.
> - Não sejam criadas inconsistências entre datas, valores, vendas, produtos e relacionamentos.
>
> Quero que os dados sejam variados e realistas, evitando registros repetitivos ou informações sem sentido.
> Antes de finalizar, execute o script, se o ambiente permitir, e verifique se os INSERTs funcionam e se os dados respeitam todas as regras do banco. Se encontrar algum problema, corrija antes de entregar.
> Minha intenção é ter um arquivo SQL, organizado e comentado, que possamos executar e utilizar como parte da entrega final do projeto.

## Informações fornecidas pelo grupo

A IA usou apenas dados já definidos no projeto:

- quadro de funcionários, horário de funcionamento, serviços e produtos descritos na caracterização da empresa;
- formas de pagamento do RF10 e política de comissão de 40% (RP03);
- duração dos serviços em minutos, decidida pelo grupo (corte = 60 e barba = 35);
- formato `AAAA-MM` e situações `REGISTRADA` e `EM_APURACAO` para as comissões;
- testes do documento "Plano de testes da NAVØR" (T01 a T16);
- indicadores e regras do NAVØR CLUB do documento "Inovação e Valor Agregado";
- estrutura e restrições do `1-DDL_Criacao.sql`.

Os valores que a documentação não trazia foram **propostos pela IA e validados pelo grupo**: preços, durações dos demais serviços, produtos, fornecedores, nomes fictícios e volume de registros.

## Situações cobertas pela massa

Encaixe sem agendamento, agendamento cancelado, horário cancelado reaproveitado, serviço adicional e serviço trocado no atendimento (RN07), reajuste de preço com valor congelado no histórico (RN08), pessoa que é cliente e funcionário (RN23), profissional não comissionado, pagamento dividido, cartão recusado, pagamento pendente, estorno de atendimento e de venda, comissão em apuração, compra entregue, parcial, recusada e em trânsito, perda e ajuste de estoque, produtos abaixo do estoque mínimo, conciliação divergente e pendente.

## Verificações de integridade e testes

Os scripts foram organizados para permitir a conferência da massa de dados e das restrições implementadas:

- `3-Validacao_integridade.sql`: contém 35 verificações de consistência.
- `4-Evidencias_plano_testes.sql`: reúne consultas relacionadas aos cenários do plano de testes.
- `5-Testes_restricoes.sql`: realiza operações controladas para verificar o bloqueio de registros inválidos.
- `6-Aplicacoes_ia.sql`: apresenta consultas analíticas para exploração dos dados.

### Conferência no SQL Server

- [ ] Executar os scripts na sequência documentada.
- [ ] Confirmar que as 35 verificações apresentam zero problemas.
- [ ] Conferir o resultado dos testes de restrições.
- [ ] Validar a coerência dos dados demonstrativos.
- [ ] Analisar os resultados das consultas gerenciais e analíticas.
