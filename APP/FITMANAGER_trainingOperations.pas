unit FITMANAGER_trainingOperations;

interface

uses
  System.SysUtils, System.Classes, System.UITypes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Edit, FMX.Memo,
  FMX.Objects, FMX.Layouts, FMX.Controls.Presentation;

type
  TFrmTrainingOperations = class(TForm)
    lblTitle: TLabel;
    sbTrainings: TScrollBox;
    lyTrainings: TLayout;
    lblSelected: TLabel;
    lblDate: TLabel;
    edtDate: TEdit;
    lblStart: TLabel;
    edtStart: TEdit;
    lblEnd: TLabel;
    edtEnd: TEdit;
    lblNote: TLabel;
    memNote: TMemo;
    btnSaveTerm: TButton;
    btnStart: TButton;
    btnFinish: TButton;
    btnRefresh: TButton;
    lblMessage: TLabel;
    lblReportsTitle: TLabel;
    lblReports: TLabel;
    btnClose: TButton;
    procedure btnCloseClick(Sender: TObject);
    procedure btnFinishClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnSaveTermClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
  private
    FTrainerId: Integer;
    FSelectedTrainingId: Integer;
    FSelectedScheduleId: Integer;
    procedure AddTrainingCard(const ATop: Single; ATrainingId: Integer;
      const ACaption, AStatus: string);
    procedure LoadReports;
    procedure LoadSelectedTraining;
    procedure RefreshTrainings;
    procedure SelectTraining(Sender: TObject);
    function ValidateTerm: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  dmDatabase;

{$R *.fmx}

constructor TFrmTrainingOperations.Create(AOwner: TComponent);
begin
  inherited;
  FTrainerId := DB.CurrentTrainerId;
  FSelectedTrainingId := 0;
  FSelectedScheduleId := 0;
  DB.InitializeDatabase;
  RefreshTrainings;
  LoadReports;
end;

procedure TFrmTrainingOperations.AddTrainingCard(const ATop: Single;
  ATrainingId: Integer; const ACaption, AStatus: string);
var
  Card: TRectangle;
  CaptionLabel, StatusLabel: TLabel;
begin
  Card := TRectangle.Create(lyTrainings);
  Card.Parent := lyTrainings;
  Card.Position.X := 4;
  Card.Position.Y := ATop;
  Card.Width := 330;
  Card.Height := 78;
  Card.XRadius := 6;
  Card.YRadius := 6;
  Card.Fill.Color := $FFFFF3E0;
  Card.Stroke.Color := $FFFFB74D;
  Card.Tag := ATrainingId;
  Card.OnClick := SelectTraining;

  CaptionLabel := TLabel.Create(Card);
  CaptionLabel.Parent := Card;
  CaptionLabel.HitTest := False;
  CaptionLabel.Position.X := 10;
  CaptionLabel.Position.Y := 8;
  CaptionLabel.Width := 310;
  CaptionLabel.Height := 42;
  CaptionLabel.WordWrap := True;
  CaptionLabel.TextSettings.Font.Size := 10;
  CaptionLabel.TextSettings.Font.Style := [TFontStyle.fsBold];
  CaptionLabel.Text := ACaption;

  StatusLabel := TLabel.Create(Card);
  StatusLabel.Parent := Card;
  StatusLabel.HitTest := False;
  StatusLabel.Position.X := 10;
  StatusLabel.Position.Y := 52;
  StatusLabel.Width := 310;
  StatusLabel.Height := 20;
  StatusLabel.TextSettings.Font.Size := 9;
  StatusLabel.Text := 'Status: ' + AStatus;
end;

procedure TFrmTrainingOperations.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmTrainingOperations.btnFinishClick(Sender: TObject);
var
  RecordId: Integer;
  MemberName, TrainingDate, StartTime, EndTime: string;
