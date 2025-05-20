### Slajd 1: Agenda prezentacji

1. Dlaczego klasyczny CRUD hamuje rozwój złożonych systemów
2. Podstawy Command-Query Separation i droga do CQRS
3. Kluczowe komponenty architektury CQRS + Event Sourcing
4. Korzyści, kompromisy i typowe wyzwania wdrożeniowe
5. Praktyczne wskazówki, narzędzia oraz podsumowanie rekomendacji

### Slajd 2: Problem klasycznych architektur CRUD

#### 1. Jeden model danych musi jednocześnie obsługiwać zapis i odczyt.
#### 2. Rozbudowane zapytania SQL i blokady transakcyjne ograniczają skalowanie poziome.
#### 3. Logika biznesowa rozmywa się między warstwami, rośnie koszt utrzymania.
#### 4. Interfejsy CRUD nie wyrażają intencji domenowych, utrudniając rozmowy z biznesem.
#### 5. Wąskie gardło bazy relacyjnej staje się krytycznym punktem awarii.

### Slajd 3: Command-Query Separation (CQS) – fundament

#### 1. Każda metoda jest albo komendą zmieniającą stan, albo zapytaniem zwracającym dane.
#### 2. Zapytania są czysto obliczeniowe i pozbawione efektów ubocznych.
#### 3. Komendy nie zwracają wartości poza potwierdzeniem lub informacją o błędzie.
#### 4. Koncepcję spopularyzowali Bertrand Meyer i Martin Fowler.
#### 5. CQS upraszcza testy jednostkowe i zwiększa czytelność API.

### Slajd 4: CQS – korzyści praktyczne

#### 1. Jasny kontrakt metody natychmiast zdradza, czy wywołanie zmieni stan systemu.
#### 2. Zapytania można testować bez mocków, bo nie zależą od wcześniejszego kontekstu.
#### 3. Silniejsze gwarancje przewidywalności ułatwiają zrównoleglanie kodu.
#### 4. Mniej niespodzianek dla nowych członków zespołu – szybki onboarding.
#### 5. Stanowi pierwszy krok do pełnego rozdzielenia modeli w CQRS.

### Slajd 5: CQS – wyzwania i ograniczenia

#### 1. Żaden język programowania nie egzekwuje CQS automatycznie, wymagana jest dyscyplina.
#### 2. Łatwo „przemycić” efekt uboczny w zapytaniu, psując całościowy model mentalny.
#### 3. Przy bardzo prostych domenach podział może wprowadzić nadmiar kodu.
#### 4. Nie rozwiązuje problemu blokowania baz przy dużej skali zapisu.
#### 5. Stanowi jedynie mikro-poziomową separację, nie odpowiada na kwestie architektoniczne.

### Slajd 6: Ewolucja od CQS do CQRS

#### 1. CQRS przenosi ideę CQS z poziomu metody na poziom całej architektury.
#### 2. Rozdziela modele zapisu i odczytu na osobne warstwy i często osobne bazy.
#### 3. Umożliwia niezależne skalowanie, optymalizację i wersjonowanie obu ścieżek.
#### 4. Naturalnie współgra z event-driven design i mikroserwisami.
#### 5. Wprowadza nowe komponenty (bus, projekcje, sagę), zwiększając złożoność.

### Slajd 7: CQRS – definicja

#### 1. Command Query Responsibility Segregation to wzorzec separacji odpowiedzialności R/W.
#### 2. Strona zapisu przyjmuje komendy, wykonuje reguły domeny i publikuje zdarzenia.
#### 3. Strona odczytu materializuje projekcje zoptymalizowane pod konkretne widoki.
#### 4. Modele mogą używać różnych technologii, które najlepiej spełniają swoje SLA.
#### 5. Spójność między stronami jest zazwyczaj „eventual” i mierzona metryką opóźnienia.

### Slajd 8: CQRS – główne założenia

