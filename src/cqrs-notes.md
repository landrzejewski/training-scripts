### Slajd 1: Agenda prezentacji

1. Dlaczego klasyczny CRUD hamuje rozwój złożonych systemów
2. Podstawy Command-Query Separation i droga do CQRS
3. Kluczowe komponenty architektury CQRS + Event Sourcing
4. Korzyści, kompromisy i typowe wyzwania wdrożeniowe
5. Praktyczne wskazówki, narzędzia oraz podsumowanie rekomendacji

### Slajd 2: Problem klasycznych architektur CRUD

Klasyczne podejście CRUD staje się problematyczne w rozbudowanych systemach. Wymusza korzystanie z jednego modelu 
danych do zapisu i odczytu, co prowadzi do kompromisów i utraty przejrzystości. Wraz z rozwojem funkcji model staje się
trudny w utrzymaniu i bardziej podatny na błędy. Długie zapytania SQL, typowe dla raportów, mogą blokować dostęp do
danych i spowalniać system. Utrudnia to skalowanie, bo wiele operacji opiera się na jednej bazie. Logika biznesowa jest
rozproszona po wielu warstwach, co komplikuje testowanie i utrzymanie. CRUD nie odzwierciedla dobrze procesów biznesowych,
przez co trudniej zrozumieć zmiany i ich kontekst. Relacyjna baza danych staje się krytycznym punktem – jej awaria może 
zatrzymać cały system.

### Slajd 3: Command-Query Separation (CQS) – fundament

Zasada CQS zakłada podział metod na dwie grupy: komendy (zmieniają stan) i zapytania (tylko odczytują dane). Dzięki
temu unika się niejasnych metod, które robią jedno i drugie, co ułatwia analizę i debugowanie. Zapytania nie mają skutków
ubocznych, więc można je bezpiecznie powtarzać, keszować i uruchamiać równolegle. Komendy zwracają jedynie potwierdzenie
lub błąd, co czyni intencje jasnymi. Pomysł ten pochodzi od Bertranda Meyera, a spopularyzowali go m.in. Martin Fowler i
środowisko DDD. Dziś CQS jest szeroko stosowane w CQRS, mikroserwisach i event sourcingu. Oddzielenie komend i zapytań
upraszcza testy i zmniejsza potrzebę mockowania. Interfejsy są bardziej zrozumiałe, a zespołowi łatwiej ogarnąć
zależności i skutki działań. Systemy oparte na CQS są bardziej modularne, testowalne i łatwiejsze w utrzymaniu.

### Slajd 4: CQS – korzyści praktyczne

Zasada CQS przynosi wiele praktycznych korzyści. Jasny podział metod pokazuje, czy dana operacja zmienia stan systemu,
czy tylko odczytuje dane – ułatwia to zrozumienie i nawigację po kodzie. Programista nie musi zaglądać do wnętrza każdej
metody. Zapytania, jako czyste funkcje, można łatwo testować bez mocków, co upraszcza testy i obniża koszty ich utrzymania.
Komendy nie kolidują z zapytaniami, co pozwala bezpiecznie uruchamiać kod równolegle. Nowi członkowie zespołu szybciej się
wdrażają, bo API jest bardziej czytelne. CQS może być też wstępem do pełnego CQRS – pozwala na stopniowe zmiany w
architekturze bez przebudowy całego systemu. Dzięki temu systemy są bardziej skalowalne i łatwiejsze w rozwoju.

### Slajd 5: CQS – wyzwania i ograniczenia

Mimo wielu zalet, CQS wiąże się też z pewnymi trudnościami. Języki programowania nie wymuszają jej stosowania – zależy 
to od dyscypliny zespołu. Łatwo przez nieuwagę wprowadzić efekt uboczny do zapytania, np. zapis loga, co zaburza spójność. 
W małych projektach CQS może być przesadą – dodatkowe klasy i interfejsy zwiększają złożoność bez wyraźnych korzyści.
Trzeba więc ocenić, czy separacja rzeczywiście się opłaca. CQS nie rozwiązuje też problemów wydajności, np. blokad bazy –
potrzebne są inne techniki, jak sharding czy kolejki. Sama zasada dotyczy głównie metod i klas, nie obejmuje całej architektury,
dlatego często traktuje się ją jako wstęp do CQRS. Jej skuteczność zależy od spójnego i przemyślanego wdrożenia,
dopasowanego do skali i złożoności projektu.

### Slajd 6: Ewolucja od CQS do CQRS

CQRS rozwija zasadę CQS, przenosząc ją na poziom całej architektury. Oddziela logikę zapisu i odczytu nie tylko metodami,
ale też modelami, warstwami, a czasem bazami danych. Część zapisu skupia się na spójności i walidacji, a odczyt – na
szybkości i elastyczności, często z użyciem denormalizacji. Obie strony można skalować niezależnie: odczyt przez replikację,
zapis przez transakcje lub kolejki. CQRS dobrze współgra z podejściem event-driven i mikroserwisami – zdarzenia ułatwiają
komunikację i podział odpowiedzialności. Architektura wprowadza jednak nowe elementy, jak event bus, projekcje czy sagi,
co zwiększa elastyczność, ale też złożoność. CQRS wymaga dojrzałości zespołu i dobrej dokumentacji. Nie pasuje do każdej
aplikacji, ale w złożonych systemach z dużą liczbą operacji może znacząco poprawić wydajność, czytelność i skalowalność.

### Slajd 7: CQRS – definicja

