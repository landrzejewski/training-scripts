### Slajd 1: Agenda prezentacji

1. Dlaczego klasyczny CRUD hamuje rozwój złożonych systemów
2. Podstawy Command-Query Separation i droga do CQRS
3. Kluczowe komponenty architektury CQRS + Event Sourcing
4. Korzyści, kompromisy i typowe wyzwania wdrożeniowe
5. Praktyczne wskazówki, narzędzia oraz podsumowanie rekomendacji

### Slajd 2: Problem klasycznych architektur CRUD

#### 1. Jeden model danych musi jednocześnie obsługiwać zapis i odczyt.
Projektowanie uniwersalnego modelu staje się trudne, gdy musi on wspierać różne przypadki użycia, a dodawanie 
nowych funkcjonalności często wymaga kompromisów w strukturze danych.

#### 2. Rozbudowane zapytania SQL i blokady transakcyjne ograniczają skalowanie poziome.
Długie zapytania raportowe potrafią blokować tabele, przez co opóźniają operacje zapisu.

#### 3. Logika biznesowa rozmywa się między warstwami, rośnie koszt utrzymania.
Brakuje jednoznacznego miejsca na reguły domenowe, więc trafiają one wszędzie, co powoduje efekt domina i wymaga 
licznych testów regresyjnych przy każdej zmianie.

#### 4. Interfejsy CRUD nie wyrażają intencji domenowych, utrudniając rozmowy z biznesem.
Operacje typu „update” czy „delete” są zbyt ogólne, by komunikować sens biznesowy, a przez to trudno śledzić, dlaczego 
dany rekord został zmodyfikowany i kto to zrobił.

#### 5. Wąskie gardło bazy relacyjnej staje się krytycznym punktem awarii.
Cały system zależy od dostępności bazy danych, więc jej awaria lub przeciążenie wpływa na wszystkie operacje w aplikacji.

### Slajd 3: Command-Query Separation (CQS) – fundament

#### 1. Każda metoda jest albo komendą zmieniającą stan, albo zapytaniem zwracającym dane.
Dzięki temu aplikacja staje się bardziej przejrzysta i przewidywalna, a wyeliminowanie metod, które „trochę zmieniają i
trochę odczytują”, upraszcza szukanie błędów, debugowanie.

#### 2. Zapytania są czysto obliczeniowe i pozbawione efektów ubocznych.
Nie wpływają na żaden stan aplikacji – po ich wykonaniu wszystko pozostaje bez zmian, co pozwala swobodnie je 
wywoływać wielokrotnie czy wykorzystywać cache.

#### 3. Komendy nie zwracają wartości poza potwierdzeniem lub informacją o błędzie.
Dzięki temu intencja użytkownika jest jasno wyrażona, co wzmacnia model mentalny i ułatwia zrozumienie systemu.

#### 4. Koncepcję spopularyzowali Bertrand Meyer i Martin Fowler.
Została zaproponowana w kontekście języka Eiffel, a potem zaadaptowana w praktykach DDD i obecnie stanowi podstawę 
wielu nowoczesnych architektur aplikacyjnych.

#### 5. CQS upraszcza testy jednostkowe i zwiększa czytelność API.
Można osobno testować komendy i zapytania, bez potrzeby mockowania całego kontekstu, a interfejsy stają się bardziej
intuicyjne, bo jasno oddzielają działania od zapytań.

### Slajd 4: CQS – korzyści praktyczne

#### 1. Jasny kontrakt metody natychmiast zdradza, czy wywołanie zmieni stan systemu.
Programista nie musi zgadywać, czy dana metoda zapisze coś do bazy, co ułatwia nawigację po kodzie i szybkie rozumienie jego działania.

#### 2. Zapytania można testować bez mocków, bo nie zależą od wcześniejszego kontekstu.
Nie potrzeba symulować zachowań systemu – wystarczą dane wejściowe, co znacząco przyspiesza pisanie i utrzymywanie testów.

#### 3. Silniejsze gwarancje przewidywalności ułatwiają zrównoleglanie kodu.
Komendy i zapytania nie wchodzą sobie w drogę, można je bezpiecznie uruchamiać równolegle, co zmniejsza ryzyko konfliktów i
jednocześnie zwiększa wydajność.

#### 4. Mniej niespodzianek dla nowych członków zespołu – szybki onboarding.
Nowi deweloperzy mogą łatwiej zrozumieć podział ról i przepływ danych w systemie, a jasne API minimalizuje potrzebę
głębokiego „grzebania” w kodzie na start.

#### 5. Stanowi pierwszy krok do pełnego rozdzielenia modeli w CQRS.
CQS przygotowuje system do bardziej zaawansowanego rozdziału logiki, pomagając wprowadzać CQRS stopniowo, bez rewolucji architektonicznej.

### Slajd 5: CQS – wyzwania i ograniczenia

#### 1. Żaden język programowania nie egzekwuje CQS automatycznie, wymagana jest dyscyplina.
Programiści muszą świadomie przestrzegać zasady, bo kompilator tego nie wymusi, a brak dyscypliny szybko prowadzi do mieszania 
efektów ubocznych w zapytaniach.

#### 2. Łatwo „przemycić” efekt uboczny w zapytaniu, psując całościowy model mentalny.
Na przykład zapis do logu w zapytaniu może wydawać się niewinny, ale łamie zasadę CQS.

#### 3. Przy bardzo prostych domenach podział może wprowadzić nadmiar kodu.
W małych systemach CQS może wydawać się przesadą i zwiększać złożoność, dlatego warto ocenić, czy korzyści z separacji
przewyższają koszt dodatkowych warstw.

#### 4. Nie rozwiązuje problemu blokowania baz przy dużej skali zapisu.
CQS skupia się na czytelności i separacji, ale nie wpływa bezpośrednio na wydajność, więc problemy z bazą nadal mogą 
występować i wymagać określonych optymalizacji.

#### 5. Stanowi jedynie mikro-poziomową separację, nie odpowiada na kwestie architektoniczne.
Mówi o metodach, ale nie adresuje szerszych aspektów systemu jak komunikacja czy skalowanie, dlatego często traktuje 
się je jako fundament do czegoś większego, jak CQRS.

### Slajd 6: Ewolucja od CQS do CQRS

#### 1. CQRS przenosi ideę CQS z poziomu metody na poziom całej architektury.
Oznacza to nie tylko podział metod, ale całych warstw systemu, przez co struktura aplikacji zmienia się w sposób systemowy.

#### 2. Rozdziela modele zapisu i odczytu na osobne warstwy i często osobne bazy.
Każda ścieżka ma inne wymagania, więc może być zaimplementowana niezależnie, co pozwala optymalizować kod i infrastrukturę pod konkretne cele.

