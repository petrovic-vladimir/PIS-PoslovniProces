unit FITMANAGER_memberHome;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Objects, FMX.Edit,
  FMX.Controls.Presentation;

type
  TFrmMemberHome = class(TForm)
    imgBackground: TImage;
    lblTitle: TLabel;
    lblInfo: TLabel;
    lblMemberStatus: TLabel;
    lblStatus: TLabel;
    btnBack: TButton;
    btnRequest: TButton;
    lblDate: TLabel;
    edtDate: TEdit;
    lblStartTime: TLabel;
    edtStartTime: TEdit;
    lblEndTime: TLabel;
    edtEndTime: TEdit;
    btnRefreshStatus: TButton;
    procedure btnBackClick(Sender: TObject);
    procedure btnRequestClick(Sender: TObject);
    procedure btnRefreshStatusClick(Sender: TObject);
  private
    FMemberId: Integer;
    FTrainerId: Integer;
    FPlanId: Integer;
    FMenuButton: TButton;
    FMenuPanel: TRectangle;
    FLogoutButton: TButton;
    function BuildPath(const APath, AFileName: string): string;
    procedure BuildLogoutMenu;
    function FindAssetFile(const AFileName: string): string;
    procedure LoadMemberContext;
    procedure LoadLatestRequest;
    procedure LoadTemplateBackground;
    procedure LogoutClick(Sender: TObject);
    function ParseIsoDate(const AValue: string; out ADate: TDateTime): Boolean;
    procedure SendTrainingRequest;
    procedure ToggleMenuClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  System.DateUtils, dmDatabase;

{$R *.fmx}

constructor TFrmMemberHome.Create(AOwner: TComponent);
begin
  inherited;
  LoadTemplateBackground;
  BuildLogoutMenu;
  btnBack.Visible := True;
  try
    DB.InitializeDatabase;
    LoadMemberContext;
  except
    on E: Exception do
      lblStatus.Text := 'Greska pri ucitavanju baze: ' + E.Message;
  end;
end;

procedure TFrmMemberHome.BuildLogoutMenu;
begin
  FMenuButton := TButton.Create(Self);
  FMenuButton.Parent := Self;
  FMenuButton.Position.X := 10;
  FMenuButton.Position.Y := 8;
  FMenuButton.Width := 34;
  FMenuButton.Height := 30;
  FMenuButton.Text := #9776;
  FMenuButton.OnClick := ToggleMenuClick;
  FMenuButton.BringToFront;

  FMenuPanel := TRectangle.Create(Self);
  FMenuPanel.Parent := Self;
  FMenuPanel.Position.X := 10;
  FMenuPanel.Position.Y := 42;
  FMenuPanel.Width := 118;
  FMenuPanel.Height := 42;
  FMenuPanel.XRadius := 6;
  FMenuPanel.YRadius := 6;
  FMenuPanel.Fill.Color := $FFFFFFFF;
  FMenuPanel.Stroke.Color := $FF444444;
  FMenuPanel.Visible := False;
  FMenuPanel.BringToFront;

  FLogoutButton := TButton.Create(FMenuPanel);
  FLogoutButton.Parent := FMenuPanel;
  FLogoutButton.Position.X := 6;
  FLogoutButton.Position.Y := 6;
  FLogoutButton.Width := 106;
  FLogoutButton.Height := 30;
  FLogoutButton.Text := 'Logout';
  FLogoutButton.OnClick := LogoutClick;
end;

