PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS reports;
DROP TABLE IF EXISTS records;
DROP TABLE IF EXISTS member_progress;
DROP TABLE IF EXISTS training;
DROP TABLE IF EXISTS schedule;
DROP TABLE IF EXISTS plan_training;
DROP TABLE IF EXISTS training_room;
DROP TABLE IF EXISTS program_training;
DROP TABLE IF EXISTS app_user;
DROP TABLE IF EXISTS administrator;
DROP TABLE IF EXISTS trainer;
DROP TABLE IF EXISTS member;

CREATE TABLE member (
    member_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    age INTEGER NOT NULL,
    sex TEXT NOT NULL,
    phone TEXT,
    email TEXT NOT NULL,
    membership_date TEXT,
    status TEXT,
    password TEXT NOT NULL DEFAULT 'clan123'
);

CREATE TABLE trainer (
    trainer_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone TEXT,
    email TEXT NOT NULL,
    specialization TEXT,
    status TEXT,
    password TEXT NOT NULL DEFAULT 'trener123'
);

CREATE TABLE administrator (
    administrator_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    status TEXT NOT NULL
);

CREATE TABLE program_training (
    program_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    program_type TEXT NOT NULL,
    goal TEXT,
    status TEXT NOT NULL DEFAULT 'Aktivan'
);

CREATE TABLE training_room (
    room_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    capacity INTEGER NOT NULL,
    status TEXT NOT NULL
);

CREATE TABLE plan_training (
    plan_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    goal TEXT,
    max_training_count INTEGER NOT NULL,
    duration_minutes INTEGER NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT NOT NULL,
    status TEXT NOT NULL,
    program_id INTEGER,
    room_id INTEGER,
    member_id INTEGER NOT NULL,
    trainer_id INTEGER NOT NULL,
    FOREIGN KEY(program_id) REFERENCES program_training(program_id) ON DELETE SET NULL,
    FOREIGN KEY(room_id) REFERENCES training_room(room_id),
    FOREIGN KEY(member_id) REFERENCES member(member_id),
    FOREIGN KEY(trainer_id) REFERENCES trainer(trainer_id)
);

CREATE TABLE schedule (
    schedule_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT,
    training_date TEXT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    status TEXT,
    note TEXT,
    change_count INTEGER NOT NULL DEFAULT 0,
    plan_id INTEGER NOT NULL,
    FOREIGN KEY(plan_id) REFERENCES plan_training(plan_id)
);

CREATE TABLE training (
    training_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT,
    reservation_time TEXT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    status TEXT,
    note TEXT,
    member_id INTEGER NOT NULL,
    trainer_id INTEGER NOT NULL,
    schedule_id INTEGER NOT NULL,
    FOREIGN KEY(member_id) REFERENCES member(member_id),
    FOREIGN KEY(trainer_id) REFERENCES trainer(trainer_id),
    FOREIGN KEY(schedule_id) REFERENCES schedule(schedule_id)
);

CREATE TABLE records (
    record_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT,
    presence INTEGER NOT NULL DEFAULT 1,
    status TEXT,
    trainer_note TEXT,
    record_date TEXT NOT NULL,
    record_time TEXT NOT NULL,
    training_id INTEGER NOT NULL,
    FOREIGN KEY(training_id) REFERENCES training(training_id)
);

CREATE TABLE reports (
    report_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    report_type TEXT,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    date_created TEXT NOT NULL,
    description TEXT,
    record_id INTEGER NOT NULL,
    FOREIGN KEY(record_id) REFERENCES records(record_id)
);

CREATE TABLE member_progress (
    progress_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT,
    member_id INTEGER NOT NULL UNIQUE,
    initial_weight REAL NOT NULL,
    current_weight REAL NOT NULL,
    height_cm INTEGER NOT NULL,
    initial_bmi REAL NOT NULL,
    current_bmi REAL NOT NULL,
    initial_muscle_percent REAL NOT NULL,
    current_muscle_percent REAL NOT NULL,
    initial_calories INTEGER NOT NULL,
    current_calories INTEGER NOT NULL,
    FOREIGN KEY(member_id) REFERENCES member(member_id)
);

