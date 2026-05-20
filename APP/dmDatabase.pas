unit dmDatabase;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.FMXUI.Wait, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, FireDAC.Comp.Script, FireDAC.Comp.ScriptCommands;

type
  TUserRole = (urNone, urAdmin, urMember, urTrainer);

  TDB = class(TDataModule)
    FDConnection1: TFDConnection;
    FDQuery1: TFDQuery;
  private
    FCurrentRole: TUserRole;
    FCurrentUserId: Integer;
    FCurrentMemberId: Integer;
    FCurrentTrainerId: Integer;
    FCurrentUsername: string;
    function BuildPath(const APath, AFileName: string): string;
    function ColumnExists(const ATableName, AColumnName: string): Boolean;
    function ColumnIsRequired(const ATableName, AColumnName: string): Boolean;
    function GetDatabaseFileName: string;
    function GetDatabaseScriptFileName: string;
    function GetDatabaseTemplateFileName: string;
    function DatabaseIsReady: Boolean;
    procedure ConfigureConnection;
    procedure CreateDatabaseFromScript(const AScriptFileName: string);
    procedure CreateMinimalDatabase;
    procedure EnsureDatabaseSchema;
    procedure EnsureLoginSchema;
    procedure ExecuteSqlText(const ASqlText: string);
    procedure RebuildPlanTrainingForProgramDelete;
  public
    function AuthenticateUser(const ALogin, APassword: string): Boolean;
    procedure InitializeDatabase;
    procedure ResetCurrentUser;
    function RegisterMemberUser(const AFirstName, ALastName, AUsername, APassword,
      AEmail, APhone: string): Boolean;
    property CurrentMemberId: Integer read FCurrentMemberId;
    property CurrentRole: TUserRole read FCurrentRole;
    property CurrentTrainerId: Integer read FCurrentTrainerId;
    property CurrentUserId: Integer read FCurrentUserId;
    property CurrentUsername: string read FCurrentUsername;
  end;

var
  DB: TDB;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

procedure TDB.ConfigureConnection;
begin
  FDConnection1.Connected := False;
  FDConnection1.Params.Values['DriverID'] := 'SQLite';
  FDConnection1.Params.Values['Database'] := GetDatabaseFileName;
  FDConnection1.LoginPrompt := False;
end;

function TDB.DatabaseIsReady: Boolean;
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FDConnection1;
    Query.SQL.Text :=
      'SELECT COUNT(*) AS table_count FROM sqlite_master ' +
      'WHERE type = ''table'' AND name IN (' +
      '''member'', ''trainer'', ''program_training'', ''plan_training'', ' +
      '''schedule'', ''training'', ''records'', ''reports'')';
    Query.Open;
    Result := Query.FieldByName('table_count').AsInteger = 8;
  finally
    Query.Free;
  end;
end;

function TDB.AuthenticateUser(const ALogin, APassword: string): Boolean;
var
  LoginEmail: string;
