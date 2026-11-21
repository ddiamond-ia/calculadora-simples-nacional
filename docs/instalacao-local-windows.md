# Instalação local no Windows (sem Docker)

Passo a passo para rodar a calculadora do Simples Nacional no próprio computador, já com as soluções para os problemas mais comuns.

## 1. Instalar o Java 25

1. Baixe em <https://adoptium.net/temurin/releases/?version=25> (Windows, x64, JDK, arquivo `.msi`).
2. Na instalação, ative **"Set JAVA_HOME variable"** ("Will be installed on local hard drive").
3. Feche e abra de novo o PowerShell e confira:
   ```powershell
   java -version
   echo $env:JAVA_HOME
   ```
   O primeiro comando precisa mostrar a versão 25 ou mais. O segundo, o caminho do Java.

**Se o `JAVA_HOME` estiver vazio ou errado** (erro *"JAVA_HOME not found"* ou *"JAVA_HOME is set to an invalid directory"*), rode este comando, que descobre o caminho certo sozinho:
```powershell
$jdk = (Get-Item (Get-Command java).Source).Directory.Parent.FullName; setx JAVA_HOME "$jdk"; $env:JAVA_HOME = $jdk; echo $env:JAVA_HOME
```

## 2. Baixar os dois repositórios da Receita

Instale o Git (<https://git-scm.com>) e rode no PowerShell:
```powershell
git clone https://github.com/ReceitaFederal/calculadora-rtc-simples-nacional.git
git clone https://github.com/ReceitaFederal/calculadora-rtc-regime-regular.git
```

## 3. Gerar o banco de dados (na pasta do regime regular)

O manual da Receita manda gerar o banco na pasta do Simples, mas o projeto do Simples não tem o plugin do Flyway configurado e o comando falha lá. Gere na pasta do regime regular e depois copie.

No Explorador de Arquivos, entre em `calculadora-rtc-regime-regular`, clique com o botão direito num espaço vazio → **Abrir no Terminal**, e rode:
```powershell
mkdir calculadora\db
.\mvnw.cmd flyway:migrate "-Dflyway.configFiles=flyway\flyway-pro.conf" --batch-mode --errors
```
Espere aparecer **BUILD SUCCESS**. Depois copie o banco para a pasta do Simples:
```powershell
mkdir ..\calculadora-rtc-simples-nacional\calculadora\db -Force
Copy-Item calculadora\db\calculadora-pro.db ..\calculadora-rtc-simples-nacional\calculadora\db\
```

## 4. Rodar a calculadora

```powershell
cd ..\calculadora-rtc-simples-nacional
.\mvnw.cmd spring-boot:run "-Dspring-boot.run.profiles=offline"
```
Está pronta quando aparecer `Started ... Application` ou a linha `Banco de dados: arquivo [calculadora-pro.db] ...`. Abra <http://localhost:8082/api/swagger-ui.html> e deixe a janela aberta enquanto usa.

## Problemas comuns

| Mensagem | Solução |
|---|---|
| `O comando mvnw.cmd não foi encontrado, mas existe no local atual` | No PowerShell, escreva `.\mvnw.cmd`, com ponto e barra no começo |
| `JAVA_HOME not found` / `JAVA_HOME is set to an invalid directory` | Veja o passo 1 |
| `Não é possível localizar o caminho` | Abra o terminal direto na pasta, com o botão direito → **Abrir no Terminal** |
| Erro do Flyway (`MojoExecutionException`) na pasta do Simples | Gere o banco na pasta do regime regular (passo 3) |
| `Identify and stop the process that's listening on port 8082` | A calculadora já está aberta em outra janela. Use essa, ou feche-a antes |