begin
  if FSelectedTrainingId = 0 then
  begin
    lblMessage.Text := 'Prvo izaberi trening.';
    Exit;
  end;

  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'SELECT m.first_name || '' '' || m.last_name AS member_name, ' +
    's.training_date, s.start_time, s.end_time ' +
    'FROM training tr JOIN member m ON m.member_id = tr.member_id ' +
    'JOIN schedule s ON s.schedule_id = tr.schedule_id ' +
    'WHERE tr.training_id = :training_id';
  DB.FDQuery1.ParamByName('training_id').AsInteger := FSelectedTrainingId;
  DB.FDQuery1.Open;
  if DB.FDQuery1.IsEmpty then
  begin
    DB.FDQuery1.Close;
    Exit;
  end;
  MemberName := DB.FDQuery1.FieldByName('member_name').AsString;
  TrainingDate := DB.FDQuery1.FieldByName('training_date').AsString;
  StartTime := DB.FDQuery1.FieldByName('start_time').AsString;
  EndTime := DB.FDQuery1.FieldByName('end_time').AsString;
  DB.FDQuery1.Close;

  DB.FDConnection1.StartTransaction;
  try
    DB.FDConnection1.ExecSQL(
      'UPDATE training SET status = ''Zavrsen'', note = ? WHERE training_id = ?',
      [Trim(memNote.Text), FSelectedTrainingId]);
    DB.FDConnection1.ExecSQL(
      'UPDATE schedule SET status = ''Zavrsen'' WHERE schedule_id = ?',
      [FSelectedScheduleId]);
    DB.FDConnection1.ExecSQL(
      'INSERT INTO records(presence, status, trainer_note, record_date, record_time, training_id) ' +
      'VALUES (1, ''Zavrsen'', ?, ?, ?, ?)',
      [Trim(memNote.Text), FormatDateTime('yyyy-mm-dd', Date),
       FormatDateTime('hh:nn', Time), FSelectedTrainingId]);

    DB.FDQuery1.SQL.Text := 'SELECT last_insert_rowid() AS new_id';
    DB.FDQuery1.Open;
    RecordId := DB.FDQuery1.FieldByName('new_id').AsInteger;
    DB.FDQuery1.Close;

    DB.FDConnection1.ExecSQL(
      'INSERT INTO reports(title, report_type, start_time, end_time, date_created, description, record_id) ' +
      'VALUES (?, ''Realizacija'', ?, ?, ?, ?, ?)',
      ['Izvestaj - ' + MemberName, TrainingDate + ' ' + StartTime,
       TrainingDate + ' ' + EndTime, FormatDateTime('yyyy-mm-dd', Date),
       Trim(memNote.Text), RecordId]);
    DB.FDConnection1.Commit;
    lblMessage.Text := 'Trening je zavrsen, evidentiran i dodat u izvestaje.';
  except
    on E: Exception do
    begin
      DB.FDConnection1.Rollback;
      lblMessage.Text := 'Greska: ' + E.Message;
      Exit;
    end;
  end;
  RefreshTrainings;
  LoadReports;
end;

procedure TFrmTrainingOperations.btnRefreshClick(Sender: TObject);
begin
  RefreshTrainings;
  LoadReports;
end;

procedure TFrmTrainingOperations.btnSaveTermClick(Sender: TObject);
begin
  if (FSelectedTrainingId = 0) or not ValidateTerm then
    Exit;

  DB.FDConnection1.StartTransaction;
  try
    DB.FDConnection1.ExecSQL(
      'UPDATE schedule SET training_date = ?, start_time = ?, end_time = ?, note = ? ' +
      'WHERE schedule_id = ?',
      [Trim(edtDate.Text), Trim(edtStart.Text), Trim(edtEnd.Text),
       Trim(memNote.Text), FSelectedScheduleId]);
    DB.FDConnection1.ExecSQL(
      'UPDATE training SET start_time = ?, end_time = ?, note = ? WHERE training_id = ?',
      [Trim(edtStart.Text), Trim(edtEnd.Text), Trim(memNote.Text),
       FSelectedTrainingId]);
    DB.FDConnection1.Commit;
    lblMessage.Text := 'Termin je azuriran.';
  except
    on E: Exception do
    begin
      DB.FDConnection1.Rollback;
      lblMessage.Text := 'Greska: ' + E.Message;
      Exit;
    end;
  end;
  RefreshTrainings;
end;

procedure TFrmTrainingOperations.btnStartClick(Sender: TObject);
begin
  if FSelectedTrainingId = 0 then
  begin
    lblMessage.Text := 'Prvo izaberi trening.';
    Exit;
  end;
  DB.FDConnection1.ExecSQL(
    'UPDATE training SET status = ''U toku'' WHERE training_id = ?',
    [FSelectedTrainingId]);
  DB.FDConnection1.ExecSQL(
    'UPDATE schedule SET status = ''U toku'' WHERE schedule_id = ?',
    [FSelectedScheduleId]);
  lblMessage.Text := 'Trening je pokrenut.';
  RefreshTrainings;
end;

procedure TFrmTrainingOperations.LoadReports;
var
  Lines: string;
begin
  Lines := '';
  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'SELECT rp.title, rp.date_created, r.status ' +
    'FROM reports rp JOIN records r ON r.record_id = rp.record_id ' +
    'JOIN training tr ON tr.training_id = r.training_id ' +
    'WHERE tr.trainer_id = :trainer_id ORDER BY rp.report_id DESC LIMIT 8';
  DB.FDQuery1.ParamByName('trainer_id').AsInteger := FTrainerId;
  DB.FDQuery1.Open;
  while not DB.FDQuery1.Eof do
  begin
    Lines := Lines + Format('%s | %s | %s'#13#10,
      [DB.FDQuery1.FieldByName('date_created').AsString,
       DB.FDQuery1.FieldByName('title').AsString,
       DB.FDQuery1.FieldByName('status').AsString]);
    DB.FDQuery1.Next;
  end;
  DB.FDQuery1.Close;
  if Lines = '' then
    Lines := 'Nema evidentiranih treninga.';
  lblReports.Text := Lines;
end;

procedure TFrmTrainingOperations.LoadSelectedTraining;
var
  Status: string;
