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
    FProgressPanel: TRectangle;
    FProgressStatus: TLabel;
    FProgressTitle: TLabel;
    FInitialHeader: TLabel;
    FCurrentHeader: TLabel;
    FProgressInfo: TLabel;
    FUpdateProgressButton: TButton;
    FProgressExists: Boolean;
    FEditAge: TEdit;
    FEditHeight: TEdit;
    FEditInitialWeight: TEdit;
    FEditCurrentWeight: TEdit;
    FEditInitialBmi: TEdit;
    FEditCurrentBmi: TEdit;
    FEditInitialMuscle: TEdit;
    FEditCurrentMuscle: TEdit;
    FEditInitialCalories: TEdit;
    FEditCurrentCalories: TEdit;
    FTrainerLabel: TLabel;
    FTrainerCombo: TComboBox;
    FMemberStatusLabel: TLabel;
    FMemberStatusCombo: TComboBox;
    FProgramIds: array of Integer;
    FRoomIds: array of Integer;
    FTrainerIds: array of Integer;
    procedure AddMemberDataCell(AParent: TFmxObject; const AText: string;
      ALeft, ATop, AWidth, AHeight: Single; AColor: TAlphaColor;
      AFontSize: Single; ABold: Boolean = False);
    procedure BuildMemberDataTable;
    procedure BuildProgressEditor;
    procedure BuildMemberStatusControls;
    procedure BuildTrainerControls;
    procedure ConfigureProgressEditor;
    function CreateProgressEdit(ALeft, ATop, AWidth: Single): TEdit;
    function BuildPath(const APath, AFileName: string): string;
    function FindAssetFile(const AFileName: string): string;
    procedure LoadMember;
    procedure LoadTemplateBackground;
    procedure LoadPlan;
    procedure LoadPrograms;
    procedure LoadMemberDataTable;
    procedure LoadRooms;
    procedure LoadTrainers;
    procedure RefreshTrainerForm;
    procedure SaveProgressClick(Sender: TObject);
    procedure UpdateProgressClick(Sender: TObject);
    procedure SetupScrollableContent;
    function IsValidIsoDate(const AValue: string): Boolean;
    function TryParseNumber(const AValue: string; out AResult: Double): Boolean;
    function SavePlanChange: Boolean;
  public
    constructor CreateForMember(AOwner: TComponent; AMemberId: Integer;
      ATrainerForm: TForm); reintroduce;
  end;

implementation

uses
  dmDatabase, FITMANAGER_trainerHome, FITMANAGER_progressUpdate;

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
    FMemberStatusCombo.Items.Clear;
    FMemberStatusCombo.Items.Add('Aktivan');
    FMemberStatusCombo.Items.Add('Pauziran');
    FMemberStatusCombo.Items.Add('Neaktivan');
    BuildMemberDataTable;
    BuildProgressEditor;
    LoadMember;
    LoadMemberDataTable;
    LoadPlan;
    LoadPrograms;
    LoadRooms;
    LoadTrainers;
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

procedure TFrmMemberPlanDetail.BuildMemberStatusControls;
begin
  FMemberStatusLabel := TLabel.Create(Self);
  FMemberStatusLabel.Parent := FContent;
  FMemberStatusLabel.Position.X := 46;
  FMemberStatusLabel.Position.Y := 1200;
  FMemberStatusLabel.Width := 300;
  FMemberStatusLabel.Height := 22;
  FMemberStatusLabel.TextSettings.Font.Size := 12;
  FMemberStatusLabel.TextSettings.Font.Style := [TFontStyle.fsBold];
  FMemberStatusLabel.Text := 'Status clana:';

  FMemberStatusCombo := TComboBox.Create(Self);
  FMemberStatusCombo.Parent := FContent;
  FMemberStatusCombo.Position.X := 46;
  FMemberStatusCombo.Position.Y := 1224;
  FMemberStatusCombo.Width := 300;
  FMemberStatusCombo.Height := 36;
  FMemberStatusCombo.TabOrder := 9;

  lblMessage.Position.Y := 1262;
  btnConfirm.Position.Y := 1284;
  btnConfirm.TabOrder := 10;
end;

function TFrmMemberPlanDetail.CreateProgressEdit(ALeft, ATop,
  AWidth: Single): TEdit;
begin
  Result := TEdit.Create(Self);
  Result.Parent := FProgressPanel;
  Result.Position.X := ALeft;
  Result.Position.Y := ATop;
  Result.Width := AWidth;
  Result.Height := 30;
  Result.TextSettings.Font.Size := 9;