CQRS to wzorzec architektoniczny oparty na rozdzieleniu zapisu i odczytu. Komponenty zajmują się albo zmianą stanu (komendy),
albo odczytem danych (zapytania), nigdy obiema funkcjami naraz. Strona zapisu waliduje komendy, wykonuje logikę i emituje
zdarzenia – są one głównym źródłem prawdy. Strona odczytu tworzy projekcje, czyli uproszczone widoki danych dopasowane do
potrzeb użytkownika, co przyspiesza zapytania. Obie części mogą korzystać z różnych technologii – np. SQL do zapisu, NoSQL
lub cache do odczytu – co pozwala lepiej spełniać wymagania wydajnościowe. CQRS zakłada model „eventual consistency” – dane
między zapisem a odczytem są synchronizowane z opóźnieniem, ale to opóźnienie da się kontrolować. Dzięki temu można precyzyjnie
skalować system zgodnie z rzeczywistym obciążeniem. CQRS wspiera podejście event-driven, w którym każde zdarzenie może wywołać
dalsze akcje. To zwiększa modularność, przejrzystość i ułatwia utrzymanie systemu w dłuższym czasie.

### Slajd 8: CQRS – główne założenia

CQRS opiera się na założeniu, że model zapisu i odczytu powinny być rozdzielone. Dzięki temu logika domenowa skupia się 
wyłącznie na regułach biznesowych, a odczyt – na potrzebach UI, często przy użyciu prostych, zdenormalizowanych modeli.
Ponieważ większość operacji to odczyty, można je skalować niezależnie, bez wpływu na resztę systemu. Komendy przechodzą
przez dokładną walidację i są wykonywane w transakcjach zgodnych z ACID, co zapewnia spójność. Odczyt opiera się na
projekcjach tworzonych na podstawie zdarzeń, co eliminuje potrzebę łączenia danych w locie. Komunikacja przez zdarzenia
zwiększa niezawodność i pozwala na luźne powiązania między komponentami. Można też stosować różne technologie po obu stronach,
dopasowane do konkretnych potrzeb. CQRS pozwala lepiej zarządzać złożonością, optymalizować koszty i budować systemy
skalowalne, elastyczne i bezpieczne w długim okresie.

### Slajd 9: Oddzielenie modeli zapisu i odczytu

Rozdzielenie modeli zapisu i odczytu to podstawowa cecha CQRS, pozwalająca dopasować każdą warstwę do jej roli. Model 
zapisu zawiera tylko dane potrzebne do logiki biznesowej i walidacji – jest znormalizowany i skupiony na regułach domeny. 
Model odczytu natomiast buduje widoki dopasowane do UI lub API – może być nadmiarowy i zoptymalizowany pod konkretne 
zapytania. Dzięki temu zmiany po jednej stronie (np. w widokach) nie wymagają modyfikacji po drugiej, co przyspiesza 
rozwój i zmniejsza ryzyko błędów. Projekcje tworzone na podstawie zdarzeń można łatwo odtworzyć lub zmodyfikować bez 
wpływu na dane biznesowe. Oddzielne modele pozwalają też używać różnych technologii – np. relacyjna baza do zapisu, 
a szybki silnik wyszukiwania do odczytu. Ułatwia to skalowanie i szybkie reagowanie na zmiany. Read Model może być często 
zmieniany, bez ryzyka naruszenia stabilnej logiki zapisów. Takie podejście skraca czas wdrożeń, zwiększa 
bezpieczeństwo i ułatwia zarządzanie złożonością w dynamicznych systemach.

### Slajd 10: Separation of Concerns w skali systemu

Zasada Separation of Concerns w CQRS umożliwia podział odpowiedzialności na poziomie całego systemu. Zespół od zapisu 
skupia się na logice biznesowej i integralności danych, a zespół odczytu – na szybkości działania i dopasowaniu danych 
do widoków. Dzięki temu każdy zespół specjalizuje się w swoim obszarze, co upraszcza pracę i zmniejsza złożoność poznawczą.
Testy logiki biznesowej są niezależne od interfejsu, co pozwala unikać rozbudowanego mockowania. Częstsze wdrożenia po
stronie odczytu nie zagrażają stabilności zapisów, co ułatwia szybkie reagowanie na potrzeby użytkowników. Problemy z
wydajnością zapytań nie blokują zapisu – każda warstwa ma własne SLA i monitoring. Takie rozdzielenie wspiera mikroserwisy,
gdzie każda odpowiedzialność może być obsługiwana przez osobny serwis i zespół, bez ryzyka konfliktów. CQRS działa więc nie
tylko jako wzorzec techniczny, ale i organizacyjny – porządkuje kod i usprawnia procesy wytwórcze, co zwiększa elastyczność,
jakość i szybkość rozwoju systemu.

### Slajd 11: Poliglotyczna persystencja

Poliglotyczna persystencja w CQRS polega na używaniu różnych technologii baz danych dla zapisu i odczytu, dopasowanych do 
ich specyficznych potrzeb. Write Model zwykle korzysta z relacyjnej bazy z gwarancjami ACID – idealnej do walidacji i transakcji. 
Read Model może opierać się na rozwiązaniach jak Elasticsearch, Redis czy GraphQL subscriptions, zoptymalizowanych pod szybkie i 
elastyczne zapytania. Analizy można prowadzić w osobnej hurtowni danych (np. ClickHouse, BigQuery), bez obciążania bazy operacyjnej.
Kluczową zaletą jest możliwość niezależnego rozwoju każdej części – zmiana technologii odczytu nie wymusza modyfikacji zapisu. 
Ułatwia to eksperymenty, wdrażanie zmian i ogranicza ryzyko. Dodatkowo pozwala optymalizować koszty: odczyt może działać na 
tańszych rozwiązaniach, a zapis pozostać na bardziej niezawodnej, ale kosztowniejszej infrastrukturze. Takie podejście 
poprawia skalowalność, elastyczność i pozwala lepiej dopasować system do faktycznych potrzeb biznesowych i technicznych.

### Slajd 12: Niezależne skalowanie R/W

