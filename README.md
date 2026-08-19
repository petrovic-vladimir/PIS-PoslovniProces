# FITMANAGER

FITMANAGER je informacioni sistem izrađen u Delphi/FireMonkey okruženju za podršku poslovnom procesu upravljanja realizacijom treninga u fitnes centru. Aplikacija povezuje izbor programa, kreiranje individualnog plana, zakazivanje termina, dodelu trenera, realizaciju treninga, evidenciju prisustva i izveštavanje.

Projekat prati proces opisan u dokumentu [Predlog rešenja – Upravljanje proizvodnjom](Predlog%20Rešenja%20-%20Upravljanje%20proizvodnjom.pdf).

## Tehnologije

- Delphi 12 / RAD Studio 12
- FireMonkey (FMX)
- FireDAC
- SQLite
- ciljna platforma za demonstraciju: Win32

## Pokretanje projekta

1. Klonirati ili preuzeti repozitorijum.
2. Otvoriti `APP/FITMANAGER_APP.dproj` u RAD Studio okruženju.
3. U meniju **Target Platforms** izabrati **Windows 32-bit**.
4. Izabrati konfiguraciju **Debug** ili **Release**.
5. Pokrenuti **Build**, a zatim **Run**.

Aplikacija automatski pronalazi SQLite bazu. Ako radna baza ne postoji, kreira je na osnovu `database/create_database.sql` i popunjava demonstracionim podacima.

> Za prvo pokretanje nije potrebno ručno izvršavati SQL skriptu.

## Podaci za prijavljivanje

Prijavljivanje je moguće korisničkim imenom ili email adresom.

| Uloga | Korisničko ime | Lozinka |
|---|---|---|
| Administrator | `admin` | `admin123` |
| Trener | `milan.trifunovic` | `trener123` |
| Član | `aleksandar.markovic` | `clan123` |

Svi demonstracioni treneri koriste lozinku `trener123`, a svi demonstracioni članovi lozinku `clan123`.

<details>
<summary>Svi demonstracioni treneri</summary>

| Korisničko ime | Ime i prezime | Specijalizacija |
|---|---|---|
| `milan.trifunovic` | Milan Trifunović | Snaga i hipertrofija |
| `ivana.ristic` | Ivana Ristić | Pilates i mobilnost |
| `nemanja.kostic` | Nemanja Kostić | Kondicija i kardio trening |
| `tamara.pavlovic` | Tamara Pavlović | Joga i pravilno držanje |
| `uros.matic` | Uroš Matić | Redukcija telesne mase |
| `katarina.popovic.trener` | Katarina Popović | Rehabilitacioni trening |
| `aleksa.djordjevic` | Aleksa Đorđević | Funkcionalni trening |
| `mina.vasic` | Mina Vasić | Korektivne vežbe |
| `filip.tomic` | Filip Tomić | Sportska priprema |
| `nina.zivkovic` | Nina Živković | Trening izdržljivosti |

</details>

<details>
<summary>Svi demonstracioni članovi</summary>

| Korisničko ime | Ime i prezime |
|---|---|
| `aleksandar.markovic` | Aleksandar Marković |
| `vlada` | Vladimir Petrović |
| `nikola.stankovic` | Nikola Stanković |
| `jelena.petrovic` | Jelena Petrović |
| `marko.ilic` | Marko Ilić |
| `ana.ristic` | Ana Ristić |
| `stefan.djordjevic` | Stefan Đorđević |
| `katarina.popovic` | Katarina Popović |
| `luka.pavlovic` | Luka Pavlović |
| `sara.nikolic` | Sara Nikolić |

</details>

## Uloge u sistemu

### Administrator

Administrator upravlja opštim podacima sistema:

- pregleda programe treninga;
- dodaje nove programe;
- menja naziv, opis, tip, cilj i status programa;
- briše program bez brisanja istorijskih planova;
- pregleda zbirne izveštaje;
- prati angažovanje svakog trenera;
- vidi broj održanih i propuštenih treninga;
- prati broj promena termina i procenat dolazaka.

### Trener

Trener obavlja stručni i operativni deo procesa:

- vidi članove koji pripadaju njemu;
- vidi novog člana bez plana dok mu trener još nije dodeljen;
- menja status svog člana na `Aktivan`, `Pauziran` ili `Neaktivan`;
- unosi početna merenja člana;
- ažurira trenutna merenja na posebnoj stranici;
- bira program, salu i odgovarajućeg trenera;
- kreira i menja individualni plan;
- odobrava ili odbija zahteve za termin;
- menja datum i vreme treninga;
- pokreće i završava trening;
- evidentira prisustvo ili izostanak;
- unosi stručnu napomenu i formira izveštaj.

### Član

Član koristi operativni deo sistema:

- registruje novi nalog;
- prijavljuje se u sistem;
- vidi status poslednjeg zahteva;
- bira datum i vreme treninga;
- šalje zahtev dodeljenom treneru;
- otkazuje aktivni zahtev ili odobreni termin.

## Program treninga i plan treninga

Ova dva pojma imaju različite uloge:

- **Program treninga** je unapred definisana kategorija rada, na primer mršavljenje, snaga, hipertrofija ili kondicija.
- **Plan treninga** je konkretna realizacija izabranog programa za jednog člana. Sadrži cilj, broj treninga, trajanje, period važenja, salu i dodeljenog trenera.

Član ne može da zakazuje trening dok nema aktivan plan, salu i dodeljenog trenera.

Pauziran ili neaktivan član ostaje vidljiv samo treneru kome je dodeljen, kako bi trener mogao ponovo da ga aktivira. Pauziran član može da se prijavi i pregleda dashboard, ali ne može da zakaže novi trening. Neaktivan član ne može da se prijavi.