begin
  ResetCurrentUser;
  InitializeDatabase;
  LoginEmail := Trim(ALogin);

  FDQuery1.Close;
  FDQuery1.SQL.Text :=
    'SELECT administrator_id, username, email FROM administrator ' +
    'WHERE (LOWER(TRIM(username)) = LOWER(:login_username) OR LOWER(TRIM(email)) = LOWER(:login_email)) ' +
    'AND password = :password AND TRIM(status) = :status ' +
    'LIMIT 1';
  FDQuery1.ParamByName('login_username').AsString := LoginEmail;
  FDQuery1.ParamByName('login_email').AsString := LoginEmail;
  FDQuery1.ParamByName('password').AsString := APassword;
  FDQuery1.ParamByName('status').AsString := 'Aktivan';
  FDQuery1.Open;
  Result := not FDQuery1.IsEmpty;
  if Result then
  begin
    FCurrentUserId := FDQuery1.FieldByName('administrator_id').AsInteger;
    FCurrentUsername := FDQuery1.FieldByName('username').AsString;
    FCurrentRole := urAdmin;
    FDQuery1.Close;
    Exit(True);
  end;
  FDQuery1.Close;

  FDQuery1.SQL.Text :=
    'SELECT trainer_id, username, email FROM trainer ' +
    'WHERE (LOWER(TRIM(username)) = LOWER(:login_username) OR LOWER(TRIM(email)) = LOWER(:login_email)) ' +
    'AND password = :password AND TRIM(status) = :status ' +
    'LIMIT 1';
  FDQuery1.ParamByName('login_username').AsString := LoginEmail;
  FDQuery1.ParamByName('login_email').AsString := LoginEmail;
  FDQuery1.ParamByName('password').AsString := APassword;
  FDQuery1.ParamByName('status').AsString := 'Aktivan';
  FDQuery1.Open;
  Result := not FDQuery1.IsEmpty;
  if Result then
  begin
    FCurrentUserId := FDQuery1.FieldByName('trainer_id').AsInteger;
    FCurrentTrainerId := FCurrentUserId;
    FCurrentUsername := FDQuery1.FieldByName('username').AsString;
    FCurrentRole := urTrainer;
    FDQuery1.Close;
    Exit(True);
  end;
  FDQuery1.Close;

  FDQuery1.SQL.Text :=
    'SELECT member_id, username, email FROM member ' +
    'WHERE (LOWER(TRIM(username)) = LOWER(:login_username) OR LOWER(TRIM(email)) = LOWER(:login_email)) ' +
    'AND password = :password AND TRIM(status) = :status ' +
    'LIMIT 1';
  FDQuery1.ParamByName('login_username').AsString := LoginEmail;
  FDQuery1.ParamByName('login_email').AsString := LoginEmail;
  FDQuery1.ParamByName('password').AsString := APassword;
  FDQuery1.ParamByName('status').AsString := 'Aktivan';
  FDQuery1.Open;
  Result := not FDQuery1.IsEmpty;
  if Result then
  begin
    FCurrentUserId := FDQuery1.FieldByName('member_id').AsInteger;
    FCurrentMemberId := FCurrentUserId;
    FCurrentUsername := FDQuery1.FieldByName('username').AsString;
    FCurrentRole := urMember;
  end;
  FDQuery1.Close;
end;

function TDB.BuildPath(const APath, AFileName: string): string;
begin
  Result := IncludeTrailingPathDelimiter(APath) + AFileName;
end;

function TDB.ColumnExists(const ATableName, AColumnName: string): Boolean;
var
  Query: TFDQuery;
begin
  Result := False;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FDConnection1;
    Query.SQL.Text := 'PRAGMA table_info(' + ATableName + ')';
    Query.Open;
    while not Query.Eof do
    begin
      if SameText(Query.FieldByName('name').AsString, AColumnName) then
        Exit(True);
      Query.Next;
    end;
  finally
    Query.Free;
  end;
end;

function TDB.ColumnIsRequired(const ATableName, AColumnName: string): Boolean;
var
  Query: TFDQuery;
begin
  Result := False;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FDConnection1;
    Query.SQL.Text := 'PRAGMA table_info(' + ATableName + ')';
    Query.Open;
    while not Query.Eof do
    begin
      if SameText(Query.FieldByName('name').AsString, AColumnName) then
        Exit(Query.FieldByName('notnull').AsInteger = 1);
      Query.Next;
    end;
  finally
    Query.Free;
  end;
end;

procedure TDB.CreateDatabaseFromScript(const AScriptFileName: string);
begin
  ExecuteSqlText(TFile.ReadAllText(AScriptFileName, TEncoding.UTF8));
end;

