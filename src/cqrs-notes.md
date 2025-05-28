### Slajd 1: Agenda prezentacji

1. Dlaczego klasyczny CRUD hamuje rozwój złożonych systemów
2. Podstawy Command-Query Separation i droga do CQRS
3. Kluczowe komponenty architektury CQRS + Event Sourcing
4. Korzyści, kompromisy i typowe wyzwania wdrożeniowe
5. Praktyczne wskazówki, narzędzia oraz podsumowanie rekomendacji

### Slajd 2: Ograniczenia podejścia CRUD

Podejście CRUD w złożonych systemach szybko staje się trudne w utrzymaniu i ogranicza możliwości skalowania. Wspólny 
model danych dla operacji zapisu i odczytu wymusza kompromisy, obniża przejrzystość oraz zwiększa podatność na błędy. 
Z biegiem czasu logika biznesowa rozprasza się pomiędzy warstwami aplikacji, co utrudnia jej zrozumienie, testowanie i 
rozwój. Długotrwałe transakcje, często występujące przy raportowaniu, mogą blokować dostęp do bazy danych i spowalniać 
działanie systemu. W efekcie relacyjna baza danych staje się wąskim gardłem całego rozwiązania.

### Slajd 3: Command-Query Separation (CQS)

Zasada Command-Query Separation (CQS) wprowadza wyraźne rozróżnienie między metodami zmieniającymi stan systemu (komendy)
a tymi, które jedynie odczytują dane (zapytania). Dzięki temu unika się niejednoznacznych operacji pełniących obie funkcje 
jednocześnie, co znacznie ułatwia analizę, testowanie i debugowanie kodu. Zapytania, jako operacje bez skutków ubocznych, 
mogą być bezpiecznie powtarzane, cachowane i uruchamiane równolegle. Komendy natomiast zwracają jedynie potwierdzenie wykonania 
lub informację o błędzie, co sprawia, że ich działanie jest przewidywalne i przejrzyste. Podejście to upraszcza API oraz
poprawia czytelność i ułatwia zrozumienie rozwiązania.

### Slajd 4: Od CQS do CQRS

CQRS (Command Query Responsibility Segregation) to wzorzec architektoniczny, który rozwija ideę CQS, przenosząc rozdział 
operacji zapisu i odczytu na poziom całej architektury systemu. Komendy modyfikują stan i generują zdarzenia, które stają
się głównym źródłem prawdy. Zapytania natomiast opierają się na dedykowanych, zoptymalizowanych projekcjach danych, 
tworzonych z myślą o konkretnych potrzebach użytkownika. Dzięki temu możliwe jest zastosowanie różnych technologii storage po 
obu stronach architektury, co zwiększa elastyczność, skalowalność i wydajność. CQRS zakłada spójność ostateczną 
(eventual consistency), co oznacza, że dane po stronie odczytu mogą być chwilowo niespójne, ale są synchronizowane w 
sposób kontrolowany. Podejście oparte na zdarzeniach oraz modularna struktura rozwiązania  ułatwiają rozwój, testowanie i 
utrzymanie złożonych systemów.

### Slajd 5: Oddzielenie modeli zapisu i odczytu

Rozdzielenie modeli zapisu i odczytu pozwala precyzyjnie dostosować każdą część systemu do jej roli. Model zapisu koncentruje 
się na logice biznesowej i walidacji danych, natomiast model odczytu służy do budowy zoptymalizowanych widoków, 
dopasowanych do potrzeb interfejsu użytkownika lub API. Taka separacja zmniejsza zależności między warstwami, 
co przyspiesza rozwój, upraszcza testowanie i ogranicza ryzyko wprowadzania błędów. Projekcje tworzone na podstawie zdarzeń 
można elastycznie modyfikować lub odtwarzać bez ingerencji w dane domenowe. 

### Slajd 6: Niezależne skalowanie odczytu zapisu

