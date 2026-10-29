# Setup do ambiente (kind)

O kind roda cada node do Kubernetes como um container Docker. No Windows, isso precisa de **WSL2**, que por sua vez precisa do **hypervisor** carregado.

## Diagnóstico do PC (2026-10-29)

PC: Ryzen 5 5500, placa Mancer MCR-A520M-DXV4, BIOS 5.17, Windows 11 Pro.

| Item | Situação |
|------|----------|
| Virtualização (SVM) na BIOS | ✅ habilitada |
| SLAT | ✅ |
| DEP/NX no Windows | ✅ (OptIn) |
| Recursos WSL, VirtualMachinePlatform, Hyper-V | ✅ habilitados |
| **Hypervisor carregado** | ❌ **não** |
| WSL | instalado, sem distro |

Causa encontrada no Visualizador de Eventos (Sistema, origem `Hyper-V-Hypervisor`, evento 44), em todo boot até 22/10:

> Falha na inicialização do hipervisor; O recurso Sem Execução (NX) não está presente ou não está habilitado no BIOS.

Ou seja: **a virtualização está ligada**. O que trava é a opção **NX** (No-Execute) que o firmware entrega ao hypervisor. Depois de 22/10 não aparecem mais eventos, o que indica que o hypervisor parou de ser chamado no boot (provavelmente algum script deixou `hypervisorlaunchtype` em `off`).

## Passo 1 - Configuração de boot (PowerShell como Administrador)

```powershell
powershell -ExecutionPolicy Bypass -File scripts\check-virtualizacao.ps1 -Fix
```

Reinicie e rode o script de novo sem `-Fix`. Se `HypervisorPresent` der `True`, siga para o Passo 3.

## Passo 2 - BIOS (se aparecer o evento 44 de novo)

Entre na BIOS (tecla `Del` no boot) e procure, normalmente em **Advanced > CPU Configuration** (ou **AMD CBS**):

- **NX Mode** (ou "No-Execute Memory Protection" / "Execute Disable Bit"): **Enabled**
- **SVM Mode**: **Enabled**
- Se não achar o NX: **Load Optimized Defaults**, salvar, reativar SVM e testar de novo.

Se a opção não existir: procure uma versão de BIOS mais nova da Mancer para a MCR-A520M-DXV4. Se não houver, vá para o plano B (notebook).

## Passo 3 - WSL + Docker + kind no PC

```powershell
wsl --install -d Ubuntu
```

Dentro do Ubuntu (WSL), instale o Docker Engine direto, sem precisar do Docker Desktop:

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER   # sair e entrar de novo no WSL
```

E depois siga o [Passo 4](#passo-4---kind-e-kubectl).

## Plano B - Notebook como servidor de lab

1. Instalar **Ubuntu Server 24.04** no notebook (ou Ubuntu Desktop, se for usar ele também).
2. `sudo apt install openssh-server` e configurar o notebook para não suspender com a tampa fechada (`HandleLidSwitch=ignore` em `/etc/systemd/logind.conf`).
3. Do PC: `ssh usuario@IP-do-notebook` (dá para usar o terminal do VS Code com a extensão Remote - SSH).
4. Instalar Docker com o script do Passo 3 e seguir o Passo 4.

> Se o notebook tiver Windows e você não quiser formatar, dá para usar WSL nele também, mas o acesso via SSH fica bem mais trabalhoso.

## Passo 4 - kind e kubectl

```bash
# kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x kind && sudo mv kind /usr/local/bin/

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/ && rm kubectl

# primeiro cluster
kind create cluster --name pick --config labs/kind/cluster-3-nodes.yaml
kubectl get nodes
```