Jedną z głównych zalet CQRS jest niezależne skalowanie odczytu i zapisu. Ponieważ odczyty stanowią większość 
ruchu (nawet 90%), można je łatwo skalować horyzontalnie – przez replikację baz, cache (np. Redis) czy CDN – co 
zmniejsza obciążenie głównej bazy i pozwala obsłużyć duży ruch z niskim opóźnieniem. Zapis skaluje się selektywnie, 
np. przez sharding po ID klienta, co umożliwia równoległe przetwarzanie operacji i zwiększa wydajność.
Rozdzielenie tych warstw eliminuje problem blokowania – długie zapytania nie wpływają na zapisy, co redukuje ryzyko 
locków i deadlocków. Replikacja odczytu w różnych regionach świata pozwala lokalnie serwować dane, co poprawia 
szybkość działania aplikacji. CQRS pozwala też lepiej zarządzać kosztami – infrastrukturę dostosowuje się do 
faktycznego ruchu, unikając przewymiarowania. Ułatwia to rozwój – nowe funkcje można wdrażać niezależnie po jednej ze 
stron. System staje się dzięki temu bardziej skalowalny, elastyczny i odporny na zmienne obciążenia.

### Slajd 13: Read Model – kluczowe cechy

Read Model w CQRS służy wyłącznie do szybkiego i prostego odczytu danych, z myślą o interfejsie użytkownika. Dane są w 
nim zdenormalizowane i dostosowane do konkretnych widoków, co upraszcza frontend i przyspiesza odpowiedzi. W przeciwieństwie
do Write Modelu nie zawiera logiki biznesowej, więc łatwo go testować i modyfikować. Aktualizacje odbywają się asynchronicznie
na podstawie zdarzeń – dane mogą być lekko opóźnione, ale dzięki temu system jest bardziej wydajny. Struktura read modelu
może być całkowicie niezależna od modelu zapisu – dopasowana do potrzeb raportów czy UI, bez ograniczeń reguł domenowych.
Największą zaletą jest to, że read model można w każdej chwili usunąć i odbudować ze zdarzeń – nie przechowuje źródłowych
danych, więc jest nietrwały, ale bezpieczny i elastyczny.

### Slajd 14: Write Model – kluczowe cechy

Write Model w CQRS to centralne miejsce, gdzie egzekwowana jest logika biznesowa i zapewniana spójność danych. Opiera się 
na Agregatach – obiektach łączących stan i reguły, które decydują, czy dana komenda może zostać wykonana. Dzięki temu każda 
operacja w systemie ma jasny kontekst i jest zrozumiała również dla biznesu. Po zatwierdzeniu komendy Agregat emituje zdarzenia, 
które trafiają do Event Store i stanowią jedyne źródło prawdy o zmianach w systemie. Te zdarzenia uruchamiają dalsze działania,
jak aktualizacja projekcji czy komunikacja z innymi serwisami. Struktura danych w Write Modelu jest silnie znormalizowana – 
celem jest dokładne odwzorowanie reguł domenowych, a nie szybki odczyt. Skalowanie odbywa się nie przez replikację, lecz przez
partycjonowanie strumieni zdarzeń (np. według ID klienta), co pozwala przetwarzać komendy równolegle i wydajnie. Dzięki
temu Write Model zachowuje spójność i dobrze radzi sobie z dużym ruchem transakcyjnym bez blokad i przeciążeń.

### Slajd 15: Commands – kontrakt intencji

Komendy w CQRS to jednoznaczne instrukcje, które wyrażają intencje użytkownika – np. „ZmieńEmailKlienta” czy „DezaktywujProdukt”.
Dzięki swojej formie są czytelne zarówno dla programistów, jak i osób biznesowych. Zawierają tylko niezbędne 
dane (np. ID i nowe wartości), co zmniejsza ryzyko błędów i chroni przed nieautoryzowanymi zmianami. Komenda może zostać odrzucona, 
jeśli narusza reguły domenowe lub wersja danych się nie zgadza – zapobiega to utracie spójności. Komendy nie zwracają pełnych
danych domenowych – jedynie potwierdzenie lub błąd. Upraszcza to API i przenosi obsługę reakcji do interfejsu. Każda komenda
powinna mieć unikalny identyfikator, by zapewnić idempotencję – nawet jeśli zostanie wysłana kilka razy, system rozpozna
duplikat i nie powtórzy operacji. To ważne w środowiskach rozproszonych, gdzie komunikaty mogą się powielać. Komendy nadają
operacjom wyraźny kontekst, porządkują interakcję z domeną i wzmacniają odporność systemu na błędy.

### Slajd 16: Queries – kontrakt odczytu

Queries w CQRS służą wyłącznie do odczytu danych – nie zmieniają stanu systemu, co czyni je bezpiecznymi, przewidywalnymi i
łatwymi do testowania. Można je wywoływać wielokrotnie bez skutków ubocznych, co sprzyja stabilności aplikacji. Zwracają
dane w formie gotowej do użycia – np. DTO, paginowane listy czy strumienie – co upraszcza frontend i przyspiesza działanie interfejsu.
Zmiany w strukturze odczytu wymagają modyfikacji tylko handlera zapytania, bez wpływu na model domenowy czy zapis, co pozwala
szybko iterować i rozwijać UI. Brak efektów ubocznych ułatwia też keszowanie – np. w Redisie, pamięci aplikacji czy
przez CDN – co zwiększa wydajność i odciąża serwer. Queries są więc lekkie, szybkie i jednoznaczne: „podaj dane”, bez żadnych
decyzji czy modyfikacji. Taka separacja upraszcza kod, wspiera skalowalność i poprawia jakość całej architektury.

### Slajd 17: Event Bus – rola i zalety

