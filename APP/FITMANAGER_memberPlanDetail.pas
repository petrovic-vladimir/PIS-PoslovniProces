unit FITMANAGER_memberPlanDetail;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.UITypes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.ListBox, FMX.Edit,
  FMX.Objects, FMX.Layouts, FMX.Controls.Presentation;

type
  TFrmMemberPlanDetail = class(TForm)
    imgBackground: TImage;
    lblTitle: TLabel;
    lblMemberName: TLabel;
    lblMemberGoal: TLabel;
    lblPlanTitle: TLabel;
    edtPlanTitle: TEdit;
    lblGoal: TLabel;
    edtGoal: TEdit;
    lblProgram: TLabel;
    cbPrograms: TComboBox;
    lblRoom: TLabel;
    cbRooms: TComboBox;
    lblMaxTrainingCount: TLabel;
    edtMaxTrainingCount: TEdit;
    lblDuration: TLabel;
    edtDuration: TEdit;
    lblStartDate: TLabel;
    edtStartDate: TEdit;
    lblEndDate: TLabel;
    edtEndDate: TEdit;
    lblStatus: TLabel;
    cbStatus: TComboBox;
    lblMessage: TLabel;
    btnConfirm: TButton;
    procedure btnConfirmClick(Sender: TObject);
  private
    FMemberId: Integer;
    FPlanId: Integer;
    FTrainerId: Integer;
    FCurrentRoomId: Integer;
    FTrainerForm: TForm;
    FContent: TVertScrollBox;
    FMemberDataTable: TRectangle;
    FProgramIds: array of Integer;
    FRoomIds: array of Integer;
    procedure AddMemberDataCell(AParent: TFmxObject; const AText: string;
      ALeft, ATop, AWidth, AHeight: Single; AColor: TAlphaColor;
      AFontSize: Single; ABold: Boolean = False);
    procedure BuildMemberDataTable;
    function BuildPath(const APath, AFileName: string): string;
    function FindAssetFile(const AFileName: string): string;
    procedure LoadMember;
    procedure LoadTemplateBackground;
    procedure LoadPlan;
    procedure LoadPrograms;
    procedure LoadMemberDataTable;
    procedure LoadRooms;
    procedure RefreshTrainerForm;
    procedure SetupScrollableContent;
    function IsValidIsoDate(const AValue: string): Boolean;
    function SavePlanChange: Boolean;
  public
    constructor CreateForMember(AOwner: TComponent; AMemberId: Integer;
      ATrainerForm: TForm); reintroduce;
  end;

implementation

uses
  dmDatabase, FITMANAGER_trainerHome;

{$R *.fmx}

constructor TFrmMemberPlanDetail.CreateForMember(AOwner: TComponent;
  AMemberId: Integer; ATrainerForm: TForm);
begin
  inherited Create(AOwner);
  FMemberId := AMemberId;
  FPlanId := 0;
  FTrainerId := 0;
  FCurrentRoomId := 0;
  FTrainerForm := ATrainerForm;
  LoadTemplateBackground;
  SetupScrollableContent;

  try
    DB.InitializeDatabase;
    cbStatus.Items.Clear;
    cbStatus.Items.Add('Aktivan');
    cbStatus.Items.Add('Pauziran');
    cbStatus.Items.Add('Neaktivan');
    BuildMemberDataTable;
    LoadMember;
    LoadMemberDataTable;
    LoadPlan;
    LoadPrograms;
    LoadRooms;
  except
    on E: Exception do
      lblMemberName.Text := 'Greska: ' + E.Message;
  end;
end;

function TFrmMemberPlanDetail.BuildPath(const APath, AFileName: string): string;
begin
  Result := IncludeTrailingPathDelimiter(APath) + AFileName;
end;

function TFrmMemberPlanDetail.FindAssetFile(const AFileName: string): string;
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

procedure TFrmMemberPlanDetail.btnConfirmClick(Sender: TObject);
begin
  if SavePlanChange then
  begin
    RefreshTrainerForm;
    Close;
  end;
end;

procedure TFrmMemberPlanDetail.AddMemberDataCell(AParent: TFmxObject;
  const AText: string; ALeft, ATop, AWidth, AHeight: Single; AColor: TAlphaColor;
  AFontSize: Single; ABold: Boolean);