end;

procedure TFrmMemberPlanDetail.BuildProgressEditor;
var
  RowLabel: TLabel;
  SaveButton: TButton;

  procedure AddRowLabel(const AText: string; ATop: Single);
  begin
    RowLabel := TLabel.Create(Self);
    RowLabel.Parent := FProgressPanel;
    RowLabel.Position.X := 8;
    RowLabel.Position.Y := ATop;
    RowLabel.Width := 80;
    RowLabel.Height := 30;
    RowLabel.TextSettings.Font.Size := 7.5;
    RowLabel.TextSettings.VertAlign := TTextAlign.Center;
    RowLabel.Text := AText;
  end;

begin
  FProgressExists := False;
  FProgressPanel := TRectangle.Create(Self);
  FProgressPanel.Parent := FContent;
  FProgressPanel.Position.X := 46;
  FProgressPanel.Position.Y := 620;
  FProgressPanel.Width := 300;
  FProgressPanel.Height := 398;
  FProgressPanel.Fill.Color := $FFFFF8E1;
  FProgressPanel.Stroke.Color := $FFFF8A80;
  FProgressPanel.XRadius := 8;
  FProgressPanel.YRadius := 8;

  FProgressTitle := TLabel.Create(Self);
  FProgressTitle.Parent := FProgressPanel;
  FProgressTitle.Position.X := 8;
  FProgressTitle.Position.Y := 6;
  FProgressTitle.Width := 284;
  FProgressTitle.Height := 34;
  FProgressTitle.TextSettings.Font.Size := 8.5;
  FProgressTitle.TextSettings.Font.Style := [TFontStyle.fsBold];
  FProgressTitle.TextSettings.HorzAlign := TTextAlign.Center;
  FProgressTitle.WordWrap := True;
  FProgressTitle.Text := 'Prvi unos merenja clana';

  FInitialHeader := TLabel.Create(Self);
  FInitialHeader.Parent := FProgressPanel;
  FInitialHeader.Position.X := 92;
  FInitialHeader.Position.Y := 42;
  FInitialHeader.Width := 94;
  FInitialHeader.Height := 20;
  FInitialHeader.TextSettings.Font.Size := 7;
  FInitialHeader.TextSettings.Font.Style := [TFontStyle.fsBold];
  FInitialHeader.TextSettings.HorzAlign := TTextAlign.Center;
  FInitialHeader.Text := 'Pocetno';

  FCurrentHeader := TLabel.Create(Self);
  FCurrentHeader.Parent := FProgressPanel;
  FCurrentHeader.Position.X := 194;
  FCurrentHeader.Position.Y := 42;
  FCurrentHeader.Width := 98;
  FCurrentHeader.Height := 20;
  FCurrentHeader.TextSettings.Font.Size := 7;
  FCurrentHeader.TextSettings.Font.Style := [TFontStyle.fsBold];
  FCurrentHeader.TextSettings.HorzAlign := TTextAlign.Center;
  FCurrentHeader.Text := 'Trenutno';

  AddRowLabel('Godine', 64);
  FEditAge := CreateProgressEdit(92, 64, 200);
  AddRowLabel('Visina cm', 102);
  FEditHeight := CreateProgressEdit(92, 102, 200);
  AddRowLabel('Tezina kg', 140);
  FEditInitialWeight := CreateProgressEdit(92, 140, 94);
  FEditCurrentWeight := CreateProgressEdit(194, 140, 98);
  AddRowLabel('BMI (auto)', 178);
  FEditInitialBmi := CreateProgressEdit(92, 178, 94);
  FEditCurrentBmi := CreateProgressEdit(194, 178, 98);
  FEditInitialBmi.Enabled := False;
  FEditCurrentBmi.Enabled := False;
  AddRowLabel('Misici %', 216);
  FEditInitialMuscle := CreateProgressEdit(92, 216, 94);
  FEditCurrentMuscle := CreateProgressEdit(194, 216, 98);
  AddRowLabel('Kalorije', 254);
  FEditInitialCalories := CreateProgressEdit(92, 254, 94);
  FEditCurrentCalories := CreateProgressEdit(194, 254, 98);

  SaveButton := TButton.Create(Self);
  SaveButton.Parent := FProgressPanel;
  SaveButton.Position.X := 70;
  SaveButton.Position.Y := 294;
  SaveButton.Width := 160;
  SaveButton.Height := 34;
  SaveButton.Text := 'Sacuvaj merenja';
  SaveButton.OnClick := SaveProgressClick;

  FProgressInfo := TLabel.Create(Self);
  FProgressInfo.Parent := FProgressPanel;
  FProgressInfo.Position.X := 8;
  FProgressInfo.Position.Y := 330;
  FProgressInfo.Width := 284;
  FProgressInfo.Height := 26;
  FProgressInfo.TextSettings.Font.Size := 7;
  FProgressInfo.TextSettings.HorzAlign := TTextAlign.Center;
  FProgressInfo.WordWrap := True;
  FProgressInfo.Text := 'Pocetne vrednosti se unose samo prvi put.';

  FProgressStatus := TLabel.Create(Self);
  FProgressStatus.Parent := FProgressPanel;
  FProgressStatus.Position.X := 8;
  FProgressStatus.Position.Y := 358;
  FProgressStatus.Width := 284;
  FProgressStatus.Height := 34;
  FProgressStatus.TextSettings.Font.Size := 7.5;
  FProgressStatus.TextSettings.HorzAlign := TTextAlign.Center;
  FProgressStatus.WordWrap := True;

  FUpdateProgressButton := TButton.Create(Self);
  FUpdateProgressButton.Parent := FContent;
  FUpdateProgressButton.Position.X := 86;
  FUpdateProgressButton.Position.Y := 612;
  FUpdateProgressButton.Width := 220;
  FUpdateProgressButton.Height := 24;
  FUpdateProgressButton.Text := 'Azuriraj trenutne vrednosti';
  FUpdateProgressButton.OnClick := UpdateProgressClick;
  FUpdateProgressButton.Visible := False;