INSERT INTO member(member_id, username, first_name, last_name, age, sex, phone, email, membership_date, status, password) VALUES
(300, 'aleksandar.markovic', 'Aleksandar', 'Markovic', 34, 'Muski', '+381641112233', 'aleksandar.markovic@example.com', '2026-01-08', 'Aktivan', 'clan123'),
(301, 'milica.jovanovic', 'Milica', 'Jovanovic', 28, 'Zenski', '+381641112244', 'milica.jovanovic@example.com', '2026-01-15', 'Aktivan', 'clan123'),
(302, 'nikola.stankovic', 'Nikola', 'Stankovic', 41, 'Muski', '+381641112255', 'nikola.stankovic@example.com', '2026-01-22', 'Aktivan', 'clan123'),
(303, 'jelena.petrovic', 'Jelena', 'Petrovic', 36, 'Zenski', '+381641112266', 'jelena.petrovic@example.com', '2026-02-01', 'Aktivan', 'clan123'),
(304, 'marko.ilic', 'Marko', 'Ilic', 25, 'Muski', '+381641112277', 'marko.ilic@example.com', '2026-02-10', 'Aktivan', 'clan123'),
(305, 'ana.ristic', 'Ana', 'Ristic', 31, 'Zenski', '+381641112288', 'ana.ristic@example.com', '2026-02-18', 'Aktivan', 'clan123'),
(306, 'stefan.djordjevic', 'Stefan', 'Djordjevic', 45, 'Muski', '+381641112299', 'stefan.djordjevic@example.com', '2026-03-03', 'Aktivan', 'clan123'),
(307, 'katarina.popovic', 'Katarina', 'Popovic', 23, 'Zenski', '+381641112300', 'katarina.popovic@example.com', '2026-03-12', 'Aktivan', 'clan123'),
(308, 'luka.pavlovic', 'Luka', 'Pavlovic', 39, 'Muski', '+381641112311', 'luka.pavlovic@example.com', '2026-03-21', 'Aktivan', 'clan123'),
(309, 'sara.nikolic', 'Sara', 'Nikolic', 27, 'Zenski', '+381641112322', 'sara.nikolic@example.com', '2026-04-02', 'Aktivan', 'clan123');

INSERT INTO trainer(trainer_id, username, first_name, last_name, phone, email, specialization, status, password) VALUES
(400, 'milan.trifunovic', 'Milan', 'Trifunovic', '+381601001001', 'milan.trifunovic@fitmanager.rs', 'Snaga i hipertrofija', 'Aktivan', 'trener123'),
(401, 'ivana.ristic', 'Ivana', 'Ristic', '+381601001002', 'ivana.ristic@fitmanager.rs', 'Pilates i mobilnost', 'Aktivan', 'trener123'),
(402, 'nemanja.kostic', 'Nemanja', 'Kostic', '+381601001003', 'nemanja.kostic@fitmanager.rs', 'Kondicija i kardio trening', 'Aktivan', 'trener123'),
(403, 'tamara.pavlovic', 'Tamara', 'Pavlovic', '+381601001004', 'tamara.pavlovic@fitmanager.rs', 'Joga i pravilno drzanje', 'Aktivan', 'trener123'),
(404, 'uros.matic', 'Uros', 'Matic', '+381601001005', 'uros.matic@fitmanager.rs', 'Redukcija telesne mase', 'Aktivan', 'trener123'),
(405, 'katarina.popovic.trener', 'Katarina', 'Popovic', '+381601001006', 'katarina.popovic@fitmanager.rs', 'Rehabilitacioni trening', 'Aktivan', 'trener123'),
(406, 'aleksa.djordjevic', 'Aleksa', 'Djordjevic', '+381601001007', 'aleksa.djordjevic@fitmanager.rs', 'Funkcionalni trening', 'Aktivan', 'trener123'),
(407, 'mina.vasic', 'Mina', 'Vasic', '+381601001008', 'mina.vasic@fitmanager.rs', 'Korektivne vezbe', 'Aktivan', 'trener123'),
(408, 'filip.tomic', 'Filip', 'Tomic', '+381601001009', 'filip.tomic@fitmanager.rs', 'Sportska priprema', 'Aktivan', 'trener123'),
(409, 'nina.zivkovic', 'Nina', 'Zivkovic', '+381601001010', 'nina.zivkovic@fitmanager.rs', 'Trening izdrzljivosti', 'Aktivan', 'trener123');