procedure TFrmMemberHome.btnBackClick(Sender: TObject);
begin
  if FMemberId = 0 then
    Exit;

  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'UPDATE training SET status = :cancelled ' +
    'WHERE training_id = (' +
    'SELECT tr.training_id FROM training tr ' +
    'WHERE tr.member_id = :member_id AND tr.status IN (:pending, :approved) ' +
    'ORDER BY tr.training_id DESC LIMIT 1)';
  DB.FDQuery1.ParamByName('cancelled').AsString := 'Otkazan';
  DB.FDQuery1.ParamByName('member_id').AsInteger := FMemberId;
  DB.FDQuery1.ParamByName('pending').AsString := 'Na cekanju';
  DB.FDQuery1.ParamByName('approved').AsString := 'Odobren';
  DB.FDQuery1.ExecSQL;
  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'UPDATE schedule SET status = :cancelled WHERE schedule_id = (' +
    'SELECT tr.schedule_id FROM training tr WHERE tr.member_id = :member_id ' +
    'ORDER BY tr.training_id DESC LIMIT 1)';
  DB.FDQuery1.ParamByName('cancelled').AsString := 'Otkazan';
  DB.FDQuery1.ParamByName('member_id').AsInteger := FMemberId;
  DB.FDQuery1.ExecSQL;
  LoadLatestRequest;
end;

procedure TFrmMemberHome.LogoutClick(Sender: TObject);
begin
  DB.ResetCurrentUser;
  if Assigned(Application.MainForm) then
    Application.MainForm.Show;
  Close;
end;

procedure TFrmMemberHome.btnRequestClick(Sender: TObject);
begin
  SendTrainingRequest;
end;

procedure TFrmMemberHome.btnRefreshStatusClick(Sender: TObject);
begin
  LoadLatestRequest;
end;

function TFrmMemberHome.BuildPath(const APath, AFileName: string): string;
begin
  Result := IncludeTrailingPathDelimiter(APath) + AFileName;
end;

function TFrmMemberHome.FindAssetFile(const AFileName: string): string;
var
  Candidate: string;
begin
  Candidate := BuildPath(BuildPath(ExtractFilePath(ParamStr(0)), 'assets'), AFileName);
  if TFile.Exists(Candidate) then
    Exit(Candidate);

  Candidate := BuildPath(ExtractFilePath(ParamStr(0)), AFileName);
  if TFile.Exists(Candidate) then
    Exit(Candidate);

  Candidate := BuildPath(System.IOUtils.TPath.GetDocumentsPath, AFileName);
  if TFile.Exists(Candidate) then
    Exit(Candidate);

  Result := '';
end;

procedure TFrmMemberHome.LoadTemplateBackground;
var
  FileName: string;
begin
  FileName := FindAssetFile('Template1.png');
  if FileName <> '' then
    imgBackground.Bitmap.LoadFromFile(FileName);
end;

procedure TFrmMemberHome.LoadMemberContext;
begin
  FMemberId := 0;
  FTrainerId := 0;
  FPlanId := 0;

  DB.FDQuery1.Close;
  if DB.CurrentMemberId > 0 then
  begin
    DB.FDQuery1.SQL.Text :=
      'SELECT member_id, first_name, last_name, age, status FROM member ' +
      'WHERE member_id = :member_id LIMIT 1';
    DB.FDQuery1.ParamByName('member_id').AsInteger := DB.CurrentMemberId;
  end
  else
  begin
    DB.FDQuery1.SQL.Text :=
      'SELECT member_id, first_name, last_name, age, status FROM member ' +
      'WHERE status = :status ORDER BY member_id LIMIT 1';
    DB.FDQuery1.ParamByName('status').AsString := 'Aktivan';
  end;
  DB.FDQuery1.Open;
  if not DB.FDQuery1.IsEmpty then
  begin
    FMemberId := DB.FDQuery1.FieldByName('member_id').AsInteger;
    lblInfo.Text := Format('%s %s',
      [DB.FDQuery1.FieldByName('first_name').AsString,
       DB.FDQuery1.FieldByName('last_name').AsString]);
    lblMemberStatus.Text := 'Status: ' + DB.FDQuery1.FieldByName('status').AsString;
  end;

  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'SELECT p.plan_id, p.title, p.goal, p.duration_minutes, p.trainer_id, ' +
    'pr.title AS program_title, t.first_name AS trainer_first_name, ' +
    't.last_name AS trainer_last_name, t.specialization ' +
    'FROM plan_training p ' +
    'LEFT JOIN program_training pr ON pr.program_id = p.program_id ' +
    'JOIN trainer t ON t.trainer_id = p.trainer_id ' +
    'WHERE p.member_id = :member_id ORDER BY p.plan_id LIMIT 1';
  DB.FDQuery1.ParamByName('member_id').AsInteger := FMemberId;
  DB.FDQuery1.Open;
  if not DB.FDQuery1.IsEmpty then
  begin
    FPlanId := DB.FDQuery1.FieldByName('plan_id').AsInteger;
    FTrainerId := DB.FDQuery1.FieldByName('trainer_id').AsInteger;
  end
  else
    lblStatus.Text := 'Clan jos nema dodeljen plan treninga.';

  DB.FDQuery1.Close;
  LoadLatestRequest;
