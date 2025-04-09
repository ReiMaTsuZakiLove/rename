<# : Batch部分
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% == 0 (
    goto :ADMIN_OK
) else (
    echo 正在请求管理员权限...
    powershell -Command "Start-Process -Verb RunAs -FilePath '%~f0'"
    exit /b
)

:ADMIN_OK

:: 执行内嵌的PowerShell脚本
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression $([System.IO.File]::ReadAllText('%~f0', [Text.Encoding]::UTF8))"

pause
exit /b
#>

# PowerShell脚本部分
$debugMode = $true

function Log-Info {
    param($message)
    Write-Host "[INFO] $message" -ForegroundColor Cyan
}

function Log-Error {
    param($message)
    Write-Host "[ERROR] $message" -ForegroundColor Red
}

function Show-Help {
    Write-Host "`nrename - 使用说明" -ForegroundColor Yellow
    Write-Host "===============================`n" -ForegroundColor Cyan

    Write-Host "这是一个给文件统一名字的脚本，本脚本的对象是同文件夹中所有的文件，建议新建一个文件夹将需要改名的文件和本脚本放在一起"
    Write-Host "示例都是脸滚键盘打出来的，并无任何意义，如果想要增加功能可以自己加,目前支持以下指令"
    Write-Host "---------------------------------" -ForegroundColor Cyan

    Write-Host "1. 普通删除模式" -ForegroundColor White
    Write-Host "   格式: [要删除的字符串]"
    Write-Host "   示例: 输入[ThZu.Cc]  "
    Write-Host "   [ThZu.Cc]abp-664 →abp-664 "
    Write-Host "   -------------------------------"
    
    Write-Host "2. 添加前缀 (-a)" -ForegroundColor White
    Write-Host "   格式: -a 前缀内容"
    Write-Host "   示例: 输入-a CTNOZ-  "
    Write-Host "   151→CTNOZ-151 "
    Write-Host "   -------------------------------"
    
    Write-Host "3. 删除首个匹配前内容 (-b)" -ForegroundColor White
    Write-Host "   格式: -b 删除第一组关键词及之前的所有内容 "
    Write-Host "   示例: -b あず希,  "
    Write-Host "   あず希,あず希が女性用バイ○グラとお酒を飲んでSEXしてみた →あず希が女性用バイ○グラとお酒を飲んでSEXしてみた"  
    Write-Host "   -------------------------------"
    
    Write-Host "4. 将文件名中的关键词A改为关键词B(-c)" -ForegroundColor White
    Write-Host "   格式: -c 原内容 新内容"
    Write-Host "   示例: -c 乙愛麗絲 乙アリス "
    Write-Host "   MVSD-504 乙愛麗絲 → MVSD-504 乙アリス "
    Write-Host "   -------------------------------"
    
    Write-Host "5. 从（第一个关键词A）到（第一个关键词B）之间包括关键词在内所有的字符都删除 (-ft)" -ForegroundColor White
    Write-Host "   格式: -c 起始符 结束符"
    Write-Host "   示例: 输入-ft []"
    Write-Host "   [ThZu.Cc]WANZ-152→WANZ-152  "
    Write-Host "   -------------------------------"

    Write-Host "通用功能说明：" -ForegroundColor Green
    Write-Host "---------------------------------" -ForegroundColor Cyan
    Write-Host "- 支持带空格参数（用引号包裹）"
    Write-Host "- 自动处理文件名冲突（自动添加序号）"
    Write-Host "- 排除系统保护文件（如pagefile.sys）"
    Write-Host "- 空文件名自动设置为'1'"
}

function Add-Prefix {
    param($o, $p)
    $p + $o
}

function Remove-TextBetween {
    param($o, $s, $e)
    $i = $o.IndexOf($s)
    $j = $o.IndexOf($e)
    if ($i -ge 0 -and $j -gt $i) {
        $o.Remove($i, $j - $i + 1)
    }
    else {
        $o
    }
}

function Remove-Before {
    param($o, $t)
    $i = $o.IndexOf($t)
    if ($i -ge 0) {
        $o.Substring($i + $t.Length)
    }
    else {
        $o
    }
}

function Replace-FirstOccurrence {
    param($o, $old, $new)
    if ([string]::IsNullOrEmpty($old)) { return $o }
    $escapedOld = [regex]::Escape($old)
    [regex]::Replace($o, $escapedOld, $new, 1)
}

function Safe-Replace {
    param($o, $p)
    if ([string]::IsNullOrEmpty($p)) { return $o }
    $o.Replace($p, '')
}