#### 1. Jeden model domenowy nie musi sprostać wszystkim wymaganiom raportowym.
#### 2. Większość ruchu aplikacji to odczyty, więc warto je skalować niezależnie.
#### 3. Zapis powinien być silnie chroniony regułami biznesowymi i ACID-ową transakcją.
#### 4. Odczyt może być mocno zdenormalizowany, dostarczając dane „pod ekran”.
#### 5. Obie strony komunikują się wyłącznie przez zdarzenia, nie przez bezpośredni SQL.

### Slajd 9: Oddzielenie modeli zapisu i odczytu

#### 1. Write Model trzyma jedynie dane potrzebne do walidacji/realizacji decyzji biznesowej.
#### 2. Read Model buduje widoki dopasowane do scenariuszy front-endu lub API publicznych.
#### 3. Zmiana schematu jednej strony nie wymusza migracji drugiej, co skraca sprinty.
#### 4. Błędy w projekcjach nie zagrażają integralności zapisu; można je odtworzyć.
#### 5. Decyzje skalowania i doboru baz danych podejmuje się osobno dla każdej ścieżki.

### Slajd 10: Separation of Concerns w skali systemu

#### 1. Zespół „write” skupia się na regułach domeny, zespół „read” na doświadczeniu użytkownika.
#### 2. Testy biznesowe nie muszą znać struktury projekcji, co zmniejsza liczbę mocków.
#### 3. Read-side można wdrożyć częściej, bo nie narusza krytycznego kodu transakcyjnego.
#### 4. Błędy wydajnościowe w zapytaniach nie blokują ścieżki zapisu.
#### 5. Decoupling sprzyja architekturze mikroserwisowej i podziałowi odpowiedzialności.

### Slajd 11: Poliglotyczna persystencja

#### 1. Write Model może korzystać z relacyjnej bazy dla ACID i transakcji.
#### 2. Read Model bywa oparty na Elasticsearch, Redisie lub GraphQL subscriptions.
#### 3. Dla analityki można dodać hurtownię kolumnową bez naruszania modelu zapisu.
#### 4. Zmiana technologii po jednej stronie nie wymaga big-bang migracji całego systemu.
#### 5. Umożliwia optymalizację kosztów hostingu przez dobór tańszych silników read-replica.

### Slajd 12: Niezależne skalowanie R/W

#### 1. Odczyty (często 90 % ruchu) skalujemy przez repliki, CDN lub cache in-memory.
#### 2. Zapis skaluje się selektywnie, np. shardingiem po kluczu domenowym.
#### 3. Eliminujemy problemy z lockami, bo zapisy nie konkurują z długimi raportami.
#### 4. Można wprowadzać geograficzne repliki tylko dla read-side, przyspieszając UI globalnie.
#### 5. Koszt infrastruktury jest dopasowany do charakteru obciążenia, a nie „średniej”.

### Slajd 13: Read Model – kluczowe cechy

#### 1. Dane są zdenormalizowane i przygotowane do bezpośredniego renderowania.
#### 2. Brak logiki biznesowej; jedynym celem jest szybki, tani odczyt.
#### 3. Zmiany w projekcjach są asynchroniczne, opóźnienie mierzone w milisekundach–sekundach.
#### 4. Schemat może być całkowicie inny niż w Write Model, np. kolumnowy.
#### 5. Cały Read Store można skasować i odbudować z historii zdarzeń bez ryzyka utraty danych.

### Slajd 14: Write Model – kluczowe cechy

#### 1. Zawiera Agregaty, które egzekwują invariants domeny w jednej transakcji.
#### 2. Przyjmuje wyłącznie komendy, które reprezentują intencje użytkownika.
#### 3. Po pomyślnym zapisie emituje zdarzenia będące jedynym źródłem prawdy.
#### 4. Dane są często znormalizowane, by uniknąć duplikacji i ułatwić spójność.
#### 5. Skalowanie odbywa się przez partycjonowanie strumieni zdarzeń, a nie replikę odczytu.

### Slajd 15: Commands – kontrakt intencji

