unit FITMANAGER_progressUpdate;

interface

uses
  System.SysUtils, System.Classes, System.UITypes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Edit,
  FMX.Controls.Presentation;

type
  TFrmProgressUpdate = class(TForm)
  private
    FMemberId: Integer;
    FTitle: TLabel;
    FMemberName: TLabel;
    FMessage: TLabel;
    FEditAge: TEdit;
    FEditHeight: TEdit;
    FEditWeight: TEdit;
    FEditBmi: TEdit;
    FEditMuscle: TEdit;
    FEditCalories: TEdit;
    FSaveButton: TButton;
    procedure AddField(const ACaption: string; ATop: Single; out AEdit: TEdit);
    procedure BackClick(Sender: TObject);
    procedure BuildInterface;
    procedure LoadCurrentValues;
    procedure SaveClick(Sender: TObject);
    function TryParseNumber(const AValue: string; out AResult: Double): Boolean;
  public
    constructor CreateForMember(AOwner: TComponent; AMemberId: Integer); reintroduce;
  end;

implementation

uses
  dmDatabase;

constructor TFrmProgressUpdate.CreateForMember(AOwner: TComponent;
  AMemberId: Integer);
begin
  inherited CreateNew(AOwner);
  FMemberId := AMemberId;
  Caption := 'Azuriranje trenutnih vrednosti';
  ClientWidth := 390;
  ClientHeight := 650;
  Fill.Color := $FFFFF8E1;
  BuildInterface;
  DB.InitializeDatabase;
  LoadCurrentValues;
end;

procedure TFrmProgressUpdate.AddField(const ACaption: string; ATop: Single;
  out AEdit: TEdit);
var
  FieldLabel: TLabel;
begin
  FieldLabel := TLabel.Create(Self);
  FieldLabel.Parent := Self;
  FieldLabel.Position.X := 46;
  FieldLabel.Position.Y := ATop;
  FieldLabel.Width := 298;
  FieldLabel.Height := 22;
  FieldLabel.TextSettings.Font.Size := 11;
  FieldLabel.TextSettings.Font.Style := [TFontStyle.fsBold];
  FieldLabel.Text := ACaption;

  AEdit := TEdit.Create(Self);
  AEdit.Parent := Self;
  AEdit.Position.X := 46;
  AEdit.Position.Y := ATop + 24;
  AEdit.Width := 298;
  AEdit.Height := 36;
  AEdit.TextSettings.Font.Size := 11;
end;

procedure TFrmProgressUpdate.BackClick(Sender: TObject);
begin
  ModalResult := mrClose;
end;

procedure TFrmProgressUpdate.BuildInterface;
var
  BackButton: TButton;
begin
  FTitle := TLabel.Create(Self);
  FTitle.Parent := Self;
  FTitle.Position.X := 36;
  FTitle.Position.Y := 24;
  FTitle.Width := 318;
  FTitle.Height := 34;
  FTitle.TextSettings.Font.Size := 17;
  FTitle.TextSettings.Font.Style := [TFontStyle.fsBold];
  FTitle.TextSettings.HorzAlign := TTextAlign.Center;
  FTitle.Text := 'Azuriraj trenutne vrednosti';

  FMemberName := TLabel.Create(Self);
  FMemberName.Parent := Self;
  FMemberName.Position.X := 46;
  FMemberName.Position.Y := 64;
  FMemberName.Width := 298;
  FMemberName.Height := 30;
  FMemberName.TextSettings.Font.Size := 13;
  FMemberName.TextSettings.Font.Style := [TFontStyle.fsBold];
  FMemberName.TextSettings.HorzAlign := TTextAlign.Center;

  AddField('Godine:', 104, FEditAge);
  AddField('Visina (cm):', 170, FEditHeight);
  AddField('Trenutna tezina (kg):', 236, FEditWeight);
  AddField('Trenutni BMI (automatski):', 302, FEditBmi);
  FEditBmi.Enabled := False;
  AddField('Trenutni procenat misica:', 368, FEditMuscle);
  AddField('Trenutni broj kalorija:', 434, FEditCalories);

  FMessage := TLabel.Create(Self);
  FMessage.Parent := Self;
  FMessage.Position.X := 36;
  FMessage.Position.Y := 504;
  FMessage.Width := 318;
  FMessage.Height := 42;
  FMessage.TextSettings.Font.Size := 9;
  FMessage.TextSettings.HorzAlign := TTextAlign.Center;
  FMessage.WordWrap := True;

  BackButton := TButton.Create(Self);
  BackButton.Parent := Self;
  BackButton.Position.X := 46;
  BackButton.Position.Y := 558;
  BackButton.Width := 112;
  BackButton.Height := 42;
  BackButton.Text := 'Nazad';
  BackButton.ModalResult := mrClose;
  BackButton.OnClick := BackClick;

  FSaveButton := TButton.Create(Self);
  FSaveButton.Parent := Self;
  FSaveButton.Position.X := 176;
  FSaveButton.Position.Y := 558;
  FSaveButton.Width := 168;
  FSaveButton.Height := 42;
  FSaveButton.Text := 'Sacuvaj promene';
  FSaveButton.OnClick := SaveClick;