Event Bus w CQRS odpowiada za asynchroniczne przesyłanie zdarzeń między zapisem a odczytem. Dzięki temu zapis nie czeka na
przetworzenie zdarzeń – są one publikowane od razu po wykonaniu komendy, a dalsze działania dzieją się niezależnie.
Komponenty, takie jak projekcje czy integracje, subskrybują zdarzenia i mogą być skalowane osobno, bez wpływu na wydajność zapisu.
Event Bus zapewnia mechanizmy ponawiania i gwarantuje co najmniej jednokrotne dostarczenie, co zwiększa niezawodność nawet przy
błędach sieci czy przetwarzania. Dzięki wzorcowi publish/subscribe mikroserwisy nie muszą się znać – wystarczy, że
obsługują te same zdarzenia, co upraszcza integrację i uniezależnia moduły. Największą zaletą jest możliwość dodawania nowych
projekcji, usług czy analiz bez zmian w istniejącym kodzie – zgodnie z zasadą Open/Closed. Każda zmiana stanu jest rejestrowana
jako zdarzenie, co zwiększa przejrzystość systemu i umożliwia logowanie, audyt oraz monitoring. Event Bus sprawia, że architektura
staje się elastyczna, odporna na błędy i łatwa do rozbudowy w środowiskach rozproszonych.

### Slajd 18: Event Store – jedyne źródło prawdy

Event Store w CQRS i event sourcingu to centralny rejestr wszystkich zmian w systemie – każda decyzja biznesowa zapisywana 
jest jako zdarzenie, w niezmienionej formie i chronologicznym porządku. Nie ma nadpisywania ani kasowania danych – każda
zmiana zostaje zachowana, co daje pełną audytowalność i możliwość odtworzenia stanu systemu w dowolnym momencie.
Agregaty nie przechowują stanu w klasyczny sposób – wyliczają go na podstawie zdarzeń, co zapewnia precyzję i przejrzystość
logiki biznesowej. Event Store działa jako log tylko-do-zapisu (append-only), co ułatwia replikację, backup, 
partycjonowanie i eliminuje problemy z konkurencyjnymi zapisami. Dzięki pełnej historii możliwa jest analiza zdarzeń z 
przeszłości (time-travel debug), co pomaga w diagnostyce, audycie i spełnieniu wymagań compliance. Event Store może też 
pełnić rolę kolejki – zapis i publikacja zdarzenia są atomowe, więc nie potrzeba skomplikowanych mechanizmów transakcyjnych między komponentami.
To wszystko sprawia, że Event Store jest nie tylko bazą danych, ale sercem całej architektury zdarzeniowej – wspiera skalowalność, 
odporność i przejrzystość systemu, pozwalając jednocześnie zachować pełną kontrolę nad tym, co się wydarzyło i dlaczego.

### Slajd 19: Read-store Projections

Projekcje (Read-store Projections) w CQRS służą do utrzymywania aktualnych, zoptymalizowanych widoków odczytu na podstawie
zdarzeń z Write Modelu. Każde zdarzenie trafia do odpowiedniego handlera, który aktualizuje dane w Read Store – bez
konieczności sięgania do bazy transakcyjnej. Widoki te są dostosowane do konkretnych potrzeb UI, API czy raportów – często
zdenormalizowane i gotowe do natychmiastowego użycia, co zwiększa szybkość działania i upraszcza zapytania.
System mierzy tzw. lag – opóźnienie między zapisem zdarzenia a jego przetworzeniem w projekcji – co pozwala kontrolować 
świeżość danych i reagować na przeciążenia. W razie potrzeby projekcję można bezpiecznie usunąć i odbudować od zera,
korzystając z pełnej historii zdarzeń – bez backupów i bez utraty danych. Nowy ekran czy raport to po prostu nowy handler –
nie wymaga zmian w modelu zapisu ani logice domenowej. Dzięki temu rozwój frontendu jest szybki i bezpieczny. Projekcje 
są więc lekkie, elastyczne, łatwe w skalowaniu i odporne na awarie – stanowią jeden z kluczowych elementów architektury zdarzeniowej.

### Slajd 20: Process Managers i Sagi

Process Managers i Sagi to mechanizmy do obsługi złożonych procesów biznesowych, które obejmują wiele agregatów i kroków.
Reagują na zdarzenia i wysyłają kolejne komendy, tworząc sekwencję działań rozłożoną w czasie – bez blokowania całego systemu.
Dzięki temu procesy, takie jak zakupy czy płatności, mogą być realizowane asynchronicznie i odpornie na błędy.
Zamiast tradycyjnych transakcji obejmujących wiele źródeł danych, Sagi stosują lokalne operacje i kompensacje – w razie 
błędu można cofnąć wykonane wcześniej kroki, bez potrzeby globalnego commit-u. Każda Saga lub Process Manager przechowuje
własny stan procesu (np. jako „stan maszyny”), co pozwala wznowić działanie od przerwanego miejsca po awarii.
Komunikacja między serwisami odbywa się przez zdarzenia, a nie przez bezpośrednie wywołania – to zmniejsza zależności i
zwiększa niezawodność. Takie podejście dobrze sprawdza się w środowiskach rozproszonych i mikroserwisach, pozwalając budować
systemy elastyczne, skalowalne i odporne na awarie.

### Slajd 21: CQRS + Event Sourcing – synergia

Połączenie CQRS i Event Sourcing daje silną, komplementarną architekturę. CQRS wyznacza miejsca powstawania zdarzeń 
(po komendach w Write Modelu) oraz ich konsumpcji (projekcje, integracje), co zapewnia przejrzystość i kontrolę nad zmianami.
Event Sourcing z kolei zapisuje każdą zmianę jako trwałe zdarzenie, tworząc pełną historię systemu bez potrzeby dodatkowego audytu.
Dzięki temu Read Model można łatwo odbudować – wystarczy ponownie przetworzyć strumień zdarzeń. Każde zdarzenie może być użyte
przez wiele projekcji, co umożliwia dodawanie nowych widoków lub raportów bez ingerencji w logikę zapisu – wystarczy nowy handler.
Wspiera to zasadę Open/Closed i ułatwia rozwój bez ryzyka regresji. CQRS daje skalowalność i separację odpowiedzialności,
a Event Sourcing – trwałość, pełny audit-trail i możliwość przywrócenia stanu systemu. Razem tworzą elastyczną i odporną
architekturę, idealną dla nowoczesnych systemów rozproszonych, gdzie dane muszą być nie tylko aktualne, ale i w pełni śledzalne.