procedure TDB.CreateMinimalDatabase;
const
  CMinimalDatabaseSql =
    'PRAGMA foreign_keys = OFF;'#13#10 +
    'CREATE TABLE IF NOT EXISTS member (' +
    'member_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT, ' +
    'username TEXT NOT NULL UNIQUE, first_name TEXT NOT NULL, last_name TEXT NOT NULL, age INTEGER NOT NULL, ' +
    'sex TEXT NOT NULL, phone TEXT, email TEXT NOT NULL, membership_date TEXT, status TEXT, ' +
    'password TEXT NOT NULL DEFAULT ''clan123'');'#13#10 +
    'CREATE TABLE IF NOT EXISTS trainer (' +
    'trainer_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT, ' +
    'username TEXT NOT NULL UNIQUE, first_name TEXT NOT NULL, last_name TEXT NOT NULL, phone TEXT, email TEXT NOT NULL, ' +
    'specialization TEXT, status TEXT, password TEXT NOT NULL DEFAULT ''trener123'');'#13#10 +
    'CREATE TABLE IF NOT EXISTS administrator (' +
    'administrator_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT, ' +
    'username TEXT NOT NULL UNIQUE, first_name TEXT NOT NULL, last_name TEXT NOT NULL, email TEXT NOT NULL UNIQUE, ' +
    'password TEXT NOT NULL, status TEXT NOT NULL);'#13#10 +
    'CREATE TABLE IF NOT EXISTS program_training (' +
    'program_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL UNIQUE, ' +
    'description TEXT NOT NULL, program_type TEXT NOT NULL, goal TEXT, status TEXT NOT NULL DEFAULT ''Aktivan'');'#13#10 +
    'CREATE TABLE IF NOT EXISTS plan_training (' +
    'plan_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, goal TEXT, ' +
    'max_training_count INTEGER NOT NULL, duration_minutes INTEGER NOT NULL, start_date TEXT NOT NULL, ' +
    'end_date TEXT NOT NULL, status TEXT NOT NULL, program_id INTEGER, member_id INTEGER NOT NULL, ' +
    'trainer_id INTEGER NOT NULL, ' +
    'FOREIGN KEY(program_id) REFERENCES program_training(program_id) ON DELETE SET NULL, ' +
    'FOREIGN KEY(member_id) REFERENCES member(member_id), ' +
    'FOREIGN KEY(trainer_id) REFERENCES trainer(trainer_id));'#13#10 +
    'CREATE TABLE IF NOT EXISTS schedule (' +
    'schedule_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT, training_date TEXT NOT NULL, ' +
    'start_time TEXT NOT NULL, end_time TEXT NOT NULL, status TEXT, note TEXT, plan_id INTEGER NOT NULL, ' +
    'FOREIGN KEY(plan_id) REFERENCES plan_training(plan_id));'#13#10 +
    'CREATE TABLE IF NOT EXISTS training (' +
    'training_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT, reservation_time TEXT NOT NULL, ' +
    'start_time TEXT NOT NULL, end_time TEXT NOT NULL, status TEXT, note TEXT, member_id INTEGER NOT NULL, ' +
    'trainer_id INTEGER NOT NULL, schedule_id INTEGER NOT NULL, ' +
    'FOREIGN KEY(member_id) REFERENCES member(member_id), ' +
    'FOREIGN KEY(trainer_id) REFERENCES trainer(trainer_id), ' +
    'FOREIGN KEY(schedule_id) REFERENCES schedule(schedule_id));'#13#10 +
    'CREATE TABLE IF NOT EXISTS records (' +
    'record_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT, presence INTEGER NOT NULL DEFAULT 1, ' +
    'status TEXT, trainer_note TEXT, record_date TEXT NOT NULL, record_time TEXT NOT NULL, training_id INTEGER NOT NULL, ' +
    'FOREIGN KEY(training_id) REFERENCES training(training_id));'#13#10 +
    'CREATE TABLE IF NOT EXISTS reports (' +
    'report_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT, title TEXT, report_type TEXT, ' +
    'start_time TEXT NOT NULL, end_time TEXT NOT NULL, date_created TEXT NOT NULL, description TEXT, record_id INTEGER NOT NULL, ' +
    'FOREIGN KEY(record_id) REFERENCES records(record_id));'#13#10 +
    'INSERT OR IGNORE INTO member(member_id, username, first_name, last_name, age, sex, phone, email, membership_date, status, password) VALUES ' +
    '(300, ''aleksandar.markovic'', ''Aleksandar'', ''Markovic'', 34, ''Muski'', ''+381641112233'', ' +
    '''aleksandar.markovic@example.com'', ''2026-01-08'', ''Aktivan'', ''clan123'');'#13#10 +
    'INSERT OR IGNORE INTO trainer(trainer_id, username, first_name, last_name, phone, email, specialization, status, password) VALUES ' +
    '(400, ''milan.trifunovic'', ''Milan'', ''Trifunovic'', ''+381601001001'', ''milan.trifunovic@fitmanager.rs'', ' +
    '''Snaga i hipertrofija'', ''Aktivan'', ''trener123'');'#13#10 +
    'INSERT OR IGNORE INTO administrator VALUES ' +
    '(1, ''admin'', ''Admin'', ''Fitmanager'', ''admin@fitmanager.rs'', ''admin123'', ''Aktivan'');'#13#10 +
    'INSERT OR IGNORE INTO program_training VALUES ' +
    '(100, ''Pocetni program snage'', ''Program za clanove koji prvi put rade sa opterecenjem.'', ' +
    '''Snaga'', ''Savladavanje tehnike i osnovna snaga'', ''Aktivan'');'#13#10 +
    'INSERT OR IGNORE INTO plan_training VALUES ' +
    '(200, ''Osnovna snaga - Aleksandar'', ''Sigurna tehnika cucnja, potiska i mrtvog dizanja'', ' +
    '16, 60, ''2026-05-01'', ''2026-07-15'', ''Aktivan'', 100, 300, 400);'#13#10 +
    'DELETE FROM sqlite_sequence WHERE name IN (''administrator'', ''program_training'', ''plan_training'', ''member'', ''trainer'');'#13#10 +
    'INSERT INTO sqlite_sequence(name, seq) VALUES ' +
    '(''administrator'', 1), (''program_training'', 100), (''plan_training'', 200), (''member'', 300), (''trainer'', 400);'#13#10 +
    'PRAGMA foreign_keys = ON;';
begin
  ExecuteSqlText(CMinimalDatabaseSql);
end;

procedure TDB.EnsureDatabaseSchema;
begin
  if not ColumnExists('plan_training', 'trainer_id') then
  begin
    FDConnection1.ExecSQL('ALTER TABLE plan_training ADD COLUMN trainer_id INTEGER');
    FDConnection1.ExecSQL(
      'UPDATE plan_training SET trainer_id = CASE plan_id ' +
      'WHEN 200 THEN 400 WHEN 201 THEN 404 WHEN 202 THEN 400 ' +
      'WHEN 203 THEN 402 WHEN 204 THEN 401 WHEN 205 THEN 405 ' +
      'WHEN 206 THEN 406 WHEN 207 THEN 407 WHEN 208 THEN 408 ' +
      'WHEN 209 THEN 409 ELSE 400 END ' +
      'WHERE trainer_id IS NULL');
  end;

  if ColumnIsRequired('plan_training', 'program_id') then
    RebuildPlanTrainingForProgramDelete;

  FDConnection1.ExecSQL(
    'CREATE TABLE IF NOT EXISTS training_room (' +
    'room_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT, ' +
    'name TEXT NOT NULL UNIQUE, capacity INTEGER NOT NULL, status TEXT NOT NULL)');
  FDConnection1.ExecSQL('INSERT OR IGNORE INTO training_room(room_id, name, capacity, status) VALUES (900, ''Sala 1'', 12, ''Aktivna'')');
  FDConnection1.ExecSQL('INSERT OR IGNORE INTO training_room(room_id, name, capacity, status) VALUES (901, ''Sala 2'', 8, ''Aktivna'')');
  FDConnection1.ExecSQL('INSERT OR IGNORE INTO training_room(room_id, name, capacity, status) VALUES (902, ''Kardio sala'', 16, ''Aktivna'')');
  FDConnection1.ExecSQL('INSERT OR IGNORE INTO training_room(room_id, name, capacity, status) VALUES (903, ''Funkcionalna zona'', 10, ''Aktivna'')');
  if not ColumnExists('plan_training', 'room_id') then
    FDConnection1.ExecSQL('ALTER TABLE plan_training ADD COLUMN room_id INTEGER');
  FDConnection1.ExecSQL('UPDATE plan_training SET room_id = 900 WHERE room_id IS NULL');

  FDConnection1.ExecSQL(
    'CREATE TABLE IF NOT EXISTS member_progress (' +
    'progress_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT, ' +
    'member_id INTEGER NOT NULL UNIQUE, initial_weight REAL NOT NULL, current_weight REAL NOT NULL, ' +
    'height_cm INTEGER NOT NULL, initial_bmi REAL NOT NULL, current_bmi REAL NOT NULL, ' +
    'initial_muscle_percent REAL NOT NULL, current_muscle_percent REAL NOT NULL, ' +
    'initial_calories INTEGER NOT NULL, current_calories INTEGER NOT NULL, ' +
    'FOREIGN KEY(member_id) REFERENCES member(member_id))');
  FDConnection1.ExecSQL('INSERT OR IGNORE INTO member_progress VALUES (1000, 300, 102, 100, 187, 29.2, 28.6, 34, 36, 3240, 3120)');
  FDConnection1.ExecSQL('INSERT OR IGNORE INTO member_progress VALUES (1001, 301, 78, 74, 168, 27.6, 26.2, 31, 33, 2450, 2300)');
  FDConnection1.ExecSQL('INSERT OR IGNORE INTO member_progress VALUES (1002, 302, 86, 89, 182, 26.0, 26.9, 38, 40, 2980, 3200)');
  FDConnection1.ExecSQL('INSERT OR IGNORE INTO member_progress VALUES (1003, 303, 68, 66, 171, 23.3, 22.6, 35, 36, 2180, 2100)');
  FDConnection1.ExecSQL('INSERT OR IGNORE INTO member_progress VALUES (1004, 304, 91, 90, 179, 28.4, 28.1, 32, 33, 2860, 2800)');
  FDConnection1.ExecSQL('INSERT OR IGNORE INTO member_progress VALUES (1005, 305, 64, 63, 170, 22.1, 21.8, 36, 38, 2100, 2050)');
  FDConnection1.ExecSQL('INSERT OR IGNORE INTO member_progress VALUES (1006, 306, 95, 94, 188, 26.9, 26.6, 39, 40, 3100, 3050)');
  FDConnection1.ExecSQL('INSERT OR IGNORE INTO member_progress VALUES (1007, 307, 59, 60, 166, 21.4, 21.8, 34, 35, 1980, 2020)');
  FDConnection1.ExecSQL('INSERT OR IGNORE INTO member_progress VALUES (1008, 308, 106, 103, 195, 27.9, 27.1, 33, 35, 3300, 3180)');
  FDConnection1.ExecSQL('INSERT OR IGNORE INTO member_progress VALUES (1009, 309, 72, 70, 174, 23.8, 23.1, 32, 34, 2260, 2180)');

  EnsureLoginSchema;
end;

procedure TDB.EnsureLoginSchema;
begin
  FDConnection1.ExecSQL(
    'CREATE TABLE IF NOT EXISTS administrator (' +
    'administrator_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT, ' +
    'first_name TEXT NOT NULL, last_name TEXT NOT NULL, email TEXT NOT NULL UNIQUE, ' +
    'password TEXT NOT NULL, status TEXT NOT NULL)');

  if not ColumnExists('member', 'password') then
    FDConnection1.ExecSQL('ALTER TABLE member ADD COLUMN password TEXT NOT NULL DEFAULT ''clan123''');
  if not ColumnExists('trainer', 'password') then
    FDConnection1.ExecSQL('ALTER TABLE trainer ADD COLUMN password TEXT NOT NULL DEFAULT ''trener123''');
  if not ColumnExists('member', 'username') then
    FDConnection1.ExecSQL('ALTER TABLE member ADD COLUMN username TEXT');
  if not ColumnExists('trainer', 'username') then
    FDConnection1.ExecSQL('ALTER TABLE trainer ADD COLUMN username TEXT');
  if not ColumnExists('administrator', 'username') then
    FDConnection1.ExecSQL('ALTER TABLE administrator ADD COLUMN username TEXT');

  FDConnection1.ExecSQL('UPDATE member SET password = ''clan123'' WHERE password IS NULL OR password = ''''');
  FDConnection1.ExecSQL('UPDATE trainer SET password = ''trener123'' WHERE password IS NULL OR password = ''''');
  FDConnection1.ExecSQL('UPDATE member SET username = LOWER(REPLACE(first_name || ''.'' || last_name, '' '', '''')) WHERE username IS NULL OR username = ''''');
  FDConnection1.ExecSQL('UPDATE trainer SET username = LOWER(REPLACE(first_name || ''.'' || last_name, '' '', '''')) WHERE username IS NULL OR username = ''''');
  FDConnection1.ExecSQL('UPDATE administrator SET username = ''admin'' WHERE username IS NULL OR username = ''''');
  FDConnection1.ExecSQL('UPDATE member SET username = ''ana.ristic'', password = ''clan123'', status = ''Aktivan'' WHERE email = ''ana.ristic@example.com''');
  FDConnection1.ExecSQL('UPDATE member SET username = ''aleksandar.markovic'', password = ''clan123'', status = ''Aktivan'' WHERE email = ''aleksandar.markovic@example.com''');
  FDConnection1.ExecSQL('UPDATE trainer SET username = ''milan.trifunovic'', password = ''trener123'', status = ''Aktivan'' WHERE email = ''milan.trifunovic@fitmanager.rs''');
  FDConnection1.ExecSQL('UPDATE member SET status = ''Neaktivan'' WHERE LOWER(TRIM(username)) = ''clan'' OR LOWER(TRIM(email)) = ''clan''');
  FDConnection1.ExecSQL(
    'INSERT OR IGNORE INTO administrator(administrator_id, username, first_name, last_name, email, password, status) ' +
    'VALUES (1, ''admin'', ''Admin'', ''Fitmanager'', ''admin@fitmanager.rs'', ''admin123'', ''Aktivan'')');
  FDConnection1.ExecSQL('DROP TABLE IF EXISTS app_user');