#### 1. Komenda to komunikat w trybie rozkazującym, np. „DeactivateInventoryItem”.
#### 2. Zawiera minimalny zestaw danych potrzebny do wykonania akcji.
#### 3. Może zostać odrzucona, gdy narusza zasady biznesowe lub wersjonowanie agregatu.
#### 4. Nie zwraca modelu domeny, tylko potwierdzenie lub kod błędu.
#### 5. Idempotentne dzięki unikalnemu identyfikatorowi.

### Slajd 16: Queries – kontrakt odczytu

#### 1. Zapytanie nie zmienia stanu systemu, wyłącznie odczytuje przygotowaną projekcję.
#### 2. Może zwracać obiekty transferowe, strony lub strumienie danych.
#### 3. Dowolna zmiana schematu w Read Model wymaga jedynie aktualizacji handlera zapytania.
#### 4. Dzięki braku side-effects zapytania są łatwe do cache’owania i testowania.
#### 5. Szybkość odpowiedzi wspiera bogate doświadczenie użytkownika w interfejsie.

### Slajd 17: Event Bus – rola i zalety

#### 1. Asynchronicznie transportuje zdarzenia między Write i Read Model.
#### 2. Umożliwia skalowanie subskrybentów poziomo bez obciążania bazy zapisu.
#### 3. Obsługuje ponowne pobranie i gwarancję „at-least-once”, podnosząc niezawodność.
#### 4. Standaryzuje integrację między mikroserwisami poprzez publish/subscribe.
#### 5. Pozwala dodawać nowe projekcje lub integracje bez zmian w kodzie komendy.

### Slajd 18: Event Store – jedyne źródło prawdy

#### 1. Przechowuje niezmienny log zdarzeń w kolejności ich powstania.
#### 2. Stan agregatu odtwarza się przez re-play strumienia zdarzeń.
#### 3. Log jest append-only, co upraszcza replikację i partycjonowanie.
#### 4. Pełna historia spełnia wymagania audytu i umożliwia „time-travel debug”.
#### 5. Event Store może pełnić rolę kolejki, redukując potrzebę 2-phase commit.

### Slajd 19: Read-store Projections

#### 1. Procesory projekcji subskrybują zdarzenia i aktualizują Read Store.
#### 2. Mogą tworzyć materializowane widoki.
#### 3. Lag projekcji jest monitorowany, aby utrzymać akceptowalną świeżość danych.
#### 4. W przypadku błędu można skasować projekcję i przetworzyć zdarzenia od zera.
#### 5. Każda nowa potrzeba raportowa to tylko kolejny handler, nie zmiana bazy zapisu.

### Slajd 20: Process Managers i Sagi

#### 1. Koordynują wielo-krokowe procesy przekraczające granice agregatu.
#### 2. Reagują na zdarzenia, publikując kolejne komendy w ustalonej sekwencji.
#### 3. Pozwalają zastąpić globalne transakcje lokalnymi kompensacjami.
#### 4. Utrzymują stan procesu, aby wiedzieć, który krok jest aktualnie wykonywany.
#### 5. Minimalizują coupling między serwisami, zwiększając odporność na awarie.

### Slajd 21: CQRS + Event Sourcing – synergia

#### 1. CQRS definiuje, gdzie powstają i gdzie konsumowane są zdarzenia.
#### 2. Event Sourcing zapewnia, że stan każdej encji można zrewidować wstecznie.
#### 3. Połączenie gwarantuje pełny audit-trail i łatwość regeneracji Read Modelu.
#### 4. Zapis pojedynczego faktu zasila dowolną liczbę projekcji bez duplikacji.
#### 5. Wzajemnie wzmacniają korzyści skalowania i rozdziału odpowiedzialności.

### Slajd 22: Event Sourcing – definicja