### Slajd 22: Event Sourcing – definicja

Event Sourcing to wzorzec, w którym stan systemu wynika nie z bieżących wartości w bazie, lecz z sekwencji zdarzeń
opisujących fakty, które już zaszły – np. „ZamówienieWysłane” czy „ProduktWycofany”. Zdarzenia są trwałe, niezmienne
i zapisywane w kolejności ich wystąpienia, co tworzy pełną, audytowalną historię zmian. Zamiast aktualizować dane, system
zapisuje nowe zdarzenia, które pokazują, jak stan ewoluował. Agregaty odtwarzają swój stan poprzez przetworzenie własnego
strumienia zdarzeń. Dla wydajności można stosować snapshoty – zapis aktualnego stanu, od którego odtwarzanie jest szybsze.
Nie potrzeba pól typu `updated_at` – sam Event Store pełni rolę dziennika zmian. Zdarzenia mogą być też wykorzystywane
później, np. do analiz, raportów, prognoz czy rekomendacji – bez zmian w logice domenowej. Dzięki temu system staje się w
pełni śledzalny, zrozumiały i gotowy do dalszego rozwoju opartego na rzeczywistych danych z przeszłości.

### Slajd 23: Zdarzenia domenowe – charakterystyka

Zdarzenia domenowe w CQRS i event sourcingu to trwałe fakty opisujące to, co już się wydarzyło – np. „ZamówienieZłożone” czy
„PłatnośćPotwierdzona”. Ich nazwy zawsze odnoszą się do przeszłości, co eliminuje niejasności i jasno oddziela je od intencji
(komend). Payload zawiera tylko potrzebne dane – nie pełne encje – co zmniejsza zależności między komponentami i ułatwia rozwój.
Zdarzenia są wersjonowane i uporządkowane, co pozwala systemowi działać z różnymi wersjami równocześnie, bez ryzyka przerwań.
Można je kodować w formatach jak JSON (czytelność) czy Protobuf (wydajność), pod warunkiem zachowania kompatybilności schematów.
Jedno zdarzenie może wywołać wiele reakcji: aktualizację projekcji, wysłanie powiadomienia, integrację z zewnętrznym systemem itd.
Bez bezpośrednich zależności między modułami, co zapewnia luźne powiązania i elastyczny rozwój. Zdarzenia stają się więc głównym
mechanizmem komunikacji w systemie – czytelnym, stabilnym i łatwym do rozbudowy.

### Slajd 24: Model faktów w czasie

Model faktów w czasie zakłada, że każdy agregat posiada własną oś czasu – uporządkowaną sekwencję zdarzeń z wersją. Dzięki temu
możliwe jest śledzenie pełnej historii zmian oraz kontrola wersji: jeśli dwie komendy próbują zmodyfikować ten sam agregat
jednocześnie, system wykryje konflikt i go obsłuży, bez potrzeby globalnych blokad. To zwiększa wydajność i odporność na problemy 
związane z równoległością. Zapisana historia pozwala też na symulacje typu „co by było, gdyby” – można odtworzyć stan z dowolnego
momentu i testować alternatywne scenariusze. Strumień zdarzeń nadaje się również bezpośrednio do analityki i uczenia maszynowego –
dane behawioralne są dostępne bez potrzeby ETL. Zmiany schematu lub widoków nie wymagają migracji danych – wystarczy nowy handler,
który odczyta te same zdarzenia inaczej. To upraszcza rozwój i minimalizuje ryzyko. Model faktów w czasie łączy elastyczność
techniczną z silnym wsparciem dla analizy i rozwoju systemów złożonych i długowiecznych.

### Slajd 25: Time-travel debugging i audyt

Time-travel debugging i audyt to jedne z najcenniejszych korzyści Event Sourcingu. Dzięki zachowanej sekwencji zdarzeń
można odtworzyć dowolny stan systemu z przeszłości – nawet sprzed miesięcy – co pozwala dokładnie przeanalizować, jak
doszło do błędu. Ułatwia to diagnozę problemów, tworzenie post-mortem i znacząco przyspiesza debugowanie.
Pełna historia zdarzeń spełnia też wymogi regulacyjne (np. RODO, GDPR, normy branżowe), zapewniając przejrzystość i możliwość
śledzenia każdej zmiany. Możliwa jest anonimizacja danych osobowych bez utraty wartości analitycznej, co umożliwia zgodność
z przepisami przy zachowaniu funkcji audytu i analizy. Taki log pozwala także wykrywać nadużycia – podejrzane wzorce,
nietypowe działania czy zmiany można analizować z pełną wiedzą, kto i kiedy je wykonał. W efekcie system staje się bardziej
bezpieczny, odporny na błędy i lepiej przygotowany na wyzwania związane z utrzymaniem, zgodnością i bezpieczeństwem.

### Slajd 26: Rolling Snapshots – optymalizacja

Rolling Snapshots to technika optymalizacji w Event Sourcingu, pozwalająca przyspieszyć odtwarzanie agregatów przy dużej
liczbie zdarzeń. Snapshot to zapisany stan agregatu po przetworzeniu np. 1000 eventów – zamiast liczyć całą historię od początku,
system zaczyna od snapshotu i przetwarza tylko nowsze zdarzenia. Skraca to czas ładowania i poprawia wydajność.
Tworzenie snapshotów odbywa się asynchronicznie, w tle – nie blokuje zapisów ani nie wpływa na bieżące działanie systemu.
Snapshot nie musi być najnowszy – wystarczy, że pasuje do wersji agregatu, a reszta stanu zostanie uzupełniona z późniejszych zdarzeń.
Włączenie snapshotowania powinno być decyzją opartą na danych, np. gdy czas odtwarzania przekracza ustalony próg (np. P95).
Nie warto wdrażać go zbyt wcześnie, by uniknąć zbędnej komplikacji. Dzięki snapshotom system zachowuje wszystkie zalety
Event Sourcingu – pełną historię, audytowalność – przy lepszej wydajności. To narzędzie inżynierskie, a nie domyślny element architektury.

