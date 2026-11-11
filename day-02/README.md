# Day 02 - Pods, resources e emptyDir

**Data:** 2026-11-11

## Pod com mais de um container

[pod2.yaml](pod2.yaml): pod `gli-2` com dois containers, `nginx` e `busybox` (com `sleep 600` para não terminar na hora).

- Os containers do mesmo pod dividem a mesma rede (mesmo IP, falam entre si por `localhost`) e podem dividir volumes.
- Sobem e caem juntos: o pod é a unidade que o Kubernetes agenda num node.

```bash
kubectl apply -f day-02/pod2.yaml
kubectl get pods                              # READY 2/2
kubectl exec -ti gli-2 -c busybox -- sh       # -c escolhe em qual container entrar
kubectl logs gli-2 -c nginx
```

## Gerar o YAML com dry-run

Em vez de escrever o manifest do zero, dá para pedir para o kubectl gerar:

```bash
kubectl run gli-1 --image nginx --dry-run=client -o yaml > pod.yaml
```

> **Atenção:** o [pod.yaml](pod.yaml) ficou só com a linha `pod/gli-1 created (dry run)`. Isso acontece quando roda o `--dry-run=client` sem o `-o yaml`: o kubectl só imprime a mensagem, não o manifest.

## Resources: requests e limits

[podresourceslimites.yaml](podresourceslimites.yaml): container `ubuntu` com `sleep 1800`.

```yaml
resources:
  limits:
    cpu: "0.5"
    memory: "128Mi"
  requests:
    cpu: "0.3"
    memory: "64Mi"
```

- **requests**: o mínimo que o container precisa. É o que o **scheduler** usa para escolher o node (só vai para um node que tenha esse tanto livre).
- **limits**: o máximo que o container pode usar.

> **Complemento:** o que acontece ao passar do limite é diferente para cada recurso:
> - **CPU**: o container é **estrangulado** (throttling), fica mais lento, mas continua rodando.
> - **Memória**: o container é **morto** (`OOMKilled`) e o kubelet reinicia conforme o `restartPolicy`.
>
> Unidades: `cpu: "0.5"` = `500m` (meio core). `Mi` = mebibyte (1024 x 1024 bytes).

```bash
kubectl describe pod gli-2      # mostra Limits e Requests do container
kubectl describe node <node>    # "Allocated resources" mostra quanto o node já reservou
```

## Volume emptyDir

[pod-emptydir.yaml](pod-emptydir.yaml): o mesmo pod de resources, trocando o container para `nginx` e montando um volume `emptyDir` em `/glipops`.

```yaml
spec:
  containers:
  - name: webserver
    volumeMounts:
    - mountPath: /glipops          # onde aparece dentro do container
      name: primeiro-emptydir      # tem que bater com o nome em volumes
  volumes:
  - name: primeiro-emptydir
    emptyDir:
      sizeLimit: 256Mi
```

- O volume é declarado no **pod** (`volumes`) e montado em cada **container** (`volumeMounts`), ligado pelo nome.
- O emptyDir nasce **vazio** quando o pod sobe e fica no disco do node.
- Os dados sobrevivem se o **container** reiniciar, mas são **apagados quando o pod é removido**.
- Serve para dados temporários ou para dois containers do mesmo pod compartilharem arquivos.

> **Complemento:** se passar do `sizeLimit`, o kubelet expulsa o pod (evicted).

```bash
kubectl apply -f day-02/pod-emptydir.yaml
kubectl exec -ti gli-2 -- ls /glipops
kubectl exec -ti gli-2 -- sh -c 'echo teste > /glipops/arquivo.txt'
```

> **Erro que tive:** escrevi `mounthPath` em vez de `mountPath`, e o campo não é reconhecido.

## Para revisar

- [ ] Gerar de novo o `pod.yaml` com `-o yaml`
- [ ] Testar o OOMKilled: rodar um container que use mais memória que o limit
- [ ] Testar o emptyDir compartilhado entre dois containers do mesmo pod
