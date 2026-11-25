# Day 04 - ReplicaSet, DaemonSet e limpeza do cluster

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

[nginx-daemonset.yaml](nginx-daemonset.yaml): DaemonSet `node-exporter-daemonset` rodando o `prom/node-exporter` (exporter de métricas do Prometheus).

- O DaemonSet roda **um pod em cada node**. Não tem `replicas`: o número de pods é o número de nodes.
- Se entrar um node novo no cluster, ele ganha um pod automaticamente. Se um node sai, o pod dele some junto.
- Uso típico: agentes que precisam estar em todo node (métricas, logs, rede). O `kube-proxy` e o `kindnet` do cluster são DaemonSets.

O que tem nesse YAML:

- `hostNetwork: true` + `hostPort: 9100`: o pod usa a rede do próprio node, então as métricas ficam em `<IP-do-node>:9100`.
- `hostPath` montando `/proc` e `/sys` do node (só leitura): é de onde o node-exporter lê CPU, memória, disco e rede da máquina.

> **Complemento:**
> - No kind, o DaemonSet sobe só nos **2 workers**. O control-plane tem um **taint** (`node-role.kubernetes.io/control-plane:NoSchedule`) que impede pods comuns de rodar nele. Para rodar lá também, precisaria de uma `toleration`.
> - O node-exporter normalmente recebe `args` dizendo onde estão os diretórios montados (`--path.procfs=/host/proc` e `--path.sysfs=/host/sys`). Sem isso, ele lê o `/proc` e o `/sys` de dentro do container.
> - O arquivo se chama `nginx-daemonset.yaml`, mas não tem nginx nele.

```bash
kubectl apply -f day-04/nginx-daemonset.yaml
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

## Para revisar

- [ ] Trocar a imagem do ReplicaSet no YAML, aplicar e ver que os pods antigos não mudam
- [ ] Adicionar uma `toleration` no DaemonSet para rodar também no control-plane
- [ ] Acessar as métricas do node-exporter (`curl <IP-do-node>:9100/metrics` de dentro do cluster)