end;

procedure TFrmMemberPlanDetail.ConfigureProgressEditor;
  procedure SetPlanControlsVisible(AVisible: Boolean);
  begin
    lblPlanTitle.Visible := AVisible;
    edtPlanTitle.Visible := AVisible;
    lblGoal.Visible := AVisible;
    edtGoal.Visible := AVisible;
    lblProgram.Visible := AVisible;
    cbPrograms.Visible := AVisible;
    lblRoom.Visible := AVisible;
    cbRooms.Visible := AVisible;
    FTrainerLabel.Visible := AVisible;
    FTrainerCombo.Visible := AVisible;
    lblMaxTrainingCount.Visible := AVisible;
    edtMaxTrainingCount.Visible := AVisible;
    lblDuration.Visible := AVisible;
    edtDuration.Visible := AVisible;
    lblStartDate.Visible := AVisible;
    edtStartDate.Visible := AVisible;
    lblEndDate.Visible := AVisible;
    edtEndDate.Visible := AVisible;
    lblStatus.Visible := AVisible;
    cbStatus.Visible := AVisible;
    FMemberStatusLabel.Visible := AVisible;
    FMemberStatusCombo.Visible := AVisible;
    lblMessage.Visible := AVisible;
    btnConfirm.Visible := AVisible;
  end;
begin
  FInitialHeader.Visible := not FProgressExists;
  FEditInitialWeight.Visible := not FProgressExists;
  FEditInitialBmi.Visible := not FProgressExists;
  FEditInitialMuscle.Visible := not FProgressExists;
  FEditInitialCalories.Visible := not FProgressExists;
  FCurrentHeader.Visible := False;
  FEditCurrentWeight.Visible := False;
  FEditCurrentBmi.Visible := False;
  FEditCurrentMuscle.Visible := False;
  FEditCurrentCalories.Visible := False;
  FInitialHeader.Position.X := 92;
  FInitialHeader.Width := 200;
  FInitialHeader.Text := 'Pocetna vrednost';
  FEditInitialWeight.Position.X := 92;
  FEditInitialWeight.Width := 200;
  FEditInitialBmi.Position.X := 92;
  FEditInitialBmi.Width := 200;
  FEditInitialMuscle.Position.X := 92;
  FEditInitialMuscle.Width := 200;
  FEditInitialCalories.Position.X := 92;
  FEditInitialCalories.Width := 200;
  FProgressPanel.Visible := not FProgressExists;
  FUpdateProgressButton.Visible := FProgressExists;
  SetPlanControlsVisible(FProgressExists);
  if FProgressExists then
    FContent.Content.Height := 1360
  else
    FContent.Content.Height := 1030;
