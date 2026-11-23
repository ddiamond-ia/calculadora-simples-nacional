# Calculadora CBS/IBS – Simples Nacional (uso interno)

Publica a **Calculadora de Tributos – Simples Nacional**, da Receita Federal, num endereço na internet **com login**, para uso das pessoas da empresa.

- Código oficial da Receita: <https://github.com/ReceitaFederal/calculadora-rtc-simples-nacional> (licença MIT)
- O que ela faz: calcula a **CBS e o IBS** (Reforma Tributária do Consumo, LC 214/2025) das notas emitidas por empresas do Simples Nacional.
- O que ela **não** faz: não calcula o DAS. O imposto mensal continua sendo apurado no PGDAS-D, no Portal do Simples Nacional.

Este repositório não copia o código da Receita. Na hora da publicação, ele baixa a versão oficial, gera o banco de dados e coloca um login na frente.

---

## Como funciona

```
Pessoa da empresa ──HTTPS──▶ Render ──▶ Caddy (login) ──▶ Calculadora da Receita (Java)
```

| Arquivo | Para que serve |
|---|---|
| `Dockerfile` | Baixa o código oficial, gera o banco e monta a imagem com Java 25 e Caddy |
| `docker/Caddyfile` | Login (usuário e senha) e encaminhamento para a calculadora |
| `docker/iniciar.sh` | Lê os usuários da variável `USUARIOS` e inicia tudo |
| `site/index.html` | Página inicial com instruções de uso |
| `render.yaml` | Configuração pronta para o Render |
| `docs/instalacao-local-windows.md` | Como rodar a calculadora no próprio computador (Windows) |

---

## Publicar na VPS com EasyPanel (Hostinger)

A cada alteração na branch `main`, o GitHub monta a imagem da calculadora e a publica em
`ghcr.io/ddiamond-ia/calculadora-simples-nacional:latest` (veja a aba **Actions**).

1. No EasyPanel, abra (ou crie) um projeto → **+ Service** → **App**, com o nome `calculadora`.
2. **Source** → **Docker Image** → `ghcr.io/ddiamond-ia/calculadora-simples-nacional:latest` → **Save**.
   Se a imagem estiver privada no GitHub, preencha também usuário e um token com permissão `read:packages`.
3. **Environment**:
   ```
   USUARIOS=ana:SenhaForte123,joao:OutraSenha456
   PORT=10000
   PROTOCOLO_EXTERNO=https
   ```
   → **Save**.
4. **Domains** → edite o domínio criado automaticamente e troque a porta para **10000** → **Save**.
5. **Deploy**. Para atualizar depois de uma nova versão no GitHub, clique em **Deploy** de novo.

## Publicar no Render (passo a passo)

1. Crie uma conta em <https://render.com> e entre com a sua conta do GitHub.
2. No painel, clique em **New** → **Blueprint**.
3. Autorize o Render a acessar **este repositório** e selecione-o.
4. O Render lê o arquivo `render.yaml` e pede o valor de **`USUARIOS`**. Preencha assim:
   ```
   ana:SenhaForte123,joao:OutraSenha456
   ```
   - Usuário e senha separados por `:`
   - Vários usuários separados por `,`
   - Senhas com pelo menos 8 caracteres e sem vírgula
5. Clique em **Apply** (ou **Deploy**). A primeira publicação demora alguns minutos, porque compila a calculadora.
6. Quando o status ficar **Live**, o endereço aparece no topo da página do serviço, algo como `https://calculadora-simples-nacional.onrender.com`.
7. Abra o endereço. O navegador pede usuário e senha. Depois do login, aparece a página inicial com o botão **Abrir calculadora**.

### Plano

O `render.yaml` usa o plano **starter** (pago, sempre ligado). Para testar sem custo, troque `plan: starter` por `plan: free`. O plano gratuito desliga depois de 15 minutos sem uso, e o primeiro acesso seguinte demora para responder.

---

## Gerenciar usuários

No Render: abra o serviço → **Environment** → edite **`USUARIOS`** → **Save Changes**. O serviço reinicia sozinho em cerca de um minuto.

- **Incluir uma pessoa:** acrescente `,nome:senha` no final.
- **Tirar uma pessoa:** apague o trecho dela.
- **Trocar uma senha:** edite o trecho da pessoa.

As senhas ficam só no Render, nunca neste repositório.

---

## Atualizar a calculadora

A Receita publica novas versões nos repositórios oficiais. Para atualizar:

1. Pegue o código do commit mais recente de cada repositório oficial:
   - <https://github.com/ReceitaFederal/calculadora-rtc-regime-regular/commits>
   - <https://github.com/ReceitaFederal/calculadora-rtc-simples-nacional/commits>
2. Troque os valores de `REF_REGIME_REGULAR` e `REF_SIMPLES` no começo do `Dockerfile`.
3. Salve a alteração no GitHub. O Render publica a nova versão automaticamente.

Versões fixadas atualmente (19/11/2026):

| Repositório | Commit |
|---|---|
| calculadora-rtc-regime-regular | `f1eebd7ce3157423b1a6aaca7dc1d6c3395452c4` |
| calculadora-rtc-simples-nacional | `a926d5a76095ac0295a6612a9a54db7ffead2396` |

---

## Como usar a calculadora

A página inicial tem o resumo. Em poucas palavras:

1. Clique em **Abrir calculadora**.
2. Abra `POST /calculadora/observabilidade/simples-nacional/nao-assistido`, clique em **Try it out**, ajuste o exemplo e clique em **Execute**.
3. Confira o `estadoItem` de cada item na resposta: `CALCULADO`, `INCONSISTENCIA_ENTRADA` ou `NAO_CALCULADO`.

A calculadora precisa das **alíquotas efetivas de CBS e IBS** do período, como publicadas no PGDAS. Ela não calcula essas alíquotas a partir do faturamento.

---

## Segurança

- Só a rota `/saude` (verificação de funcionamento usada pelo Render) fica sem login.
- O Render entrega o HTTPS. As senhas trafegam criptografadas.
- O login é o do próprio navegador. Para sair, feche o navegador.
- Use senhas fortes e troque a senha quando alguém sair da empresa.

---

## Rodar com Docker no próprio computador (opcional)

```bash
docker build -t calculadora-simples .
docker run --rm -p 10000:10000 -e USUARIOS="teste:senha12345" -e PROTOCOLO_EXTERNO=http calculadora-simples
```

Depois abra <http://localhost:10000>.