CQRS pozwala na niezależne skalowanie odczytu i zapisu, co zwiększa elastyczność systemu. Odczyty, które zwykle dominują w 
ruchu (nawet 90%), można skalować horyzontalnie poprzez replikację, cache (np. Redis) lub CDN, co redukuje obciążenie 
głównej bazy i zapewnia niskie opóźnienia. Zapis skaluje się selektywnie, np. przez sharding po ID klienta, 
umożliwiając równoległe przetwarzanie operacji. Oddzielenie tych warstw eliminuje problem blokowania – długie zapytania 
nie wpływają na zapisy, co zmniejsza ryzyko locków i deadlocków. Replikacja danych w różnych regionach pozwala lokalnie 
serwować treści, poprawiając szybkość działania aplikacji. Dodatkowo CQRS umożliwia lepsze zarządzanie kosztami oraz 
niezależne wdrażanie nowych funkcji, co przyspiesza rozwój systemu.

### Slajd 7: Read Model

Read Model w CQRS służy wyłącznie do szybkiego i prostego odczytu danych, z myślą o interfejsie użytkownika. Dane są w 
nim zdenormalizowane i dostosowane do konkretnych widoków, co upraszcza frontend i przyspiesza odpowiedzi. Nie zawiera 
logiki biznesowej, więc jest prosty w testowaniu i modyfikacji. Aktualizacje odbywają się asynchronicznie na podstawie 
zdarzeń, co zwiększa wydajność kosztem minimalnych opóźnień. Struktura read modelu jest niezależna od modelu zapisu i 
dostosowana do potrzeb raportowania czy UI. W połączeniu z Event Sourcing może być w pełni odbudowany 
ze zdarzeń, co czyni go elastycznym i odpornym na awarie.

### Slajd 8: Write Model

Write Model w CQRS to miejsce, gdzie koncentruje się logika biznesowa systemu. Opiera się na Agregatach, które łączą stan i
reguły domenowe, weryfikując poprawność komend przed ich wykonaniem. Po akceptacji komendy Agregat emituje zdarzenia
zapisywane w Event Store, stanowiące jedyne źródło prawdy o zmianach. Struktura danych jest silnie znormalizowana,
co pozwala precyzyjnie odwzorować reguły biznesowe, choć nie jest zoptymalizowana pod kątem odczytu. Skalowanie
Write Modelu odbywa się przez partycjonowanie strumieni zdarzeń, np. według ID klienta, co umożliwia równoległe i
wydajne przetwarzanie operacji. Dzięki temu model zachowuje spójność, odporność na blokady i dobrą wydajność przy dużym ruchu transakcyjnym.

### Slajd 9: Commands – kontrakt intencji

Komendy w CQRS to jednoznaczne instrukcje wyrażające intencje użytkownika, takie jak „ZmieńEmailKlienta” czy „DezaktywujProdukt”. 
Są czytelne dla programistów i osób biznesowych, zawierając wyłącznie niezbędne dane, co zmniejsza ryzyko błędów i nadużyć. 
Komenda może zostać odrzucona, jeśli narusza reguły domenowe lub wersja danych jest nieaktualna, co chroni spójność systemu. 
Zamiast pełnych danych zwracają jedynie potwierdzenie lub błąd, upraszczając API. Każda komenda powinna mieć unikalny 
identyfikator, by zapewnić idempotencję – kluczową w środowiskach rozproszonych. Komendy nadają operacjom jasny 
kontekst i wzmacniają odporność systemu na błędy i duplikacje.

### Slajd 10: Queries – kontrakt odczytu