end;

procedure TDB.RebuildPlanTrainingForProgramDelete;
begin
  ExecuteSqlText(
    'PRAGMA foreign_keys = OFF;'#13#10 +
    'CREATE TABLE plan_training_new (' +
    'plan_id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT, ' +
    'title TEXT NOT NULL, goal TEXT, max_training_count INTEGER NOT NULL, ' +
    'duration_minutes INTEGER NOT NULL, start_date TEXT NOT NULL, end_date TEXT NOT NULL, ' +
    'status TEXT NOT NULL, program_id INTEGER, member_id INTEGER NOT NULL, trainer_id INTEGER NOT NULL, ' +
    'FOREIGN KEY(program_id) REFERENCES program_training(program_id) ON DELETE SET NULL, ' +
    'FOREIGN KEY(member_id) REFERENCES member(member_id), ' +
    'FOREIGN KEY(trainer_id) REFERENCES trainer(trainer_id));'#13#10 +
    'INSERT INTO plan_training_new ' +
    '(plan_id, title, goal, max_training_count, duration_minutes, start_date, end_date, status, program_id, member_id, trainer_id) ' +
    'SELECT plan_id, title, goal, max_training_count, duration_minutes, start_date, end_date, status, program_id, member_id, trainer_id ' +
    'FROM plan_training;'#13#10 +
    'DROP TABLE plan_training;'#13#10 +
    'ALTER TABLE plan_training_new RENAME TO plan_training;'#13#10 +
    'DELETE FROM sqlite_sequence WHERE name = ''plan_training'';'#13#10 +
    'INSERT INTO sqlite_sequence(name, seq) SELECT ''plan_training'', COALESCE(MAX(plan_id), 199) FROM plan_training;'#13#10 +
    'PRAGMA foreign_keys = ON;');