var
  Cell: TRectangle;
  CellText: TLabel;
begin
  Cell := TRectangle.Create(AParent);
  Cell.Parent := AParent;
  Cell.Position.X := ALeft;
  Cell.Position.Y := ATop;
  Cell.Width := AWidth;
  Cell.Height := AHeight;
  Cell.Fill.Color := AColor;
  Cell.Stroke.Color := $FFFF8A80;
  Cell.XRadius := 0;
  Cell.YRadius := 0;

  CellText := TLabel.Create(Cell);
  CellText.Parent := Cell;
  CellText.Align := TAlignLayout.Client;
  CellText.Text := AText;
  CellText.WordWrap := True;
  CellText.TextSettings.Font.Size := AFontSize;
  if ABold then
    CellText.TextSettings.Font.Style := [TFontStyle.fsBold];
  CellText.TextSettings.HorzAlign := TTextAlign.Center;
  CellText.TextSettings.VertAlign := TTextAlign.Center;
end;

procedure TFrmMemberPlanDetail.BuildMemberDataTable;
begin
  FMemberDataTable := TRectangle.Create(Self);
  FMemberDataTable.Parent := FContent;
  FMemberDataTable.Position.X := 56;
  FMemberDataTable.Position.Y := 280;
  FMemberDataTable.Width := 318;
  FMemberDataTable.Height := 329;
  FMemberDataTable.Fill.Color := $FFFFF3E0;
  FMemberDataTable.Stroke.Color := $FFFF8A80;
  FMemberDataTable.XRadius := 0;
  FMemberDataTable.YRadius := 0;
  FMemberDataTable.BringToFront;
end;

function TFrmMemberPlanDetail.IsValidIsoDate(const AValue: string): Boolean;
var
  Year, Month, Day: Integer;
  ParsedDate: TDateTime;
begin
  Result := False;
  if Length(Trim(AValue)) <> 10 then
    Exit;

  Year := StrToIntDef(Copy(AValue, 1, 4), 0);
  Month := StrToIntDef(Copy(AValue, 6, 2), 0);
  Day := StrToIntDef(Copy(AValue, 9, 2), 0);
  Result := (AValue[5] = '-') and (AValue[8] = '-') and
    TryEncodeDate(Year, Month, Day, ParsedDate);
end;

procedure TFrmMemberPlanDetail.LoadMember;
begin
  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'SELECT first_name, last_name FROM member WHERE member_id = :member_id';
  DB.FDQuery1.ParamByName('member_id').AsInteger := FMemberId;
  DB.FDQuery1.Open;

  if not DB.FDQuery1.IsEmpty then
    lblMemberName.Text := Format('%s %s',
      [DB.FDQuery1.FieldByName('first_name').AsString,
       DB.FDQuery1.FieldByName('last_name').AsString])
  else
    lblMemberName.Text := 'Clan nije pronadjen';

  DB.FDQuery1.Close;
end;

procedure TFrmMemberPlanDetail.LoadTemplateBackground;
var
  FileName: string;
begin
  FileName := FindAssetFile('Template2.png');
  if FileName <> '' then
    imgBackground.Bitmap.LoadFromFile(FileName);
  imgBackground.SendToBack;
end;

procedure TFrmMemberPlanDetail.RefreshTrainerForm;
begin
  if Assigned(FTrainerForm) then
  begin
    if FTrainerForm is TFrmTrainerHome then
      TFrmTrainerHome(FTrainerForm).RefreshDashboard;
    FTrainerForm.Show;
  end;
end;

procedure TFrmMemberPlanDetail.LoadMemberDataTable;
const
  CLabelColumn = 106;
  CValueColumn = 106;
  CRowHeight = 47;
var
  Age: string;
  HeightCm: string;
  InitialWeight, CurrentWeight: string;
  InitialBmi, CurrentBmi: string;
  InitialMuscle, CurrentMuscle: string;
  InitialCalories, CurrentCalories: string;