end;

procedure TFrmMemberPlanDetail.BuildTrainerControls;
begin
  FTrainerLabel := TLabel.Create(Self);
  FTrainerLabel.Parent := FContent;
  FTrainerLabel.Position.X := 46;
  FTrainerLabel.Position.Y := 914;
  FTrainerLabel.Width := 300;
  FTrainerLabel.Height := 22;
  FTrainerLabel.TextSettings.Font.Size := 12;
  FTrainerLabel.TextSettings.Font.Style := [TFontStyle.fsBold];
  FTrainerLabel.Text := 'Trener (ime i specijalizacija):';

  FTrainerCombo := TComboBox.Create(Self);
  FTrainerCombo.Parent := FContent;
  FTrainerCombo.Position.X := 46;
  FTrainerCombo.Position.Y := 938;
  FTrainerCombo.Width := 300;
  FTrainerCombo.Height := 36;
  FTrainerCombo.TabOrder := 3;
  edtMaxTrainingCount.TabOrder := 4;
  edtDuration.TabOrder := 5;
  edtStartDate.TabOrder := 6;
  edtEndDate.TabOrder := 7;
  cbStatus.TabOrder := 8;
  btnConfirm.TabOrder := 9;

  lblMaxTrainingCount.Position.Y := lblMaxTrainingCount.Position.Y + 68;
  edtMaxTrainingCount.Position.Y := edtMaxTrainingCount.Position.Y + 68;
  lblDuration.Position.Y := lblDuration.Position.Y + 68;
  edtDuration.Position.Y := edtDuration.Position.Y + 68;
  lblStartDate.Position.Y := lblStartDate.Position.Y + 68;
  edtStartDate.Position.Y := edtStartDate.Position.Y + 68;
  lblEndDate.Position.Y := lblEndDate.Position.Y + 68;
  edtEndDate.Position.Y := edtEndDate.Position.Y + 68;
  lblStatus.Position.Y := lblStatus.Position.Y + 68;
  cbStatus.Position.Y := cbStatus.Position.Y + 68;
  lblMessage.Position.Y := lblMessage.Position.Y + 68;
  btnConfirm.Position.Y := btnConfirm.Position.Y + 68;
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

function TFrmMemberPlanDetail.TryParseNumber(const AValue: string;
  out AResult: Double): Boolean;
var
  NormalizedValue: string;
begin
  NormalizedValue := Trim(AValue);
  NormalizedValue := StringReplace(NormalizedValue, '.',
    FormatSettings.DecimalSeparator, [rfReplaceAll]);
  NormalizedValue := StringReplace(NormalizedValue, ',',
    FormatSettings.DecimalSeparator, [rfReplaceAll]);
  Result := TryStrToFloat(NormalizedValue, AResult);
end;

procedure TFrmMemberPlanDetail.SaveProgressClick(Sender: TObject);
var
  Age, HeightCm, InitialCalories, CurrentCalories: Integer;
  InitialWeight, CurrentWeight, InitialBmi, CurrentBmi: Double;
  InitialMuscle, CurrentMuscle: Double;