Queries w CQRS służą wyłącznie do odczytu i nie zmieniają stanu systemu, co czyni je bezpiecznymi, przewidywalnymi i łatwymi
do testowania. Można je wywoływać wielokrotnie bez skutków ubocznych, co sprzyja stabilności i umożliwia skuteczne cachowanie.
Zwracają dane w formacie gotowym do użycia, takim jak DTO, listy czy strumienie, co upraszcza frontend i przyspiesza
działanie interfejsu. Zmiany w zapytaniach nie wpływają na logikę domenową ani zapis, co pozwala elastycznie rozwijać UI.
Queries są lekkie, szybkie i jednoznaczne – realizują proste żądania typu „podaj dane”, bez decyzji czy logiki biznesowej.
Taka separacja upraszcza kod, poprawia skalowalność i wspiera jakość architektury systemu.

### Slajd 11: Event Bus

Event Bus w CQRS odpowiada za asynchroniczne przekazywanie zdarzeń między komponentami systemu. Po wykonaniu komendy 
zdarzenia są natychmiast publikowane, a dalsze działania – jak aktualizacja projekcji czy integracje – odbywają 
się niezależnie. Dzięki wzorcowi publish/subscribe moduły nie są silnie sprzężone, co upraszcza integrację i 
zwiększa modularność. Event Bus wspiera niezawodność poprzez ponawianie i gwarantowane dostarczenie. 
Umożliwia też łatwe dodawanie nowych funkcji – projekcji, analiz, powiadomień – bez ingerencji w istniejący kod, zgodnie z regułą open/close.

### Slajd 12: Event Store

Event Store w CQRS i event sourcingu to centralny rejestr wszystkich zmian w systemie, w którym każda decyzja biznesowa zapisywana 
jest jako niezmienne zdarzenie w chronologicznym porządku. Zamiast nadpisywać stan, agregaty wyliczają go na podstawie
sekwencji zdarzeń, co zwiększa przejrzystość i precyzję logiki domenowej. Event Store działa jako struktura 
tylko-do-zapisu (append-only), co ułatwia replikację, partycjonowanie i eliminuje konflikty przy równoczesnym zapisie. 
Dzięki pełnej historii możliwe jest odtworzenie dowolnego stanu systemu, analiza zdarzeń w czasie (time-travel debug), 
audyt oraz spełnienie wymagań compliance. Zapis i publikacja zdarzeń są atomowe, więc Event Store może pełnić również 
funkcję kolejki zdarzeń, upraszczając komunikację między komponentami. To czyni go nie tylko bazą danych, ale sercem 
całej architektury zdarzeniowej – wspierającym skalowalność, odporność i pełną obserwowalność systemu.

### Slajd 13: Process Managers i Sagi

Process Managers i Sagi obsługują złożone, wieloetapowe procesy biznesowe, reagując na zdarzenia i wysyłając komendy w 
odpowiedniej kolejności. Umożliwiają realizację operacji rozłożonych w czasie, bez blokowania systemu i z
odpornością na błędy. Zamiast globalnych transakcji stosują lokalne działania i mechanizmy kompensacji, które cofają 
skutki w razie niepowodzenia. Każda Saga przechowuje własny stan procesu, co pozwala wznawiać go po awarii. Komunikacja 
między serwisami odbywa się wyłącznie przez zdarzenia, co zmniejsza zależności i zwiększa niezawodność. Kluczowym 
momentem jest tzw. krok pivot – po jego wykonaniu możliwa jest już tylko kompensacja, co upraszcza podejmowanie decyzji. 
Istnieją dwa style implementacji: choreografia (bez centralnej kontroli) i orkiestracja (z centralnym koordynatorem). 
Wszystkie zdarzenia trafiają do Event Store, zapewniając pełną historię, audyt i możliwość odtworzenia procesu.

### Slajd 14: Event Sourcing

