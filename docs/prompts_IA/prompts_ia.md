# Uso de IA na geração da massa de dados — NAVØR

Este registro atende à **Etapa 17 do Manual da Entrega Final**: os prompts usados para gerar a massa de dados em escala precisam estar documentados.

## Ferramenta utilizada

Claude (Anthropic), usado como assistente para montar o script `02_massa_dados.sql` a partir do DER, do modelo lógico, do dicionário de dados e do script `01_criacao_banco.sql` do projeto.

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
- estrutura e restrições do `01_criacao_banco.sql`.

Os valores que a documentação não trazia foram **propostos pela IA e validados pelo grupo**: preços, durações dos demais serviços, produtos, fornecedores, nomes fictícios e volume de registros.

## Situações cobertas pela massa

Encaixe sem agendamento, agendamento cancelado, horário cancelado reaproveitado, serviço adicional e serviço trocado no atendimento (RN07), reajuste de preço com valor congelado no histórico (RN08), pessoa que é cliente e funcionário (RN23), profissional não comissionado, pagamento dividido, cartão recusado, pagamento pendente, estorno de atendimento e de venda, comissão em apuração, compra entregue, parcial, recusada e em trânsito, perda e ajuste de estoque, produtos abaixo do estoque mínimo, conciliação divergente e pendente.

## Validação realizada

Seguindo o ciclo **GERAR → TESTAR → VALIDAR → CORRIGIR** do manual:

- a Parte 2.1 do script confere 35 regras (FKs, totais, comissões, agenda, estoque e financeiro) e deve mostrar **0 problemas** em todas;
- a Parte 2.2 mostra as evidências do Plano de Testes;
- a Parte 2.3 tenta gravar dados inválidos e deve mostrar **"OK: bloqueado"** em todas as tentativas.

Conferência do grupo após rodar no SQL Server:

- [ ] o script executa sem erros após o `01_criacao_banco.sql`;
- [ ] todas as verificações da Parte 2.1 aparecem como OK;
- [ ] todos os testes da Parte 2.3 aparecem como "OK: bloqueado";
- [ ] preços, durações e produtos fazem sentido para a NAVØR;
- [ ] os resultados da Parte 3 (IA) foram lidos e fazem sentido para o negócio.