#### 1. Stan systemu wynika z sekwencji niezmiennych zdarzeń, a nie z ostatniego zapisu tabeli.
#### 2. Każde zdarzenie opisuje fakt, który już się wydarzył i nie podlega edycji.
#### 3. Aplikacja rekonstruuje aktualny stan poprzez odtworzenie strumienia.
#### 4. Pozwala przechować pełną historię zmian bez potrzeby kolumn „updated_at”.
#### 5. Umożliwia analizy zdarzeń ex-post bez zmiany kodu domeny.

### Slajd 23: Zdarzenia domenowe – charakterystyka

#### 1. Nazwa w czasie przeszłym jednoznacznie wskazuje, że fakt już zaistniał.
#### 2. Payload zawiera tylko dane potrzebne odbiorcom, niecałą encję.
#### 3. Są uporządkowane i wersjonowane, by zapewnić kompatybilność w czasie.
#### 4. Mogą być kodowane w JSON, Avro lub Protobuf – ważna jest ewolucja schematu.
#### 5. Jedno zdarzenie może wyzwolić wiele reakcji: projekcję, e-mail, rozliczenie.

### Slajd 24: Model faktów w czasie

#### 1. Każdy agregat posiada własną oś czasu zdarzeń z rosnącą wersją.
#### 2. Równoległe komendy wykrywa się przez konflikt wersji, eliminując globalne locki.
#### 3. Analizy „co-gdyby” można wykonać, odtwarzając alternatywny scenariusz.
#### 4. Historia pozwala zbudować machine-learning features bez dodatkowego ETL.
#### 5. Przy migracjach schematu wystarczy odtworzyć stan z nowego kodu projekcji.

### Slajd 25: Time-travel debugging i audyt

#### 1. Można odtworzyć stan systemu z dowolnej minuty sprzed miesięcy.
#### 2. Pomaga zidentyfikować przyczynę błędu, reprodukując dokładną sekwencję działań.
#### 3. Spełnia rygorystyczne wymagania regulacyjne, np. GDPR.
#### 4. Historię zdarzeń można anonimizować, nie tracąc wartości analitycznej.
#### 5. Ułatwia wykrywanie nadużyć, bo widać pełną ścieżkę zmian danych.

### Slajd 26: Rolling Snapshots – optymalizacja

#### 1. Snapshot to zserializowany stan agregatu po N zdarzeniach.
#### 2. Odtwarzanie zaczyna się od najnowszego snapshotu, skracając czas ładowania.
#### 3. Proces snapshotowania działa asynchronicznie, nie blokując ścieżki zapisu.
#### 4. Snapshot nie musi być najświeższy – ważna jest poprawność wersji.
#### 5. Włącza się go dopiero, gdy realne metryki P95 odczytu przekroczą próg.

### Slajd 27: Event Store jako kolejka

#### 1. Jedno fsync zapisuje zarówno dane, jak i informację do publikacji.
#### 2. Chaser-proces monitoruje numer sekwencyjny i wysyła zdarzenia do brokera.
#### 3. Zmniejsza latencję komendy, bo nie czeka na potwierdzenie z kolejki.
#### 4. Awaria brokera nie blokuje zapisu – zdarzenia czekają w logu.
#### 5. Eliminujemy potrzebę kosztownego dwufazowego commitu.

### Slajd 28: Task-Based UI – odzyskiwanie intencji

#### 1. Interfejs rozbija duży formularz na konkretne akcje użytkownika.
#### 2. Każde kliknięcie generuje jedną, semantyczną komendę domenową.
#### 3. Walidacja w czasie rzeczywistym zmniejsza frustrację i liczbę błędów.
#### 4. Nazewnictwo UI mapuje się bezpośrednio na język domeny.
#### 5. Komendy są małe i idempotentne, więc łatwe do testów i retrierów.

### Slajd 29: Komendy kontra zdarzenia – różnice

#### 1. Komenda wyraża przyszłą intencję, zdarzenie opisuje przeszły fakt.
#### 2. Komenda może zostać odrzucona, zdarzenia nie da się „cofnąć”.
#### 3. Wyraźny podział porządkuje rozmowę z interesariuszami.
#### 4. Stosowanie czasu przeszłego w nazwach zdarzeń usuwa dwuznaczności.
#### 5. Klient generuje GUID komendy, co gwarantuje idempotencję operacji.