Event Sourcing to wzorzec, w którym stan systemu wynika nie z bieżących wartości w bazie, lecz z sekwencji zdarzeń
opisujących fakty, które już zaszły – np. „ZamówienieWysłane” czy „ProduktWycofany”. Zdarzenia są trwałe, niezmienne
i zapisywane w kolejności ich wystąpienia, co tworzy pełną, audytowalną historię zmian. Zamiast aktualizować dane, system
zapisuje nowe zdarzenia, które pokazują, jak stan ewoluował. Agregaty odtwarzają swój stan poprzez przetworzenie 
strumienia zdarzeń. Dla poprawienia wydajności można stosować snapshoty – zapis aktualnego stanu, od którego odtwarzanie jest szybsze.
Nie potrzeba pól typu `updated_at` – sam Event Store pełni rolę dziennika zmian. Zdarzenia mogą być też wykorzystywane
później, np. do analiz, raportów, prognoz czy rekomendacji – bez zmian w logice domenowej. Dzięki temu system staje się w
pełni śledzalny, zrozumiały i gotowy do dalszego rozwoju opartego na rzeczywistych danych z przeszłości.

### Slajd 15: CQRS + Event Sourcing

Połączenie CQRS i Event Sourcing tworzy silną, komplementarną architekturę idealną dla systemów rozproszonych. 
CQRS precyzyjnie określa momenty powstawania i konsumpcji zdarzeń, zapewniając kontrolę i przejrzystość zmian. 
Event Sourcing zapisuje każdą zmianę jako trwałe zdarzenie, tworząc pełną historię systemu bez potrzeby dodatkowego 
audytu. Read Model można łatwo odbudować, przetwarzając ponownie strumień zdarzeń. Te same zdarzenia mogą zasilać wiele 
niezależnych projekcji, co ułatwia rozwój zgodnie z zasadą Open/Closed. CQRS zapewnia separację odpowiedzialności i 
skalowalność, a Event Sourcing – trwałość, audytowalność i możliwość przywrócenia stanu. Razem dają elastyczną, 
odporną i w pełni śledzalną architekturę nowoczesnych aplikacji.

### Slajd 16: Zdarzenia domenowe

Zdarzenia domenowe opisują to, co już się wydarzyło – np. „ZamówienieZłożone” – i zawsze odnoszą się do przeszłości,
co odróżnia je od komend. Zawierają tylko niezbędne dane, a nie całe encje, co zmniejsza zależności i upraszcza rozwój systemu.
Zdarzenia są trwałe, uporządkowane i wersjonowane, co pozwala obsługiwać różne wersje bez przerywania działania. Mogą być
kodowane np. w JSON (dla czytelności) lub Protobuf (dla wydajności), z zachowaniem kompatybilności. Jedno zdarzenie może
uruchamiać wiele niezależnych reakcji – aktualizacje projekcji, powiadomienia, integracje. Dzięki luźnym powiązaniom moduły
pozostają niezależne, co zwiększa elastyczność architektury. Zdarzenia stają się głównym mechanizmem komunikacji – stabilnym,
przejrzystym i łatwym do rozbudowy.

### Slajd 17: Komendy kontra zdarzenia

Rozróżnienie między komendami a zdarzeniami to fundament CQRS i Event Sourcingu. Komenda (np. SendInvoice) wyraża intencję
wykonania akcji w przyszłości i może zostać odrzucona, np. z powodu walidacji, konfliktu wersji lub braku uprawnień.
Zdarzenie (np. InvoiceSent) to fakt, który już się wydarzył – jest nieodwracalnym zapisem historii systemu. Komendy są w
trybie rozkazującym i reprezentują zamiar, zdarzenia – w czasie przeszłym – pokazują, co faktycznie zaszło. To pozwala
biznesowi jasno rozróżnić, co użytkownik chciał, a co faktycznie się stało. Komendy mają unikalne identyfikatory, co
umożliwia bezpieczne sprawdzanie duplikatów, szczególnie w systemach rozproszonych. To podejście zwiększa przejrzystość,
odporność na błędy i ułatwia współpracę między techniką a biznesem.

### Slajd 18: Zdarzenia jako źródło prawdy i wehikuł czasu

