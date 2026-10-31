# Motive — Önceliklendirilmiş Ürün Yol Haritası

> Kaynak: kod tabanı envanteri (Ekim 2026) + paylaşılan öneri listesi.
> Sıralama ölçütü: **hızlı kazanımlar önce** (düşük risk → çabuk teslim → kullanıcıya hemen görünür).
> Tahmin birimleri: **S** ≈ 0.5–1 gün, **M** ≈ 2–4 gün, **L** ≈ 1–2 hafta (tek geliştirici).

## İlerleme Durumu

| Faz | Durum | Doğrulama |
|---|---|---|
| Faz 0 — Hızlı kazanımlar (0.1-0.8) | ✅ Tamamlandı | `flutter analyze` temiz, 15/15 test |
| Faz 1 — 4 arena + 24 kart | ✅ Tamamlandı | 48 kart / 8 arena invariant testi, 16/16 test |
| Faz 2 — Elde tutma (özet, başarım, paylaşım) | ✅ Tamamlandı | `flutter analyze` temiz, 16/16 test |
| Faz 4 — Analyzer | ⬜ Bekliyor | |
| Faz 3 — Zorluk & çoklu mod | ⬜ Bekliyor | |
| Faz 5 — Altyapı (CI, test, crash) | ⬜ Bekliyor | |
| Faz 6 — Büyük yatırımlar (i18n, tablet, backend) | ⬜ Bekliyor | |

---


## 0. Mevcut Durum — Envantervi Bulguları (önemli sapmalar)

Öneri listesi "mevcut 4 alan / 24 kart" diyor, kod ise şunu gösteriyor:

| Bulgu | Kanıt |
|---|---|
| **8 arena tanımlı, 4'ü boş** | `lib/features/game/data/datasources/card_catalog_datasource.dart:21-30` → `rc, ms, mm, ng, wp, dg, hl, sp`; kartlar yalnız `rc/ms/mm/ng` içinde (satır 55-183) |
| Boş arenaların UI'da renk yok | `lib/features/game/presentation/widgets/card_styles.dart:62-67` → `_colors` sadece 4 id; diğerleri mor fallback |
| Kart toplamı 24, **test'e sabitlenmiş** | `test/features/game/game_bloc_test.dart:47` → `hasLength(24)` |
| Arena listesi dinamik (UI otomatik genişler) | `collection_page.dart:86,142`, `onboarding_page.dart:271`, `me_page.dart:71,108` |
| Cevap modu ikili (holds/doesn't hold) | `game_bloc.dart:37-43`, `case_card.dart:243,245` |
| Süre/zorluk altyapısı **yok** | projede timer/countdown eşleşmesi yok |
| XP, seri (`streak()`), aktif gün var; **başarım/challenge/haftalık takip yok** | `player_progress.dart:46-91` |
| Ayarlar: tema(dark/light), hatırlatıcı, arena, isim, API key | `app_settings.dart:5-26` |
| **Bildirim saati sabit 08:00** | `app_constants.dart:14`, `notification_service.dart:70` |
| `SoundService.enabled` var ama **UI anahtarı yok** | `sound_service.dart:14`; `me_page.dart:56-96`'da ses satırı yok |
| Analyzer: Claude + offline (12 kural), geçmiş limiti 30 | `claude_analyzer_datasource.dart`, `offline_analyzer_datasource.dart:28-142`, `app_constants.dart:22` |
| **Dışa aktarma / çeviri / URL / paylaşım yok** | `share_plus`, `pdf`, `url_launcher` pubspec'te yok |
| Avatar fotoğrafı **yok** (yalnızca initial harfi) | `me_page.dart:130-148` |
| Koleksiyonda filtre **var**, sıralama ve arama **yok** | `collection_page.dart:132-178` |
| Tema "system" seçeneği, i18n, landscape/tablet **yok** | `AppThemeMode {dark, light}`; `intl`/`l10n` yok; `OrientationBuilder` 0 eşleşme |
| Shimmer/skeleton **yok** | yalnız `CircularProgressIndicator.adaptive` |
| Test: 4 dosya (repository, bloc, planner, offline analyzer) | widget/bloc/settings/analyzer testleri yok |
| **CI/CD, Crashlytics/Sentry, Analytics yok** | `.github/` 0 dosya, pubspec.lock'ta paket yok |

---

## Faz 0 — Hızlı Kazanımlar (1–2 hafta, düşük risk, hemen görünür)

Bu fazda yeni mimari, yeni Hive alanı veya yeni paket bağımlılığı gerekmez.

| # | Öneri | Ne yapılacak | Dokunulacak dosyalar | Çaba | Etki |
|---|---|---|---|---|---|
| 0.1 | **Ses açma/kapama anahtarı** | `SoundService.enabled`'ı Settings'e bağla: `AppSettings.soundEnabled` alanı + `SettingsBloc` event + `me_page`'e satır ekle | `app_settings.dart`, `settings_model.dart`, `settings_bloc.dart`, `sound_service.dart`, `me_page.dart` | S | Orta (sessiz kullanıcı talebi) |
| 0.2 | **Bildirim saati seçimi** | `reminderHour`/`reminderMinute` alanına taşı, `showTimePicker` ile seçim, bildirimi yeniden planla | `app_constants.dart:14`, `app_settings.dart`, `notification_service.dart:65-71`, `me_page.dart:63` | S | **Yüksek** |
| 0.3 | **Tema: "System" seçeneği** | `AppThemeMode`'a `system` ekle, `app.dart:38-44`'te `ThemeMode.system` kullan | `app_settings.dart:3`, `settings_model.dart` (adapter'a 1 değer), `app.dart`, `me_page.dart:412` | S | Orta |
| 0.4 | **Koleksiyonda sıralama** | Rarity / alan / toplanma tarihine göre sıralama (collected map'i `DateTime` tutuyor, veri hazır) | `collection_cubit.dart`, `collection_page.dart:101-178` | S | **Yüksek** |
| 0.5 | **Koleksiyonda arama** | `TextField` + isim/alan filtresi (sayfada hiç `TextField` yok) | `collection_page.dart` | S | Orta |
| 0.6 | **Haptic çeşitlendirmesi** | Doğru cevap / yanlış / legendary açılışı / seviye atlama için ayrı `HapticFeedback` desenleri | `case_card.dart`, `celebration.dart`, `unlock_overlay.dart` | S | Düşük-Orta |
| 0.7 | **Daha açıklayıcı hata mesajları** | `failures.dart` mesajlarını kullanıcı-dostu metin + kurtarma aksiyonuna çevir; analyzer hatalarında "API key ekle / offline'a dön" eylemi | `core/error/failures.dart`, `analyzer_page.dart`, `feed_page.dart:33` | S | Orta |
| 0.8 | **Shimmer/skeleton loading** | `CircularProgressIndicator.adaptive()` yerine kart iskeletleri | `feed_page.dart:33`, `collection_page.dart:32`, `me_page.dart:30` | S | Orta |
| 0.9 | **Erişilebilirlik temeli** | Semantics ekle (pressable ve tab_bar dışında hiçbir kullanımı yok), büyük yazı/high-contrast ayarı | `core/widgets/*`, `case_card.dart`, `collectible_card.dart` | M | Düşük (ama Play Store puanı için değerli) |

**Faz 0 toplam: ≈ 4–7 gün.** Toplam etki/çabuk oranı en yüksek paket.

### Faz 0 — Uygulanan sonuç

| Madde | Sonuç |
|---|---|
| 0.1 Ses anahtarı | ✅ `AppSettings.soundEnabled` + Hive `f[8]` (geriye uyumlu), `SoundToggled` event, Bloc `SoundService.enabled`'ı senkronluyor, Me sayfasında satır |
| 0.2 Bildirim saati | ✅ `reminderHour/Minute` + `ReminderRequest` + `RescheduleReminder` usecase, `scheduleDailyDrop(hour:, minute:)`, Me'de `showTimePicker`, feed'deki sabit "8:00" kaldırıldı |
| 0.3 Tema "System" | ✅ `AppThemeMode.system` (adapter string tabanlı → migrasyon gerekmedi), `ThemeMode.system`, Me'de Dark/Light/**Auto** |
| 0.4 + 0.5 Sıralama & arama | ✅ `CollectionSort{number,rarity,recent,arena}` + arama (soru/kuvvet/no/arena adı) + "N SHOWN" + boş sonuç ekranı |
| 0.6 Haptic | ✅ `core/services/haptics.dart` → `swipe/wrong/correct(tier)/unlock(tier)/celebrate/denied/tap`; Pressable, çipler, kilitli kart |
| 0.7 Hata mesajları | ✅ `Failure.hint`; analyzer hata kutusunda ikon + hint + **Try again / Add a Claude key**; feed hata ekranına açıklama |
| 0.8 Shimmer | ✅ `core/widgets/skeleton.dart` (`Skeleton`, `SkeletonCard`, `SkeletonLines`); feed + koleksiyon grid + Me |

> Not: Faz 0.9 (erişilebilirlik) bu turda kapsam dışı bırakıldı.


---

## Faz 1 — İçerik Genişlemesi: 4 Boş Arena + 24 Kart (1 hafta)

Öneri listesindeki "yeni arenalar" aslında **yarı hazır**: `wp/dg/hl/sp` zaten `_fields` içinde, sadece kartları yok. Bu, işin maliyetini ciddi düşürüyor.

| # | Görev | Detay | Çaba |
|---|---|---|---|
| 1.1 | **4 arenaya 6'şar kart yaz** (24 yeni kart, toplam 48) | `card_catalog_datasource.dart` → `_cards` listesine `_k(...)` ekle; `number` alanları 25-48, nadirlik dağılımını mevcut dengede tut (24 kartta 8 common/7 rare/6 epic/**3 legendary**) | M (içerik üretimi ana iş) |
| 1.2 | **Legendary sayısını artır** | Her yeni arenaya 1 legendary + mevcut arenalara 1'er tane ekle (hedef toplam 7-8) | S |
| 1.3 | **Arena renklerini tamamla** | `card_styles.dart:62-67` → `wp/dg/hl/sp` için 4 renk ekle (şu an mor fallback) | S |
| 1.4 | **Varsayılan arena sabitlerini gözden geçir** | `app_settings.dart:10` (`['ms','mm']`), `onboarding_cubit.dart:11,41` — yeni arenaları onboarding seçimine serpiştir | S |
| 1.5 | **Testi güncelle** | `game_bloc_test.dart:47` → `hasLength(24)` **kırılacak**; `hasLength(48)` yap + arena başına 6 kart assert'i ekle | S |
| 1.6 | **Uzmanlık eşiklerini doğrula** | `player_progress.dart:17-23` (`cardsPerField=6` sabit, `app_constants.dart:8`) — yeni arenalarda `expert` rozeti otomatik çalışır, ekstra iş yok | S |

**Faz 1 toplam: ≈ 4–6 gün.** İçerik ekledikçe DropPlanner otomatik olarak yeni kartları havuza katar (`drop_planner.dart:19-64`), ek altyapı gerekmez.

### Faz 1 — Uygulanan sonuç

| Madde | Sonuç |
|---|---|
| 1.1 4 arenaya 6'şar kart | ✅ `wp1-6`, `dg1-6`, `hl1-6`, `sp1-6` → numaralar 25-48, toplam **48 kart / 8 arena** |
| 1.2 Legendary artırımı | ✅ **3 → 8**. Yeni arenalarda 1'er tane + `ms3` epic→legendary (ms arenasının legendary'sı yoktu). Dağılım: 16 common / 15 rare / 9 epic / 8 legendary |
| 1.3 Arena renkleri | ✅ `card_styles.dart` → wp `#8B9CFF`, dg `#5CD8FF`, hl `#FF6E6E`, sp `#FFD24F` |
| 1.4 Varsayılan arena sabitleri | ✅ Tek nokta: `AppConstants.defaultPickedFields = ['ms','mm','wp']` (3 yerdeki kopya birleştirildi) |
| 1.5 Test güncellemesi | ✅ `hasLength(24)` → 48 + arena başına 6 kart assert'i; `drop_planner_test` review havuzu 22→46 |
| 1.6 Uzmanlık eşikleri | ✅ `cardsPerField = 6` zaten 8 arena ile de doğru; yeni invariant testi bunu koruyor |

Yeni kalıcı test: `test/features/game/catalog_invariants_test.dart`
(8 arena × 6 kart, id/numara benzersizliği, her arenada ≥1 legendary, her kartta hypothesis/why dolu).


> **Not:** Legendary kart artışı + yeni arenalar, kart paylaşım (Faz 3) ve haftalık görevler (Faz 2) için ham madde sağlar → **Faz 1, 2 ve 3'ün ön koşulu**.

---

## Faz 2 — Elde Tutma: Başarımlar, Haftalık Özet, Meydan Okumalar (1–2 hafta)

Yeni Hive alanı ve `PlayerProgress` genişletmesi gerektirir → Faz 0'dan sonra, ama içerikle eşzamanlı başlanabilir.

| # | Öneri | Ne yapılacak | Çaba |
|---|---|---|---|
| 2.1 | **Haftalık özet** | `PlayerProgress` içinde `activeDays` zaten gün anahtarı tutuyor (`player_progress.dart:51`) → `DayKey` üzerinden doğruluk/toplanan kart/en iyi arena hesapla, `me_page`'e kart ekle (7 günlük şerit `me_page.dart:181-259` hâlihazırda var, üzerine inşa et) | M |
| 2.2 | **Başarımlar (rozetler)** | `Achievement` entity + `Hive` typeId (yeni typeId `6`, `hive_constants.dart:11-18`) + `achievements` anahtarı. Koşullar: ilk kart, 10 günlük seri, tüm Money Mind kartları, 48/48 koleksiyon | M |
| 2.3 | **Haftalık/aylık meydan okumalar** | "Bu hafta 50 kart topla", "3 gün üst üste doğru cevap" → hafta başı (`DayKey.startOfWeek`) sıfırlanan sayaçlar + ödül XP | M |
| 2.4 | **Kartlara kişisel not** | `MotiveCard`'a değil, ayrı `cardNotes` map'i (katalog kartı immutable kalmalı) → Hive `game_box`'a `cardNotes` anahtarı; `card_detail_overlay.dart`'a not alanı | M |
| 2.5 | **Profil fotoğrafı** | `image_picker` zaten pubspec'te (`^1.2.3`), analyzer'da kullanılıyor → `me_page.dart:130-148` daire içine `Image.file` + `Hive`'e byte/path sakla | S |
| 2.6 | **Kart paylaşma (screenshot/share)** | `RepaintBoundary` + `toImage` ile kartı PNG'e çevir, `share_plus` ile paylaş → `collectible_card.dart`/`card_detail_overlay.dart`'a paylaş butonu. **Yeni paket:** `share_plus` | M |

**Faz 2 toplam: ≈ 8–13 gün.**
**Kritik bağımlılık:** 2.4–2.6 Hive şemasına yazıyor → **2.1–2.6'dan önce `Hive` migration/versiyonlama stratejisini belirle** (mevcut `progress` typeId 3'ü genişletmek yerine yeni anahtar kullanmak en güvenlisi).

### Faz 2 — Uygulanan sonuç

Şema stratejisi: **yeni alan indeksi** (`f[6..f[8]`) + **yeni kutu anahtarı** (`card_notes`) + yeni paket `share_plus`. Eski kayıtlar okunmaya devam eder (eksik alanlar varsayılana düşer).

| Madde | Sonuç |
|---|---|
| 2.1 Haftalık özet | ✅ `DayStat` (gün başına cevap/doğru/XP) `ProgressModel.f[6]` + `PlayerProgress.weekOf()` → `WeekSummary` (kart, doğru/cevap, doğruluk, XP, aktif gün, öne çıkan arena). Me sayfasına **THIS WEEK** kartı; günlük kova 90 günde bir kırpılıyor |
| 2.2 Başarımlar | ✅ `domain/services/achievements.dart` → 14 rozet (tier'lı), koşullar saf fonksiyon → yeni sürümde eklenen rozet geçmişte hak edenlere ilk açılışta düşer (`getProgress`'te evaluate). Kazanılanlar `f[7]`, Me'de rozet duvarı + "See all" sheeti, kazanıldığında snackbar kutlaması |
| 2.3 Haftalık meydan okumalar | ✅ `domain/services/challenges.dart` → haftalık 3 hedef (10 kart / 25 doğru / 5 gün), pazartesi bazlı kimlik (`week:...`), ödül XP `claimedChallenges` (`f[8]`) ile bir kez ödenir. Me'de **WEEKLY GOALS** kartı, animasyonlu ilerleme çubukları |
| 2.4 Kart notu | ✅ Karta değil ayrı `HiveKeys.notes` (`card_notes`) → `GameLocalDataSource.getNotes/saveNote` + `GetNotes/SaveNote` usecase + `GameBloc.notes` / `CardNoteSaved`; kart detay overlay'inde not alanı (kapanışta kaydedilir). **Reset notları silmez** |
| 2.5 Profil fotoğrafı | ✅ `AppSettings.avatar` (`Uint8List`, Hive `f[9]`, eski kayıtta null → initial harfi), `AvatarChanged` event, Me'deki daireye dokununca kütüphane/kamera alt sayfası + kaldırma; 640px/quality 78 küçültme |
| 2.6 Kart paylaşma | ✅ Yeni paket **`share_plus`**; kart detayında `RepaintBoundary` → `toImage` → PNG → paylaş sayfası ("Force · Arena" metniyle), haptic + hata snackbar'ı |

Ek: `AnswerOutcome` artık `achievements` ve `challenges` taşıyor; `app.dart` bunları "Achievement · … / Goal complete · …" olarak kutluyor.

---

## Faz 3 — Oyun Derinliği: Zorluk ve Çoklu Mod (1–2 hafta)

Zorluk/timer ve yeni cevap modu, oyun mantığına en derin dokunuş → **test ağı olmadan girme.**

| # | Öneri | Ne yapılacak | Çaba |
|---|---|---|---|
| 3.1 | **Zorluk seviyeleri** | `AppSettings.difficulty {easy, normal, hard}`. Kolay: ipucu (`card`'daki `why` erken gösterilir). Zor: `case_card.dart`'a geri sayım (mevcut 2 sn failsafe `case_card.dart:114` üzerine inşa). **Timer altyapısı sıfırdan** | M |
| 3.2 | **Çoktan seçmeli mod** | `answerCase` imzası `bool saysHolds` yerine enum `Answer`'a genişletmeli (`game_repository.dart:17`, `game_repository_impl.dart:82`, `game_bloc.dart:37-43`) → **kayıcı ve Hive `CaseAnswer` (typeId 1) uyumluluğu** | M-L |
| 3.3 | **Eşleştirme modu** | Kart ↔ psikolojik kuvvet eşleştirme; `MotiveCard.force` alanı zaten var (`motive_card.dart`) | M |

**Faz 3 toplam: ≈ 8–14 gün.**
**Risk:** `answerCase(bool)` imzasını değiştirmek repository + bloc + Hive `CaseAnswer` + 4 test dosyasını etkiler. Önce 3.1'i (sadece UI) yap, 3.2-3.3 için ayrı sprint planla.

---

## Faz 4 — Analyzer Geliştirmeleri (1–2 hafta)

| # | Öneri | Ne yapılacak | Çaba |
|---|---|---|---|
| 4.1 | **Analizi dışa aktarma** | Sonucu düz metin olarak `share_plus` ile paylaş (PDF için `pdf` paketi ekle) → **hızlı kazanım, önce bunu yap** | S |
| 4.2 | **Geçmişte arama/filtreleme** | `analyzer_page.dart:204` yalnız `history.take(10)` gösteriyor; tamamını göster + `TextField` filtresi | S |
| 4.3 | **URL'den analiz** | Post URL → HTML çek (`http` zaten var) → metni ayıkla. Web'de CORS riski → `url_launcher` ile açıp kopyalama yolu da seçenek | M |
| 4.4 | **Çeviri önerisi** | Girdi dili algıla → Claude prompt'una çeviri adımı ekle (mevcut şema `claude_analyzer_datasource.dart:55-77`) | M |
| 4.5 | **Karşılaştırmalı analiz** | İki `AnalysisRequest` → tek prompt'ta yan yana; UI'da iki sütun | M |
| 4.6 | **Çoklu motor (OpenAI / yerel LLM)** | `AnalyzerDataSource` arayüzü zaten var (`analyzer_repository_impl.dart:43-65` seçim mantığı hazır) → yeni datasource + ayar seçimi | M |

**Faz 4 toplam: ≈ 8–13 gün.** 4.1–4.2 mimari değişiklik gerektirmez, önce onlar.

---

## Faz 5 — Altyapı & Kalite (sürekli, Faz 0 ile paralel başlat)

| # | Öneri | Ne yapılacak | Çaba | Not |
|---|---|---|---|---|
| 5.1 | **CI/CD (GitHub Actions)** | `.github/workflows/ci.yml`: `flutter analyze` + `flutter test` + debug build. En düşük maliyetli, en yüksek geri dönüş | S | **İlk hafta yap** — sonraki tüm fazların güven ağı |
| 5.2 | **Test altyapısı** | `mocktail`, `bloc_test` ekle; kapsam: `settings_bloc`, `analyzer_bloc`, Hive adapter'ları, `notification_service`, `sound_service` | M | Mevcut 4 test iyi temel ama yetersiz |
| 5.3 | **Widget testleri** | `feed_page`, `collection_page`, `case_card` (cevap akışı), `me_page` | M | |
| 5.4 | **Crash reporting** | Sentry (bağımsız, hafif) veya Firebase Crashlytics. **Yeni paket** | S | Web + mobil uyumlu |
| 5.5 | **Analytics** | Firebase Analytics ya da hafif olay takibi (hangi arena terk ediliyor, analyzer hata oranı) | M | Karar gerektirir (gizlilik politikası) |
| 5.6 | **Web: Claude CORS proxy** | `claude_analyzer_datasource.dart` doğrudan `api.anthropic.com`'a istek atıyor → web build'de engellenir. Alternatif: offline analyzer'ı web'de varsayilan yap | M | Yalnız `flutter web` hedefleniyorsa öncelikli |
| 5.7 | **Performans** | Büyük koleksiyonlarda `RepaintBoundary` + `addAutomaticKeepAlives:false` | S | 48 kartta şimdilik kritik değil |

**Faz 5 toplam: ≈ 9–14 gün** (5.1 + 5.2 ilk hafta ≈ 3 gün).

---

## Faz 6 — Büyük Yatırımlar (öncelikli olarak **sona**)

Bunlar çaba/geri dönüş oranı düşük ya da çapraz etkisi yüksek olduğu için hızlı kazanımlar sıralamasında geride.

| # | Öneri | Neden sonda? | Çaba |
|---|---|---|---|
| 6.1 | **Dil desteği (i18n)** | Tüm gömülü İngizlizce metinlerin (sayfalar + kart içerikleri + hata mesajları) çevrilmesi gerekir. **Kural:** Eğer TR/EN gerçekten hedefse, içerik üretimi (Faz 1) **bitmeden** bunu yap — yoksa 48 kartı iki kez çevirmek gerekir. Karar noktası: hemen. | **L** (en pahalı madde) |
| 6.2 | **Tablet / landscape** | `OrientationBuilder` yok, grid sabit `crossAxisCount: 3`; tüm ekranların yeniden düzenlenmesi | L |
| 6.3 | **Arkadaşlar / leaderboard** | Firebase/backend zorunlu — mimari yeni baştan. XP verisi `PlayerProgress`'te hazır ama sunucu tarafı yok | L |
| 6.4 | **Veri yedekleme/geri yükleme** | Hive kutularını dışa/içe aktarma; 6.1 sonrası daha anlamlı (JSON + sürüm alanı) | M |
| 6.5 | **Tema varyasyonları (AMOLED siyah vb.)** | `MotiveColors` ThemeExtension zaten iyi kurgulu → ekleme kolay ama kozmetik | S |
| 6.6 | **Onboarding video/gif** | Düşük öncelik | S |

**Faz 6 toplam (i18n hariç ≈ 5–8 gün; i18n ≈ 2–3 hafta).**

---

## Önerilen Sıralama (özet)

```
Hafta 1-2   Faz 0  Hızlı kazanımlar (0.1-0.8)     + 5.1 CI + 5.2 test altyapısı
            └─ KARAR NOKTASI: i18n (6.1) gerekli mi? → evetse hemen başla

Hafta 2-3   Faz 1  4 boş arena + 24 kart + 4 legendary  (test 24→48)

Hafta 3-5   Faz 2  Haftalık özet → başarımlar → meydan okumalar → not/avatar → paylaş

Hafta 5-7   Faz 4  Analyzer: dışa aktarma + geçmiş arama (S) → URL → çeviri → çoklu motor

Hafta 7-9   Faz 3  Zorluk modu → çoktan seçmeli → eşleştirme

Hafta 9+    Faz 5  Crash reporting, analytics, web CORS
            Faz 6  i18n / tablet / leaderboard / yedekleme
```

### Hemen başlanabilecek ilk 5 madde (yarın için)

1. **0.2 Bildirim saati seçimi** — en görünür, en talep edilen, `AppConstants` sabitini kaldırıp `showTimePicker` bağlamak yeterli.
2. **0.1 Ses anahtarı** — `SoundService.enabled` zaten hazır, sadece UI + 1 settings alanı.
3. **0.4 + 0.5 Koleksiyonda sıralama/arama** — veri (`collected` map'inde `DateTime`) hazır, tek sayfa işi.
4. **5.1 GitHub Actions CI** — 1 dosya, tüm sonraki fazların güvenlik ağı.
5. **0.3 Tema "System"** — enum'a 1 değer + `ThemeMode.system`.

### Dikkat edilecek kırılganlıklar

- `game_bloc_test.dart:47` → `hasLength(24)` her kart eklemede kırılacak.
- `app_settings.dart` `copyWith`/`props` ve `settings_model.dart` Hive adapter (`f[0]..f[5]`) → **her yeni ayar alanı iki dosyada da** güncellenmeli.
- `MotiveCard` immutable; kişisel not **kart nesnesine** eklenmemeli (katalog paylaşımlı).
- `answerCase({required bool saysHolds})` imzası çoktan seçmeli modda kırılacak → genişletme stratejisi önceden belirlenmeli.
- Hive'a yeni alan eklerken typeId çakışma yok (mevcut en yüksek typeId: 5).