### Slajd 30: Idempotencja – dlaczego jest potrzebna

#### 1. W sieci zawsze musimy liczyć się z retry po timeout-cie lub awarii.
#### 2. Handlery komend ignorują duplikaty dzięki unikalnemu identyfikatorowi.
#### 3. Konsumenci zdarzeń utrzymują tabelę „processed_events” i pomijają powtórki.
#### 4. Ułatwia testy end-to-end, bo scenariusz można odtworzyć wielokrotnie.
#### 5. Zmniejsza ryzyko niechcianych efektów przy deployach typu blue/green.

### Slajd 31: Eventual Consistency – model użytkowy

#### 1. Po zapisie odczyt może chwilę pokazywać stary stan – trzeba to komunikować w UI.
#### 2. Najczęściej wystarczy informacja „Twoje dane są aktualizowane w tle”.
#### 3. Mechanizmy kompensacyjne mogą wycofać operację, gdy kolejny krok sagii zawiedzie.
#### 4. Monitoring lag-u projekcji gwarantuje, że nie przekracza on SLA biznesowego.
#### 5. W zamian zyskujemy wysoką dostępność i brak globalnych locków.

### Slajd 32: Wyzwania implementacji CQRS

#### 1. Podwójny model danych oznacza więcej miejsc na błąd w wersjonowaniu.
#### 2. Konieczna jest automatyczna migracja projekcji przy zmianach schematu zdarzeń.
#### 3. Zespół DevOps musi utrzymać kolejkę, replikę i monitorować lag.
#### 4. Debugowanie wymaga korelacji komenda → zdarzenie → projekcja.
#### 5. Over-engineering grozi tam, gdzie domena jest prostym CRUD-em.

### Slajd 33: Wyzwania implementacji Event Sourcing

#### 1. Projektowanie zdarzeń wymaga dobrej znajomości domeny i przewidywania zmian.
#### 2. Każdy błąd w „fakcie” jest trwały; trzeba emitować zdarzenia korekcyjne.
#### 3. Snapshoty i retencja logu wprowadzają dodatkową politykę utrzymania.
#### 4. Wersjonowanie schematu zdarzenia musi być wstecznie kompatybilne.
#### 5. Testy integracyjne uruchamiają pełny pipeline zapisu i odczytu, co podnosi koszt CI.

### Slajd 34: Obserwowalność i monitoring lagów

#### 1. Każde zdarzenie dostaje znacznik czasu i numer sekwencyjny.
#### 2. Metryka „current_position – published_position” pokazuje opóźnienie Chasera.
#### 3. Correlation ID przechodzi przez komendę, zdarzenie i HTTP response.
#### 4. Trace’y są agregowane np. w Jaeger/Zipkin, ułatwiając docieranie do źródła błędu.
#### 5. Alerting proaktywnie informuje, gdy Read Model opóźnia się ponad próg SLA.

### Slajd 35: Impedance Mismatch a zdarzenia

#### 1. W tradycyjnym ORM trzeba mapować obiekty do SQL, co generuje złożoność.
#### 2. Zdarzenia są natywne dla domeny i magazynu, eliminując warstwę mapowania.
#### 3. Brak N+1 i lazy loading – aplikacja przetwarza listę faktów w pamięci.
#### 4. BI/ML korzysta z tego samego logu, bez budowania osobnych ETL-i.
#### 5. Zespół uczy się jednego modelu danych, co skraca onboarding.

### Slajd 36: Saga Pattern – podstawy

#### 1. Saga dzieli kompleksową operację na serię lokalnych transakcji.
#### 2. Po błędzie uruchamiane są kompensacje przywracające spójny stan.
#### 3. Krok pivot wyznacza „punkt bez powrotu”, po którym tylko kompensacje są możliwe.
#### 4. Saga może działać w trybie choreografii lub orkiestracji.
#### 5. Zapisy zdarzeń sagi są również audytowane w Event Store.

