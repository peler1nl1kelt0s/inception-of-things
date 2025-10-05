    default: Branch 'master' set up to track remote branch 'master' from 'origin'.
    default: ✓ GitLab projesi başarıyla yapılandırıldı.
    default: 
    default: ### Adım 6: Argo CD Uygulaması Yapılandırılıyor ###
    default: Argo CD'de uygulama oluşturuluyor...
    default: application.argoproj.io/iot-app-from-local-gitlab created
    default: ✓ Argo CD uygulaması başarıyla yapılandırıldı.
    default: 
    default: #############################################################
    default: ###           KURULUM BAŞARIYLA TAMAMLANDI!              ###
    default: #############################################################
    default: 
    default: Arayüzlere Erişim Bilgileri:
    default:   GitLab Arayüzü:   http://gitlab.local:8080:8443
    default:     Kullanıcı Adı: root
    default:     Şifre: hAwRqz34aUDCfpXPAw4pYrbTpSv0m2dPzbYmUvGjsP8=
    default: 
    default:   Argo CD Arayüzü:  http://localhost:8081
    default:     Kullanıcı Adı: admin
    default:     Şifre: Px7rlXvSgTBFeb6h
    default: 
    default:   Uygulama:          http://localhost:8888
    default: 
    default: Kurulum tamamlandı! Argo CD'nin uygulamayı senkronize etmesi birkaç dakika sürebilir.


Failed to load target state: failed to generate manifest for source 1 of 1: rpc error: code = Unknown desc = failed to list refs: authentication required: HTTP Basic: Access denied. If a password was provided for Git authentication, the password was incorrect or you're required to use a token instead of a password. If a token was provided, it was either incorrect, expired, or improperly scoped. See http://172.17.0.1:8080/help/topics/git/troubleshooting_git.md#error-on-git-fetch-http-basic-access-denied


kod değişikliği yapıldı bu hatadan sonra ama make atılmadı