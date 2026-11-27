# Day 04 - ReplicaSet, DaemonSet, probes e limpeza do cluster

**Data:** 2026-11-25

## ReplicaSet direto

[nginx-replicaset.yaml](nginx-replicaset.yaml): ReplicaSet `nginx-replicaset` com 3 réplicas de `nginx:1.19.1`.

- O ReplicaSet garante que sempre existam N pods com as labels do `selector`. Se um pod morre, ele cria outro.

> **Complemento:** dá para criar um ReplicaSet sem Deployment, mas no dia a dia não se faz isso. O ReplicaSet sozinho **não faz rolling update**: se você trocar a imagem no YAML e aplicar, os pods que já existem continuam com a imagem antiga. Só os pods criados depois (quando um morre) pegam a nova. Quem cria um ReplicaSet novo e troca os pods aos poucos é o **Deployment**.

```bash
kubectl apply -f day-04/nginx-replicaset.yaml
kubectl get rs,pods -l app=nginx-app
kubectl delete pod <um-pod-do-rs>          # o ReplicaSet cria outro na hora
```

> **Obs.:** o `requests.memory: 126Mi` provavelmente era para ser `128Mi`. Funciona do mesmo jeito, só é um número diferente do padrão.

## DaemonSet

[node-exporter-daemonset.yaml](node-exporter-daemonset.yaml): DaemonSet `node-exporter-daemonset` rodando o `prom/node-exporter` (exporter de métricas do Prometheus).

- O DaemonSet roda **um pod em cada node**. Não tem `replicas`: o número de pods é o número de nodes.
- Se entrar um node novo no cluster, ele ganha um pod automaticamente. Se um node sai, o pod dele some junto.
- Uso típico: agentes que precisam estar em todo node (métricas, logs, rede). O `kube-proxy` e o `kindnet` do cluster são DaemonSets.

O que tem nesse YAML:

- `hostNetwork: true` + `hostPort: 9100`: o pod usa a rede do próprio node, então as métricas ficam em `<IP-do-node>:9100`.
- `hostPath` montando `/proc` e `/sys` do node (só leitura): é de onde o node-exporter lê CPU, memória, disco e rede da máquina.

> **Complemento:**
> - No kind, o DaemonSet sobe só nos **2 workers**. O control-plane tem um **taint** (`node-role.kubernetes.io/control-plane:NoSchedule`) que impede pods comuns de rodar nele. Para rodar lá também, precisaria de uma `toleration`.
> - O node-exporter normalmente recebe `args` dizendo onde estão os diretórios montados (`--path.procfs=/host/proc` e `--path.sysfs=/host/sys`). Sem isso, ele lê o `/proc` e o `/sys` de dentro do container.

```bash
kubectl apply -f day-04/node-exporter-daemonset.yaml
kubectl get ds
kubectl get pods -o wide -l app=node-exporter-daemonset   # um pod por worker, coluna NODE
kubectl describe node glicluster-control-plane | grep Taints
```

## Deployment

[nginx-deployment.yaml](nginx-deployment.yaml): Deployment `nginx-deployment` com 1 réplica de `nginx`, sem namespace (cai no `default`).

## Apagar recursos

- Apagar um pod que pertence a um Deployment ou ReplicaSet não adianta: ele é recriado na hora (reconciliação).
- Pod solto (criado com `kubectl run` ou `kind: Pod`) é apagado e não volta.

> **Complemento:** para tirar os pods, apaga quem manda neles:
>
> ```
> Deployment → ReplicaSet → Pods
> DaemonSet  → Pods
> ```
>
> Apagar o namespace apaga tudo o que está dentro dele.

```bash
kubectl get deploy,rs,ds -A                    # quem está criando os pods
kubectl delete deploy nginx-deployment -n default
kubectl delete namespace glipops               # apaga tudo do namespace
```

> **Obs.:** namespace é um recurso do cluster inteiro, então `kubectl get namespaces -n glipops` ignora o `-n`.

## Probes

As probes são os testes que o **kubelet** faz no container para saber se ele está vivo, pronto ou já terminou de subir. Os três arquivos usam o mesmo Deployment de nginx com 3 réplicas, mudando só a probe.