### Slajd 27: Event Store jako kolejka

Wykorzystanie Event Store jako kolejki upraszcza komunikację w systemach z Event Sourcingiem i CQRS. Zdarzenie i informacja
o jego publikacji zapisywane są w jednym fsync, co oznacza, że zapis i wysyłka są atomowe – bez ryzyka utraty danych między
etapami. Odpada też potrzeba stosowania złożonych transakcji 2PC. Za publikację odpowiada proces chaser, który śledzi kolejne
zdarzenia i przesyła je do brokera (np. Kafka, RabbitMQ). Dzięki temu zapis komendy kończy się szybciej – system odpowiada
natychmiast po zapisaniu zdarzenia, a nie po wysyłce, co zmniejsza latencję i zwiększa responsywność.
Jeśli broker jest chwilowo niedostępny, zapis nadal działa – zdarzenia są bezpiecznie przechowywane w Event Store i zostaną
opublikowane później. Architektura staje się dzięki temu prostsza, bardziej niezawodna i łatwiejsza w utrzymaniu. Event Store
pełni wtedy nie tylko rolę magazynu stanu, ale też centralnego kanału integracji – łącząc zapis i propagację zdarzeń w jednym,
spójnym mechanizmie.

### Slajd 28: Task-Based UI – odzyskiwanie intencji

Task-Based UI to podejście do projektowania interfejsów, które doskonale współgra z CQRS i architekturą opartą na zdarzeniach.
Zamiast jednego, ogólnego przycisku „Zapisz wszystko”, interfejs oferuje konkretne, jednoznaczne akcje, takie jak „Anuluj zamówienie”
czy „Zmień termin spotkania”. Każda z tych akcji generuje odrębną komendę, jasno wyrażającą intencję użytkownika.
Dzięki temu interfejs jest lepiej dopasowany do języka biznesowego, co ułatwia współpracę między zespołem technicznym i biznesowym.
Walidacja odbywa się w czasie rzeczywistym – błędne komendy są natychmiast odrzucane, co poprawia ergonomię i skraca czas reakcji użytkownika.
Nazwy i działania w UI wynikają bezpośrednio z modelu domenowego. Każda komenda jest mała, precyzyjna i idempotentna, co czyni ją
odporną na błędy i łatwą do testowania – kluczowe cechy w systemach rozproszonych. W efekcie UI nie jest tylko warstwą prezentacji,
ale aktywną częścią logiki systemu, wzmacniając jego spójność, przejrzystość i niezawodność.

### Slajd 29: Komendy kontra zdarzenia – różnice

Różnica między **komendami** a **zdarzeniami** to podstawowy element CQRS i Event Sourcingu.
* **Komenda** (np. *SendInvoice*) to **intencja** – żądanie wykonania jakiejś akcji w przyszłości. Może zostać odrzucona, np. 
z powodu błędnej walidacji, konfliktu wersji lub braku uprawnień.
* **Zdarzenie** (np. *InvoiceSent*) to **fakt**, który **już się wydarzył** i którego nie można cofnąć. Jest trwałym zapisem historii systemu.

To rozróżnienie wprowadza porządek:
* Komendy używają trybu rozkazującego i reprezentują *zamiar*,
* Zdarzenia są w czasie przeszłym i oznaczają *co rzeczywiście zaszło*.

Biznes może więc jasno rozróżnić, co użytkownik **chciał zrobić**, a co **faktycznie się stało**.
Dodatkowo, komendy mają unikalne identyfikatory (np. GUID nadawany przez klienta), co pozwala backendowi sprawdzić, czy 
dana operacja już została wykonana – istotne w środowiskach rozproszonych, gdzie zdarzają się duplikaty.
To wszystko zwiększa **czytelność, odporność i testowalność** systemu, a także ułatwia współpracę techniczno-biznesową.

### Slajd 30: Idempotencja – dlaczego jest potrzebna

Idempotencja to kluczowy mechanizm w architekturach rozproszonych, który zapewnia stabilność działania mimo problemów
sieciowych i powtórzeń komunikatów. Gdy klient nie wie, czy jego komenda została przetworzona (np. po time-oucie), może
ją bezpiecznie wysłać ponownie, a system – dzięki unikalnym identyfikatorom (np. GUID) przypisanym każdej komendzie –
rozpozna duplikat i go zignoruje. Podobnie działają konsumenci zdarzeń, którzy zapisują identyfikatory przetworzonych
eventów w tabeli `processed_events`, chroniąc system przed skutkami wielokrotnego przetwarzania, takimi jak podwójne
opłaty czy zduplikowane rekordy. Idempotencja upraszcza też testy end-to-end, pozwalając na wielokrotne uruchamianie
tych samych scenariuszy bez wpływu na stan systemu, co zwiększa ich niezawodność. Jest również niezbędna przy strategiach
wdrożeń typu blue/green czy canary, gdzie zdarzenia i komendy mogą dotrzeć do systemu więcej niż raz. Dzięki idempotencji
system jest odporny na błędy sieciowe, łatwiejszy w utrzymaniu i bezpieczny w warunkach ciągłych zmian.

### Slajd 31: Eventual Consistency – model użytkowy

Eventual Consistency to model spójności, w którym dane nie są od razu aktualne po zapisie, ale z czasem osiągają zgodność,
co doskonale sprawdza się w rozproszonych i skalowalnych systemach, o ile zostanie poprawnie wdrożony i zakomunikowany
użytkownikowi. Po wykonaniu komendy widok może być przez chwilę nieaktualny, ponieważ projekcje są aktualizowane
asynchronicznie — dlatego UI powinno jasno sygnalizować ten stan, np. komunikatem „Dane są aktualizowane w tle”, co zmniejsza
frustrację i zwiększa zaufanie. W przypadku błędów w dalszym przetwarzaniu (np. w sagach) mogą zostać automatycznie uruchomione
działania kompensacyjne, które przywracają spójność logiczną. Ważne jest też monitorowanie opóźnienia między zapisem a odczytem —
jeśli lag przekracza ustalony próg (SLA), należy zareagować, zanim użytkownik zauważy problem. W zamian za zgodę na chwilową
niespójność system zyskuje wysoką dostępność, odporność na awarie i możliwość działania bez globalnych blokad, co znacznie
zwiększa jego wydajność i elastyczność.