Każdy agregat posiada własną oś czasu – chronologiczną sekwencję wersjonowanych zdarzeń, 
które tworzą kompletną historię zmian. Dzięki temu możliwe jest wykrywanie konfliktów przy równoczesnych modyfikacjach 
bez stosowania globalnych blokad, co zwiększa wydajność i odporność systemu. Taka architektura pozwala odtworzyć dowolny 
stan z przeszłości, przeprowadzać symulacje „co by było, gdyby” i testować alternatywne scenariusze bez ryzyka. 
Mechanizm time-travel debugging ułatwia diagnozowanie błędów, analizę incydentów oraz tworzenie raportów post-mortem. 
Pełna historia zdarzeń spełnia wymagania audytu i zgodności z przepisami (np. RODO, GDPR), umożliwiając śledzenie każdej 
zmiany z dokładnością co do czasu i źródła. Dane mogą być wykorzystywane bezpośrednio do analityki czy uczenia maszynowego,
bez potrzeby klasycznego ETL. Zmiany w strukturze danych nie wymagają migracji – wystarczy nowy handler, który inaczej 
zinterpretuje te same zdarzenia. Dzięki temu system staje się bardziej przejrzysty, elastyczny i lepiej przygotowany na
rozwój oraz wymagania regulacyjne.

### Slajd 19: Rolling Snapshots

Rolling Snapshots to technika optymalizacji w Event Sourcingu, która przyspiesza odtwarzanie agregatów w systemach z dużą
liczbą zdarzeń. Zamiast przeliczać całą historię od początku, system zaczyna od ostatniego snapshotu – zapisanego stanu
agregatu – i przetwarza tylko nowsze zdarzenia. Dzięki temu ładowanie agregatów staje się szybsze i bardziej wydajne.
Snapshoty tworzone są asynchronicznie, w tle, bez wpływu na działanie systemu ani blokowania zapisów. Nie muszą być
najnowsze – wystarczy, że pasują do wersji agregatu, a reszta stanu zostanie uzupełniona dynamicznie. Warto wdrażać
snapshoty tylko tam, gdzie rzeczywiście występuje problem z czasem odtwarzania, np. powyżej ustalonego progu (jak P95).
Technika ta pozwala zachować wszystkie zalety Event Sourcingu – historię i audyt – przy wyższej wydajności. Snapshotowanie
to narzędzie optymalizacyjne, a nie obowiązkowy element architektury.

### Slajd 20: Eventual Consistency

Eventual Consistency to model, w którym dane nie są spójne natychmiast po zapisie, ale z czasem osiągają zgodność. Projekcje
aktualizują się asynchronicznie, dlatego UI powinien jasno informować użytkownika o chwilowej niespójności, np. komunikatem
„Dane są aktualizowane w tle”. W razie błędów możliwe jest automatyczne uruchomienie kompensacji, która przywraca logikę
biznesową do właściwego stanu. Kluczowe jest monitorowanie opóźnień – jeśli przekroczą ustalony próg (SLA), system powinien
zareagować, zanim problem dotrze do użytkownika. W zamian za zgodę na tymczasową niespójność zyskujemy wysoką dostępność,
odporność na awarie i brak globalnych blokad. To podejście zwiększa elastyczność i wydajność nowoczesnych systemów rozproszonych.

### Slajd 21: Wyzwania implementacji CQRS

CQRS przynosi wiele korzyści, ale wiąże się też z technicznymi i organizacyjnymi wyzwaniami, które trzeba świadomie kontrolować.
Rozdzielenie zapisu i odczytu oznacza, że każde zdarzenie musi być spójne zarówno z logiką komendy, jak i z projekcjami – co
zwiększa liczbę punktów podatnych na błędy. Migracja projekcji wymaga mechanizmów „rebuildu” oraz strategii wersjonowania
zdarzeń, by uniknąć problemów ze zgodnością danych. Od strony operacyjnej potrzeba nowych kompetencji: DevOps musi zarządzać
nie tylko bazą, ale też kolejkami, retry, replikacją i monitoringiem lagów. Debugowanie staje się bardziej złożone, bo wymaga
śledzenia pełnego przepływu – od komendy, przez zdarzenie, po widok. CQRS to narzędzie, nie cel – w prostych systemach CRUD
jego użycie może wprowadzić niepotrzebną złożoność. Kluczowe jest dopasowanie podejścia do realnej złożoności domeny i konkretnych potrzeb biznesowych.

