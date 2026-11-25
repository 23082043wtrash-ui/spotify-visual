# Spotify Visual

Gerenciador 3.0 para Windows 11, com Spicetify e integracao experimental Windhawk.

## Instalacao unica

Feche o Spotify inclusive na bandeja. Baixe `Instalar-Atualizador.ps1` e execute com Windows PowerShell **sem administrador**. O instalador cria os atalhos Spotify Visual e Spotify Visual - modo seguro. Use o primeiro para verificar atualizacoes. O instalador oficial do Windhawk pode solicitar UAC; nao execute scripts deste repositorio como administrador.

## Canal de atualizacoes

`gerenciador.json` define a versao e SHA-256 de `Gerenciador.ps1`. `update.json` define a versao e SHA-256 da extensao `spotify-visual.js`. Publique os arquivos primeiro e os respectivos manifestos por ultimo, com versao crescente. O bootstrap local verifica tamanho, hash e sintaxe do PowerShell antes de substituir o gerenciador; guarda a versao anterior. Hashes no mesmo repositorio verificam integridade, nao autenticidade independente. Proteja a conta do GitHub com 2FA.

O gerenciador verifica Spicetify, instala Windhawk alpha 8 se a CLI estiver ausente (hash oficial fixado), instala/configura o CEF/Spotify Tweaks e tenta atualizar somente esse mod quando indicado pela CLI. A atualizacao do motor Windhawk continua sob controle do proprio Windhawk; seu status e registrado. As protecoes de CEF nao testado e atualizacoes normais do Spotify permanecem habilitadas. A CLI do Windhawk pode falhar ou exigir permissao adicional; nesse caso o gerenciador avisa e tenta desativar o mod. O modo seguro tenta desativar o mod e restaurar o Spotify. Nao ha garantia de deteccao de todos os bugs.

Para pausar as atualizacoes, crie o arquivo vazio `%LOCALAPPDATA%\SpotifyVisual\desativar-atualizacoes.txt`. Remova-o para reativar. O log local fica em `%LOCALAPPDATA%\SpotifyVisual\atualizacoes.log`.

O bootstrap fixo e a compatibilidade no Windows ainda precisam de teste real; mudancas no bootstrap podem exigir uma nova instalacao. O repositorio nao recebe dados pessoais, imagens ou fontes. Nao use o antigo `Configurar-Windhawk.ps1` com o gerenciador 3.0.