begin
  FProgressStatus.Text := '';
  Age := StrToIntDef(Trim(FEditAge.Text), 0);
  HeightCm := StrToIntDef(Trim(FEditHeight.Text), 0);
  if (Age < 10) or (Age > 120) then
  begin
    FProgressStatus.Text := 'Godine moraju biti izmedju 10 i 120.';
    Exit;
  end;
  if (HeightCm < 100) or (HeightCm > 250) then
  begin
    FProgressStatus.Text := 'Visina mora biti izmedju 100 i 250 cm.';
    Exit;
  end;

  if Trim(FEditCurrentWeight.Text) = '' then
    FEditCurrentWeight.Text := FEditInitialWeight.Text;
  if Trim(FEditCurrentMuscle.Text) = '' then
    FEditCurrentMuscle.Text := FEditInitialMuscle.Text;
  if Trim(FEditCurrentCalories.Text) = '' then
    FEditCurrentCalories.Text := FEditInitialCalories.Text;

  if not TryParseNumber(FEditInitialWeight.Text, InitialWeight) or
     not TryParseNumber(FEditCurrentWeight.Text, CurrentWeight) or
     (InitialWeight < 20) or (InitialWeight > 400) or
     (CurrentWeight < 20) or (CurrentWeight > 400) then
  begin
    FProgressStatus.Text := 'Tezina mora biti broj izmedju 20 i 400 kg.';
    Exit;
  end;
  if not TryParseNumber(FEditInitialMuscle.Text, InitialMuscle) or
     not TryParseNumber(FEditCurrentMuscle.Text, CurrentMuscle) or
     (InitialMuscle < 1) or (InitialMuscle > 100) or
     (CurrentMuscle < 1) or (CurrentMuscle > 100) then
  begin
    FProgressStatus.Text := 'Procenat misica mora biti izmedju 1 i 100.';
    Exit;
  end;

  InitialCalories := StrToIntDef(Trim(FEditInitialCalories.Text), 0);
  CurrentCalories := StrToIntDef(Trim(FEditCurrentCalories.Text), 0);
  if (InitialCalories < 500) or (InitialCalories > 10000) or
     (CurrentCalories < 500) or (CurrentCalories > 10000) then
  begin
    FProgressStatus.Text := 'Kalorije moraju biti izmedju 500 i 10000.';
    Exit;
  end;

  InitialBmi := InitialWeight / ((HeightCm / 100.0) * (HeightCm / 100.0));
  CurrentBmi := CurrentWeight / ((HeightCm / 100.0) * (HeightCm / 100.0));
  FEditInitialBmi.Text := FormatFloat('0.0', InitialBmi);
  FEditCurrentBmi.Text := FormatFloat('0.0', CurrentBmi);

  DB.FDConnection1.StartTransaction;
  try
    DB.FDQuery1.Close;
    DB.FDQuery1.SQL.Text :=
      'UPDATE member SET age = :age WHERE member_id = :member_id';
    DB.FDQuery1.ParamByName('age').AsInteger := Age;
    DB.FDQuery1.ParamByName('member_id').AsInteger := FMemberId;
    DB.FDQuery1.ExecSQL;

    DB.FDQuery1.Close;
    if FProgressExists then
      DB.FDQuery1.SQL.Text :=
        'UPDATE member_progress SET height_cm = :height_cm, ' +
        'current_weight = :current_weight, current_bmi = :current_bmi, ' +
        'current_muscle_percent = :current_muscle, ' +
        'current_calories = :current_calories WHERE member_id = :member_id'
    else
      DB.FDQuery1.SQL.Text :=
        'INSERT INTO member_progress(member_id, initial_weight, current_weight, ' +
        'height_cm, initial_bmi, current_bmi, initial_muscle_percent, ' +
        'current_muscle_percent, initial_calories, current_calories) ' +
        'VALUES (:member_id, :initial_weight, :current_weight, :height_cm, ' +
        ':initial_bmi, :current_bmi, :initial_muscle, :current_muscle, ' +
        ':initial_calories, :current_calories)';

    DB.FDQuery1.ParamByName('member_id').AsInteger := FMemberId;
    DB.FDQuery1.ParamByName('height_cm').AsInteger := HeightCm;
    DB.FDQuery1.ParamByName('current_weight').AsFloat := CurrentWeight;
    DB.FDQuery1.ParamByName('current_bmi').AsFloat := CurrentBmi;
    DB.FDQuery1.ParamByName('current_muscle').AsFloat := CurrentMuscle;
    DB.FDQuery1.ParamByName('current_calories').AsInteger := CurrentCalories;
    if not FProgressExists then
    begin
      DB.FDQuery1.ParamByName('initial_weight').AsFloat := InitialWeight;
      DB.FDQuery1.ParamByName('initial_bmi').AsFloat := InitialBmi;
      DB.FDQuery1.ParamByName('initial_muscle').AsFloat := InitialMuscle;
      DB.FDQuery1.ParamByName('initial_calories').AsInteger := InitialCalories;
    end;
    DB.FDQuery1.ExecSQL;
    DB.FDConnection1.Commit;
    FProgressStatus.Text := 'Merenja su uspesno sacuvana.';
    LoadMemberDataTable;
  except
    on E: Exception do
    begin
      DB.FDConnection1.Rollback;
      FProgressStatus.Text := 'Merenja nisu sacuvana: ' + E.Message;
    end;
  end;
end;

procedure TFrmMemberPlanDetail.UpdateProgressClick(Sender: TObject);
var
  UpdateForm: TFrmProgressUpdate;
begin
  UpdateForm := TFrmProgressUpdate.CreateForMember(Self, FMemberId);
  try
    UpdateForm.ShowModal;
  finally
    UpdateForm.Free;
  end;
  LoadMemberDataTable;