### Slajd 37: Frameworki i biblioteki – Java

#### 1. Axon Framework oferuje command-bus, event-store i silnik sag w jednym ekosystemie.
#### 2. Lagom udostępnia Event Sourcing i CQRS out-of-the-box na Akka Cluster.
#### 3. Eventuate Tram implementuje transactional outbox i sagas zgodnie z patternami microservices.io.
#### 4. Spring Boot integruje się z nimi przez startery, skracając czas konfiguracji.
#### 5. Wybór zależy od potrzeb: monolit modułowy vs rozproszony klaster.

### Slajd 38: Frameworki i biblioteki – .NET

#### 1. MediatR dostarcza prosty mediator do patternu command/query handler.
#### 2. EventStoreDB zapewnia bazę logu zdarzeń z gRPC i subskrypcjami catch-up.
#### 3. NServiceBus łączy routing komunikatów z silnikiem sag i retry-policy.
#### 4. Dapr abstrahuje message-broker i state-store, umożliwiając CQRS-lite na kontenerach.
#### 5. CQRS w .NET integruje się dobrze z Azure Service Bus i Functions.

### Slajd 39: Frameworki i biblioteki – Python i inne

#### 1. Biblioteka eventsourcing implementuje event-store, snapshoty i projekcje zgodne z DDD.
#### 2. FastAPI ma szablony CQRS-lite z async command/query bus opartym na RabbitMQ.
#### 3. Faust lub Kafka-Streams w Pythonie pozwalają budować projekcje strumieniowe.
#### 4. Go i Rust oferują lekkie biblioteki (EventSourcing-Go, Cqrs-rs) do serwisów o niskim narzucie.
#### 5. Architektura ważniejsza niż język – CQRS działa w każdym ekosystemie.

### Slajd 40: Kryteria decyzji „czy stosować CQRS”

#### 1. Wysoka asymetria R/W i potrzeba elastycznego skalowania odczytu.
#### 2. Złożona domena z licznymi regułami, które trudno zmieścić w CRUD.
#### 3. Konieczność pełnego audytu i historii zmian dla compliance.
#### 4. Wiele zespołów równolegle modyfikuje różne aspekty systemu.
#### 5. Prostym systemom CRUD niepotrzebna ta złożoność.

### Slajd 41: Strategia adopcji w istniejącym systemie

#### 1. Zaczynamy od wyodrębnienia pojedynczego modułu o największej asymetrii R/W.
#### 2. Równolegle utrzymujemy stary CRUD i nowy CQRS, migrując ruch stopniowo.
#### 3. Wprowadzamy Event Sourcing tylko tam, gdzie wartość historyczna jest największa.
#### 4. Edukujemy zespół przez warsztaty DDD i kata event-storming.
#### 5. Monitorujemy metryki lag-u i kosztów, aby uzasadnić dalszą migrację.

### Slajd 42: Najczęstsze pułapki i anty-wzorce

#### 1. Over-engineering: wdrożenie CQRS w prostym CRUD bez potrzeby.
#### 2. Łączenie read i write w tej samej bazie niweczy separację.
#### 3. Publikowanie zdarzeń tylko „dla integracji”, a nie jako źródło prawdy.
#### 4. Brak idempotencji w konsumentach prowadzi do duplikacji danych.
#### 5. Zaniedbanie monitoringu skutkuje „niewidzialnym” lagiem.

### Slajd 43: Podsumowanie i rekomendacje

#### 1. CQRS + Event Sourcing daje ogromne korzyści w złożonych, skalowalnych systemach.
#### 2. Fundamentem jest rozdzielenie komend i zapytań oraz traktowanie zdarzeń jako faktów.
#### 3. Korzyści (skalowanie, audyt, elastyczność) przychodzą kosztem złożoności.
#### 4. Zaczynamy małymi krokami, mierzymy lag i edukujemy zespół.
#### 5. Stosuj tam, gdzie asymetria R/W i historia mają znaczenie.