end;

procedure TFrmMemberHome.SendTrainingRequest;
var
  ScheduleId: Integer;
  RequestDate: TDateTime;
  StartTimeValue, EndTimeValue: TDateTime;
begin
  if (FMemberId = 0) or (FTrainerId = 0) or (FPlanId = 0) then
  begin
    lblStatus.Text := 'Nije moguce poslati zahtev jer clan, trener ili plan nisu pronadjeni.';
    Exit;
  end;

  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'SELECT 1 FROM training WHERE member_id = :member_id ' +
    'AND status IN (:pending, :approved, :active) LIMIT 1';
  DB.FDQuery1.ParamByName('member_id').AsInteger := FMemberId;
  DB.FDQuery1.ParamByName('pending').AsString := 'Na cekanju';
  DB.FDQuery1.ParamByName('approved').AsString := 'Odobren';
  DB.FDQuery1.ParamByName('active').AsString := 'U toku';
  DB.FDQuery1.Open;
  if not DB.FDQuery1.IsEmpty then
  begin
    DB.FDQuery1.Close;
    lblStatus.Text := 'Vec postoji aktivan zahtev ili trening.';
    Exit;
  end;
  DB.FDQuery1.Close;

  if not ParseIsoDate(Trim(edtDate.Text), RequestDate) then
  begin
    lblStatus.Text := 'Datum mora biti u formatu yyyy-mm-dd.';
    Exit;
  end;
  if not TryStrToTime(Trim(edtStartTime.Text), StartTimeValue) or
     not TryStrToTime(Trim(edtEndTime.Text), EndTimeValue) then
  begin
    lblStatus.Text := 'Vreme mora biti u formatu hh:mm.';
    Exit;
  end;
  if EndTimeValue <= StartTimeValue then
  begin
    lblStatus.Text := 'Vreme zavrsetka mora biti posle pocetka.';
    Exit;
  end;

  DB.FDConnection1.StartTransaction;
  try
    DB.FDQuery1.Close;
    DB.FDQuery1.SQL.Text :=
      'INSERT INTO schedule (training_date, start_time, end_time, status, note, plan_id) ' +
      'VALUES (:training_date, :start_time, :end_time, :status, :note, :plan_id)';
    DB.FDQuery1.ParamByName('training_date').AsString := FormatDateTime('yyyy-mm-dd', RequestDate);
    DB.FDQuery1.ParamByName('start_time').AsString := FormatDateTime('hh:nn', StartTimeValue);
    DB.FDQuery1.ParamByName('end_time').AsString := FormatDateTime('hh:nn', EndTimeValue);
    DB.FDQuery1.ParamByName('status').AsString := 'Zahtev poslat';
    DB.FDQuery1.ParamByName('note').AsString := 'Zahtev clana iz mobilnog ekrana.';
    DB.FDQuery1.ParamByName('plan_id').AsInteger := FPlanId;
    DB.FDQuery1.ExecSQL;

    DB.FDQuery1.SQL.Text := 'SELECT last_insert_rowid() AS new_id';
    DB.FDQuery1.Open;
    ScheduleId := DB.FDQuery1.FieldByName('new_id').AsInteger;
    DB.FDQuery1.Close;

    DB.FDQuery1.SQL.Text :=
      'INSERT INTO training (reservation_time, start_time, end_time, status, note, member_id, trainer_id, schedule_id) ' +
      'VALUES (:reservation_time, :start_time, :end_time, :status, :note, :member_id, :trainer_id, :schedule_id)';
    DB.FDQuery1.ParamByName('reservation_time').AsString := FormatDateTime('yyyy-mm-dd hh:nn', Now);
    DB.FDQuery1.ParamByName('start_time').AsString := FormatDateTime('hh:nn', StartTimeValue);
    DB.FDQuery1.ParamByName('end_time').AsString := FormatDateTime('hh:nn', EndTimeValue);
    DB.FDQuery1.ParamByName('status').AsString := 'Na cekanju';
    DB.FDQuery1.ParamByName('note').AsString := 'Clan je poslao zahtev za trening.';
    DB.FDQuery1.ParamByName('member_id').AsInteger := FMemberId;
    DB.FDQuery1.ParamByName('trainer_id').AsInteger := FTrainerId;
    DB.FDQuery1.ParamByName('schedule_id').AsInteger := ScheduleId;
    DB.FDQuery1.ExecSQL;

    DB.FDConnection1.Commit;
    LoadLatestRequest;
  except
    DB.FDConnection1.Rollback;
    raise;
  end;