#### 3. Umożliwia niezależne skalowanie, optymalizację i wersjonowanie obu ścieżek.
Read-side można replikować, write-side silnie chronić, co ułatwia dostosowanie się do realnych potrzeb systemu.

#### 4. Naturalnie współgra z event-driven design i mikroserwisami.
Zdarzenia stają się podstawą komunikacji między komponentami, co ułatwia rozdzielenie odpowiedzialności i zwiększenie niezawodności.

#### 5. Wprowadza nowe komponenty (bus, projekcje, sagę), zwiększając złożoność.
Architektura staje się bardziej modularna, ale też wymaga większej świadomości.

### Slajd 7: CQRS – definicja

#### 1. Command Query Responsibility Segregation to wzorzec separacji odpowiedzialności R/W.
Podstawą jest zasada: albo zmieniasz stan, albo go odczytujesz – nigdy oba naraz, co sprawia, że każdy komponent ma jedną odpowiedzialność.

#### 2. Strona zapisu przyjmuje komendy, wykonuje reguły domeny i publikuje zdarzenia.
Komendy są walidowane i przekształcane w zdarzenia, które reprezentują fakty i stanowią jedyne źródło prawdy w systemie.

#### 3. Strona odczytu materializuje projekcje zoptymalizowane pod konkretne widoki.
Dane są przygotowywane tak, by odpowiadały potrzebom UI lub API, co pozwala uniknąć kosztownych i nadmiarowych zapytań do bazy.

#### 4. Modele mogą używać różnych technologii, które najlepiej spełniają swoje SLA.
Write model może korzystać z RDBMS, read model z Elasticsearch, co daje swobodę wyboru technologii do konkretnego celu.

#### 5. Spójność między stronami jest zazwyczaj „eventual” i mierzona metryką opóźnienia.
Nie zakładamy natychmiastowej synchronizacji po zapisie, a lag między zapisem a widocznością danych jest kontrolowany i akceptowalny.

### Slajd 8: CQRS – główne założenia

#### 1. Jeden model domenowy nie musi sprostać wszystkim wymaganiom raportowym.
Odczyty mogą być oparte na innych strukturach danych niż zapisy, dzięki czemu nie przeciąża się logiki domenowej potrzebami UI.

#### 2. Większość ruchu aplikacji to odczyty, więc warto je skalować niezależnie.
Read-side może obsłużyć setki tysięcy zapytań bez obciążania zapisu, co pozwala obniżyć koszty operacyjne i zwiększyć wydajność.

#### 3. Zapis powinien być silnie chroniony regułami biznesowymi i ACID-ową transakcją.
Każda decyzja zmieniająca stan musi przejść przez rygorystyczną walidację, co zapewnia bezpieczeństwo i integralność danych.

#### 4. Odczyt może być mocno zdenormalizowany, dostarczając dane „pod ekran”.
Projekcje są budowane pod konkretne potrzeby widoków lub integracji, eliminując konieczność łączenia wielu tabel na żywo.

#### 5. Obie strony komunikują się wyłącznie przez zdarzenia, nie przez bezpośredni SQL.
Zapis generuje zdarzenia, które napędzają aktualizację odczytu, co zmniejsza coupling i ułatwia refaktoryzację.

### Slajd 9: Oddzielenie modeli zapisu i odczytu

#### 1. Write Model trzyma jedynie dane potrzebne do walidacji/realizacji decyzji biznesowej.
Nie zawiera informacji zbędnych do podejmowania decyzji, jest w pełni znormalizowany, skupiony na logice domeny.

#### 2. Read Model buduje widoki dopasowane do scenariuszy front-endu lub API publicznych.
Może zawierać dane nadmiarowe, by przyspieszyć odczyt, a zmienność w UI nie wpływa na model domenowy.

#### 3. Zmiana schematu jednej strony nie wymusza migracji drugiej, co skraca sprinty.
Odczyt może ewoluować niezależnie od zapisu i odwrotnie, co zmniejsza ilość regresji i umożliwia częstsze releasy.

#### 4. Błędy w projekcjach nie zagrażają integralności zapisu; można je odtworzyć.
Projekcje są tylko pochodną zdarzeń – mogą być odbudowane w dowolnym momencie, co pozwala na bezpieczne eksperymenty i szybkie poprawki.

#### 5. Decyzje skalowania i doboru baz danych podejmuje się osobno dla każdej ścieżki.
Każda strona może mieć inny profil wydajnościowy i kosztowy, co umożliwia precyzyjne dopasowanie infrastruktury do potrzeb.

### Slajd 10: Separation of Concerns w skali systemu

#### 1. Zespół „write” skupia się na regułach domeny, zespół „read” na doświadczeniu użytkownika.
Taki podział zwiększa specjalizację i jakość w każdej warstwie, zmniejszając liczbę kontekstów, które trzeba ogarnąć jednocześnie.

#### 2. Testy biznesowe nie muszą znać struktury projekcji, co zmniejsza liczbę mocków.
Agregaty są testowane niezależnie od tego, jak wyglądają dane na froncie, co upraszcza testy i zwiększa ich wartość diagnostyczną.

#### 3. Read-side można wdrożyć częściej, bo nie narusza krytycznego kodu transakcyjnego.
Możliwe są szybkie iteracje UI bez ryzyka zaburzenia logiki domeny, co przyspiesza time-to-market dla funkcjonalności widocznych dla użytkownika.

#### 4. Błędy wydajnościowe w zapytaniach nie blokują ścieżki zapisu.
Gdy read-side zwalnia, system nadal może bezpiecznie przyjmować dane, co umożliwia niezależne zarządzanie SLA i alertowaniem.

#### 5. Decoupling sprzyja architekturze mikroserwisowej i podziałowi odpowiedzialności.
Każdy zespół może rozwijać własną część bez ryzyka kolizji, a CQRS stanowi fundament do dalszej dekompozycji systemu.

### Slajd 11: Poliglotyczna persystencja

#### 1. Write Model może korzystać z relacyjnej bazy dla ACID i transakcji.
Zapewnia to spójność i niezawodność w krytycznych operacjach biznesowych, co jest idealne dla logiki wymagającej 
walidacji i silnych gwarancji.

#### 2. Read Model bywa oparty na Elasticsearch, Redisie lub GraphQL subscriptions.
Dobiera się technologię, która najlepiej odpowiada na potrzeby widoku, co znacznie poprawia czas odpowiedzi i elastyczność zapytań.