end;

procedure TDB.ExecuteSqlText(const ASqlText: string);
var
  Script: TFDScript;
begin
  Script := TFDScript.Create(nil);
  try
    Script.Connection := FDConnection1;
    Script.SQLScripts.Clear;
    Script.SQLScripts.Add.SQL.Text := ASqlText;
    Script.ValidateAll;
    Script.ExecuteAll;
  finally
    Script.Free;
  end;
end;

procedure TDB.InitializeDatabase;
var
  DatabaseFileName: string;
  DatabaseTemplateFileName: string;
  DatabaseScriptFileName: string;
begin
  ConfigureConnection;
  DatabaseFileName := FDConnection1.Params.Values['Database'];

  if not TFile.Exists(DatabaseFileName) then
  begin
    TDirectory.CreateDirectory(ExtractFilePath(DatabaseFileName));

    DatabaseTemplateFileName := GetDatabaseTemplateFileName;
    if (DatabaseTemplateFileName <> '') and
       (not SameText(DatabaseTemplateFileName, DatabaseFileName)) then
      TFile.Copy(DatabaseTemplateFileName, DatabaseFileName, True);

    if not TFile.Exists(DatabaseFileName) then
    begin
      FDConnection1.Connected := True;
      DatabaseScriptFileName := GetDatabaseScriptFileName;
      if DatabaseScriptFileName <> '' then
        CreateDatabaseFromScript(DatabaseScriptFileName)
      else
        CreateMinimalDatabase;
    end
    else
      FDConnection1.Connected := True;
  end
  else
    FDConnection1.Connected := True;

  if not DatabaseIsReady then
  begin
    DatabaseScriptFileName := GetDatabaseScriptFileName;
    if DatabaseScriptFileName <> '' then
      CreateDatabaseFromScript(DatabaseScriptFileName)
    else
    begin
      DatabaseTemplateFileName := GetDatabaseTemplateFileName;
      if (DatabaseTemplateFileName <> '') and
         (not SameText(DatabaseTemplateFileName, DatabaseFileName)) then
      begin
        FDConnection1.Connected := False;
        TFile.Copy(DatabaseTemplateFileName, DatabaseFileName, True);
        FDConnection1.Connected := True;
      end;

      if not DatabaseIsReady then
        CreateMinimalDatabase;
    end;
  end;

  EnsureDatabaseSchema;
