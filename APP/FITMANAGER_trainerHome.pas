unit FITMANAGER_trainerHome;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.UITypes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Objects, FMX.Layouts,
  FMX.Controls.Presentation;

type
  TFrmTrainerHome = class(TForm)
    imgBackground: TImage;
    lblTrainerName: TLabel;
    lblRequestsTitle: TLabel;
    lblRequests: TLabel;
    btnApprove: TButton;
    btnDecline: TButton;
    lblMembersTitle: TLabel;
    sbMembers: TScrollBox;
    lyMembersContent: TLayout;
    btnBack: TButton;
    btnOperations: TButton;
    procedure btnApproveClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure btnDeclineClick(Sender: TObject);
    procedure btnOperationsClick(Sender: TObject);
  private
    FTrainerId: Integer;
    FFirstRequestId: Integer;
    FMenuButton: TButton;
    FMenuPanel: TRectangle;
    FLogoutButton: TButton;
    function BuildPath(const APath, AFileName: string): string;
    procedure BuildLogoutMenu;
    function FindAssetFile(const AFileName: string): string;
    procedure AddMemberCard(const ALeft, ATop: Single; const AName, APlanTitle,
      AGoal, AStatus: string; AMemberId: Integer);
    procedure MemberCardClick(Sender: TObject);
    procedure LoadMemberCards;
    procedure LoadTemplateBackground;
    procedure LoadTrainerContext;
    procedure LogoutClick(Sender: TObject);
    procedure RefreshRequests;
    procedure ToggleMenuClick(Sender: TObject);
    procedure UpdateFirstRequestStatus(const AStatus: string);
  public
    constructor Create(AOwner: TComponent); override;
    procedure RefreshDashboard;
  end;

implementation

uses
  dmDatabase, FITMANAGER_memberPlanDetail, FITMANAGER_trainingOperations;

{$R *.fmx}

constructor TFrmTrainerHome.Create(AOwner: TComponent);
begin
  inherited;
  LoadTemplateBackground;
  BuildLogoutMenu;
  btnBack.Visible := False;
  try
    DB.InitializeDatabase;
    LoadTrainerContext;
    RefreshRequests;
  except
    on E: Exception do
      lblRequests.Text := 'Greska pri ucitavanju baze: ' + E.Message;
  end;
end;

procedure TFrmTrainerHome.BuildLogoutMenu;
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

procedure TFrmTrainerHome.AddMemberCard(const ALeft, ATop: Single;
  const AName, APlanTitle, AGoal, AStatus: string; AMemberId: Integer);
var
  Card: TRectangle;
  NameLabel, PlanLabel, GoalLabel, StatusLabel: TLabel;
begin
  Card := TRectangle.Create(lyMembersContent);
  Card.Parent := lyMembersContent;
  Card.Position.X := ALeft;
  Card.Position.Y := ATop;
  Card.Width := 272;
  Card.Height := 156;
  Card.XRadius := 8;
  Card.YRadius := 8;
  Card.Fill.Color := $FFFFE8CF;
  Card.Stroke.Color := $00FFFFFF;
  Card.Tag := AMemberId;
  Card.HitTest := True;
  Card.OnClick := MemberCardClick;

  NameLabel := TLabel.Create(Card);
  NameLabel.Parent := Card;
  NameLabel.HitTest := False;
  NameLabel.Position.X := 10;
  NameLabel.Position.Y := 8;
  NameLabel.Width := 252;
  NameLabel.Height := 26;
  NameLabel.Text := AName;
  NameLabel.TextSettings.Font.Size := 12;
  NameLabel.TextSettings.Font.Style := [TFontStyle.fsBold];

  PlanLabel := TLabel.Create(Card);
  PlanLabel.Parent := Card;
  PlanLabel.HitTest := False;
  PlanLabel.Position.X := 10;
  PlanLabel.Position.Y := 42;
  PlanLabel.Width := 252;
  PlanLabel.Height := 28;
  PlanLabel.Text := 'Plan: ' + APlanTitle;
  PlanLabel.WordWrap := True;
  PlanLabel.TextSettings.Font.Size := 9;

  StatusLabel := TLabel.Create(Card);
  StatusLabel.Parent := Card;
  StatusLabel.HitTest := False;
  StatusLabel.Position.X := 10;
  StatusLabel.Position.Y := 76;
  StatusLabel.Width := 252;
  StatusLabel.Height := 22;
  StatusLabel.Text := 'Status clana: ' + AStatus;
  StatusLabel.TextSettings.Font.Size := 9;
  StatusLabel.TextSettings.Font.Style := [TFontStyle.fsBold];

  GoalLabel := TLabel.Create(Card);
  GoalLabel.Parent := Card;
  GoalLabel.HitTest := False;
  GoalLabel.Position.X := 10;
  GoalLabel.Position.Y := 102;
  GoalLabel.Width := 252;
  GoalLabel.Height := 46;
  GoalLabel.Text := 'Cilj: ' + AGoal;
  GoalLabel.WordWrap := True;
  GoalLabel.TextSettings.Font.Size := 9;
