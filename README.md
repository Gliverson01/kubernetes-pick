# kubernetes-pick

Minhas anotações e labs do **PICK - Programa Intensivo em Containers e Kubernetes 2026** (LINUXtips).

Objetivo: me especializar em containers e Kubernetes, estudando **1 hora por dia** e praticando tudo num cluster local com [kind](https://kind.sigs.k8s.io/).

## Estrutura

```
.
├── days/                 # uma pasta por Day do curso (anotações + manifests)
│   └── _template/        # copiar para criar um Day novo
├── labs/
│   └── kind/             # configs de cluster kind usadas nos exercícios
├── docs/
│   ├── plano-de-estudos.md   # rotina de 1h/dia e revisões
│   └── setup-kind.md         # como subir o ambiente (PC ou notebook)
├── scripts/
│   └── check-virtualizacao.ps1  # diagnóstico de virtualização no Windows
└── diario.md             # registro curto de cada sessão de estudo
```

## Progresso

| Day | Tema | Status | Anotações |
|-----|------|--------|-----------|
| 01 | _preencher_ | ⬜ | [days/day-01](days/) |
| 02 | _preencher_ | ⬜ | |
| 03 | _preencher_ | ⬜ | |

Legenda: ⬜ não iniciado · 🟨 em andamento · ✅ concluído · 🔁 revisar

## Como uso este repo

1. Antes de cada sessão: abrir o [diário](diario.md) e ver onde parei.
2. Criar o Day novo a partir do template: `cp -r days/_template days/day-XX`.
3. Assistir a aula anotando no `README.md` do Day, e salvar os manifests YAML na pasta `manifests/` do Day.
4. Aplicar tudo no kind (`kubectl apply -f days/day-XX/manifests/`) e registrar o que quebrou e como resolvi.
5. Fechar a sessão com uma linha no diário e um commit.

## Ambiente

Veja [docs/setup-kind.md](docs/setup-kind.md).
