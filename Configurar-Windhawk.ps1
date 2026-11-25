# Spotify Visual - configuracao experimental do Windhawk (execucao unica).
# Nao modifica Spicetify, a extensao ou dados pessoais.
param()
$ErrorActionPreference = 'Stop'
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $p = Start-Process -FilePath (Join-Path $PSHOME 'powershell.exe') -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "' + $PSCommandPath + '"') -Verb RunAs -Wait -PassThru
    exit $p.ExitCode
}
$mod = 'cef-titlebar-enabler-universal'
$tag = '2.0.0-alpha.8'
$hash = '7327471e2d93a8c58481321cce546632adb146cf125d17d7144d0e7d2a064967'
$cli = $null
$work = $null
$modTouched = $false
$log = Join-Path $env:LOCALAPPDATA 'SpotifyVisual\windhawk-instalacao.log'
New-Item -ItemType Directory -Path (Split-Path -Parent $log) -Force | Out-Null
function Log([string]$m) {
    Write-Host $m
    Add-Content -LiteralPath $log -Value ("$(Get-Date -Format s) " + $m) -Encoding UTF8
}
function Find-Cli {
    $dirs = @((Join-Path $env:ProgramFiles 'Windhawk'))
    if ($env:ProgramW6432) { $dirs += (Join-Path $env:ProgramW6432 'Windhawk') }
    foreach ($dir in ($dirs | Select-Object -Unique)) {
        $candidate = Join-Path $dir 'windhawk-cli.exe'
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    return $null
}
function Invoke-Wh([string[]]$argv) {
    Log ('windhawk-cli ' + ($argv -join ' '))
    $ErrorActionPreference = 'Continue'
    & $script:cli @argv 2>&1 | ForEach-Object { Log ([string]$_) }
    $code = $LASTEXITCODE
    if ($code -ne 0) { throw ('Windhawk CLI falhou: ' + ($argv -join ' ') + ' (codigo ' + $code + ')') }
}
function Assert-Closed {
    if (Get-Process Spotify -ErrorAction SilentlyContinue) { throw 'Feche o Spotify completamente, inclusive na bandeja, e execute novamente.' }
}
try {
    Assert-Closed
    $cli = Find-Cli
    if (-not $cli) {
        Log "Baixando Windhawk $tag do repositorio oficial."
        $work = Join-Path $env:TEMP ('SpotifyVisual-Windhawk-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $work | Out-Null
        $installer = Join-Path $work 'windhawk_setup.exe'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri "https://github.com/ramensoftware/windhawk/releases/download/$tag/windhawk_setup.exe" -UseBasicParsing -OutFile $installer -TimeoutSec 120
        if ((Get-FileHash -LiteralPath $installer -Algorithm SHA256).Hash -ine $hash) { throw 'SHA-256 do instalador oficial divergente. Instalacao interrompida.' }
        Log 'Integridade conferida. Instalando Windhawk em modo standard.'
        $p = Start-Process -FilePath $installer -ArgumentList '/S','/STANDARD' -Wait -PassThru
        if ($p.ExitCode -ne 0) { throw ('Instalador Windhawk retornou ' + $p.ExitCode) }
        $cli = Find-Cli
    }
    if (-not $cli) { throw 'CLI nao encontrada na pasta padrao. Confira a instalacao do Windhawk 2.0.' }
    Invoke-Wh @('--version')
    Assert-Closed
    # Instala a versao oficial no catalogo, desativada ate configurar.
    # Nao altera outros mods e nao autoriza CEF nao testado.
    $modTouched = $true
    Invoke-Wh @('mod','install',$mod,'2.0','--disabled','--yes')
    Invoke-Wh @('mod','settings','set',$mod,'showframe=0','showcontrols=1','transparentrendering=1','blockupdates=0','allowuntested=0')
    Assert-Closed
    Invoke-Wh @('mod','enable',$mod)
    Invoke-Wh @('mod','show',$mod)
    Invoke-Wh @('mod','settings','get',$mod)
    Log 'Configuracao concluida. Feche esta janela e abra Spotify pelo atalho Spotify Visual.'
    Log 'Se a API nao estiver disponivel, o Visual continuara no modo normal.'
    [void](Read-Host 'Pressione Enter para fechar')
    exit 0
} catch {
    Log ('ERRO: ' + $_.Exception.Message)
    if ($modTouched -and $cli) {
        try { Invoke-Wh @('mod','disable',$mod); Log 'Mod desativado por seguranca.' }
        catch { Log 'Nao foi possivel desativar automaticamente. Desative CEF/Spotify Tweaks no Windhawk.' }
    }
    Log ('Log: ' + $log)
    [void](Read-Host 'Pressione Enter para fechar')
    exit 1
} finally {
    if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
