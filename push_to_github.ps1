# Push all project files to the given GitHub repo
# Usage: Open PowerShell in repository root and run: .\push_to_github.ps1

$remote = 'https://github.com/AliIrmak24/proje1.git'

Write-Host "Remote repository: $remote"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git yüklü değil. Lütfen Git'i yükleyin: https://git-scm.com/downloads"
    exit 1
}

try {
    & git rev-parse --is-inside-work-tree > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Git deposu bulunamadı. 'git init' yapılıyor..."
        git init
    } else {
        Write-Host "Mevcut git deposu bulundu."
    }

    Write-Host "Değişiklikler ekleniyor..."
    git add -A

    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    git commit -m "Commit from local workspace: $now" --allow-empty | Out-Null

    # Remove existing origin if present and add the provided remote
    $remoteExists = git remote | Select-String -Pattern "^origin$" 2>$null
    if ($remoteExists) {
        Write-Host "Varolan 'origin' uzaktan kaldırılıyor ve yeniden ekleniyor..."
        git remote remove origin
    }
    git remote add origin $remote

    # Ensure main branch
    git branch -M main

    Write-Host "Pushing to $remote (main)..."
    git push -u origin main

    Write-Host "İşlem tamamlandı."
} catch {
    Write-Error "Bir hata oluştu: $_"
    exit 1
}