#### 3. Dla analityki można dodać hurtownię kolumnową bez naruszania modelu zapisu.
Odczyty analityczne są całkowicie oddzielone od ścieżki operacyjnej, co pozwala uniknąć wpływu długich zapytań na użytkowników końcowych.

#### 4. Zmiana technologii po jednej stronie nie wymaga big-bang migracji całego systemu.
Infrastruktura read i write mogą ewoluować niezależnie, co zmniejsza ryzyko i koszt zmian technologicznych.

#### 5. Umożliwia optymalizację kosztów hostingu przez dobór tańszych silników read-replica.
Read-side może działać na szybszych, ale mniej trwałych rozwiązaniach, dzięki czemu koszty infrastruktury dopasowuje się do charakteru obciążenia.

### Slajd 12: Niezależne skalowanie R/W

#### 1. Odczyty (często 90 % ruchu) skalujemy przez repliki, CDN lub cache in-memory.
Zapytania są rozpraszane po wielu źródłach, zmniejszając obciążenie głównej bazy, co pozwala osiągnąć wysoką wydajność nawet przy dużym ruchu.

#### 2. Zapis skaluje się selektywnie, np. shardingiem po kluczu domenowym.
Można rozdzielać dane klientów lub konteksty biznesowe na niezależne partycje, co poprawia równoległość operacji i skraca czas odpowiedzi.

#### 3. Eliminujemy problemy z lockami, bo zapisy nie konkurują z długimi raportami.
Zmniejsza to ryzyko przeciążeń i deadlocków w bazie danych, co pozwala zachować wysoką dostępność nawet w godzinach szczytu.

#### 4. Można wprowadzać geograficzne repliki tylko dla read-side, przyspieszając UI globalnie.
Dane mogą być lokalnie dostępne dla użytkowników z różnych regionów, co poprawia czas ładowania stron i komfort korzystania z aplikacji.

#### 5. Koszt infrastruktury jest dopasowany do charakteru obciążenia, a nie „średniej”.
Unika się przewymiarowania zasobów tylko pod skrajne przypadki, co czyni skalowanie bardziej ekonomicznym.

### Slajd 13: Read Model – kluczowe cechy

#### 1. Dane są zdenormalizowane i przygotowane do bezpośredniego renderowania.
Dzięki temu aplikacja nie musi przetwarzać danych na etapie wyświetlania, co skraca czas odpowiedzi i upraszcza frontend.

#### 2. Brak logiki biznesowej; jedynym celem jest szybki, tani odczyt.
Read model nie waliduje, nie podejmuje decyzji – tylko serwuje dane, co ułatwia jego rozwój i testowanie.

#### 3. Zmiany w projekcjach są asynchroniczne, opóźnienie mierzone w milisekundach–sekundach.
Odczyt nie jest natychmiastowy, ale aktualizuje się bardzo szybko, co jest akceptowalnym kompromisem na rzecz skalowalności.

#### 4. Schemat może być całkowicie inny niż w Write Model, np. kolumnowy.
Można go projektować pod konkretne potrzeby raportowe lub API, dzięki czemu nie ogranicza nas struktura danych zapisu.

#### 5. Cały Read Store można skasować i odbudować z historii zdarzeń bez ryzyka utraty danych.
W razie błędu lub zmiany schematu można go łatwo odtworzyć, co zwiększa bezpieczeństwo i elastyczność architektury.

### Slajd 14: Write Model – kluczowe cechy

#### 1. Zawiera Agregaty, które egzekwują invariants domeny w jednej transakcji.
Agregat to strażnik integralności reguł biznesowych i tylko on ma prawo decydować, czy komenda może być wykonana.

#### 2. Przyjmuje wyłącznie komendy, które reprezentują intencje użytkownika.
Każde wywołanie metody w modelu zapisu jest wyrazem konkretnego działania, co ułatwia komunikację z biznesem i zrozumienie procesów.

#### 3. Po pomyślnym zapisie emituje zdarzenia będące jedynym źródłem prawdy.
Zdarzenia zapisane w Event Store stanowią oficjalną historię systemu i napędzają całą resztę – od projekcji po integracje.

#### 4. Dane są często znormalizowane, by uniknąć duplikacji i ułatwić spójność.
Write model dba o precyzję i jednoznaczność danych, dzięki czemu łatwiej zachować porządek i poprawność.

#### 5. Skalowanie odbywa się przez partycjonowanie strumieni zdarzeń, a nie replikę odczytu.
Strumienie można rozdzielić np. według ID klienta lub typu zdarzenia, co pozwala lepiej wykorzystać zasoby i uniknąć bottlenecków.

### Slajd 15: Commands – kontrakt intencji

#### 1. Komenda to komunikat w trybie rozkazującym, np. „DeactivateInventoryItem”.
Sama nazwa wyraża zamiar i sugeruje efekt operacji, co pomaga w czytelności kodu i rozmowie z interesariuszami.

#### 2. Zawiera minimalny zestaw danych potrzebny do wykonania akcji.
Nie przekazuje całych obiektów, tylko wymagane informacje, co ogranicza powierzchnię błędów i poprawia precyzję.

#### 3. Może zostać odrzucona, gdy narusza zasady biznesowe lub wersjonowanie agregatu.
System może odmówić wykonania komendy, jeśli warunki nie są spełnione, co zapewnia ochronę przed niepożądanymi stanami.

#### 4. Nie zwraca modelu domeny, tylko potwierdzenie lub kod błędu.
Dzięki temu oddziela intencję od rezultatu, pozostawiając reakcję po stronie UI i upraszcza API.

#### 5. Idempotentne dzięki unikalnemu identyfikatorowi.
Każda komenda ma swój identyfikator, co pozwala ignorować duplikaty i budować systemy odporne na powtórzenia.

### Slajd 16: Queries – kontrakt odczytu

#### 1. Zapytanie nie zmienia stanu systemu, wyłącznie odczytuje przygotowaną projekcję.
Można je bezpiecznie wykonywać wielokrotnie bez efektów ubocznych, co zwiększa stabilność systemu i upraszcza jego testowanie.

#### 2. Może zwracać obiekty transferowe, strony lub strumienie danych.
Dane są od razu gotowe do użycia w UI, bez potrzeby dodatkowego przetwarzania, co przyspiesza interfejsy i zmniejsza złożoność aplikacji klienckiej.

#### 3. Dowolna zmiana schematu w Read Model wymaga jedynie aktualizacji handlera zapytania.
Modyfikacje nie wpływają na stronę zapisu ani strukturę domeny, co daje większą swobodę i krótszy cykl wdrożeniowy.