INSERT INTO administrator VALUES
(1, 'admin', 'Admin', 'Fitmanager', 'admin@fitmanager.rs', 'admin123', 'Aktivan');

INSERT INTO program_training VALUES
(100, 'Pocetni program snage', 'Program za clanove koji prvi put rade sa opterecenjem.', 'Snaga', 'Savladavanje tehnike i osnovna snaga', 'Aktivan'),
(101, 'Redukcija telesne mase', 'Kombinacija kruznog treninga i kardio rada.', 'Redukcija tezine', 'Gubitak masti i bolja kondicija', 'Aktivan'),
(102, 'Misicna hipertrofija', 'Planiran rad po misicnim grupama za povecanje misicne mase.', 'Hipertrofija', 'Povecanje misicne mase', 'Aktivan'),
(103, 'Kondicija i izdrzljivost', 'Intervalni treninzi srednjeg i visokog intenziteta.', 'Kondicija', 'Bolja aerobna i anaerobna izdrzljivost', 'Aktivan'),
(104, 'Pilates stabilizacija', 'Rad na dubokim misicima trupa i pravilnom drzanju.', 'Pilates', 'Stabilnost i kontrola pokreta', 'Aktivan'),
(105, 'Mobilnost i fleksibilnost', 'Treninzi za opseg pokreta, kukove, ramena i kicmu.', 'Mobilnost', 'Veca pokretljivost', 'Aktivan'),
(106, 'Funkcionalni trening', 'Vezbe snage, ravnoteze i koordinacije za svakodnevne pokrete.', 'Funkcionalni trening', 'Funkcionalna spremnost', 'Aktivan'),
(107, 'Korektivni trening', 'Individualni pristup slabim tackama i posturalnim problemima.', 'Korektivni trening', 'Korekcija pokreta', 'Aktivan'),
(108, 'Sportska priprema', 'Program za rekreativne sportiste sa fokusom na eksplozivnost.', 'Sportska priprema', 'Sportske performanse', 'Aktivan'),
(109, 'Kardio zdravlje', 'Kontrolisani kardio treninzi za srce i opstu kondiciju.', 'Kardio', 'Kardiovaskularno zdravlje', 'Aktivan');

INSERT INTO training_room VALUES
(900, 'Sala 1', 12, 'Aktivna'),
(901, 'Sala 2', 8, 'Aktivna'),
(902, 'Kardio sala', 16, 'Aktivna'),
(903, 'Funkcionalna zona', 10, 'Aktivna');

INSERT INTO plan_training VALUES
(200, 'Osnovna snaga - Aleksandar', 'Sigurna tehnika cucnja, potiska i mrtvog dizanja', 16, 60, '2026-05-01', '2026-12-31', 'Aktivan', 100, 900, 300, 400),
(201, 'Redukcija - Milica', 'Postepeno smanjenje masnog tkiva uz pracenje pulsa', 18, 50, '2026-05-01', '2026-12-31', 'Aktivan', 101, 902, 301, 404),
(202, 'Hipertrofija - Nikola', 'Povecanje misicne mase uz progresivno opterecenje', 20, 65, '2026-05-02', '2026-12-31', 'Aktivan', 102, 900, 302, 400),
(203, 'Kondicija - Jelena', 'Intervalni rad i stabilan napredak izdrzljivosti', 14, 45, '2026-05-02', '2026-12-31', 'Aktivan', 103, 902, 303, 402),
(204, 'Pilates - Marko', 'Stabilnost trupa i rasterecenje donjih ledja', 12, 45, '2026-05-03', '2026-12-31', 'Aktivan', 104, 901, 304, 401),
(205, 'Mobilnost - Ana', 'Rad na mobilnosti kukova i ramenog pojasa', 10, 40, '2026-05-03', '2026-12-31', 'Aktivan', 105, 901, 305, 405),
(206, 'Funkcionalni rad - Stefan', 'Jacanje celog tela kroz pokrete vise zglobova', 16, 55, '2026-05-04', '2026-12-31', 'Aktivan', 106, 903, 306, 406),
(207, 'Korektivni plan - Katarina', 'Posturalne vezbe i kontrola lopatica', 12, 45, '2026-05-04', '2026-12-31', 'Aktivan', 107, 901, 307, 407),
(208, 'Sportska priprema - Luka', 'Eksplozivnost, agilnost i prevencija povreda', 18, 60, '2026-05-05', '2026-12-31', 'Aktivan', 108, 903, 308, 408),
(209, 'Kardio plan - Sara', 'Kontrolisani kardio i pracenje zone pulsa', 14, 45, '2026-05-05', '2026-12-31', 'Aktivan', 109, 902, 309, 409);