### Slajd 26: Wyzwania implementacji Event Sourcing

Wdrożenie Event Sourcingu wymaga dojrzałości projektowej i operacyjnej, wykraczającej poza klasyczne modelowanie danych. 
Zdarzenia są trwałe – raz zapisane nie mogą być edytowane, dlatego ich projektowanie i wersjonowanie musi być przemyślane 
od początku. Korekta błędu oznacza emisję nowych zdarzeń, co komplikuje logikę i wymaga zachowania kompatybilności wstecznej. 
Dodatkowym wyzwaniem jest zarządzanie snapshotami i retencją – decyzje dotyczące ich częstotliwości, przechowywania i 
archiwizacji wpływają na koszty, wydajność i zgodność z regulacjami. Wersjonowanie eventów i kontraktów to osobna odpowiedzialność, 
szczególnie gdy w systemie działają konsumenci różnych wersji. Testowanie również staje się bardziej złożone – musi 
obejmować pełen przepływ: komendę, zdarzenie i projekcję. Mimo tych trudności Event Sourcing daje pełną historię, audyt i 
elastyczność, ale wymaga automatyzacji, dyscypliny i świadomego zarządzania cyklem życia danych.

### Slajd 27: Frameworki i biblioteki – Java

W ekosystemie Java dostępnych jest kilka dojrzałych frameworków wspierających CQRS i Event Sourcing, z których każdy odpowiada
na inne potrzeby architektoniczne. **Axon Framework** to kompleksowe rozwiązanie z wbudowanym command busem, event store,
silnikiem sag oraz integracją z Spring Boot i JPA, idealne dla aplikacji z rozbudowaną logiką domenową. **Lagom**, oparty
na Akka Cluster i modelu aktorów, wspiera CQRS i Event Sourcing „z pudełka” i dobrze sprawdza się w systemach rozproszonych,
które muszą być odporne na awarie i łatwo skalowalne. **Eventuate Tram** to z kolei biblioteka skupiająca się na wzorcach takich
jak transactional outbox i saga orchestration, zgodnych z praktykami microservices.io – świetnie pasuje do architektury mikroserwisowej,
gdzie ważna jest lokalna spójność i niezawodna komunikacja. Wszystkie te narzędzia oferują integrację ze Spring Bootem przez
gotowe startery, co przyspiesza konfigurację i rozwój. Wybór zależy od kontekstu: Axon będzie dobrym wyborem dla większych,
domenowo zorientowanych monolitów, a Lagom lub Eventuate lepiej sprawdzą się w środowiskach rozproszonych z naciskiem na skalowalność i autonomię usług.

### Slajd 28: Frameworki i biblioteki – .NET

W ekosystemie .NET dostępnych jest wiele narzędzi wspierających CQRS i Event Sourcing, dopasowanych do różnych poziomów
złożoności. **MediatR** to lekka biblioteka oparta na wzorcu mediatora, która ułatwia separację handlerów komend i zapytań,
idealna do prostych lub średnich wdrożeń bez rozbudowanej infrastruktury. **EventStoreDB** to natywna baza do Event Sourcingu,
oferująca dostęp przez gRPC, wersjonowanie i subskrypcje typu catch-up do tworzenia projekcji i integracji. W bardziej złożonych
środowiskach **NServiceBus** zapewnia zaawansowaną obsługę komunikatów, retry policy, dead-letter queues oraz silnik sag,
co czyni go odpowiednim wyborem dla systemów o wysokich wymaganiach niezawodności i skalowalności. **Dapr** to nowoczesna
platforma abstrakcyjna nad brokerami i magazynami danych, umożliwiająca tworzenie aplikacji event-driven w duchu CQRS-lite,
szczególnie przydatna w środowiskach kontenerowych i Kubernetes. CQRS w .NET świetnie współgra również z usługami chmurowymi
Azure – **Service Bus**, **Event Grid** i **Azure Functions** pozwalają budować skalowalne, zdarzeniowe systemy w architekturze
serverless, zgodne z DDD i nowoczesnymi praktykami rozwoju systemów rozproszonych.