#### 4. Dzięki braku side-effects zapytania są łatwe do cache’owania i testowania.
Można bezpiecznie korzystać z pamięci podręcznej lub CDN, a testy są szybkie i nie wymagają skomplikowanego przygotowania danych.

#### 5. Szybkość odpowiedzi wspiera bogate doświadczenie użytkownika w interfejsie.
Użytkownik nie musi czekać na przetwarzanie danych w backendzie, co zwiększa responsywność i satysfakcję z korzystania z aplikacji.

### Slajd 17: Event Bus – rola i zalety

#### 1. Asynchronicznie transportuje zdarzenia między Write i Read Model.
Nie blokuje zapisu – zdarzenia są przekazywane niezależnie w tle, co umożliwia luźne powiązania między komponentami.

#### 2. Umożliwia skalowanie subskrybentów poziomo bez obciążania bazy zapisu.
Nowe komponenty mogą nasłuchiwać zdarzeń bez wpływu na system źródłowy, co wspiera architekturę mikroserwisową i rozszerzalność.

#### 3. Obsługuje ponowne pobranie i gwarancję „at-least-once”, podnosząc niezawodność.
Nawet w przypadku chwilowych awarii komunikacja pozostaje spójna, a system może ponawiać wysyłkę, aż subskrybent poprawnie przetworzy zdarzenie.

#### 4. Standaryzuje integrację między mikroserwisami poprzez publish/subscribe.
Serwisy nie muszą znać się nawzajem – wystarczy wspólne zdarzenie, co ułatwia wdrażanie nowych usług i minimalizuje zależności.

#### 5. Pozwala dodawać nowe projekcje lub integracje bez zmian w kodzie komendy.
Można rozszerzyć system o nowe funkcje bez modyfikacji core, co wspiera zasadę Open/Closed i rozwój bez ryzyka regresji.

### Slajd 18: Event Store – jedyne źródło prawdy

#### 1. Przechowuje niezmienny log zdarzeń w kolejności ich powstania.
Każda zmiana jest zapisywana jako oddzielny fakt, nigdy nadpisywana, co umożliwia pełną audytowalność i rewizję historii.

#### 2. Stan agregatu odtwarza się przez re-play strumienia zdarzeń.
Aplikacja przelicza stan z sekwencji zdarzeń, a nie z pojedynczego snapshotu, dzięki czemu zawsze wiadomo, jak system do niego doszedł.

#### 3. Log jest append-only, co upraszcza replikację i partycjonowanie.
Nie występują konflikty zapisu – tylko dopisywanie na koniec, co ułatwia skalowanie i tworzenie kopii zapasowych.

#### 4. Pełna historia spełnia wymagania audytu i umożliwia „time-travel debug”.
Można cofnąć się w czasie i odtworzyć dowolny stan systemu, co jest idealne przy analizie błędów lub zgodności z regulacjami.

#### 5. Event Store może pełnić rolę kolejki, redukując potrzebę 2-phase commit.
Zapis i wysyłka zdarzenia odbywają się w jednym kroku, co zwiększa spójność i upraszcza architekturę komunikacji.


### Slajd 19: Read-store Projections

#### 1. Procesory projekcji subskrybują zdarzenia i aktualizują Read Store.
Każde nowe zdarzenie trafia do handlera, który aktualizuje dane odczytu, co pozwala utrzymać widoki zgodne z aktualnym stanem systemu.

#### 2. Mogą tworzyć materializowane widoki.
Format i struktura projekcji zależą od potrzeb konsumentów danych, co ułatwia optymalizację pod kątem wydajności zapytań.

#### 3. Lag projekcji jest monitorowany, aby utrzymać akceptowalną świeżość danych.
System stale śledzi opóźnienie między zapisem a aktualizacją widoku, co pozwala reagować, zanim użytkownik zauważy różnicę.

#### 4. W przypadku błędu można skasować projekcję i przetworzyć zdarzenia od zera.
Projekcje są odtwarzalne – nie muszą być backupowane jak klasyczne bazy, co ułatwia recovery po awarii lub błędnej migracji.

#### 5. Każda nowa potrzeba raportowa to tylko kolejny handler, nie zmiana bazy zapisu.
Dodanie nowego widoku nie wymaga modyfikowania core’owej logiki, co wzmacnia separację odpowiedzialności i szybkość dostarczania.

### Slajd 20: Process Managers i Sagi

#### 1. Koordynują wielo-krokowe procesy przekraczające granice agregatu.
Pozwalają zrealizować złożoną logikę, która obejmuje wiele encji, jak rezerwacje czy płatności.

#### 2. Reagują na zdarzenia, publikując kolejne komendy w ustalonej sekwencji.
Każdy krok zależy od poprzedniego i jest aktywowany asynchronicznie, co pozwala budować odporne i skalowalne przepływy.

#### 3. Pozwalają zastąpić globalne transakcje lokalnymi kompensacjami.
Zamiast jednego commit-u, mamy serię operacji z fallbackiem, co eliminuje potrzebę blokowania całego systemu.

#### 4. Utrzymują stan procesu, aby wiedzieć, który krok jest aktualnie wykonywany.
Każdy Process Manager ma własny „stan maszyny”, co umożliwia wznowienie po awarii.

#### 5. Minimalizują coupling między serwisami, zwiększając odporność na awarie.
Serwisy komunikują się przez zdarzenia, niebezpośrednie API, co ogranicza ryzyko efektu domina w przypadku błędu.

### Slajd 21: CQRS + Event Sourcing – synergia

#### 1. CQRS definiuje, gdzie powstają i gdzie konsumowane są zdarzenia.
Komendy generują zdarzenia, a projekcje i integracje je przetwarzają, co daje jasny przepływ danych i punkt kontrolny dla każdej zmiany.

#### 2. Event Sourcing zapewnia, że stan każdej encji można zrewidować wstecznie.
Każdy agregat posiada pełną historię zdarzeń, z której można go odtworzyć, co eliminuje potrzebę kolumn typu `updated_at` i logów audytowych.

#### 3. Połączenie gwarantuje pełny audit-trail i łatwość regeneracji Read Modelu.
Umożliwia to zgodność z wymaganiami prawnymi i szybką rekonfigurację systemu, ponieważ Read Model można przebudować bez dotykania Write Modelu.

#### 4. Zapis pojedynczego faktu zasila dowolną liczbę projekcji bez duplikacji.
Jedno zdarzenie może mieć wielu niezależnych subskrybentów, dzięki czemu nowe funkcje nie wymagają zmian w istniejącej logice.

#### 5. Wzajemnie wzmacniają korzyści skalowania i rozdziału odpowiedzialności.
CQRS skaluje się przez separację, Event Sourcing przez trwałość i rozproszenie, razem tworząc odporną, elastyczną architekturę.

