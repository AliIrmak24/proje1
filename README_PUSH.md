Kılavuz: Tüm kodu https://github.com/AliIrmak24/proje1 deposuna gönderme

1) Gereksinimler
- Bu makinada `git` kurulu olmalı.
- GitHub HTTPS push için kullanıcı adı/parola ya da Personal Access Token (PAT) gereklidir.

2) Otomatik betik (önerilen)
- PowerShell'de proje kökünde şu komutu çalıştırın:

```
.\push_to_github.ps1
```

- Betik bir git deposu başlatır (gerekiyorsa), tüm dosyaları ekler, commit yapar ve `origin` adlı uzak olarak `https://github.com/AliIrmak24/proje1.git` ekleyip `main` dalına gönderir.

3) Manuel adımlar (isteğe bağlı)
- Terminalde proje kökünde çalıştırın:

```
git init
git add -A
git commit -m "Initial commit from local workspace"
git remote add origin https://github.com/AliIrmak24/proje1.git
git branch -M main
git push -u origin main
```

4) Notlar
- Eğer push sırasında kimlik doğrulama istenirse, GitHub kullanıcı adınızı ve PAT girin.
- Eğer uzak depo boş değilse ya da farklı bir geçmiş varsa, `--force` kullanmadan önce dikkatli olun.
