# Plano de estudos - 1h por dia

## Formato de cada sessão (60 min)

| Tempo | Atividade |
|-------|-----------|
| 5 min | Ler o diário e as "dúvidas para revisar" do Day anterior |
| 25 min | Aula (pausar e anotar no README do Day) |
| 25 min | Prática no kind: aplicar os manifests, quebrar, consertar |
| 5 min | Linha no diário + `git commit` |

Regra: **não pular a prática**. Se a aula for longa, divida em duas sessões em vez de cortar o lab.

## Ritmo semanal

- **Seg a Qui:** conteúdo novo (seguindo a ordem do curso).
- **Sex:** revisão: refazer um lab de memória, sem olhar as anotações.
- **Sáb (opcional):** mini-projeto juntando o que foi visto na semana.
- **Dom:** descanso.

## Retomando o curso

Como já assisti alguns Days sem anotar, a primeira semana é para **recuperar**:

1. Para cada Day já visto, criar a pasta com o template e escrever um resumo rápido (15 min por Day, no máximo).
2. Refazer no kind os labs desses Days.
3. Só depois seguir para o próximo Day inédito.

## Dicas

- `kubectl explain <recurso>` e `kubectl <cmd> --dry-run=client -o yaml` geram YAML mais rápido que copiar da documentação.
- Para cada recurso novo, responda nas anotações: *o que é, por que existe, o que acontece se eu apagar.*
- Pensando em certificação (CKA/CKAD), treine fazer os labs só com o terminal e com https://kubernetes.io/docs aberto.