end;

procedure TDB.ResetCurrentUser;
begin
  FCurrentRole := urNone;
  FCurrentUserId := 0;
  FCurrentMemberId := 0;
  FCurrentTrainerId := 0;
  FCurrentUsername := '';
end;

function TDB.RegisterMemberUser(const AFirstName, ALastName, AUsername,
  APassword, AEmail, APhone: string): Boolean;
begin
  Result := False;
  InitializeDatabase;

  FDQuery1.Close;
  FDQuery1.SQL.Text :=
    'SELECT 1 FROM member WHERE email = :email OR username = :username ' +
    'UNION SELECT 1 FROM trainer WHERE email = :email OR username = :username ' +
    'UNION SELECT 1 FROM administrator WHERE email = :email OR username = :username';
  FDQuery1.ParamByName('username').AsString := Trim(AUsername);
  FDQuery1.ParamByName('email').AsString := Trim(AEmail);
  FDQuery1.Open;
  if not FDQuery1.IsEmpty then
  begin
    FDQuery1.Close;
    Exit;
  end;
  FDQuery1.Close;

  FDConnection1.StartTransaction;
  try
    FDQuery1.SQL.Text :=
      'INSERT INTO member(username, first_name, last_name, age, sex, phone, email, membership_date, status, password) ' +
      'VALUES (:username, :first_name, :last_name, :age, :sex, :phone, :email, :membership_date, :status, :password)';
    FDQuery1.ParamByName('username').AsString := Trim(AUsername);
    FDQuery1.ParamByName('first_name').AsString := Trim(AFirstName);
    FDQuery1.ParamByName('last_name').AsString := Trim(ALastName);
    FDQuery1.ParamByName('age').AsInteger := 18;
    FDQuery1.ParamByName('sex').AsString := 'Nije uneto';
    FDQuery1.ParamByName('phone').AsString := Trim(APhone);
    FDQuery1.ParamByName('email').AsString := Trim(AEmail);
    FDQuery1.ParamByName('membership_date').AsString := FormatDateTime('yyyy-mm-dd', Date);
    FDQuery1.ParamByName('status').AsString := 'Aktivan';
    FDQuery1.ParamByName('password').AsString := APassword;
    FDQuery1.ExecSQL;

    FDConnection1.Commit;
    Result := True;
  except
    on E: Exception do
    begin
      FDConnection1.Rollback;
      raise;
    end;
  end;