INSERT INTO schedule(schedule_id, training_date, start_time, end_time, status, note, plan_id) VALUES
(500, '2026-05-11', '08:00', '09:00', 'Potvrdjen', 'Prvi termin za proveru tehnike', 200),
(501, '2026-05-11', '09:15', '10:05', 'Potvrdjen', 'Kruzni trening niskog intenziteta', 201),
(502, '2026-05-12', '10:00', '11:05', 'Potvrdjen', 'Gornji deo tela', 202),
(503, '2026-05-12', '17:00', '17:45', 'Planiran', 'Intervalni kardio', 203),
(504, '2026-05-13', '12:00', '12:45', 'Planiran', 'Pilates na prostirci', 204),
(505, '2026-05-13', '18:00', '18:40', 'Potvrdjen', 'Mobilnost kukova', 205),
(506, '2026-05-14', '08:30', '09:25', 'Potvrdjen', 'Funkcionalni kruzni rad', 206),
(507, '2026-05-14', '16:00', '16:45', 'Potvrdjen', 'Korektivne vezbe', 207),
(508, '2026-05-15', '11:00', '12:00', 'Otkazan', 'Clan pomerio termin', 208),
(509, '2026-05-15', '19:00', '19:45', 'Planiran', 'Kardio zona 2', 209);

INSERT INTO training VALUES
(600, '2026-05-10 18:20', '08:00', '09:00', 'Zakazan', 'Proveriti mobilnost zglobova pre rada', 300, 400, 500),
(601, '2026-05-10 18:35', '09:15', '10:05', 'Zakazan', 'Pripremiti traku i medicinke', 301, 404, 501),
(602, '2026-05-10 19:00', '10:00', '11:05', 'Zakazan', 'Fokus na ledja i ramena', 302, 400, 502),
(603, '2026-05-11 09:10', '17:00', '17:45', 'Zakazan', 'Pulsometar obavezan', 303, 402, 503),
(604, '2026-05-11 09:30', '12:00', '12:45', 'Zakazan', 'Lagani intenzitet zbog ledja', 304, 401, 504),
(605, '2026-05-11 10:05', '18:00', '18:40', 'Zakazan', 'Testirati opseg ramena', 305, 405, 505),
(606, '2026-05-12 08:00', '08:30', '09:25', 'Zakazan', 'Rad sa girjama', 306, 406, 506),
(607, '2026-05-12 08:45', '16:00', '16:45', 'Zakazan', 'Kontrola drzanja', 307, 407, 507),
(608, '2026-05-12 11:20', '11:00', '12:00', 'Otkazan', 'Termin otkazan na zahtev clana', 308, 408, 508),
(609, '2026-05-12 12:00', '19:00', '19:45', 'Zakazan', 'Lagani kardio bez sprinta', 309, 409, 509);

INSERT INTO records VALUES
(700, 1, 'Zavrsen', 'Dobra tehnika, raditi na dubini cucnja.', '2026-05-11', '09:05', 600),
(701, 1, 'Zavrsen', 'Odlican tempo, zadrzati intenzitet.', '2026-05-11', '10:10', 601),
(702, 1, 'Zavrsen', 'Povecati opterecenje naredne nedelje.', '2026-05-12', '11:10', 602),
(703, 1, 'Zavrsen', 'Puls stabilan, dobar oporavak.', '2026-05-12', '17:50', 603),
(704, 0, 'Propusten', 'Clan nije dosao, kontaktirati za novi termin.', '2026-05-13', '12:50', 604),
(705, 1, 'Zavrsen', 'Vidljiv napredak u mobilnosti ramena.', '2026-05-13', '18:45', 605),
(706, 1, 'Zavrsen', 'Dobar rad sa girjama, paziti na zamor.', '2026-05-14', '09:30', 606),
(707, 1, 'Zavrsen', 'Lopatice stabilnije nego prosle nedelje.', '2026-05-14', '16:50', 607),
(708, 0, 'Otkazan', 'Termin otkazan pre pocetka.', '2026-05-15', '11:05', 608),
(709, 1, 'Zavrsen', 'Kardio zona pogodjena, bez tegoba.', '2026-05-15', '19:50', 609);