end;

procedure TFrmTrainerHome.LogoutClick(Sender: TObject);
begin
  DB.ResetCurrentUser;
  if Assigned(Application.MainForm) then
    Application.MainForm.Show;
  Close;
end;

procedure TFrmTrainerHome.MemberCardClick(Sender: TObject);
var
  MemberId: Integer;
begin
  if not (Sender is TRectangle) then
    Exit;

  MemberId := TRectangle(Sender).Tag;
  TFrmMemberPlanDetail.CreateForMember(Application, MemberId, Self).Show;
  Hide;
end;

procedure TFrmTrainerHome.btnApproveClick(Sender: TObject);
begin
  UpdateFirstRequestStatus('Odobren');
end;

procedure TFrmTrainerHome.btnBackClick(Sender: TObject);
begin
  if Assigned(Application.MainForm) then
    Application.MainForm.Show;
  Close;
end;

procedure TFrmTrainerHome.btnDeclineClick(Sender: TObject);
begin
  UpdateFirstRequestStatus('Odbijen');
end;

procedure TFrmTrainerHome.btnOperationsClick(Sender: TObject);
begin
  TFrmTrainingOperations.Create(Application).Show;
end;

function TFrmTrainerHome.BuildPath(const APath, AFileName: string): string;
begin
  Result := IncludeTrailingPathDelimiter(APath) + AFileName;
end;

function TFrmTrainerHome.FindAssetFile(const AFileName: string): string;
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

procedure TFrmTrainerHome.LoadTemplateBackground;
var
  FileName: string;
begin
  FileName := FindAssetFile('Template2.png');
  if FileName <> '' then
    imgBackground.Bitmap.LoadFromFile(FileName);
end;

procedure TFrmTrainerHome.LoadTrainerContext;
begin
  FTrainerId := 0;

  DB.FDQuery1.Close;
  if DB.CurrentTrainerId > 0 then
  begin
    DB.FDQuery1.SQL.Text :=
      'SELECT trainer_id, first_name, last_name FROM trainer ' +
      'WHERE trainer_id = :trainer_id LIMIT 1';
    DB.FDQuery1.ParamByName('trainer_id').AsInteger := DB.CurrentTrainerId;
  end
  else
  begin
    DB.FDQuery1.SQL.Text :=
      'SELECT trainer_id, first_name, last_name FROM trainer ' +
      'WHERE status = :status ORDER BY trainer_id LIMIT 1';
    DB.FDQuery1.ParamByName('status').AsString := 'Aktivan';
  end;
  DB.FDQuery1.Open;
  if not DB.FDQuery1.IsEmpty then
  begin
    FTrainerId := DB.FDQuery1.FieldByName('trainer_id').AsInteger;
    lblTrainerName.Text := Format('%s %s',
      [DB.FDQuery1.FieldByName('first_name').AsString,
       DB.FDQuery1.FieldByName('last_name').AsString]);
  end;
  DB.FDQuery1.Close;

  LoadMemberCards;
end;

procedure TFrmTrainerHome.RefreshDashboard;
begin
  try
    LoadTrainerContext;
    RefreshRequests;
  except
    on E: Exception do
      lblRequests.Text := 'Greska pri osvezavanju: ' + E.Message;
  end;
end;

procedure TFrmTrainerHome.LoadMemberCards;
const
  CCardHeight = 156;
  CRowGap = 6;
var
  Index: Integer;
  CardLeft, CardTop: Single;
  FullName, PlanTitle, Goal: string;
begin
  while lyMembersContent.ChildrenCount > 0 do
    lyMembersContent.Children[0].Free;

  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'SELECT m.member_id, m.first_name, m.last_name, m.status AS member_status, ' +
    'p.title AS plan_title, p.goal ' +
    'FROM member m ' +
    'LEFT JOIN plan_training p ON p.plan_id = (' +
    'SELECT p2.plan_id FROM plan_training p2 WHERE p2.member_id = m.member_id ' +
    'ORDER BY CASE WHEN p2.status = ''Aktivan'' THEN 0 ELSE 1 END, p2.plan_id DESC LIMIT 1) ' +
    'WHERE ((p.plan_id IS NULL AND m.status = :active_status) ' +
    'OR p.trainer_id = :trainer_id) ' +
    'ORDER BY m.member_id';
  DB.FDQuery1.ParamByName('active_status').AsString := 'Aktivan';
  DB.FDQuery1.ParamByName('trainer_id').AsInteger := FTrainerId;
  DB.FDQuery1.Open;

  Index := 0;
  while not DB.FDQuery1.Eof do
  begin
    CardLeft := 6;
    CardTop := Index * (CCardHeight + CRowGap);

    FullName := Format('%s %s',
      [DB.FDQuery1.FieldByName('first_name').AsString,
       DB.FDQuery1.FieldByName('last_name').AsString]);

    Goal := DB.FDQuery1.FieldByName('goal').AsString;
    if Goal = '' then
      Goal := 'Cilj nije unet.';

    PlanTitle := DB.FDQuery1.FieldByName('plan_title').AsString;
    if PlanTitle = '' then
      PlanTitle := 'Plan nije definisan';

    AddMemberCard(CardLeft, CardTop, FullName, PlanTitle, Goal,
      DB.FDQuery1.FieldByName('member_status').AsString,
      DB.FDQuery1.FieldByName('member_id').AsInteger);

    Inc(Index);
    DB.FDQuery1.Next;
  end;

  lyMembersContent.Height := Index * (CCardHeight + CRowGap);
  DB.FDQuery1.Close;