function Get-NewName {
    param($name, $cmd, $isFile)
    switch ($cmd.Type) {
        'add' { 
            $p = $cmd.Prefix -replace '[\\/:*?"<>|]', '_'
            if ($isFile) { 
                $n = [IO.Path]::GetFileNameWithoutExtension($name)
                $p + $n + [IO.Path]::GetExtension($name)
            }
            else { 
                $p + $name 
            }
        }
        'ft' { 
            $res = Remove-TextBetween $name $cmd.Param1 $cmd.Param2
            if ([string]::IsNullOrWhiteSpace($res)) { "1" } else { $res }
        }
        'before' {
            $res = Remove-Before $name $cmd.Target
            if ([string]::IsNullOrWhiteSpace($res)) { "1" } else { $res }
        }
        'change' {
            if ($isFile) {
                $nameWithoutExt = [IO.Path]::GetFileNameWithoutExtension($name)
                $extension = [IO.Path]::GetExtension($name)
                $newBase = Replace-FirstOccurrence $nameWithoutExt $cmd.OldStr $cmd.NewStr
                if ([string]::IsNullOrWhiteSpace($newBase)) {
                    "1" + $extension
                }
                else {
                    $newBase + $extension
                }
            }
            else {
                $res = Replace-FirstOccurrence $name $cmd.OldStr $cmd.NewStr
                if ([string]::IsNullOrWhiteSpace($res)) {
                    "1"
                }
                else {
                    $res
                }
            }
        }
        default { 
            if ($isFile) {
                $n = Safe-Replace ([IO.Path]::GetFileNameWithoutExtension($name)) $cmd.Pattern
                if ([string]::IsNullOrWhiteSpace($n)) {
                    "1" + [IO.Path]::GetExtension($name)
                }
                else {
                    $n + [IO.Path]::GetExtension($name)
                }
            }
            else {
                $res = Safe-Replace $name $cmd.Pattern
                if ([string]::IsNullOrWhiteSpace($res)) {
                    "1"
                }
                else {
                    $res
                }
            }
        }
    }
}

function Resolve-Conflicts {
    param($base, $ext, $isFile, $orig)
    $count = 1
    $new = $base + $ext
    while ((Test-Path $new) -and ($new -ne $orig)) {
        $new = "$base($count)$ext"
        $count++
    }
    $new
}

function Parse-Command {
    param($inputStr)
    $inputStr = $inputStr.Trim()
    if ([string]::IsNullOrEmpty($inputStr)) {
        Log-Error "输入不能为空"
        return $null
    }

    if ($inputStr -eq '-help') {
        return @{ Type = 'help' }
    }

    switch -regex ($inputStr) {
        '^-a\s+(.+)$' {
            $prefix = $matches[1].Trim(' ', '"', "'")
            if ($prefix -eq '') {
                Log-Error "前缀内容不能为空"
                return $null
            }
            return @{ Type = 'add'; Prefix = $prefix }
        }
        '^-b\s+(.+)$' {
            $target = $matches[1].Trim(' ', '"', "'")
            if ($target -eq '') {
                Log-Error "目标字符串不能为空"
                return $null
            }
            return @{ Type = 'before'; Target = $target }
        }
        '^-ft\s+([^\s]+)\s+([^\s]+)$' {
            $start = $matches[1].Trim(' ', '"', "'")
            $end = $matches[2].Trim(' ', '"', "'")
            if ($start -eq '' -or $end -eq '') {
                Log-Error "起始符和结束符不能为空"
                return $null
            }
            return @{ Type = 'ft'; Param1 = $start; Param2 = $end }
        }
        '^-c\s+([^\s]+)\s+(.*)$' {
            $oldStr = $matches[1].Trim(' ', '"', "'")
            $newStr = $matches[2].Trim(' ', '"', "'")
            if ($oldStr -eq '') {
                Log-Error "原内容不能为空"
                return $null
            }
            return @{ Type = 'change'; OldStr = $oldStr; NewStr = $newStr }
        }
        default {
            $pattern = $inputStr.Trim(' ', '"', "'")
            if ($pattern -eq '') {
                Log-Error "删除内容不能为空"
                return $null
            }
            return @{ Type = 'replace'; Pattern = $pattern }
        }
    }
}

# 主处理逻辑
$scriptName = [IO.Path]::GetFileName($MyInvocation.MyCommand.Path)
$batName = [IO.Path]::ChangeExtension($scriptName, "bat")
$exclude = @($scriptName, $batName, "pagefile.sys", "hiberfil.sys", "swapfile.sys")

do {
    $input = Read-Host "`n#基本功能调用指令
`n-a  # 添加前缀`n-b  # 删除首个匹配前内容`n-ft  # 删除区间内容`n-c  # 替换首个匹配项`n[字符串] # 普通删除模式`n-help     # 显示帮助
`n请输入指令"
    if ($input -eq 'exit') { break }
    
    $cmd = Parse-Command $input
    if (-not $cmd) { continue }

    if ($cmd.Type -eq 'help') {
        Show-Help
        continue
    }

    Get-ChildItem -LiteralPath $PWD -Force | Where-Object { 
        $_.Name -notin $exclude -and !$_.Attributes.HasFlag([IO.FileAttributes]::System)
    } | ForEach-Object {
        try {
            $newName = Get-NewName $_.Name $cmd ($_ -is [IO.FileInfo])
            if ($newName -eq $_.Name) { return }
            
            if ($_ -is [IO.FileInfo]) {
                $base = [IO.Path]::GetFileNameWithoutExtension($newName)
                $ext = [IO.Path]::GetExtension($newName)
            }
            else {
                $base = $newName
                $ext = ""
            }

            $final = Resolve-Conflicts $base $ext ($_ -is [IO.FileInfo]) $_.FullName
            Rename-Item -LiteralPath $_.FullName -NewName $final -Force
            Log-Info "已重命名: [$($_.Name)] → [$final]"
        }
        catch { 
            Log-Error "处理失败: $($_.Name) (错误: $($_.Exception.Message))" 
        }
    }
    
    Write-Host "`n操作完成！" -ForegroundColor Green
} while ($true)

Write-Host "`n程序已退出" -ForegroundColor Yellow    