begin
  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'SELECT tr.schedule_id, tr.status, tr.note, s.training_date, s.start_time, s.end_time, ' +
    'm.first_name, m.last_name FROM training tr ' +
    'JOIN schedule s ON s.schedule_id = tr.schedule_id ' +
    'JOIN member m ON m.member_id = tr.member_id ' +
    'WHERE tr.training_id = :training_id';
  DB.FDQuery1.ParamByName('training_id').AsInteger := FSelectedTrainingId;
  DB.FDQuery1.Open;
  if not DB.FDQuery1.IsEmpty then
  begin
    FSelectedScheduleId := DB.FDQuery1.FieldByName('schedule_id').AsInteger;
    Status := DB.FDQuery1.FieldByName('status').AsString;
    lblSelected.Text := Format('Izabran: %s %s (%s)',
      [DB.FDQuery1.FieldByName('first_name').AsString,
       DB.FDQuery1.FieldByName('last_name').AsString, Status]);
    edtDate.Text := DB.FDQuery1.FieldByName('training_date').AsString;
    edtStart.Text := DB.FDQuery1.FieldByName('start_time').AsString;
    edtEnd.Text := DB.FDQuery1.FieldByName('end_time').AsString;
    memNote.Text := DB.FDQuery1.FieldByName('note').AsString;
    btnStart.Enabled := SameText(Status, 'Odobren') or SameText(Status, 'Zakazan');
    btnFinish.Enabled := SameText(Status, 'U toku');
    btnSaveTerm.Enabled := not SameText(Status, 'Zavrsen') and
      not SameText(Status, 'Otkazan') and not SameText(Status, 'Odbijen');
  end;
  DB.FDQuery1.Close;
end;

procedure TFrmTrainingOperations.RefreshTrainings;
var
  Index: Integer;
  Caption: string;
begin
  FSelectedTrainingId := 0;
  FSelectedScheduleId := 0;
  lblSelected.Text := 'Izaberi trening iz liste';
  btnSaveTerm.Enabled := False;
  btnStart.Enabled := False;
  btnFinish.Enabled := False;

  while lyTrainings.ChildrenCount > 0 do
    lyTrainings.Children[0].Free;

  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'SELECT tr.training_id, tr.status, s.training_date, s.start_time, s.end_time, ' +
    'm.first_name, m.last_name FROM training tr ' +
    'JOIN schedule s ON s.schedule_id = tr.schedule_id ' +
    'JOIN member m ON m.member_id = tr.member_id ' +
    'WHERE tr.trainer_id = :trainer_id ORDER BY s.training_date DESC, s.start_time DESC';
  DB.FDQuery1.ParamByName('trainer_id').AsInteger := FTrainerId;
  DB.FDQuery1.Open;
  Index := 0;
  while not DB.FDQuery1.Eof do
  begin
    Caption := Format('%s %s | %s | %s-%s',
      [DB.FDQuery1.FieldByName('first_name').AsString,
       DB.FDQuery1.FieldByName('last_name').AsString,
       DB.FDQuery1.FieldByName('training_date').AsString,
       DB.FDQuery1.FieldByName('start_time').AsString,
       DB.FDQuery1.FieldByName('end_time').AsString]);
    AddTrainingCard(Index * 84, DB.FDQuery1.FieldByName('training_id').AsInteger,
      Caption, DB.FDQuery1.FieldByName('status').AsString);
    Inc(Index);
    DB.FDQuery1.Next;
  end;
  DB.FDQuery1.Close;
  lyTrainings.Height := Index * 84;
end;

procedure TFrmTrainingOperations.SelectTraining(Sender: TObject);
begin
  if Sender is TRectangle then
  begin
    FSelectedTrainingId := TRectangle(Sender).Tag;
    LoadSelectedTraining;
  end;
end;

function TFrmTrainingOperations.ValidateTerm: Boolean;
var
  ParsedDate, StartValue, EndValue: TDateTime;
  Year, Month, Day: Integer;
  DateText: string;
begin
  Result := False;
  DateText := Trim(edtDate.Text);
  if Length(DateText) = 10 then
  begin
    Year := StrToIntDef(Copy(DateText, 1, 4), 0);
    Month := StrToIntDef(Copy(DateText, 6, 2), 0);
    Day := StrToIntDef(Copy(DateText, 9, 2), 0);
  end
  else
  begin
    Year := 0;
    Month := 0;
    Day := 0;
  end;
  if (Length(DateText) <> 10) or (DateText[5] <> '-') or
     (DateText[8] <> '-') or not TryEncodeDate(Year, Month, Day, ParsedDate) then
  begin
    lblMessage.Text := 'Datum mora biti yyyy-mm-dd.';
    Exit;
  end;
  if not TryStrToTime(Trim(edtStart.Text), StartValue) or
     not TryStrToTime(Trim(edtEnd.Text), EndValue) then
  begin
    lblMessage.Text := 'Vreme mora biti hh:mm.';
    Exit;
  end;
  if EndValue <= StartValue then
  begin
    lblMessage.Text := 'Zavrsetak mora biti posle pocetka.';
    Exit;
  end;
  Result := True;
end;

end.