## Kompletan poslovni tok

### 1. Registracija člana

Na početnoj stranici izabrati **Registruj se**, popuniti sva polja i potvrditi registraciju. Novi nalog dobija ulogu člana i status `Aktivan`.

Novi član u ovom trenutku nema program, plan, merenja ni trenera i zato još ne može da zakaže termin.

### 2. Prvi unos merenja

Trener se prijavljuje i na kontrolnoj tabli otvara karticu novog člana.

Ako član nema podatke u evidenciji napretka, prikazuje se samo forma za prvi unos:

- godine;
- visina;
- početna težina;
- početni BMI, koji se računa automatski;
- početni procenat mišićne mase;
- početni broj kalorija.

Nakon čuvanja početna forma trajno nestaje. Početne vrednosti ostaju sačuvane kao osnova za poređenje napretka.

### 3. Ažuriranje trenutnih vrednosti

Posle prvog unosa na kartici se prikazuje dugme **Ažuriraj trenutne vrednosti**. Dugme otvara posebnu stranicu na kojoj trener može da promeni:

- godine i visinu;
- trenutnu težinu;
- trenutni procenat mišićne mase;
- trenutni broj kalorija.

Trenutni BMI se automatski preračunava. Nakon povratka na karticu tabela početnih i trenutnih vrednosti automatski se osvežava.

### 4. Kreiranje plana i dodela trenera

Na istoj kartici trener popunjava:

- naziv plana;
- cilj treninga;
- program treninga;
- salu;
- trenera i njegovu specijalizaciju;
- maksimalni broj treninga;
- trajanje jednog treninga;
- datum početka i završetka plana;
- status plana.

Datumi se unose u formatu `yyyy-mm-dd`.

Nakon čuvanja kartica člana se prikazuje samo treneru koji je izabran u planu. Član bez plana je privremeno vidljiv trenerima da bi mogao da bude preuzet, ali dodeljeni član ne može biti prikazan kod više trenera.

### 5. Zakazivanje termina

Član se prijavljuje i unosi datum, vreme početka i vreme završetka treninga.

Sistem proverava:

- da li član ima aktivan plan;
- da li je datum unutar perioda plana;
- da li maksimalni broj treninga nije dostignut;
- da li je trener aktivan;
- da li je sala aktivna;
- da li su trener i sala slobodni u traženom terminu.

Član može imati više budućih termina, ali termini ne smeju da se preklapaju sa zauzećem trenera ili sale.

### 6. Odobravanje zahteva

Dodeljeni trener vidi zahtev na svojoj kontrolnoj tabli i bira **Odobri** ili **Odbij**. Pre odobravanja sistem ponovo proverava raspoloživost trenera i sale.

### 7. Izmena termina

Trener otvara **Realizaciju treninga**, bira trening i može da promeni datum, vreme ili napomenu.

Svaka stvarna promena datuma ili vremena povećava broj evidentiranih promena termina. Promena same napomene se ne računa kao promena termina.

### 8. Realizacija treninga

Za člana koji je došao trener:

1. bira trening;
2. pritiska **Pokreni**;
3. ostavlja uključeno polje da je član prisustvovao;
4. unosi napomenu;
5. pritiska **Završi**.

Ako član nije došao, trener isključuje polje za prisustvo i završava evidenciju bez pokretanja treninga. Status tada postaje `Propušten`.

Isti trening nije moguće evidentirati dva puta.

### 9. Izveštavanje

Po završetku ili evidentiranju izostanka sistem automatski kreira:

- zapis o prisustvu;
- konačni status treninga;
- napomenu trenera;
- datum i vreme evidencije;
- izveštaj o realizaciji.

Administrator na svojoj kontrolnoj tabli bira **Izveštaji** i dobija pregled po trenerima i zbirne pokazatelje.

## Predloženi scenario za demonstraciju

Najpotpunija demonstracija dobija se kreiranjem novog člana:

1. Registrovati novog člana sa proizvoljnim korisničkim imenom i lozinkom.
2. Prijaviti se kao `milan.trifunovic` / `trener123`.
3. Otvoriti karticu novog člana.
4. Uneti početna merenja i sačuvati ih.
5. Proveriti da je početna forma nestala i da se pojavilo dugme za ažuriranje trenutnih vrednosti.
6. Kreirati plan i kao trenera izabrati Milana.
7. Prijaviti se kao novi član i poslati zahtev za termin unutar perioda plana.
8. Ponovo se prijaviti kao Milan i odobriti zahtev.
9. Otvoriti realizaciju treninga, po želji promeniti termin, pokrenuti i završiti trening.
10. Prijaviti se kao `admin` / `admin123` i otvoriti izveštaje.

Za demonstraciju kontrole pristupa može se u planu izabrati drugi trener. Posle čuvanja kartica nestaje sa Milanove kontrolne table i postaje vidljiva samo izabranom treneru.

## Najčešći problemi

### Član ne može da zakaže trening

Proveriti da li član ima aktivan plan, izabranog trenera i salu. Datum termina mora biti unutar perioda plana.

### Trener ne vidi karticu člana

Ako član već ima plan, karticu vidi samo trener dodeljen poslednjim aktivnim planom. Prijaviti se nalogom tog trenera.

### Termin nije moguće odobriti ili sačuvati

Drugi trening verovatno zauzima istog trenera ili istu salu u delu izabranog intervala.

### Potreban je povratak na početne demonstracione podatke

1. Zaustaviti aplikaciju.
2. Napraviti rezervnu kopiju postojeće radne baze ako su podaci važni.
3. Obrisati samo radnu bazu `APP/Win32/database/fitmanager.db`.
4. Ponovo pokrenuti aplikaciju.

Aplikacija će napraviti novu bazu iz `database/create_database.sql`.