end;

procedure TFrmMemberPlanDetail.LoadMember;
begin
  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'SELECT first_name, last_name, status FROM member WHERE member_id = :member_id';
  DB.FDQuery1.ParamByName('member_id').AsInteger := FMemberId;
  DB.FDQuery1.Open;

  if not DB.FDQuery1.IsEmpty then
  begin
    lblMemberName.Text := Format('%s %s',
      [DB.FDQuery1.FieldByName('first_name').AsString,
       DB.FDQuery1.FieldByName('last_name').AsString]);
    FMemberStatusCombo.ItemIndex := FMemberStatusCombo.Items.IndexOf(
      DB.FDQuery1.FieldByName('status').AsString);
    if FMemberStatusCombo.ItemIndex < 0 then
      FMemberStatusCombo.ItemIndex := 0;
  end
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
    'SELECT m.age, p.progress_id, p.initial_weight, p.current_weight, p.height_cm, ' +
    'p.initial_bmi, p.current_bmi, p.initial_muscle_percent, ' +
    'p.current_muscle_percent, p.initial_calories, p.current_calories ' +
    'FROM member m LEFT JOIN member_progress p ON p.member_id = m.member_id ' +
    'WHERE m.member_id = :member_id LIMIT 1';
  DB.FDQuery1.ParamByName('member_id').AsInteger := FMemberId;
  DB.FDQuery1.Open;

  if not DB.FDQuery1.IsEmpty then
  begin
    Age := DB.FDQuery1.FieldByName('age').AsString;
    FEditAge.Text := Age;
    FProgressExists := not DB.FDQuery1.FieldByName('progress_id').IsNull;
    if FProgressExists then
    begin
      HeightCm := DB.FDQuery1.FieldByName('height_cm').AsString;
      InitialWeight := DB.FDQuery1.FieldByName('initial_weight').AsString + ' kg';
      CurrentWeight := DB.FDQuery1.FieldByName('current_weight').AsString + ' kg';
      InitialBmi := DB.FDQuery1.FieldByName('initial_bmi').AsString;
      CurrentBmi := DB.FDQuery1.FieldByName('current_bmi').AsString;
      InitialMuscle := DB.FDQuery1.FieldByName('initial_muscle_percent').AsString + '%';
      CurrentMuscle := DB.FDQuery1.FieldByName('current_muscle_percent').AsString + '%';
      InitialCalories := DB.FDQuery1.FieldByName('initial_calories').AsString;
      CurrentCalories := DB.FDQuery1.FieldByName('current_calories').AsString;

      FEditHeight.Text := DB.FDQuery1.FieldByName('height_cm').AsString;
      FEditInitialWeight.Text := DB.FDQuery1.FieldByName('initial_weight').AsString;
      FEditCurrentWeight.Text := DB.FDQuery1.FieldByName('current_weight').AsString;
      FEditInitialBmi.Text := DB.FDQuery1.FieldByName('initial_bmi').AsString;
      FEditCurrentBmi.Text := DB.FDQuery1.FieldByName('current_bmi').AsString;
      FEditInitialMuscle.Text := DB.FDQuery1.FieldByName('initial_muscle_percent').AsString;
      FEditCurrentMuscle.Text := DB.FDQuery1.FieldByName('current_muscle_percent').AsString;
      FEditInitialCalories.Text := DB.FDQuery1.FieldByName('initial_calories').AsString;
      FEditCurrentCalories.Text := DB.FDQuery1.FieldByName('current_calories').AsString;
    end
    else
    begin
      FEditHeight.Text := '';
      FEditInitialWeight.Text := '';
      FEditCurrentWeight.Text := '';
      FEditInitialBmi.Text := '';
      FEditCurrentBmi.Text := '';
      FEditInitialMuscle.Text := '';
      FEditCurrentMuscle.Text := '';
      FEditInitialCalories.Text := '';
      FEditCurrentCalories.Text := '';
    end;
  end;

  DB.FDQuery1.Close;
  FEditInitialWeight.Enabled := not FProgressExists;
  FEditInitialMuscle.Enabled := not FProgressExists;
  FEditInitialCalories.Enabled := not FProgressExists;
  ConfigureProgressEditor;

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
    'WHERE member_id = :member_id ORDER BY plan_id DESC LIMIT 1';
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

procedure TFrmMemberPlanDetail.LoadTrainers;
var
  NewIndex: Integer;