begin
  if not Assigned(FMemberDataTable) then
    Exit;

  while FMemberDataTable.ChildrenCount > 0 do
    FMemberDataTable.Children[0].Free;

  Age := '-';
  HeightCm := '-';
  InitialWeight := '-';
  CurrentWeight := '-';
  InitialBmi := '-';
  CurrentBmi := '-';
  InitialMuscle := '-';
  CurrentMuscle := '-';
  InitialCalories := '-';
  CurrentCalories := '-';

  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'SELECT m.age, p.initial_weight, p.current_weight, p.height_cm, p.initial_bmi, p.current_bmi, ' +
    'initial_muscle_percent, current_muscle_percent, initial_calories, current_calories ' +
    'FROM member m LEFT JOIN member_progress p ON p.member_id = m.member_id ' +
    'WHERE m.member_id = :member_id LIMIT 1';
  DB.FDQuery1.ParamByName('member_id').AsInteger := FMemberId;
  DB.FDQuery1.Open;

  if not DB.FDQuery1.IsEmpty then
  begin
    Age := DB.FDQuery1.FieldByName('age').AsString;
    HeightCm := DB.FDQuery1.FieldByName('height_cm').AsString;
    InitialWeight := DB.FDQuery1.FieldByName('initial_weight').AsString + ' kg';
    CurrentWeight := DB.FDQuery1.FieldByName('current_weight').AsString + ' kg';
    InitialBmi := DB.FDQuery1.FieldByName('initial_bmi').AsString;
    CurrentBmi := DB.FDQuery1.FieldByName('current_bmi').AsString;
    InitialMuscle := DB.FDQuery1.FieldByName('initial_muscle_percent').AsString + '%';
    CurrentMuscle := DB.FDQuery1.FieldByName('current_muscle_percent').AsString + '%';
    InitialCalories := DB.FDQuery1.FieldByName('initial_calories').AsString;
    CurrentCalories := DB.FDQuery1.FieldByName('current_calories').AsString;
  end;

  DB.FDQuery1.Close;

  AddMemberDataCell(FMemberDataTable, 'Oznake', 0, 0, CLabelColumn, CRowHeight, $FFFFE0B2, 7, True);
  AddMemberDataCell(FMemberDataTable, 'Pocetne vrednosti', CLabelColumn, 0, CValueColumn, CRowHeight, $FFFFE0B2, 6.3, True);
  AddMemberDataCell(FMemberDataTable, 'Trenutne vrednosti', CLabelColumn + CValueColumn, 0, CValueColumn, CRowHeight, $FFFFE0B2, 6.3, True);

  AddMemberDataCell(FMemberDataTable, 'Godine', 0, CRowHeight, CLabelColumn, CRowHeight, $FFFFF8E1, 5.5, True);
  AddMemberDataCell(FMemberDataTable, Age, CLabelColumn, CRowHeight, CValueColumn, CRowHeight, $FFFFFDE7, 6);
  AddMemberDataCell(FMemberDataTable, Age, CLabelColumn + CValueColumn, CRowHeight, CValueColumn, CRowHeight, $FFFFFDE7, 6);

  AddMemberDataCell(FMemberDataTable, 'Visina', 0, CRowHeight * 2, CLabelColumn, CRowHeight, $FFFFF8E1, 5.5, True);
  AddMemberDataCell(FMemberDataTable, HeightCm + ' cm', CLabelColumn, CRowHeight * 2, CValueColumn, CRowHeight, $FFFFFDE7, 6);
  AddMemberDataCell(FMemberDataTable, HeightCm + ' cm', CLabelColumn + CValueColumn, CRowHeight * 2, CValueColumn, CRowHeight, $FFFFFDE7, 6);

  AddMemberDataCell(FMemberDataTable, 'Tezina', 0, CRowHeight * 3, CLabelColumn, CRowHeight, $FFFFF8E1, 5.5, True);
  AddMemberDataCell(FMemberDataTable, InitialWeight, CLabelColumn, CRowHeight * 3, CValueColumn, CRowHeight, $FFFFFDE7, 6);
  AddMemberDataCell(FMemberDataTable, CurrentWeight, CLabelColumn + CValueColumn, CRowHeight * 3, CValueColumn, CRowHeight, $FFFFFDE7, 6);

  AddMemberDataCell(FMemberDataTable, 'BMI', 0, CRowHeight * 4, CLabelColumn, CRowHeight, $FFFFF8E1, 5.5, True);
  AddMemberDataCell(FMemberDataTable, InitialBmi, CLabelColumn, CRowHeight * 4, CValueColumn, CRowHeight, $FFFFFDE7, 6, True);
  AddMemberDataCell(FMemberDataTable, CurrentBmi, CLabelColumn + CValueColumn, CRowHeight * 4, CValueColumn, CRowHeight, $FFFFFDE7, 6, True);

  AddMemberDataCell(FMemberDataTable, '% misicne mase', 0, CRowHeight * 5, CLabelColumn, CRowHeight, $FFFFF8E1, 5.2, True);
  AddMemberDataCell(FMemberDataTable, InitialMuscle, CLabelColumn, CRowHeight * 5, CValueColumn, CRowHeight, $FFFFFDE7, 6);
  AddMemberDataCell(FMemberDataTable, CurrentMuscle, CLabelColumn + CValueColumn, CRowHeight * 5, CValueColumn, CRowHeight, $FFFFFDE7, 6);

  AddMemberDataCell(FMemberDataTable, 'Broj kalorija', 0, CRowHeight * 6, CLabelColumn, CRowHeight, $FFFFF8E1, 5.2, True);
  AddMemberDataCell(FMemberDataTable, InitialCalories, CLabelColumn, CRowHeight * 6, CValueColumn, CRowHeight, $FFFFFDE7, 6);
  AddMemberDataCell(FMemberDataTable, CurrentCalories, CLabelColumn + CValueColumn, CRowHeight * 6, CValueColumn, CRowHeight, $FFFFFDE7, 6);