INSERT INTO reports VALUES
(800, 'Nedeljni izvestaj - snaga', 'Napredak', '2026-05-11 08:00', '2026-05-11 09:00', '2026-05-11', 'Clan uspesno savladao osnovnu tehniku i spreman je za postepeno opterecenje.', 700),
(801, 'Izvestaj redukcije', 'Napredak', '2026-05-11 09:15', '2026-05-11 10:05', '2026-05-11', 'Trening zavrsen u planiranom intenzitetu, bez prevelikog zamora.', 701),
(802, 'Izvestaj hipertrofije', 'Napredak', '2026-05-12 10:00', '2026-05-12 11:05', '2026-05-12', 'Izvedene sve serije, preporuka za blago povecanje kilaze.', 702),
(803, 'Kondicioni izvestaj', 'Performanse', '2026-05-12 17:00', '2026-05-12 17:45', '2026-05-12', 'Puls i oporavak u ocekivanim vrednostima.', 703),
(804, 'Propusten pilates termin', 'Prisustvo', '2026-05-13 12:00', '2026-05-13 12:45', '2026-05-13', 'Clan nije prisustvovao, potrebno zakazati zamenski termin.', 704),
(805, 'Mobilnost ramena', 'Napredak', '2026-05-13 18:00', '2026-05-13 18:40', '2026-05-13', 'Opseg pokreta poboljsan, nastaviti sa istim protokolom.', 705),
(806, 'Funkcionalni trening', 'Napredak', '2026-05-14 08:30', '2026-05-14 09:25', '2026-05-14', 'Clan dobro reaguje na kompleksne pokrete i stabilan tempo.', 706),
(807, 'Korektivni izvestaj', 'Napredak', '2026-05-14 16:00', '2026-05-14 16:45', '2026-05-14', 'Kontrola lopatica bolja, smanjiti kompenzacije u ramenima.', 707),
(808, 'Otkazan sportski termin', 'Prisustvo', '2026-05-15 11:00', '2026-05-15 12:00', '2026-05-15', 'Termin otkazan, bez realizovanih aktivnosti.', 708),
(809, 'Kardio izvestaj', 'Performanse', '2026-05-15 19:00', '2026-05-15 19:45', '2026-05-15', 'Clan odrzao ciljnu zonu pulsa tokom celog treninga.', 709);

INSERT INTO member_progress VALUES
(1000, 300, 102, 100, 187, 29.2, 28.6, 34, 36, 3240, 3120),
(1001, 301, 78, 74, 168, 27.6, 26.2, 31, 33, 2450, 2300),
(1002, 302, 86, 89, 182, 26.0, 26.9, 38, 40, 2980, 3200),
(1003, 303, 68, 66, 171, 23.3, 22.6, 35, 36, 2180, 2100),
(1004, 304, 91, 90, 179, 28.4, 28.1, 32, 33, 2860, 2800),
(1005, 305, 64, 63, 170, 22.1, 21.8, 36, 38, 2100, 2050),
(1006, 306, 95, 94, 188, 26.9, 26.6, 39, 40, 3100, 3050),
(1007, 307, 59, 60, 166, 21.4, 21.8, 34, 35, 1980, 2020),
(1008, 308, 106, 103, 195, 27.9, 27.1, 33, 35, 3300, 3180),
(1009, 309, 72, 70, 174, 23.8, 23.1, 32, 34, 2260, 2180);

DELETE FROM sqlite_sequence
WHERE name IN ('administrator', 'program_training', 'training_room', 'plan_training', 'member', 'trainer', 'schedule', 'training', 'records', 'reports', 'member_progress');

INSERT INTO sqlite_sequence(name, seq) VALUES
('administrator', 1),
('program_training', 109),
('training_room', 903),
('plan_training', 209),
('member', 309),
('trainer', 409),
('schedule', 509),
('training', 609),
('records', 709),
('reports', 809),
('member_progress', 1009);

PRAGMA foreign_keys = ON;