### Slajd 22: Event Sourcing – definicja

#### 1. Stan systemu wynika z sekwencji niezmiennych zdarzeń, a nie z ostatniego zapisu tabeli.
Każde zdarzenie reprezentuje nieodwracalny fakt z historii domeny, a odtworzenie aktualnego stanu to po prostu przetworzenie tej sekwencji.

#### 2. Każde zdarzenie opisuje fakt, który już się wydarzył i nie podlega edycji.
Zamiast aktualizacji mamy kolejne zdarzenia pokazujące ewolucję systemu, co utrzymuje pełną przejrzystość zmian.

#### 3. Aplikacja rekonstruuje aktualny stan poprzez odtworzenie strumienia.
Zdarzenia są przetwarzane w kolejności, by uzyskać finalny wynik, a mechanizm ten może być zoptymalizowany snapshotami.

#### 4. Pozwala przechować pełną historię zmian bez potrzeby kolumn „updated_at”.
System sam w sobie jest źródłem audytu, więc nie trzeba implementować dodatkowych mechanizmów śledzenia zmian.

#### 5. Umożliwia analizy zdarzeń ex-post bez zmiany kodu domeny.
Dane mogą być reinterpretowane po czasie do nowych zastosowań, co stanowi świetne źródło wiedzy dla analityki, BI i machine learning.

### Slajd 23: Zdarzenia domenowe – charakterystyka

#### 1. Nazwa w czasie przeszłym jednoznacznie wskazuje, że fakt już zaistniał.
Przykład: „OrderPlaced”, „PaymentConfirmed” – sugerują zakończone działania, co eliminuje niejasność co do intencji i stanu.

#### 2. Payload zawiera tylko dane potrzebne odbiorcom, niecałą encję.
Minimalizm zmniejsza coupling i poprawia ewolucję schematu, co ułatwia przetwarzanie i serializację zdarzeń.

#### 3. Są uporządkowane i wersjonowane, by zapewnić kompatybilność w czasie.
Starsze i nowsze wersje zdarzenia mogą współistnieć w systemie, co jest kluczowe przy długowiecznych systemach i migracjach.

#### 4. Mogą być kodowane w JSON, Avro lub Protobuf – ważna jest ewolucja schematu.
Dobór formatu zależy od wymagań co do wielkości, szybkości i kontraktów, ale kluczowe jest zachowanie zgodności między wersjami.

#### 5. Jedno zdarzenie może wyzwolić wiele reakcji: projekcję, e-mail, rozliczenie.
Zdarzenia to centralne punkty integracji w systemie, co pozwala na bogate scenariusze bez sprzęgania serwisów.

### Slajd 24: Model faktów w czasie

#### 1. Każdy agregat posiada własną oś czasu zdarzeń z rosnącą wersją.
Pozwala to na sekwencyjne śledzenie zmian i wykrywanie konfliktów, co ułatwia zarządzanie wersjami w zapisie.

#### 2. Równoległe komendy wykrywa się przez konflikt wersji, eliminując globalne locki.
System wie, że ktoś inny zaktualizował dane wcześniej, więc można wtedy zwrócić błąd lub spróbować ponownie.

#### 3. Analizy „co-gdyby” można wykonać, odtwarzając alternatywny scenariusz.
Wystarczy odtworzyć agregat z wybranego punktu i przetworzyć inne zdarzenia, co jest przydatne w testach, symulacjach i predykcjach.

#### 4. Historia pozwala zbudować machine-learning features bez dodatkowego ETL.
Dane do trenowania modelu są już gotowe w logu zdarzeń, więc można łatwo obliczyć cechy behawioralne.

#### 5. Przy migracjach schematu wystarczy odtworzyć stan z nowego kodu projekcji.
Stare dane nie wymagają migracji – wystarczy nowy handler, co ogranicza ryzyko błędów i skraca czas wdrożeń.

### Slajd 25: Time-travel debugging i audyt

#### 1. Można odtworzyć stan systemu z dowolnej minuty sprzed miesięcy.
Wystarczy przetworzyć zdarzenia do wybranego punktu w czasie, co jest idealne do analizy incydentów produkcyjnych.

#### 2. Pomaga zidentyfikować przyczynę błędu, reprodukując dokładną sekwencję działań.
Można prześledzić każde zdarzenie, które doprowadziło do stanu końcowego, co ułatwia debugowanie i post-mortem analizy.

#### 3. Spełnia rygorystyczne wymagania regulacyjne, np. GDPR.
Daje pełną ścieżkę decyzji biznesowych i zmian danych, co szczególnie ważne w sektorze finansowym czy zdrowotnym.

#### 4. Historię zdarzeń można anonimizować, nie tracąc wartości analitycznej.
Usunięcie danych osobowych nie wpływa na możliwość analizowania trendów, co pozwala pogodzić zgodność z RODO z potrzebami biznesu.

#### 5. Ułatwia wykrywanie nadużyć, bo widać pełną ścieżkę zmian danych.
Można przeanalizować nietypowe sekwencje zdarzeń i powiązać je z użytkownikiem, co wspiera systemy detekcji oszustw i wewnętrznych audytów.

### Slajd 26: Rolling Snapshots – optymalizacja

#### 1. Snapshot to zserializowany stan agregatu po N zdarzeniach.
Przechowuje stan w danym momencie, redukując potrzebę przetwarzania całej historii, co pozwala szybciej odtwarzać stan agregatów.

#### 2. Odtwarzanie zaczyna się od najnowszego snapshotu, skracając czas ładowania.
Pozostałe zdarzenia przetwarza się tylko od momentu snapshotu, co znacząco zwiększa wydajność przy dużej liczbie eventów.

#### 3. Proces snapshotowania działa asynchronicznie, nie blokując ścieżki zapisu.
Snapshoty tworzone są w tle, nie wpływając na przepustowość systemu, co minimalizuje zakłócenia działania aplikacji.

#### 4. Snapshot nie musi być najświeższy – ważna jest poprawność wersji.
Można go odtworzyć do dowolnego punktu po nim przy użyciu późniejszych zdarzeń, wystarczy zachować zgodność wersji agregatu.

#### 5. Włącza się go dopiero, gdy realne metryki P95 odczytu przekroczą próg.
Snapshotowanie to decyzja inżynieryjna, oparta na obserwacji wydajności, co pozwala unikać przedwczesnej optymalizacji.

### Slajd 27: Event Store jako kolejka

#### 1. Jedno fsync zapisuje zarówno dane, jak i informację do publikacji.
Zmniejsza to liczbę operacji I/O, skracając czas odpowiedzi i gwarantując atomowość zapisu oraz publikacji.