### Slajd 32: Wyzwania implementacji CQRS

Wdrożenie CQRS przynosi wiele korzyści, ale wiąże się też z technicznymi i organizacyjnymi wyzwaniami, które trzeba
świadomie kontrolować. Podział na modele zapisu i odczytu oznacza, że każde zdarzenie musi być spójne zarówno z komendą,
która je wygenerowała, jak i z projekcją, która je przetwarza – zwiększa to liczbę miejsc podatnych na błędy i wymaga
ścisłej dyscypliny w wersjonowaniu i testach. Szczególną uwagę trzeba poświęcić migracji projekcji – zmiana schematu
zdarzeń może unieważnić istniejące widoki, dlatego niezbędny jest mechanizm „rebuildu” oraz strategia zarządzania wersjami
eventów. Od strony operacyjnej DevOps musi utrzymywać więcej niż tylko bazę danych – także kolejki, mechanizmy replikacji
monitorowanie opóźnień czy retry, co wymaga nowych narzędzi i kompetencji. Debugowanie również staje się bardziej złożone –
konieczne jest śledzenie pełnego cyklu: od komendy, przez zdarzenie, aż po wynikową projekcję, co wymaga dobrej obserwowalności,
ale daje też bardzo dokładny wgląd w działanie systemu. Trzeba jednak pamiętać, że CQRS to narzędzie, a nie cel sam w sobie –
w prostych systemach CRUD jego zastosowanie może być nieuzasadnione i prowadzić do nadmiarowej złożoności. Kluczowe jest więc
by podejście dopasować do realnej złożoności domeny i faktycznych potrzeb biznesowych.

### Slajd 33: Wyzwania implementacji Event Sourcing

Implementacja Event Sourcingu wiąże się z wieloma wyzwaniami, które wykraczają poza klasyczne modelowanie danych i wymagają
dojrzałości projektowej oraz operacyjnej. Zdarzenia muszą być dobrze zaprojektowane od początku, bo raz zapisane stają się
nieusuwalnym elementem systemu – błędów nie da się poprawić edytując dane, jedynym wyjściem jest emisja nowych zdarzeń
korygujących, co komplikuje logikę i wymaga przemyślanego wersjonowania. Dochodzą do tego wyzwania techniczne: zarządzanie
snapshotami i retencją danych wymaga decyzji o częstotliwości ich tworzenia, czasie przechowywania i archiwizacji, co ma wpływ
na koszty, wydajność i zgodność z regulacjami (np. RODO). Wersjonowanie zdarzeń to osobna odpowiedzialność – schema musi być
wstecznie kompatybilna, bo w systemie mogą działać równolegle konsumenci obsługujący różne wersje tego samego zdarzenia, co
wymaga dyscypliny w zarządzaniu kontraktami. Testowanie również staje się bardziej złożone – scenariusze muszą obejmować cały
przepływ: od komendy, przez zapis eventu, aż po aktualizację projekcji, co wydłuża czas testów i podnosi wymagania wobec środowiska
CI/CD. Mimo tych trudności, Event Sourcing daje ogromne korzyści: pełną historię zmian, audyt, możliwość analiz i elastycznego
rozwoju, ale jego skuteczne wdrożenie wymaga świadomego podejścia, automatyzacji i czujności na każdym etapie rozwoju systemu.

### Slajd 34: Obserwowalność i monitoring lagów

Obserwowalność i monitoring lagów są kluczowe w systemach opartych na CQRS i Event Sourcingu, gdzie dane propagują się
asynchronicznie. Każde zdarzenie powinno mieć znacznik czasu i numer sekwencyjny, co pozwala analizować kolejność i czas
emisji oraz ułatwia debugowanie i ocenę wydajności. Podstawową metryką jest różnica między `current_position`
(ostatnie zapisane zdarzenie) a `published_position` (ostatnie przetworzone przez Chasera) – wskazuje ona opóźnienie
Read Modelu względem Write Modelu i może sygnalizować przeciążenie systemu. Aby śledzić pełen przebieg żądania, warto
stosować `Correlation ID`, który przechodzi przez komendę, zdarzenie i odpowiedź – umożliwia szybkie połączenie przyczyny
z efektem. Rozproszone trace’y, np. w Jaegerze czy Zipkinie, pokazują przepływ komunikacji w mikroserwisach i pozwalają
sprawnie wykrywać źródła błędów i spowolnień. Niezbędny jest też automatyczny alerting – system powinien wykrywać, gdy
lag przekracza ustalony próg SLA i natychmiast powiadamiać zespół, zanim problem stanie się widoczny dla użytkownika.
Takie podejście zapewnia wysoką dostępność, szybką reakcję na anomalie i stabilność działania systemu pod dużym obciążeniem.

### Slajd 35: Impedance Mismatch a zdarzenia

Impedance mismatch, czyli niezgodność między modelem obiektowym a relacyjnym, to częsty problem w systemach z ORM –
wymaga mapowania obiektów na tabele, migracji schematów i generuje złożone zależności trudne w utrzymaniu. Event Sourcing
eliminuje ten problem, bo zdarzenia są natywne dla domeny i przechowywane w niezmienionej formie, bez potrzeby translacji
na encje czy struktury relacyjne. Aplikacja działa bezpośrednio na liście zdarzeń, co upraszcza logikę, eliminuje problemy
typu N+1 i zwiększa wydajność przetwarzania w pamięci. Ten sam log może być używany przez systemy BI, analitykę czy modele
ML – bez potrzeby budowy osobnych pipeline’ów ETL, co zmniejsza koszty i skraca czas wdrożeń. Co ważne, cały zespół pracuje
na jednym, spójnym modelu – bez konieczności tłumaczenia różnic między bazą, API i logiką, co ułatwia onboarding, poprawia
komunikację i redukuje liczbę błędów.