### Slajd 29: Frameworki i biblioteki – Python i inne

W świecie Pythona i innych nowoczesnych języków również istnieją narzędzia wspierające CQRS i Event Sourcing, choć zwykle
są one lżejsze i bardziej elastyczne niż w Java czy .NET. Pythonowa biblioteka **`eventsourcing`** oferuje pełne wsparcie
dla DDD: event store, snapshoty, projekcje – dobrze nadaje się do mniejszych systemów, prototypów i nauki architektury
zdarzeniowej. **FastAPI**, jako nowoczesny framework API-first, pozwala na implementację CQRS-lite z wykorzystaniem np.
RabbitMQ jako command/query busa, idealnie sprawdzając się w lekkich systemach rozproszonych. Do przetwarzania
strumieniowego i projekcji w czasie rzeczywistym można wykorzystać **Faust** lub **Kafka Streams** w wersji pythonowej,
co umożliwia m.in. agregacje i transformacje zdarzeń. W językach takich jak **Go** i **Rust** dostępne są biblioteki
typu `EventSourcing-Go` czy `cqrs-rs`, które oferują prostotę, wysoką wydajność i niskie zużycie zasobów – szczególnie
przydatne w systemach mikroserwisowych. Niezależnie od języka, kluczowe pozostają zasady architektury: jasna separacja
odpowiedzialności, spójność modelu domenowego i dyscyplina w projektowaniu zdarzeń. Wybór narzędzi powinien wynikać z
realnych potrzeb projektu, a nie technologii samej w sobie.

### Slajd 30: Kryteria decyzji „czy stosować CQRS”

Decyzja o zastosowaniu CQRS powinna wynikać z konkretnych potrzeb systemu, a nie z chęci wdrożenia popularnego wzorca –
to narzędzie, które przynosi realne korzyści głównie tam, gdzie występuje wysoka złożoność lub duża skala. Gdy system ma
wyraźną asymetrię między odczytem a zapisem (np. 90% operacji to zapytania), CQRS pozwala niezależnie skalować read-side,
co poprawia wydajność i zmniejsza koszty. W przypadku skomplikowanej logiki biznesowej, rozdzielenie komend i zapytań zwiększa
przejrzystość i umożliwia lepsze zarządzanie odpowiedzialnościami. W branżach regulowanych, gdzie wymagany jest pełny audyt,
Event Sourcing daje wbudowaną historię zmian bez dodatkowych kosztów. CQRS wspiera też pracę wielu zespołów, umożliwiając im
równoległy rozwój modeli zapisu i odczytu bez wzajemnych kolizji. Jednak w prostych systemach CRUD, bez dużych wymagań, może
jedynie wprowadzać niepotrzebną złożoność. Dlatego decyzję o jego wdrożeniu należy podejmować świadomie – na podstawie analizy
wymagań biznesowych, architektury i możliwości zespołu – jako rozwiązanie konkretnego problemu, a nie cel sam w sobie.

### Slajd 33: Strategia adopcji w istniejącym systemie