#### 2. Chaser-proces monitoruje numer sekwencyjny i wysyła zdarzenia do brokera.
Nie trzeba czekać w synchronizacji – chaser robi to równolegle, co zapewnia płynne przejście między zapisanym zdarzeniem a jego propagacją.

#### 3. Zmniejsza latencję komendy, bo nie czeka na potwierdzenie z kolejki.
Komenda kończy się szybciej, bo zdarzenie jest tylko zapisane, a nie natychmiast rozesłane, co zwiększa szybkość odpowiedzi systemu.

#### 4. Awaria brokera nie blokuje zapisu – zdarzenia czekają w logu.
Można później nadrobić publikację bez utraty danych, dzięki czemu system pozostaje dostępny nawet przy niedostępności kolejki.

#### 5. Eliminujemy potrzebę kosztownego dwufazowego commitu.
Nie trzeba używać transakcji rozproszonych, co upraszcza architekturę i zwiększa niezawodność.

### Slajd 28: Task-Based UI – odzyskiwanie intencji

#### 1. Interfejs rozbija duży formularz na konkretne akcje użytkownika.
Zamiast jednej operacji „zapisz wszystko” mamy serię zrozumiałych kroków, co poprawia UX i odwzorowanie logiki domeny.

#### 2. Każde kliknięcie generuje jedną, semantyczną komendę domenową.
Przykład: „Zarezerwuj pokój” zamiast „update(status = ‘reserved’)”, co sprawia, że intencja użytkownika staje się jednoznaczna.

#### 3. Walidacja w czasie rzeczywistym zmniejsza frustrację i liczbę błędów.
System może odrzucić komendę natychmiast, z podaniem przyczyny, co skraca czas poprawiania błędów i zwiększa satysfakcję użytkownika.

#### 4. Nazewnictwo UI mapuje się bezpośrednio na język domeny.
Interfejs staje się odzwierciedleniem procesów biznesowych, co ułatwia komunikację między zespołem technicznym a biznesem.

#### 5. Komendy są małe i idempotentne, więc łatwe do testów i retrierów.
Każda akcja użytkownika to niezależna, bezpieczna operacja, co ułatwia budowanie systemów odpornych na błędy sieciowe.

### Slajd 29: Komendy kontra zdarzenia – różnice

#### 1. Komenda wyraża przyszłą intencję, zdarzenie opisuje przeszły fakt.
Komenda mówi, co chcemy zrobić; zdarzenie – co się już stało, co stanowi kluczowy rozdział w logice systemu.

#### 2. Komenda może zostać odrzucona, zdarzenia nie da się „cofnąć”.
Weryfikacja i walidacja odbywają się po stronie zapisu, natomiast zdarzenia są trwałe i niepodważalne.

#### 3. Wyraźny podział porządkuje rozmowę z interesariuszami.
Biznes może jasno określić intencje (komendy) i fakty (zdarzenia), co poprawia komunikację i modelowanie domeny.

#### 4. Stosowanie czasu przeszłego w nazwach zdarzeń usuwa dwuznaczności.
Przykład: „InvoiceSent” vs „SendInvoice” – różnica w znaczeniu jest jasna, co pomaga uniknąć błędów interpretacyjnych.

#### 5. Klient generuje GUID komendy, co gwarantuje idempotencję operacji.
Id komendy pozwala backendowi rozpoznać, czy już została przetworzona, co ułatwia radzenie sobie z problemami sieci i powtórzeniami.

### Slajd 30: Idempotencja – dlaczego jest potrzebna

#### 1. W sieci zawsze musimy liczyć się z retry po timeout-cie lub awarii.
Brak potwierdzenia nie znaczy, że komenda nie została wykonana, więc system musi umieć to bezpiecznie obsłużyć.

#### 2. Handlery komend ignorują duplikaty dzięki unikalnemu identyfikatorowi.
Komenda z tym samym ID nie zostanie wykonana ponownie, co upraszcza kod i zwiększa bezpieczeństwo operacji.

#### 3. Konsumenci zdarzeń utrzymują tabelę „processed_events” i pomijają powtórki.
Dzięki temu nie przetwarzają dwa razy tego samego zdarzenia, co chroni przed duplikacją danych i efektów ubocznych.

#### 4. Ułatwia testy end-to-end, bo scenariusz można odtworzyć wielokrotnie.
Powtarzalność testów poprawia ich niezawodność, a idempotencja zmniejsza też problemy z „flaky tests”.

#### 5. Zmniejsza ryzyko niechcianych efektów przy deployach typu blue/green.
Komendy i zdarzenia mogą być ponawiane w sposób bezpieczny, więc system nie psuje danych nawet przy wielokrotnym uruchomieniu.

### Slajd 31: Eventual Consistency – model użytkowy

#### 1. Po zapisie odczyt może chwilę pokazywać stary stan – trzeba to komunikować w UI.
Użytkownik nie powinien być zaskoczony, że dane nie zaktualizowały się od razu, dlatego warto jasno sygnalizować, że trwa przetwarzanie.

#### 2. Najczęściej wystarczy informacja „Twoje dane są aktualizowane w tle”.
Prosty komunikat może zapobiec frustracji i nieporozumieniom, poprawiając przejrzystość działania systemu.

#### 3. Mechanizmy kompensacyjne mogą wycofać operację, gdy kolejny krok sagii zawiedzie.
W przypadku błędu, system sam anuluje skutki wcześniejszych akcji, co zwiększa spójność i zaufanie użytkownika.

#### 4. Monitoring lag-u projekcji gwarantuje, że nie przekracza on SLA biznesowego.
Opóźnienie między zapisem a odczytem jest mierzone i kontrolowane, co pozwala reagować, zanim wpłynie na doświadczenie użytkownika.

#### 5. W zamian zyskujemy wysoką dostępność i brak globalnych locków.
System może działać nawet przy dużym obciążeniu i częściowej niedostępności, co jest kluczowe w skalowalnych i rozproszonych środowiskach.

### Slajd 32: Wyzwania implementacji CQRS

#### 1. Podwójny model danych oznacza więcej miejsc na błąd w wersjonowaniu.
Trzeba pamiętać o zgodności między komendami, zdarzeniami i projekcjami, bo zmiany wymagają większej uwagi i testów.

#### 2. Konieczna jest automatyczna migracja projekcji przy zmianach schematu zdarzeń.
Projekcje mogą się zdezaktualizować po zmianach modelu domenowego, dlatego potrzebny jest mechanizm „rebuild” i strategia wersjonowania.