end;

function TDB.GetDatabaseFileName: string;
begin
  {$IFDEF MSWINDOWS}
  Result := '..\database\fitmanager.db';
  {$ELSE}
  Result := BuildPath(System.IOUtils.TPath.GetDocumentsPath, 'fitmanager.db');
  {$ENDIF}
end;

function TDB.GetDatabaseScriptFileName: string;
var
  CandidateFileName: string;
begin
  {$IFDEF MSWINDOWS}
  CandidateFileName := '..\database\create_database.sql';
  if TFile.Exists(CandidateFileName) then
    Result := CandidateFileName
  else
    Result := '';
  {$ELSE}
  CandidateFileName := BuildPath(System.IOUtils.TPath.GetDocumentsPath, 'create_database.sql');
  if TFile.Exists(CandidateFileName) then
    Exit(CandidateFileName);

  CandidateFileName := BuildPath(ExtractFilePath(ParamStr(0)), 'create_database.sql');
  if TFile.Exists(CandidateFileName) then
    Exit(CandidateFileName);

  Result := '';
  {$ENDIF}
end;

function TDB.GetDatabaseTemplateFileName: string;
var
  CandidateFileName: string;
begin
  {$IFDEF MSWINDOWS}
  Result := '';
  {$ELSE}
  CandidateFileName := BuildPath(System.IOUtils.TPath.GetDocumentsPath, 'fitmanager.db');
  if TFile.Exists(CandidateFileName) then
    Exit(CandidateFileName);

  CandidateFileName := BuildPath(ExtractFilePath(ParamStr(0)), 'fitmanager.db');
  if TFile.Exists(CandidateFileName) then
    Exit(CandidateFileName);

  Result := '';
  {$ENDIF}
end;

end.