end;

procedure TFrmMemberHome.LoadLatestRequest;
begin
  edtDate.Text := FormatDateTime('yyyy-mm-dd', IncDay(Date, 1));
  edtStartTime.Text := '18:00';
  edtEndTime.Text := '19:00';
  btnBack.Enabled := False;

  if FMemberId = 0 then
    Exit;

  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'SELECT tr.status, s.training_date, s.start_time, s.end_time ' +
    'FROM training tr JOIN schedule s ON s.schedule_id = tr.schedule_id ' +
    'WHERE tr.member_id = :member_id ORDER BY tr.training_id DESC LIMIT 1';
  DB.FDQuery1.ParamByName('member_id').AsInteger := FMemberId;
  DB.FDQuery1.Open;
  if not DB.FDQuery1.IsEmpty then
  begin
    edtDate.Text := DB.FDQuery1.FieldByName('training_date').AsString;
    edtStartTime.Text := DB.FDQuery1.FieldByName('start_time').AsString;
    edtEndTime.Text := DB.FDQuery1.FieldByName('end_time').AsString;
    lblStatus.Text := 'Poslednji zahtev: ' +
      DB.FDQuery1.FieldByName('status').AsString;
    btnBack.Enabled :=
      SameText(DB.FDQuery1.FieldByName('status').AsString, 'Na cekanju') or
      SameText(DB.FDQuery1.FieldByName('status').AsString, 'Odobren');
  end
  else
    lblStatus.Text := 'Zahtev nije poslat.';
  DB.FDQuery1.Close;
end;

function TFrmMemberHome.ParseIsoDate(const AValue: string;
  out ADate: TDateTime): Boolean;
var
  Year, Month, Day: Integer;
begin
  Result := False;
  if Length(AValue) <> 10 then
    Exit;
  if (AValue[5] <> '-') or (AValue[8] <> '-') then
    Exit;
  Year := StrToIntDef(Copy(AValue, 1, 4), 0);
  Month := StrToIntDef(Copy(AValue, 6, 2), 0);
  Day := StrToIntDef(Copy(AValue, 9, 2), 0);
  Result := TryEncodeDate(Year, Month, Day, ADate);
end;

procedure TFrmMemberHome.ToggleMenuClick(Sender: TObject);
begin
  FMenuPanel.Visible := not FMenuPanel.Visible;
  FMenuPanel.BringToFront;
  FMenuButton.BringToFront;
end;

end.
