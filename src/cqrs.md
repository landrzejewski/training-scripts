## Agenda
- Dlaczego klasyczny CRUD hamuje rozwój złożonych systemów
- Podstawy Command-Query Separation i droga do CQRS
- Kluczowe komponenty architektury CQRS + Event Sourcing
- Korzyści, kompromisy i typowe wyzwania wdrożeniowe
- Praktyczne wskazówki, narzędzia oraz podsumowanie rekomendacji

---

## Ograniczenia podejścia CRUD

- Jeden model dla zapisu i odczytu ogranicza elastyczność i przejrzystość
- Utrudnione testowanie i rozwój z powodu rozproszonej logiki biznesowej
- Długie transakcje blokują bazę, relacyjne bazy stają się wąskim gardłem

---

## Command-Query Separation (CQS)

- Rozdzielenie operacji zmieniających stan i odczytujących dane
- Lepsza testowalność, przejrzystość i możliwość równoległego przetwarzania
- Komendy są przewidywalne i nie zwracają danych, tylko wynik operacji

---

## Od CQS do CQRS

- CQRS rozdziela zapis i odczyt na poziomie architektury systemu
- Dane do odczytu pochodzą z osobnych, zoptymalizowanych projekcji
- System zakłada spójność ostateczną i wykorzystuje zdarzenia

---

## Oddzielenie modeli zapisu i odczytu

- Każda strona może używać innych struktur danych i technologii
- Mniejsza liczba zależności, szybsze testy i prostszy rozwój
- Możliwość odbudowy i modyfikacji read modeli bez wpływu na zapis

---

## Niezależne skalowanie odczytu i zapisu

- Odczyt skalowany horyzontalnie (cache, replikacja, CDN)
- Zapis optymalizowany np. przez sharding lub partycjonowanie
- Eliminacja blokad – odczyty nie wpływają na zapisy

---

## Read Model

- Służy tylko do odczytu, zdenormalizowany i dostosowany do UI
- Aktualizowany asynchronicznie na podstawie zdarzeń
- Łatwy w testowaniu i odbudowie, odporny na awarie

---

## Write Model

- Skupia logikę biznesową – wykorzystuje Agregaty
- Emituje zdarzenia jako jedyne źródło prawdy
- Znormalizowana struktura, skalowalność przez partycjonowanie

---

## Commands – kontrakt intencji

- Reprezentują intencje użytkownika, np. "ZmieńEmailKlienta"
- Mogą zostać odrzucone w razie błędu lub nieaktualnej wersji
- Powinny być idempotentne i jednoznacznie identyfikowalne

---

## Queries – kontrakt odczytu

- Służą wyłącznie do odczytu – brak skutków ubocznych
- Zwracają dane gotowe do użycia (DTO, listy, strumienie)
- Umożliwiają bezpieczne cachowanie i niezależny rozwój UI

---

## Event Bus

- Asynchroniczne przekazywanie zdarzeń (publish/subscribe)
- Luźne powiązania między modułami, łatwa integracja
- Możliwość dodawania funkcji bez zmiany istniejącego kodu

---

## Event Store

- Przechowuje niezmienne, uporządkowane zdarzenia
- Źródło historii systemu – audyt, debugowanie, przywracanie stanu
- Atomowy zapis i publikacja zdarzeń – serce architektury

---

## Process Managers i Sagi

- Koordynują złożone procesy biznesowe rozłożone w czasie
- Zamiast globalnych transakcji – lokalne akcje i kompensacje
- Wspierają odporność i możliwość wznowienia po awarii

---

## Event Sourcing

- Stan systemu pochodzi ze zdarzeń, nie aktualnych danych
- Umożliwia pełną historię, audyt, debug i time-travel
- Możliwość tworzenia snapshotów dla wydajności

---

## CQRS + Event Sourcing

