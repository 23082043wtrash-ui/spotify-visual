param([ValidateSet('Open','Safe','Install')][string]$Mode='Open')
$ErrorActionPreference='Stop'
$homeDir=Join-Path $env:LOCALAPPDATA 'SpotifyVisual'
$base='https://raw.githubusercontent.com/23082043wtrash-ui/spotify-visual/main/'
$log=Join-Path $homeDir 'atualizacoes.log'
$mod='cef-titlebar-enabler-universal'
$disabled=Test-Path (Join-Path $homeDir 'desativar-atualizacoes.txt')
function Log($m){Add-Content -LiteralPath $log -Encoding UTF8 -Value "$(Get-Date -Format s) $m"; Write-Host $m}
function Alert($m){Add-Type -AssemblyName System.Windows.Forms; [void][System.Windows.Forms.MessageBox]::Show([string]$m,'Spotify Visual 3.0.3','OK','Warning')}
function Running {return [bool](Get-Process Spotify -ErrorAction SilentlyContinue)}
function Find-Spice {
    $c=Get-Command spicetify.exe -ErrorAction SilentlyContinue
    if($c){return $c.Source}
    $p=Join-Path $env:LOCALAPPDATA 'spicetify\spicetify.exe'
    if(Test-Path -LiteralPath $p){return $p}
}
function Exec([string]$exe,[string[]]$argv,[switch]$AllowFail) {
    $ErrorActionPreference='Continue'
    Log ((Split-Path -Leaf $exe)+' '+($argv -join ' '))
    $output=@(& $exe @argv 2>&1)
    $code=$LASTEXITCODE
    foreach($line in $output){Log ([string]$line)}
    if($code -ne 0 -and -not $AllowFail){throw ("Falha: "+(Split-Path -Leaf $exe)+" "+($argv -join ' ')+" (codigo $code)")}
    return @{code=$code;text=($output -join "`n")}
}
function WhPath {
    $dirs=@($env:ProgramFiles,$env:ProgramW6432,[Environment]::GetEnvironmentVariable('ProgramFiles(x86)'))
    foreach($d in ($dirs|Where-Object {$_}|Select-Object -Unique)){
        $p=Join-Path $d 'Windhawk\windhawk-cli.exe'
        if(Test-Path -LiteralPath $p -PathType Leaf){return $p}
    }
}
function Wh([string[]]$argv,[switch]$AllowFail) {
    $write = ($argv.Count -ge 2 -and $argv[0] -eq 'mod' -and ($argv[1] -in @('install','update','enable','disable') -or ($argv[1] -eq 'settings' -and $argv.Count -ge 4 -and $argv[2] -eq 'set')))
    if(-not $write){return (Exec $script:wh $argv -AllowFail:$AllowFail)}
    # Only elevate the official installed CLI, never the downloaded manager.
    $idIndex = if($argv[1] -eq 'settings'){3}else{2}
    if($argv.Count -le $idIndex -or $argv[$idIndex] -cne 'cef-titlebar-enabler-universal'){throw 'Operacao Windhawk nao autorizada.'}
    foreach($arg in $argv){if($arg -notmatch '^[a-zA-Z0-9_.=-]+$'){throw 'Argumento Windhawk invalido.'}}
    $official=WhPath
    if(-not $official -or $official -ine $script:wh){throw 'CLI oficial do Windhawk nao encontrada.'}
    if(Running){throw 'Feche o Spotify antes de alterar o mod.'}
    Log ('Windhawk (UAC): '+($argv -join ' '))
    try{
        $p=Start-Process -FilePath $official -ArgumentList $argv -WorkingDirectory (Split-Path -Parent $official) -Verb RunAs -Wait -PassThru
        $code=$p.ExitCode
    }catch{
        Log ('Autorizacao Windows falhou: '+$_.Exception.Message)
        if(-not $AllowFail){throw}
        return @{code=1223;text='Autorizacao nao concedida ou falha ao iniciar Windhawk.'}
    }
    Log ("Windhawk (UAC) codigo $code")
    if($code -ne 0 -and -not $AllowFail){throw ('Windhawk falhou mesmo com autorizacao (codigo '+$code+'). Consulte o log.')}
    return @{code=$code;text=''}
}
function Setup-Wh {
    $stamp=Join-Path $homeDir 'windhawk-check-302.txt'
    $ready=Join-Path $homeDir 'windhawk-configurado-3.txt'
    $script:wh=WhPath
    $due=(-not(Test-Path $stamp)) -or ((Get-Date)-(Get-Item $stamp -ErrorAction SilentlyContinue).LastWriteTime).TotalHours -ge 24
    if($Mode -eq 'Install'){$due=$true}
    if(-not $due -and (Test-Path $ready) -and $script:wh){return}
    if(-not $due -and $Mode -ne 'Install'){return}
    Set-Content -LiteralPath $stamp -Value (Get-Date -Format o)
    if(Running){return}
    try {
        if(-not $script:wh){
            $dir=Join-Path $env:TEMP ('SV-WH-'+[guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $dir|Out-Null
            try{
                $exe=Join-Path $dir 'windhawk_setup.exe'
                Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/ramensoftware/windhawk/releases/download/2.0.0-alpha.8/windhawk_setup.exe' -OutFile $exe -TimeoutSec 180
                if((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ine '7327471e2d93a8c58481321cce546632adb146cf125d17d7144d0e7d2a064967'){throw 'Hash do instalador Windhawk divergente.'}
                if(Running){throw 'Spotify aberto durante a preparacao.'}
                $p=Start-Process -FilePath $exe -ArgumentList '/S','/STANDARD' -Verb RunAs -Wait -PassThru
                if($p.ExitCode -ne 0){throw "Instalador Windhawk: $($p.ExitCode)"}
            }finally{Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue}
            $script:wh=WhPath
            if(-not $script:wh){throw 'CLI Windhawk nao encontrada.'}
            Remove-Item -LiteralPath $ready -Force -ErrorAction SilentlyContinue
        }
        if(Running){throw 'Feche Spotify antes de configurar o mod.'}
        # Read-only checks; use the official CLI, never elevate a downloaded PS1.
        $status=Wh @('mod','show',$mod) -AllowFail
        $changed=$false
        if($status.code -eq 4){
            [void](Wh @('mod','install',$mod,'2.0','--disabled','--yes'))
            $changed=$true
        }elseif($status.code -ne 0){throw 'Nao foi possivel consultar o mod.'}
        elseif($due -and (Test-Path $ready)){
            $updates=Wh @('mod','list','--update-available')
            if($updates.text -match [regex]::Escape($mod)){
                [void](Wh @('mod','update',$mod,'--disabled','--yes'))
                $changed=$true
            }
        }
        if($changed -or -not(Test-Path $ready) -or $Mode -eq 'Install'){
            [void](Wh @('mod','settings','set',$mod,'showframe=0','showcontrols=1','transparentrendering=1','blockupdates=0','allowuntested=0'))
            [void](Wh @('mod','enable',$mod))
            Set-Content -LiteralPath $ready -Value 'ok'
        }
        # Check engine status via the official CLI; engine installation is managed by Windhawk.
        [void](Wh @('update','status') -AllowFail)
    }catch{
        Remove-Item -LiteralPath $ready -Force -ErrorAction SilentlyContinue
        Log ('Windhawk: '+$_.Exception.Message)
        if($script:wh){try{$check=Wh @('mod','show',$mod) -AllowFail;if($check.code -eq 0){$disabledMod=Wh @('mod','disable',$mod) -AllowFail;if($disabledMod.code -ne 0){Log 'Nao foi possivel desativar o mod; confira o Windhawk.'}}}catch{}}
        Alert ('Windhawk nao configurado. O Spotify Visual tentara continuar no modo normal. '+$_.Exception.Message)
    }
}
$spotify=Join-Path $env:APPDATA 'Spotify\Spotify.exe'
$apps=Join-Path (Split-Path -Parent $spotify) 'Apps'
$script:wh=$null
$spice=$null
$pending=$false
$backup=$null
$dest=$null
try{
    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
    if(-not(Test-Path -LiteralPath $spotify)){throw 'Spotify desktop nao encontrado na pasta padrao. Use a versao oficial de spotify.com/download.'}
    if(Running){
        if($Mode -ne 'Open'){throw 'Feche o Spotify completamente, inclusive na bandeja.'}
        Start-Process -FilePath $spotify
        exit 0
    }
    $spice=Find-Spice
    if($Mode -eq 'Safe'){
        $script:wh=WhPath
        if($script:wh){
            $r=Wh @('mod','disable',$mod) -AllowFail
            if($r.code -notin @(0,4)){Alert 'Nao foi possivel desativar o mod. Desative CEF/Spotify Tweaks no Windhawk se houver problema.'}
        }
        Remove-Item -LiteralPath (Join-Path $homeDir 'windhawk-configurado-3.txt') -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath (Join-Path $homeDir 'windhawk-check-302.txt') -Force -ErrorAction SilentlyContinue
        if($spice -and -not(Test-Path (Join-Path $apps 'xpui.spa'))){[void](Exec $spice @('restore'))}
        Start-Process -FilePath $spotify
        exit 0
    }
    if(-not $spice){
        $winget=Get-Command winget.exe -ErrorAction SilentlyContinue
        if(-not $winget){throw 'WinGet indisponivel. Instale Spicetify pelo site oficial.'}
        [void](Exec $winget.Source @('install','--id','Spicetify.Spicetify','--exact','--source','winget','--accept-package-agreements','--accept-source-agreements','--disable-interactivity'))
        $spice=Find-Spice
        if(-not $spice){throw 'Spicetify instalado, mas o terminal precisa ser reaberto.'}
    }
    if(-not $disabled){
        $spiceStamp=Join-Path $homeDir 'spicetify-check-3.txt'
        $v=(Get-Item -LiteralPath $spotify).VersionInfo.FileVersion
        $prev=if(Test-Path $spiceStamp){Get-Content -LiteralPath $spiceStamp -Raw}else{''}
        if($Mode -eq 'Install' -or $prev.Trim() -ne $v -or ((Get-Date)-(Get-Item $spiceStamp -ErrorAction SilentlyContinue).LastWriteTime).TotalHours -ge 24){
            try{
                if($spice -ieq (Join-Path $env:LOCALAPPDATA 'spicetify\spicetify.exe')){[void](Exec $spice @('upgrade','--no-restart') -AllowFail)}
                elseif($spice -match '\\WinGet\\' -and (Get-Command winget.exe -ErrorAction SilentlyContinue)){[void](Exec (Get-Command winget.exe).Source @('upgrade','--id','Spicetify.Spicetify','--exact','--source','winget','--silent','--disable-interactivity') -AllowFail)}
                $spice=Find-Spice
            }catch{Log ('Spicetify update: '+$_.Exception.Message)}
            Set-Content -LiteralPath $spiceStamp -Value $v
        }
        # Preserve an already working mod; only provision when absent.
        $script:wh=WhPath
        if($script:wh){$status=Wh @('mod','show',$mod) -AllowFail;if($status.code -ne 0){Setup-Wh}}else{Setup-Wh}
    }
    if(Running){throw 'Feche Spotify para aplicar as atualizacoes.'}
    $cfg=Join-Path $env:APPDATA 'spicetify\config-xpui.ini'
    $cp=@(& $spice -c 2>$null)
    foreach($line in $cp){if(Test-Path -LiteralPath ([string]$line).Trim() -PathType Leaf){$cfg=([string]$line).Trim();break}}
    $ext=Join-Path (Split-Path -Parent $cfg) 'Extensions'
    New-Item -ItemType Directory -Path $ext -Force|Out-Null
    $dest=Join-Path $ext 'spotify-visual.js'
    $state=Join-Path $homeDir 'visual-release.json'
    $installed=Join-Path $apps 'xpui\extensions\spotify-visual.js'
    $m=$null
    Log ('Gerenciador 3.0.3; arquivo fonte: '+$dest)
    if(-not $disabled){
        $tmp=Join-Path $homeDir ('ext-'+[guid]::NewGuid().ToString('N')+'.js')
        try{
            $m=Invoke-RestMethod -Uri ($base+'update.json?check='+[guid]::NewGuid().ToString('N')) -TimeoutSec 15 -MaximumRedirection 0
            Log ('Versao disponivel: '+$m.version)
            if($m.file -cne 'spotify-visual.js' -or $m.sha256 -notmatch '^[0-9a-fA-F]{64}$' -or $m.version -notmatch '^\d+\.\d+\.\d+$'){throw 'Manifesto da extensao invalido.'}
            $old=if(Test-Path $state){try{[version](Get-Content $state -Raw|ConvertFrom-Json).version}catch{[version]'0.0.0'}}else{[version]'0.0.0'}
            $actual=if(Test-Path $dest){(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash}else{''}
            if([version]$m.version -ge $old -and $actual -ine $m.sha256){
                Invoke-WebRequest -Uri ($base+'spotify-visual.js?sha='+$m.sha256) -UseBasicParsing -OutFile $tmp -TimeoutSec 30 -MaximumRedirection 0
                if((Get-Item $tmp).Length -gt 1048576 -or (Get-FileHash $tmp -Algorithm SHA256).Hash -ine $m.sha256){throw 'Integridade da extensao invalida.'}
                if(Test-Path $dest){$backup=Join-Path $homeDir 'extensao-anterior.js';Copy-Item $dest $backup -Force}
                Copy-Item $tmp $dest -Force
                $pending=$true
                Log ('Extensao baixada e verificada: '+$m.version)
            }
        }catch{Log ('Extensao: '+$_.Exception.Message);Alert ('Nao foi possivel buscar a atualizacao: '+$_.Exception.Message+'. A copia local sera usada.');$m=$null}
        finally{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}
    }
    if(-not(Test-Path $dest)){throw 'Extensao indisponivel. Verifique a conexao e tente novamente.'}
    $register = -not(Test-Path $cfg) -or (Get-Content $cfg -Raw) -notmatch '(?m)^\s*extensions\s*=.*spotify-visual\.js'
    if($register){
        if(Test-Path $cfg){Copy-Item $cfg (Join-Path $homeDir 'config-antes-3.ini') -Force}
        [void](Exec $spice @('config','extensions','spotify-visual.js'))
    }
    if(Running){throw 'Feche Spotify antes de atualizar a extensao.'}
    # Auto only prepares an unmodified Spotify; it may skip already applied assets.
    [void](Exec $spice @('auto','--no-restart'))
    $sourceHash=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash
    $installedHash=if(Test-Path -LiteralPath $installed){(Get-FileHash -LiteralPath $installed -Algorithm SHA256).Hash}else{''}
    if($register){
        [void](Exec $spice @('apply','--no-restart'))
    }elseif($sourceHash -ine $installedHash){
        Log 'Copia ativa diferente da fonte; atualizando extensoes explicitamente.'
        [void](Exec $spice @('refresh','-e','--no-restart'))
    }
    if(-not(Test-Path -LiteralPath $installed) -or (Get-FileHash -LiteralPath $installed -Algorithm SHA256).Hash -ine $sourceHash){
        throw 'A copia ativa do Spotify nao corresponde a extensao local.'
    }
    if($m -and $sourceHash -ieq $m.sha256){
        @{version=[string]$m.version;sha256=$m.sha256}|ConvertTo-Json|Set-Content -LiteralPath $state -Encoding UTF8
        Log ('Extensao aplicada e verificada: '+$m.version)
    }else{Log ('Copia local aplicada e verificada: '+$sourceHash)}
    Start-Process -FilePath $spotify
    exit 0
}catch{
    Log ('ERRO: '+$_.Exception.Message)
    if($pending -and $backup -and (Test-Path $backup)){Copy-Item $backup $dest -Force;Log 'Extensao anterior restaurada no disco.'}
    Alert ('Falha detectada: '+$_.Exception.Message+'. Use o atalho Spotify Visual - modo seguro se necessario. Log: '+$log)
    exit 1
}