#### 3. Zespół DevOps musi utrzymać kolejkę, replikę i monitorować lag.
Wymaga to nowych kompetencji i narzędzi operacyjnych, ponieważ monitoring staje się krytycznym elementem systemu.

#### 4. Debugowanie wymaga korelacji komenda → zdarzenie → projekcja.
Błędy trzeba śledzić przez cały łańcuch przetwarzania, co zwiększa złożoność diagnostyki, ale też jej precyzję.

#### 5. Over-engineering grozi tam, gdzie domena jest prostym CRUD-em.
Wdrożenie CQRS nie ma sensu w prostych systemach bez skomplikowanej logiki, bo może to tylko niepotrzebnie zwiększyć koszty utrzymania.

### Slajd 33: Wyzwania implementacji Event Sourcing

#### 1. Projektowanie zdarzeń wymaga dobrej znajomości domeny i przewidywania zmian.
Raz zapisane zdarzenia pozostają w systemie na zawsze, więc trzeba je dobrze przemyśleć, by nie stały się kulą u nogi.

#### 2. Każdy błąd w „fakcie” jest trwały; trzeba emitować zdarzenia korekcyjne.
Nie można cofnąć ani poprawić istniejącego zdarzenia – korekta odbywa się przez dodanie nowego zdarzenia.

#### 3. Snapshoty i retencja logu wprowadzają dodatkową politykę utrzymania.
Trzeba decydować, co trzymać, jak długo i kiedy archiwizować, co wpływa na koszt, wydajność i zgodność regulacyjną.

#### 4. Wersjonowanie schematu zdarzenia musi być wstecznie kompatybilne.
Nowi i starzy konsumenci muszą działać równolegle, więc potrzebne jest świadome zarządzanie kontraktami danych.

#### 5. Testy integracyjne uruchamiają pełny pipeline zapisu i odczytu, co podnosi koszt CI.
Testowanie systemu z Event Sourcingiem wymaga rejestrowania i odtwarzania zdarzeń, co może wydłużyć czas testów i złożoność środowiska CI/CD.

### Slajd 34: Obserwowalność i monitoring lagów

#### 1. Każde zdarzenie dostaje znacznik czasu i numer sekwencyjny.
To pozwala dokładnie śledzić, kiedy i w jakiej kolejności zdarzenia były emitowane, co ułatwia analizę wydajności i debugowanie.

#### 2. Metryka „current_position – published_position” pokazuje opóźnienie Chasera.
Można łatwo zidentyfikować, czy Read Model nadąża za Write Modelem, co jest ważnym wskaźnikiem zdrowia systemu.

#### 3. Correlation ID przechodzi przez komendę, zdarzenie i HTTP response.
Pozwala to powiązać konkretne żądanie użytkownika z jego skutkami w systemie, co ułatwia analizę incydentów i śledzenie problemów.

#### 4. Trace’y są agregowane np. w Jaeger/Zipkin, ułatwiając docieranie do źródła błędu.
Rozproszone śledzenie pokazuje cały przebieg działania w mikrousługach, co pozwala szybciej wykrywać źródło opóźnienia lub awarii.

#### 5. Alerting proaktywnie informuje, gdy Read Model opóźnia się ponad próg SLA.
System automatycznie wykrywa problemy z propagacją zdarzeń, dzięki czemu można szybko reagować, zanim użytkownicy zauważą problem.

### Slajd 35: Impedance Mismatch a zdarzenia

#### 1. W tradycyjnym ORM trzeba mapować obiekty do SQL, co generuje złożoność.
Wymusza to dodatkowe warstwy kodu, konfiguracji i migracji schematów, co często prowadzi do błędów i trudnych do utrzymania zależności.

#### 2. Zdarzenia są natywne dla domeny i magazynu, eliminując warstwę mapowania.
Nie trzeba ich tłumaczyć na inne formaty – system działa „na faktach”, co upraszcza model danych i redukuje błędy.

#### 3. Brak N+1 i lazy loading – aplikacja przetwarza listę faktów w pamięci.
Wszystkie potrzebne informacje są już zawarte w zdarzeniach, co poprawia wydajność i przewidywalność działania.

#### 4. BI/ML korzysta z tego samego logu, bez budowania osobnych ETL-i.
Dane są spójne i dostępne bez potrzeby kopiowania do osobnych hurtowni, co skraca czas i koszty analityki.

#### 5. Zespół uczy się jednego modelu danych, co skraca onboarding.
Nie trzeba tłumaczyć różnic między bazą, API i kodem domenowym, co ułatwia wejście w projekt i współpracę między działami.

### Slajd 36: Saga Pattern – podstawy

#### 1. Saga dzieli kompleksową operację na serię lokalnych transakcji.
Każdy krok wykonuje się niezależnie w jednym serwisie, a całość jest zarządzana przez sekwencję zdarzeń.

#### 2. Po błędzie uruchamiane są kompensacje przywracające spójny stan.
Zamiast rollbacków mamy operacje „odwracające” poprzednie zmiany, co działa nawet w systemach rozproszonych.

#### 3. Krok pivot wyznacza „punkt bez powrotu”, po którym tylko kompensacje są możliwe.
To granica między możliwym anulowaniem a kontynuacją procesu, co pomaga w modelowaniu ryzyka i transakcyjności.

#### 4. Saga może działać w trybie choreografii lub orkiestracji.
W choreografii każdy serwis reaguje samodzielnie na zdarzenia, a w orkiestracji centralny komponent steruje kolejnymi krokami.

#### 5. Zapisy zdarzeń sagi są również audytowane w Event Store.
Cały przebieg procesu jest możliwy do odtworzenia i analizy, co ułatwia debugowanie i raportowanie.

### Slajd 37: Frameworki i biblioteki – Java

#### 1. Axon Framework oferuje command-bus, event-store i silnik sag w jednym ekosystemie.
To kompleksowe rozwiązanie wspierające pełny cykl CQRS + Event Sourcing, integrujące się dobrze ze Springiem i JPA.

#### 2. Lagom udostępnia Event Sourcing i CQRS out-of-the-box na Akka Cluster.
Bazuje na modelu aktorów i wspiera skalowanie oraz replikację, sprawdzając się w asynchronicznych systemach.

#### 3. Eventuate Tram implementuje transactional outbox i sagas zgodnie z patternami microservices.io.
Wspiera niezawodną komunikację zdarzeniową i lokalne transakcje, ułatwiając wdrażanie wzorców DDD.

#### 4. Spring Boot integruje się z nimi przez startery, skracając czas konfiguracji.
Umożliwia szybkie prototypowanie i wdrożenie, korzystając z dużej społeczności i wsparcia.