end;

procedure TFrmMemberPlanDetail.LoadPlan;
begin
  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'SELECT plan_id, title, goal, max_training_count, duration_minutes, ' +
    'start_date, end_date, status, room_id, trainer_id FROM plan_training ' +
    'WHERE member_id = :member_id ORDER BY plan_id LIMIT 1';
  DB.FDQuery1.ParamByName('member_id').AsInteger := FMemberId;
  DB.FDQuery1.Open;

  if not DB.FDQuery1.IsEmpty then
  begin
    FPlanId := DB.FDQuery1.FieldByName('plan_id').AsInteger;
    FTrainerId := DB.FDQuery1.FieldByName('trainer_id').AsInteger;
    edtPlanTitle.Text := DB.FDQuery1.FieldByName('title').AsString;
    edtGoal.Text := DB.FDQuery1.FieldByName('goal').AsString;
    lblMemberGoal.Text := 'Cilj: ' + DB.FDQuery1.FieldByName('goal').AsString;
    edtMaxTrainingCount.Text := DB.FDQuery1.FieldByName('max_training_count').AsString;
    edtDuration.Text := DB.FDQuery1.FieldByName('duration_minutes').AsString;
    edtStartDate.Text := DB.FDQuery1.FieldByName('start_date').AsString;
    edtEndDate.Text := DB.FDQuery1.FieldByName('end_date').AsString;
    if not DB.FDQuery1.FieldByName('room_id').IsNull then
      FCurrentRoomId := DB.FDQuery1.FieldByName('room_id').AsInteger;
    cbStatus.ItemIndex := cbStatus.Items.IndexOf(DB.FDQuery1.FieldByName('status').AsString);
    if cbStatus.ItemIndex < 0 then
      cbStatus.ItemIndex := 0;
  end;

  DB.FDQuery1.Close;

  if FPlanId = 0 then
  begin
    FTrainerId := DB.CurrentTrainerId;
    if FTrainerId = 0 then
      FTrainerId := 400;
    edtPlanTitle.Text := 'Novi plan treninga';
    edtGoal.Text := '';
    lblMemberGoal.Text := 'Cilj: nije definisan';
    edtMaxTrainingCount.Text := '12';
    edtDuration.Text := '60';
    edtStartDate.Text := FormatDateTime('yyyy-mm-dd', Date);
    edtEndDate.Text := FormatDateTime('yyyy-mm-dd', Date + 30);
    cbStatus.ItemIndex := 0;
    lblMessage.Text := 'Clan jos nema plan. Unesi podatke i sacuvaj novi plan.';
  end;