end;

procedure TFrmTrainerHome.RefreshRequests;
var
  Lines: string;
begin
  FFirstRequestId := 0;
  Lines := '';

  if FTrainerId = 0 then
  begin
    lblRequests.Text := 'Trener nije pronadjen u bazi.';
    Exit;
  end;

  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'SELECT tr.training_id, tr.start_time, tr.end_time, m.first_name, m.last_name, tr.status ' +
    'FROM training tr ' +
    'JOIN member m ON m.member_id = tr.member_id ' +
    'WHERE tr.trainer_id = :trainer_id AND tr.status = :status ' +
    'ORDER BY tr.training_id DESC LIMIT 5';
  DB.FDQuery1.ParamByName('trainer_id').AsInteger := FTrainerId;
  DB.FDQuery1.ParamByName('status').AsString := 'Na cekanju';
  DB.FDQuery1.Open;

  while not DB.FDQuery1.Eof do
  begin
    if FFirstRequestId = 0 then
      FFirstRequestId := DB.FDQuery1.FieldByName('training_id').AsInteger;

    Lines := Lines + Format('%s %s | %s-%s'#13#10'%s'#13#10,
      [DB.FDQuery1.FieldByName('first_name').AsString,
       DB.FDQuery1.FieldByName('last_name').AsString,
       DB.FDQuery1.FieldByName('start_time').AsString,
       DB.FDQuery1.FieldByName('end_time').AsString,
       DB.FDQuery1.FieldByName('status').AsString]);
    DB.FDQuery1.Next;
  end;

  DB.FDQuery1.Close;
  if Lines = '' then
    Lines := 'Trenutno nema novih zahteva.';
  lblRequests.Text := Lines;
end;

procedure TFrmTrainerHome.ToggleMenuClick(Sender: TObject);
begin
  FMenuPanel.Visible := not FMenuPanel.Visible;
  FMenuPanel.BringToFront;
  FMenuButton.BringToFront;
end;

procedure TFrmTrainerHome.UpdateFirstRequestStatus(const AStatus: string);
var
  ScheduleId, RoomId: Integer;
  TrainingDate, StartTime, EndTime: string;
begin
  if FFirstRequestId = 0 then
  begin
    lblRequests.Text := 'Nema zahteva za obradu.';
    Exit;
  end;

  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'SELECT tr.schedule_id, s.training_date, s.start_time, s.end_time, p.room_id ' +
    'FROM training tr JOIN schedule s ON s.schedule_id = tr.schedule_id ' +
    'JOIN plan_training p ON p.plan_id = s.plan_id ' +
    'WHERE tr.training_id = :training_id';
  DB.FDQuery1.ParamByName('training_id').AsInteger := FFirstRequestId;
  DB.FDQuery1.Open;
  ScheduleId := DB.FDQuery1.FieldByName('schedule_id').AsInteger;
  TrainingDate := DB.FDQuery1.FieldByName('training_date').AsString;
  StartTime := DB.FDQuery1.FieldByName('start_time').AsString;
  EndTime := DB.FDQuery1.FieldByName('end_time').AsString;
  RoomId := DB.FDQuery1.FieldByName('room_id').AsInteger;
  DB.FDQuery1.Close;

  if SameText(AStatus, 'Odobren') and
     not DB.IsResourceAvailable(FTrainerId, RoomId, TrainingDate,
       StartTime, EndTime, FFirstRequestId) then
  begin
    lblRequests.Text := 'Zahtev nije odobren: trener ili sala vise nisu slobodni.';
    Exit;
  end;

  DB.FDConnection1.StartTransaction;
  try
  DB.FDQuery1.SQL.Text :=
    'UPDATE training SET status = :status WHERE training_id = :training_id';
  DB.FDQuery1.ParamByName('status').AsString := AStatus;
  DB.FDQuery1.ParamByName('training_id').AsInteger := FFirstRequestId;
  DB.FDQuery1.ExecSQL;
    DB.FDQuery1.SQL.Text :=
      'UPDATE schedule SET status = :status WHERE schedule_id = :schedule_id';
    DB.FDQuery1.ParamByName('status').AsString := AStatus;
    DB.FDQuery1.ParamByName('schedule_id').AsInteger := ScheduleId;
    DB.FDQuery1.ExecSQL;
    DB.FDConnection1.Commit;
  except
    DB.FDConnection1.Rollback;
    raise;
  end;

  RefreshRequests;
end;

end.