begin
  FTrainerCombo.Clear;
  SetLength(FTrainerIds, 0);

  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'SELECT trainer_id, first_name, last_name, specialization FROM trainer ' +
    'WHERE status = :status ORDER BY last_name, first_name';
  DB.FDQuery1.ParamByName('status').AsString := 'Aktivan';
  DB.FDQuery1.Open;
  while not DB.FDQuery1.Eof do
  begin
    NewIndex := FTrainerCombo.Items.Add(Format('%s %s - %s',
      [DB.FDQuery1.FieldByName('first_name').AsString,
       DB.FDQuery1.FieldByName('last_name').AsString,
       DB.FDQuery1.FieldByName('specialization').AsString]));
    SetLength(FTrainerIds, Length(FTrainerIds) + 1);
    FTrainerIds[NewIndex] := DB.FDQuery1.FieldByName('trainer_id').AsInteger;
    if FTrainerIds[NewIndex] = FTrainerId then
      FTrainerCombo.ItemIndex := NewIndex;
    DB.FDQuery1.Next;
  end;
  DB.FDQuery1.Close;

  if (FTrainerCombo.ItemIndex < 0) and (FTrainerCombo.Items.Count > 0) then
    FTrainerCombo.ItemIndex := 0;
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
    'ORDER BY plan_id DESC LIMIT 1';
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
  FContent.Content.Height := 1290;
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
  BuildTrainerControls;
  BuildMemberStatusControls;
end;

function TFrmMemberPlanDetail.SavePlanChange: Boolean;
var
  ProgramId: Integer;
  RoomId: Integer;
  TrainerId: Integer;
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

  if FTrainerCombo.ItemIndex < 0 then
  begin
    lblMessage.Text := 'Izaberi trenera za plan.';
    Exit;
  end;

  ProgramId := FProgramIds[cbPrograms.ItemIndex];
  RoomId := FRoomIds[cbRooms.ItemIndex];
  TrainerId := FTrainerIds[FTrainerCombo.ItemIndex];
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

  if Trim(edtEndDate.Text) < Trim(edtStartDate.Text) then
  begin
    lblMessage.Text := 'Datum kraja mora biti isti ili posle datuma pocetka.';
    Exit;
  end;

  if cbStatus.ItemIndex < 0 then
    cbStatus.ItemIndex := 0;

  if FMemberStatusCombo.ItemIndex < 0 then
  begin
    lblMessage.Text := 'Izaberi status clana.';
    Exit;
  end;

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
      'program_id = :program_id, room_id = :room_id, trainer_id = :trainer_id ' +
      'WHERE plan_id = :plan_id';

  DB.FDQuery1.ParamByName('title').AsString := Trim(edtPlanTitle.Text);
  DB.FDQuery1.ParamByName('goal').AsString := Trim(edtGoal.Text);
  DB.FDQuery1.ParamByName('max_training_count').AsInteger := MaxTrainingCount;
  DB.FDQuery1.ParamByName('duration_minutes').AsInteger := DurationMinutes;
  DB.FDQuery1.ParamByName('start_date').AsString := Trim(edtStartDate.Text);
  DB.FDQuery1.ParamByName('end_date').AsString := Trim(edtEndDate.Text);
  DB.FDQuery1.ParamByName('status').AsString := cbStatus.Items[cbStatus.ItemIndex];
  DB.FDQuery1.ParamByName('program_id').AsInteger := ProgramId;
  DB.FDQuery1.ParamByName('room_id').AsInteger := RoomId;
  DB.FDQuery1.ParamByName('trainer_id').AsInteger := TrainerId;
  if FPlanId = 0 then
  begin
    DB.FDQuery1.ParamByName('member_id').AsInteger := FMemberId;
  end
  else
    DB.FDQuery1.ParamByName('plan_id').AsInteger := FPlanId;
  DB.FDQuery1.ExecSQL;

  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'UPDATE member SET status = :status WHERE member_id = :member_id';
  DB.FDQuery1.ParamByName('status').AsString :=
    FMemberStatusCombo.Items[FMemberStatusCombo.ItemIndex];
  DB.FDQuery1.ParamByName('member_id').AsInteger := FMemberId;
  DB.FDQuery1.ExecSQL;

  FTrainerId := TrainerId;
  lblMemberGoal.Text := 'Cilj: ' + Trim(edtGoal.Text);
  Result := True;
end;

end.