### Slajd 36: Saga Pattern – podstawy

Wzorzec Saga to sposób zarządzania transakcjami w systemach rozproszonych, który pozwala bezpiecznie realizować złożone
operacje przez podział na serię lokalnych, niezależnych kroków. Zamiast jednej globalnej transakcji, każde działanie wykonuje
się w obrębie konkretnego serwisu, a przepływ kontrolowany jest przez zdarzenia. W razie błędu nie stosuje się klasycznego
rollbacku, tylko uruchamia kompensacje – czyli akcje cofające skutki wcześniej wykonanych operacji, co pozwala zachować
spójność bez wspólnej bazy danych. Ważnym punktem jest tzw. krok pivot – po jego wykonaniu proces może być tylko kompensowany,
nie anulowany, co ułatwia ocenę ryzyka i decyzje biznesowe. Istnieją dwa style implementacji: choreografia (każdy serwis działa
autonomicznie, reagując na zdarzenia) oraz orkiestracja (centralny komponent steruje kolejnymi krokami). Wszystkie zdarzenia są
zapisywane w Event Store, co zapewnia pełną historię, audyt i możliwość odtworzenia procesu. Dzięki temu Saga nie tylko porządkuje
technicznie wieloetapowe operacje, ale też zwiększa przejrzystość, bezpieczeństwo i kontrolę nad procesami biznesowymi.

### Slajd 37: Frameworki i biblioteki – Java

W ekosystemie Java dostępnych jest kilka dojrzałych frameworków wspierających CQRS i Event Sourcing, z których każdy odpowiada
na inne potrzeby architektoniczne. **Axon Framework** to kompleksowe rozwiązanie z wbudowanym command busem, event store,
silnikiem sag oraz integracją z Spring Boot i JPA, idealne dla aplikacji z rozbudowaną logiką domenową. **Lagom**, oparty
na Akka Cluster i modelu aktorów, wspiera CQRS i Event Sourcing „z pudełka” i dobrze sprawdza się w systemach rozproszonych,
które muszą być odporne na awarie i łatwo skalowalne. **Eventuate Tram** to z kolei biblioteka skupiająca się na wzorcach takich
jak transactional outbox i saga orchestration, zgodnych z praktykami microservices.io – świetnie pasuje do architektury mikroserwisowej,
gdzie ważna jest lokalna spójność i niezawodna komunikacja. Wszystkie te narzędzia oferują integrację ze Spring Bootem przez
gotowe startery, co przyspiesza konfigurację i rozwój. Wybór zależy od kontekstu: Axon będzie dobrym wyborem dla większych,
domenowo zorientowanych monolitów, a Lagom lub Eventuate lepiej sprawdzą się w środowiskach rozproszonych z naciskiem na skalowalność i autonomię usług.

### Slajd 38: Frameworki i biblioteki – .NET

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

### Slajd 39: Frameworki i biblioteki – Python i inne

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

### Slajd 40: Kryteria decyzji „czy stosować CQRS”

Decyzja o zastosowaniu CQRS powinna wynikać z konkretnych potrzeb systemu, a nie z chęci wdrożenia popularnego wzorca –
to narzędzie, które przynosi realne korzyści głównie tam, gdzie występuje wysoka złożoność lub duża skala. Gdy system ma
wyraźną asymetrię między odczytem a zapisem (np. 90% operacji to zapytania), CQRS pozwala niezależnie skalować read-side,
co poprawia wydajność i zmniejsza koszty. W przypadku skomplikowanej logiki biznesowej, rozdzielenie komend i zapytań zwiększa
przejrzystość i umożliwia lepsze zarządzanie odpowiedzialnościami. W branżach regulowanych, gdzie wymagany jest pełny audyt,
Event Sourcing daje wbudowaną historię zmian bez dodatkowych kosztów. CQRS wspiera też pracę wielu zespołów, umożliwiając im
równoległy rozwój modeli zapisu i odczytu bez wzajemnych kolizji. Jednak w prostych systemach CRUD, bez dużych wymagań, może
jedynie wprowadzać niepotrzebną złożoność. Dlatego decyzję o jego wdrożeniu należy podejmować świadomie – na podstawie analizy
wymagań biznesowych, architektury i możliwości zespołu – jako rozwiązanie konkretnego problemu, a nie cel sam w sobie.

### Slajd 41: Strategia adopcji w istniejącym systemie

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

### Slajd 42: Najczęstsze pułapki i anty-wzorce

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

### Slajd 43: Podsumowanie i rekomendacje

CQRS i Event Sourcing to silne podejścia architektoniczne, które – przy właściwym zastosowaniu – znacząco zwiększają
elastyczność, przejrzystość i odporność systemu. Oddzielenie komend (intencji), zapytań (odczytu) i zdarzeń (niezmiennych faktów)
pozwala lepiej odwzorować logikę biznesową, uprościć testowanie i ułatwić komunikację z interesariuszami. To podejście sprawdza
się szczególnie w systemach o wysokiej złożoności, dużym ruchu, konieczności audytu i długim cyklu życia danych. Wymaga jednak
dojrzałości zespołu, odpowiednich narzędzi, monitoringu i świadomego wdrożenia – w przeciwnym razie może niepotrzebnie podnieść
koszty i złożoność. Dlatego warto zaczynać iteracyjnie, od jednego modułu, mierzyć lag, analizować metryki i uczyć zespół w praktyce.
Kluczowe jest jednak podejście pragmatyczne – CQRS i Event Sourcing to narzędzia, nie dogmaty. Ich zastosowanie ma sens tylko
wtedy, gdy wynikają z realnych potrzeb domeny i przynoszą wartość biznesową.