end;

procedure TFrmProgressUpdate.LoadCurrentValues;
begin
  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'SELECT m.first_name, m.last_name, m.age, p.height_cm, p.current_weight, ' +
    'p.current_bmi, p.current_muscle_percent, p.current_calories ' +
    'FROM member m JOIN member_progress p ON p.member_id = m.member_id ' +
    'WHERE m.member_id = :member_id LIMIT 1';
  DB.FDQuery1.ParamByName('member_id').AsInteger := FMemberId;
  DB.FDQuery1.Open;
  if DB.FDQuery1.IsEmpty then
  begin
    DB.FDQuery1.Close;
    FMessage.Text := 'Pocetna merenja jos nisu uneta.';
    FSaveButton.Enabled := False;
    Exit;
  end;

  FMemberName.Text := DB.FDQuery1.FieldByName('first_name').AsString + ' ' +
    DB.FDQuery1.FieldByName('last_name').AsString;
  FEditAge.Text := DB.FDQuery1.FieldByName('age').AsString;
  FEditHeight.Text := DB.FDQuery1.FieldByName('height_cm').AsString;
  FEditWeight.Text := DB.FDQuery1.FieldByName('current_weight').AsString;
  FEditBmi.Text := DB.FDQuery1.FieldByName('current_bmi').AsString;
  FEditMuscle.Text := DB.FDQuery1.FieldByName('current_muscle_percent').AsString;
  FEditCalories.Text := DB.FDQuery1.FieldByName('current_calories').AsString;
  DB.FDQuery1.Close;
end;

procedure TFrmProgressUpdate.SaveClick(Sender: TObject);
var
  Age, HeightCm, Calories: Integer;
  Weight, Bmi, Muscle: Double;
begin
  FMessage.Text := '';
  Age := StrToIntDef(Trim(FEditAge.Text), 0);
  HeightCm := StrToIntDef(Trim(FEditHeight.Text), 0);
  Calories := StrToIntDef(Trim(FEditCalories.Text), 0);
  if (Age < 10) or (Age > 120) then
  begin
    FMessage.Text := 'Godine moraju biti izmedju 10 i 120.';
    Exit;
  end;
  if (HeightCm < 100) or (HeightCm > 250) then
  begin
    FMessage.Text := 'Visina mora biti izmedju 100 i 250 cm.';
    Exit;
  end;
  if not TryParseNumber(FEditWeight.Text, Weight) or
     (Weight < 20) or (Weight > 400) then
  begin
    FMessage.Text := 'Tezina mora biti izmedju 20 i 400 kg.';
    Exit;
  end;
  if not TryParseNumber(FEditMuscle.Text, Muscle) or
     (Muscle < 1) or (Muscle > 100) then
  begin
    FMessage.Text := 'Procenat misica mora biti izmedju 1 i 100.';
    Exit;
  end;
  if (Calories < 500) or (Calories > 10000) then
  begin
    FMessage.Text := 'Kalorije moraju biti izmedju 500 i 10000.';
    Exit;
  end;

  Bmi := Weight / ((HeightCm / 100.0) * (HeightCm / 100.0));
  FEditBmi.Text := FormatFloat('0.0', Bmi);

  DB.FDConnection1.StartTransaction;
  try
    DB.FDQuery1.Close;
    DB.FDQuery1.SQL.Text :=
      'UPDATE member SET age = :age WHERE member_id = :member_id';
    DB.FDQuery1.ParamByName('age').AsInteger := Age;
    DB.FDQuery1.ParamByName('member_id').AsInteger := FMemberId;
    DB.FDQuery1.ExecSQL;

    DB.FDQuery1.Close;
    DB.FDQuery1.SQL.Text :=
      'UPDATE member_progress SET height_cm = :height_cm, ' +
      'current_weight = :current_weight, current_bmi = :current_bmi, ' +
      'current_muscle_percent = :current_muscle, ' +
      'current_calories = :current_calories WHERE member_id = :member_id';
    DB.FDQuery1.ParamByName('height_cm').AsInteger := HeightCm;
    DB.FDQuery1.ParamByName('current_weight').AsFloat := Weight;
    DB.FDQuery1.ParamByName('current_bmi').AsFloat := Bmi;
    DB.FDQuery1.ParamByName('current_muscle').AsFloat := Muscle;
    DB.FDQuery1.ParamByName('current_calories').AsInteger := Calories;
    DB.FDQuery1.ParamByName('member_id').AsInteger := FMemberId;
    DB.FDQuery1.ExecSQL;
    DB.FDConnection1.Commit;
    FMessage.Text := 'Trenutne vrednosti su uspesno azurirane.';
  except
    on E: Exception do
    begin
      DB.FDConnection1.Rollback;
      FMessage.Text := 'Vrednosti nisu sacuvane: ' + E.Message;
    end;
  end;
end;

function TFrmProgressUpdate.TryParseNumber(const AValue: string;
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

end.