end;

procedure TFrmMemberPlanDetail.LoadRooms;
var
  NewIndex: Integer;
begin
  cbRooms.Clear;
  SetLength(FRoomIds, 0);

  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'SELECT room_id, name FROM training_room ' +
    'WHERE status = :status ORDER BY room_id';
  DB.FDQuery1.ParamByName('status').AsString := 'Aktivna';
  DB.FDQuery1.Open;
  while not DB.FDQuery1.Eof do
  begin
    NewIndex := cbRooms.Items.Add(DB.FDQuery1.FieldByName('name').AsString);
    SetLength(FRoomIds, Length(FRoomIds) + 1);
    FRoomIds[NewIndex] := DB.FDQuery1.FieldByName('room_id').AsInteger;

    if FRoomIds[NewIndex] = FCurrentRoomId then
      cbRooms.ItemIndex := NewIndex;

    DB.FDQuery1.Next;
  end;
  DB.FDQuery1.Close;

  if (cbRooms.ItemIndex < 0) and (cbRooms.Items.Count > 0) then
    cbRooms.ItemIndex := 0;
end;

procedure TFrmMemberPlanDetail.LoadPrograms;
var
  CurrentProgramId: Integer;
  NewIndex: Integer;
begin
  cbPrograms.Clear;
  SetLength(FProgramIds, 0);
  CurrentProgramId := 0;

  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'SELECT program_id FROM plan_training WHERE member_id = :member_id ' +
    'ORDER BY plan_id LIMIT 1';
  DB.FDQuery1.ParamByName('member_id').AsInteger := FMemberId;
  DB.FDQuery1.Open;
  if (not DB.FDQuery1.IsEmpty) and
     (not DB.FDQuery1.FieldByName('program_id').IsNull) then
    CurrentProgramId := DB.FDQuery1.FieldByName('program_id').AsInteger;
  DB.FDQuery1.Close;

  DB.FDQuery1.SQL.Text :=
    'SELECT program_id, title FROM program_training ' +
    'WHERE status = :status ORDER BY program_id';
  DB.FDQuery1.ParamByName('status').AsString := 'Aktivan';
  DB.FDQuery1.Open;
  while not DB.FDQuery1.Eof do
  begin
    NewIndex := cbPrograms.Items.Add(DB.FDQuery1.FieldByName('title').AsString);
    SetLength(FProgramIds, Length(FProgramIds) + 1);
    FProgramIds[NewIndex] := DB.FDQuery1.FieldByName('program_id').AsInteger;

    if FProgramIds[NewIndex] = CurrentProgramId then
      cbPrograms.ItemIndex := NewIndex;

    DB.FDQuery1.Next;
  end;
  DB.FDQuery1.Close;
end;

procedure TFrmMemberPlanDetail.SetupScrollableContent;
begin
  FContent := TVertScrollBox.Create(Self);
  FContent.Parent := Self;
  FContent.Align := TAlignLayout.Client;
  FContent.Content.Height := 1220;
  FContent.BringToFront;

  lblTitle.Parent := FContent;
  lblMemberName.Parent := FContent;
  lblMemberGoal.Parent := FContent;
  lblPlanTitle.Parent := FContent;
  edtPlanTitle.Parent := FContent;
  lblGoal.Parent := FContent;
  edtGoal.Parent := FContent;
  lblProgram.Parent := FContent;
  cbPrograms.Parent := FContent;
  lblRoom.Parent := FContent;
  cbRooms.Parent := FContent;
  lblMaxTrainingCount.Parent := FContent;
  edtMaxTrainingCount.Parent := FContent;
  lblDuration.Parent := FContent;
  edtDuration.Parent := FContent;
  lblStartDate.Parent := FContent;
  edtStartDate.Parent := FContent;
  lblEndDate.Parent := FContent;
  edtEndDate.Parent := FContent;
  lblStatus.Parent := FContent;
  cbStatus.Parent := FContent;
  lblMessage.Parent := FContent;
  btnConfirm.Parent := FContent;
