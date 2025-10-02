# KURULUM TAMAMLANDI!

Tebrikler, tüm altyapı başarıyla kuruldu. İşte sonraki adımlar:

## 1. Hosts Dosyasını Yapılandır (Zaten Yaptınız)
```
127.0.0.1 gitlab.local argocd.local
```

## 2. GitLab'e Erişin
- **Adres:** [https://gitlab.local:8443](https://gitlab.local:8443)
- Tarayıcınız bir güvenlik uyarısı verecektir. Bu normaldir. Güvenli olmadığını kabul edip devam edin.
- **Kullanıcı adı:** `root`
- **Şifre:** Sanal makineye `make ssh` ile bağlanıp şu komutu çalıştırın:
  ```bash
  kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 -d
  ```

## 3. Argo CD'ye Erişin
- **Adres:** [http://argocd.local:8081](http://argocd.local:8081)
- **Kullanıcı adı:** `admin`
- **Şifre:** Sanal makineye `make ssh` ile bağlanıp şu komutu çalıştırın:
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  ```