#### 5. Wybór zależy od potrzeb: monolit modułowy vs rozproszony klaster.
Axon lepiej sprawdza się w większych systemach domenowych, Eventuate i Lagom w mikroserwisach.

### Slajd 38: Frameworki i biblioteki – .NET

#### 1. MediatR dostarcza prosty mediator do patternu command/query handler.
Pozwala rozdzielić odpowiedzialność bez dużych zależności i nadaje się do lekkiego CQRS.

#### 2. EventStoreDB zapewnia bazę logu zdarzeń z gRPC i subskrypcjami catch-up.
Jest dedykowanym Event Storem, wspierającym wersjonowanie i projekcje.

#### 3. NServiceBus łączy routing komunikatów z silnikiem sag i retry-policy.
Oferuje zaawansowane scenariusze orkiestracji i niezawodności, dobry dla systemów enterprise.

#### 4. Dapr abstrahuje message-broker i state-store, umożliwiając CQRS-lite na kontenerach.
Buduje aplikacje event-driven bez silnego związania z konkretną technologią, idealne do Kubernetesa.

#### 5. CQRS w .NET integruje się dobrze z Azure Service Bus i Functions.
Microsoft dostarcza natywne komponenty wspierające komunikację zdarzeniową i architekturę serverless.

### Slajd 39: Frameworki i biblioteki – Python i inne

#### 1. Biblioteka eventsourcing implementuje event-store, snapshoty i projekcje zgodne z DDD.
Pozwala szybko stworzyć system CQRS + ES w Pythonie, dobrze sprawdzający się w mniejszych projektach.

#### 2. FastAPI ma szablony CQRS-lite z async command/query bus opartym na RabbitMQ.
Umożliwia budowę wydajnych API z podziałem na read/write, wspierając asynchroniczność.

#### 3. Faust lub Kafka-Streams w Pythonie pozwalają budować projekcje strumieniowe.
Doskonałe do przetwarzania danych na żywo z transformacjami i agregacjami.

#### 4. Go i Rust oferują lekkie biblioteki (EventSourcing-Go, Cqrs-rs) do serwisów o niskim narzucie.
Pozwalają budować stabilne i szybkie mikroserwisy tam, gdzie liczy się wydajność.

#### 5. Architektura ważniejsza niż język – CQRS działa w każdym ekosystemie.
Kluczem jest dyscyplina event-driven, niezależnie od wyboru technologii.

### Slajd 40: Kryteria decyzji „czy stosować CQRS”

#### 1. Wysoka asymetria R/W i potrzeba elastycznego skalowania odczytu.
Jeśli 90% operacji to zapytania, CQRS pozwala zoptymalizować odczyt osobno i zwiększyć wydajność.

#### 2. Złożona domena z licznymi regułami, które trudno zmieścić w CRUD.
Oddzielenie intencji od danych upraszcza kod i porządkuje odpowiedzialności.

#### 3. Konieczność pełnego audytu i historii zmian dla compliance.
Event Sourcing zapewnia pełną ścieżkę zmian i kontekst decyzji, co jest nieocenione w sektorach regulowanych.

#### 4. Wiele zespołów równolegle modyfikuje różne aspekty systemu.
Rozdzielenie modeli umożliwia niezależną pracę bez kolizji, wspierając skalowalność organizacyjną.

#### 5. Prostym systemom CRUD niepotrzebna ta złożoność.
CQRS nie powinien być celem samym w sobie – warto go stosować tylko tam, gdzie rozwiązuje realne problemy.

### Slajd 41: Strategia adopcji w istniejącym systemie

#### 1. Zaczynamy od wyodrębnienia pojedynczego modułu o największej asymetrii R/W.
Na przykład raportowanie zamówień lub logowanie aktywności użytkowników – niskie ryzyko, wysoka wartość.

#### 2. Równolegle utrzymujemy stary CRUD i nowy CQRS, migrując ruch stopniowo.
Zmiany wprowadzane są iteracyjnie, co zapewnia stabilność działania.

#### 3. Wprowadzamy Event Sourcing tylko tam, gdzie wartość historyczna jest największa.
Faktury, finanse, audyt – nie trzeba od razu stosować go wszędzie.

#### 4. Edukujemy zespół przez warsztaty DDD i kata event-storming.
Zrozumienie wzorców i języka domeny to klucz do sukcesu wdrożenia.

#### 5. Monitorujemy metryki lag-u i kosztów, aby uzasadnić dalszą migrację.
Dane wspierają decyzje o kolejnych etapach transformacji architektury.

### Slajd 42: Najczęstsze pułapki i anty-wzorce

#### 1. Over-engineering: wdrożenie CQRS w prostym CRUD bez potrzeby.
Złożoność nie uzasadnia się w prostych przypadkach – CQRS musi odpowiadać na realne problemy.

#### 2. Łączenie read i write w tej samej bazie niweczy separację.
Tracimy izolację, elastyczność i niezależne skalowanie.

#### 3. Publikowanie zdarzeń tylko „dla integracji”, a nie jako źródło prawdy.
Eventy muszą reprezentować rzeczywiste fakty domenowe, nie być tylko techniczną wygodą.

#### 4. Brak idempotencji w konsumentach prowadzi do duplikacji danych.
To częsta przyczyna błędów produkcyjnych – nie można tego lekceważyć.

#### 5. Zaniedbanie monitoringu skutkuje „niewidzialnym” lagiem.
Bez metryk nie wiemy, że coś się psuje – monitoring to integralna część CQRS/ES.

### Slajd 43: Podsumowanie i rekomendacje

#### 1. CQRS + Event Sourcing daje ogromne korzyści w złożonych, skalowalnych systemach.
Elastyczność, niezawodność i odwzorowanie domeny czynią go doskonałym wyborem dla dużych aplikacji.

#### 2. Fundamentem jest rozdzielenie komend i zapytań oraz traktowanie zdarzeń jako faktów.
Zmienia to sposób myślenia – z CRUD na intencje i fakty, co daje testowalny i komunikowalny model.

#### 3. Korzyści (skalowanie, audyt, elastyczność) przychodzą kosztem złożoności.
Wymaga nauki i narzędzi, ale w odpowiednich przypadkach inwestycja się zwraca.

#### 4. Zaczynamy małymi krokami, mierzymy lag i edukujemy zespół.
Stopniowa migracja i ciągła edukacja zwiększają szanse sukcesu.

#### 5. Stosuj tam, gdzie asymetria R/W i historia mają znaczenie.
CQRS/ES to narzędzie – nie cel sam w sobie. Używaj go świadomie i tam, gdzie naprawdę pomaga.