end;

function TFrmMemberPlanDetail.SavePlanChange: Boolean;
var
  ProgramId: Integer;
  RoomId: Integer;
  MaxTrainingCount: Integer;
  DurationMinutes: Integer;
begin
  Result := False;
  lblMessage.Text := '';

  if Trim(edtPlanTitle.Text) = '' then
  begin
    lblMessage.Text := 'Unesi naziv plana.';
    Exit;
  end;

  if Trim(edtGoal.Text) = '' then
  begin
    lblMessage.Text := 'Unesi cilj treninga.';
    Exit;
  end;

  if cbPrograms.ItemIndex < 0 then
  begin
    lblMessage.Text := 'Izaberi program treninga.';
    Exit;
  end;

  if cbRooms.ItemIndex < 0 then
  begin
    lblMessage.Text := 'Izaberi salu treninga.';
    Exit;
  end;

  ProgramId := FProgramIds[cbPrograms.ItemIndex];
  RoomId := FRoomIds[cbRooms.ItemIndex];
  MaxTrainingCount := StrToIntDef(Trim(edtMaxTrainingCount.Text), 0);
  DurationMinutes := StrToIntDef(Trim(edtDuration.Text), 0);
  if MaxTrainingCount <= 0 then
  begin
    lblMessage.Text := 'Broj treninga mora biti veci od nule.';
    Exit;
  end;

  if DurationMinutes <= 0 then
  begin
    lblMessage.Text := 'Trajanje mora biti vece od nule.';
    Exit;
  end;

  if (not IsValidIsoDate(Trim(edtStartDate.Text))) or
     (not IsValidIsoDate(Trim(edtEndDate.Text))) then
  begin
    lblMessage.Text := 'Datumi moraju biti u formatu yyyy-mm-dd.';
    Exit;
  end;

  if cbStatus.ItemIndex < 0 then
    cbStatus.ItemIndex := 0;

  DB.FDQuery1.Close;
  if FPlanId = 0 then
    DB.FDQuery1.SQL.Text :=
      'INSERT INTO plan_training(title, goal, max_training_count, duration_minutes, ' +
      'start_date, end_date, status, program_id, room_id, member_id, trainer_id) ' +
      'VALUES (:title, :goal, :max_training_count, :duration_minutes, ' +
      ':start_date, :end_date, :status, :program_id, :room_id, :member_id, :trainer_id)'
  else
    DB.FDQuery1.SQL.Text :=
      'UPDATE plan_training SET title = :title, goal = :goal, ' +
      'max_training_count = :max_training_count, duration_minutes = :duration_minutes, ' +
      'start_date = :start_date, end_date = :end_date, status = :status, ' +
      'program_id = :program_id, room_id = :room_id WHERE plan_id = :plan_id';

  DB.FDQuery1.ParamByName('title').AsString := Trim(edtPlanTitle.Text);
  DB.FDQuery1.ParamByName('goal').AsString := Trim(edtGoal.Text);
  DB.FDQuery1.ParamByName('max_training_count').AsInteger := MaxTrainingCount;
  DB.FDQuery1.ParamByName('duration_minutes').AsInteger := DurationMinutes;
  DB.FDQuery1.ParamByName('start_date').AsString := Trim(edtStartDate.Text);
  DB.FDQuery1.ParamByName('end_date').AsString := Trim(edtEndDate.Text);
  DB.FDQuery1.ParamByName('status').AsString := cbStatus.Items[cbStatus.ItemIndex];
  DB.FDQuery1.ParamByName('program_id').AsInteger := ProgramId;
  DB.FDQuery1.ParamByName('room_id').AsInteger := RoomId;
  if FPlanId = 0 then
  begin
    DB.FDQuery1.ParamByName('member_id').AsInteger := FMemberId;
    DB.FDQuery1.ParamByName('trainer_id').AsInteger := FTrainerId;
  end
  else
    DB.FDQuery1.ParamByName('plan_id').AsInteger := FPlanId;
  DB.FDQuery1.ExecSQL;
  lblMemberGoal.Text := 'Cilj: ' + Trim(edtGoal.Text);
  Result := True;
end;

end.