| Probe | Pergunta | Se falhar |
|---|---|---|
| **liveness** | O container está vivo? | O kubelet **reinicia** o container |
| **readiness** | O container está pronto para receber tráfego? | O pod sai do Service (não recebe requisição), mas **não reinicia** |
| **startup** | O container já terminou de subir? | O kubelet **reinicia** o container. Enquanto ela não passa, a liveness e a readiness ficam desligadas |

### Tipos de teste

- `tcpSocket`: só tenta abrir uma conexão TCP na porta. Passou se conectou.
- `httpGet`: faz um GET no `path` e na `port`. Passou se a resposta for de 200 a 399.
- `exec`: roda um comando dentro do container. Passou se o comando sair com código 0.

### Campos

- `initialDelaySeconds`: quanto esperar antes da primeira verificação.
- `periodSeconds`: de quanto em quanto tempo verifica.
- `timeoutSeconds`: quanto esperar a resposta antes de contar como falha.
- `failureThreshold`: quantas falhas seguidas até agir (reiniciar ou tirar do tráfego).
- `successThreshold`: quantos sucessos seguidos para voltar a considerar ok.

### Liveness

[nginx-liveness.yaml](nginx-liveness.yaml): `tcpSocket` na porta 80, a cada 10s, reinicia depois de 3 falhas seguidas.

> **Complemento:** o `tcpSocket` só prova que a porta está aberta. Um nginx travado ou devolvendo erro 500 ainda passa. Para web, o `httpGet` testa mais de verdade.

### Readiness

[nginx-readiness.yaml](nginx-readiness.yaml): `httpGet` em `/` na porta 80, precisa de 2 sucessos seguidos para o pod ficar pronto.

> **Complemento:** o pod aparece como `0/1` na coluna READY até a readiness passar. Com `initialDelaySeconds: 10` e `successThreshold: 2`, leva uns 20s para ficar `1/1`. No comentário do arquivo está "probe de leitura", mas readiness é **prontidão**.

### Startup

[nginx-startup.yaml](nginx-startup.yaml): `httpGet` em `/` na porta 80.

> **Correção:** na startup (e na liveness), o `successThreshold` **só aceita 1**. Com `successThreshold: 2`, o `kubectl apply` é recusado pela API com um erro dizendo que o valor deve ser 1. Para o arquivo funcionar, é só tirar essa linha ou trocar para `1`.

> **Complemento:**
> - O tempo máximo para o container subir é `initialDelaySeconds + failureThreshold x periodSeconds`. Nesse arquivo: 10 + 3 x 10 = **40s**. Se não subir nesse tempo, o kubelet reinicia.
> - A startup serve para aplicação que demora para subir: ela segura a liveness até a aplicação estar de pé, para a liveness não matar o container no meio da inicialização. Por isso ela costuma vir **junto** com uma liveness no mesmo container.

### Os três arquivos são o mesmo Deployment

Os três (e o `nginx-deployment.yaml`) usam `name: nginx-deployment`. Aplicar um depois do outro não cria três Deployments: o segundo **substitui** o primeiro, com um rolling update.

```bash
kubectl apply -f day-04/nginx-readiness.yaml
kubectl get pods -w                                  # READY 0/1 até a readiness passar
kubectl describe pod <pod>                           # mostra Liveness/Readiness/Startup e os eventos "Unhealthy"
kubectl get pods                                     # coluna RESTARTS sobe quando a liveness falha
```

## Para revisar

- [ ] Trocar a imagem do ReplicaSet no YAML, aplicar e ver que os pods antigos não mudam
- [ ] Adicionar uma `toleration` no DaemonSet para rodar também no control-plane
- [ ] Acessar as métricas do node-exporter (`curl <IP-do-node>:9100/metrics` de dentro do cluster)
- [ ] Corrigir o `successThreshold` da startup e aplicar
- [ ] Quebrar a liveness de propósito (ex.: porta 81) e ver o RESTARTS subir
- [ ] Quebrar a readiness (ex.: `path: /nao-existe`) e ver o pod ficar `0/1` sem reiniciar