Adopcja CQRS i Event Sourcingu w istniejącym systemie powinna przebiegać iteracyjnie i strategicznie, zaczynając od
obszarów o dużej asymetrii między zapisem a odczytem – np. raportowania czy logów aktywności, gdzie przeważają zapytania, a
zmiany są rzadkie i mniej krytyczne. Pozwala to ograniczyć ryzyko i szybko dostarczyć wartość bez naruszania stabilności
systemu. W początkowej fazie warto umożliwić współistnienie starego modelu CRUD i nowego komponentu CQRS, stopniowo przenosząc
ruch użytkowników, co ułatwia testowanie i kontrolę. Event Sourcing najlepiej wdrażać tam, gdzie pełna historia zmian ma
realną wartość – np. w obszarach finansowych czy audytowych – i unikać go tam, gdzie tylko zwiększa złożoność. Kluczowa
jest edukacja zespołu: warsztaty z DDD, event storming i wspólne modelowanie pomagają zbudować wspólne zrozumienie i
właściwe podejście do projektowania. Warto też od początku wprowadzić monitoring lagów, metryk wydajności i kosztów –
pozwala to nie tylko reagować na problemy, ale też podejmować świadome decyzje o dalszych krokach migracji. Tak prowadzona
adopcja jest bezpieczna, mierzalna i dostosowana do realnych potrzeb biznesu.

### Slajd 34: Najczęstsze pułapki i anty-wzorce

Wdrożenie CQRS i Event Sourcingu przynosi wiele korzyści, ale bez dyscypliny architektonicznej łatwo wpaść w typowe pułapki,
które zamiast upraszczać – komplikują rozwój systemu. Częstym błędem jest over-engineering, czyli stosowanie CQRS tam, gdzie
prosty CRUD byłby wystarczający – w takich przypadkach złożoność nie ma uzasadnienia i tylko zwiększa koszt utrzymania. Innym
problemem jest brak separacji baz danych dla odczytu i zapisu, co niweczy kluczowe zalety CQRS, jak izolacja, niezależne
skalowanie i odporność na awarie. Błędem jest też traktowanie zdarzeń jako czysto technicznych komunikatów, zamiast jako
znaczących faktów domenowych – prowadzi to do kruchego modelu, oderwanego od rzeczywistości biznesowej. Kolejna pułapka to
brak idempotencji po stronie konsumentów zdarzeń, co może skutkować duplikacją, błędami logicznymi i trudnymi do reprodukcji
incydentami. Równie niebezpieczne jest zaniedbanie monitoringu lagów i błędów propagacji – bez widoczności opóźnień i problemów
projekcje mogą działać na przestarzałych danych, co prowadzi do niejawnych błędów. Dlatego telemetria, alerty i metryki powinny
być integralną częścią architektury, nie dodatkiem. Świadome unikanie tych błędów to fundament skutecznego, stabilnego i
skalowalnego wdrożenia CQRS i Event Sourcingu.

### Slajd 35: Podsumowanie i rekomendacje

CQRS i Event Sourcing to silne podejścia architektoniczne, które – przy właściwym zastosowaniu – znacząco zwiększają
elastyczność, przejrzystość i odporność systemu. Oddzielenie komend (intencji), zapytań (odczytu) i zdarzeń (niezmiennych faktów)
pozwala lepiej odwzorować logikę biznesową, uprościć testowanie i ułatwić komunikację z interesariuszami. To podejście sprawdza
się szczególnie w systemach o wysokiej złożoności, dużym ruchu, konieczności audytu i długim cyklu życia danych. Wymaga jednak
dojrzałości zespołu, odpowiednich narzędzi, monitoringu i świadomego wdrożenia – w przeciwnym razie może niepotrzebnie podnieść
koszty i złożoność. Dlatego warto zaczynać iteracyjnie, od jednego modułu, mierzyć lag, analizować metryki i uczyć zespół w praktyce.
Kluczowe jest jednak podejście pragmatyczne – CQRS i Event Sourcing to narzędzia, nie dogmaty. Ich zastosowanie ma sens tylko
wtedy, gdy wynikają z realnych potrzeb domeny i przynoszą wartość biznesową.