- CQRS zarządza przepływem, Event Sourcing przechowuje zmiany
- Read modele można odbudować z tego samego strumienia zdarzeń
- Zapewnia przejrzystość, audyt, odporność i skalowalność

---

## Zdarzenia domenowe

- Opisują to, co już się wydarzyło, np. „ZamówienieZłożone"
- Niezależne, wersjonowane, mogą uruchamiać wiele reakcji
- Redukują zależności, wspierają elastyczność i skalowanie

---

## Komendy kontra zdarzenia

- Komendy = intencje (przyszłość), Zdarzenia = fakty (przeszłość)
- Komenda może się nie udać, zdarzenie zawsze się wydarzyło
- Rozróżnienie poprawia przejrzystość i odporność systemu

---

## Zdarzenia jako źródło prawdy i wehikuł czasu

- Każdy agregat ma własną oś czasu zdarzeń
- Możliwość symulacji, odtworzenia, analizy incydentów
- Bez migracji – nowe handlery interpretują stare zdarzenia

---

## Rolling Snapshots

- Snapshot = zapis stanu, od którego odtwarza się tylko nowe zdarzenia
- Tworzone asynchronicznie, zwiększają wydajność
- Używane tylko tam, gdzie rzeczywiście potrzebne

---

## Eventual Consistency

- Dane są spójne z czasem, nie natychmiast po zapisie
- UI powinien informować o aktualizacji w tle
- W zamian zyskujemy skalowalność, odporność i dostępność

---

## Wyzwania implementacji CQRS

- Więcej punktów awarii i złożoność operacyjna
- Potrzeba wiedzy DevOps, śledzenia lagów i rebuildu projekcji
- Nie dla prostych systemów – tylko tam, gdzie daje realną wartość

---

## Wyzwania implementacji Event Sourcing

- Trwałe, nieedytowalne zdarzenia – projektowanie i wersjonowanie
- Zarządzanie snapshotami, retencją i zgodnością
- Testowanie pełnego przepływu – komenda, zdarzenie, projekcja

---

## Frameworki – Java

- **Axon** – pełne wsparcie CQRS/ES z integracją z Spring Boot
- **Lagom** – CQRS + Akka, dobre dla systemów rozproszonych
- **Eventuate Tram** – microservices.io, transactional outbox, saga orchestration

---

## Frameworki – .NET

- **MediatR** – lekki, prosty CQRS-lite
- **EventStoreDB** – natywny event store z gRPC i catch-up
- **NServiceBus**, **Dapr** – zaawansowane scenariusze, integracja z Azure

---

## Frameworki – Python i inne

- **`eventsourcing`** – pełne DDD i Event Sourcing w Pythonie
- **FastAPI + RabbitMQ** – lekka architektura zdarzeniowa
- **Go/Rust** – lekkie i wydajne CQRS/ES biblioteki, np. `cqrs-rs`, `EventSourcing-Go`

---

## Czy stosować CQRS?

- Gdy występuje asymetria odczyt/zapis lub złożona logika
- W systemach wymagających pełnej historii i audytu
- Nie dla prostych CRUD – tylko tam, gdzie CQRS przynosi wartość

---

## Strategia adopcji

- Zaczynaj od raportowania lub mniej krytycznych komponentów
- Pozwól na współistnienie CRUD i CQRS w fazie przejściowej
- Wdrażaj monitoring, ucz zespół i mierzalnie oceniaj wartość

---

## Najczęstsze pułapki

- Over-engineering – CQRS tam, gdzie niepotrzebny
- Brak separacji baz, brak idempotencji i monitoringu
- Traktowanie zdarzeń jako technicznych wiadomości, a nie faktów

---

## Podsumowanie i rekomendacje

- CQRS i Event Sourcing zwiększają przejrzystość, skalowalność i odporność
- Wymagają dojrzałości technicznej i zespołowej
- Zaczynaj pragmatycznie, mierz efekty i dopasuj podejście do domeny  