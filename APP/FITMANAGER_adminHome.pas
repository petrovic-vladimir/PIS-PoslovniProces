unit FITMANAGER_adminHome;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.UITypes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Objects, FMX.Layouts,
  FMX.Controls.Presentation;

type
  TFrmAdminHome = class(TForm)
    imgBackground: TImage;
    lblTitle: TLabel;
    lblMessage: TLabel;
    sbPrograms: TScrollBox;
    lyProgramsContent: TLayout;
    btnBack: TButton;
    btnAdd: TButton;
    procedure FormActivate(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
  private
    FMenuButton: TButton;
    FMenuPanel: TRectangle;
    FLogoutButton: TButton;
    function BuildPath(const APath, AFileName: string): string;
    procedure BuildLogoutMenu;
    function FindAssetFile(const AFileName: string): string;
    procedure AddHeaderRow;
    procedure AddProgramRow(const ATop: Single; AProgramId: Integer;
      const ATitle, AStatus: string);
    procedure DeleteProgram(AProgramId: Integer);
    procedure DeleteProgramClick(Sender: TObject);
    procedure EditProgramClick(Sender: TObject);
    procedure LoadTemplateBackground;
    procedure LogoutClick(Sender: TObject);
    procedure ToggleMenuClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure RefreshPrograms;
  end;

implementation

uses
  dmDatabase, FITMANAGER_adminProgramDetail;

{$R *.fmx}

constructor TFrmAdminHome.Create(AOwner: TComponent);
begin
  inherited;
  LoadTemplateBackground;
  BuildLogoutMenu;
  btnBack.Visible := False;
  try
    DB.InitializeDatabase;
    RefreshPrograms;
  except
    on E: Exception do
      lblMessage.Text := 'Greska pri ucitavanju baze: ' + E.Message;
  end;
end;

procedure TFrmAdminHome.BuildLogoutMenu;
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

procedure TFrmAdminHome.AddHeaderRow;
var
  Row: TRectangle;
  LTitle, LStatus, LAction: TLabel;
begin
  Row := TRectangle.Create(lyProgramsContent);
  Row.Parent := lyProgramsContent;
  Row.Position.X := 0;
  Row.Position.Y := 0;
  Row.Width := 326;
  Row.Height := 28;
  Row.Fill.Color := $FFB9C6FF;
  Row.Stroke.Color := $00FFFFFF;

  LTitle := TLabel.Create(Row);
  LTitle.Parent := Row;
  LTitle.Position.X := 4;
  LTitle.Position.Y := 4;
  LTitle.Width := 196;
  LTitle.Height := 20;
  LTitle.TextSettings.Font.Size := 6;
  LTitle.TextSettings.HorzAlign := TTextAlign.Center;
  LTitle.Text := 'Naziv';

  LStatus := TLabel.Create(Row);
  LStatus.Parent := Row;
  LStatus.Position.X := 204;
  LStatus.Position.Y := 4;
  LStatus.Width := 58;
  LStatus.Height := 20;
  LStatus.TextSettings.Font.Size := 6;
  LStatus.TextSettings.HorzAlign := TTextAlign.Center;
  LStatus.Text := 'Status';

  LAction := TLabel.Create(Row);
  LAction.Parent := Row;
  LAction.Position.X := 266;
  LAction.Position.Y := 4;
  LAction.Width := 56;
  LAction.Height := 20;
  LAction.TextSettings.Font.Size := 6;
  LAction.TextSettings.HorzAlign := TTextAlign.Center;
  LAction.Text := 'Akcija';
end;

procedure TFrmAdminHome.AddProgramRow(const ATop: Single; AProgramId: Integer;
  const ATitle, AStatus: string);
var
  Row: TRectangle;
  LTitle, LStatus: TLabel;
  BtnDelete, BtnEdit: TButton;
  StatusText: string;
begin
  if SameText(AStatus, 'Aktivan') then
    StatusText := 'A'
  else
    StatusText := 'N';

  Row := TRectangle.Create(lyProgramsContent);
  Row.Parent := lyProgramsContent;
  Row.Position.X := 0;
  Row.Position.Y := ATop;
  Row.Width := 326;
  Row.Height := 54;
  Row.Fill.Color := $FFE9EEFF;
  Row.Stroke.Color := $00FFFFFF;

  LTitle := TLabel.Create(Row);
  LTitle.Parent := Row;
  LTitle.Position.X := 4;
  LTitle.Position.Y := 4;
  LTitle.Width := 196;
  LTitle.Height := 46;
  LTitle.TextSettings.Font.Size := 5;
  LTitle.WordWrap := True;
  LTitle.Text := ATitle;

  LStatus := TLabel.Create(Row);
  LStatus.Parent := Row;
  LStatus.Position.X := 204;
  LStatus.Position.Y := 16;
  LStatus.Width := 58;
  LStatus.Height := 20;
  LStatus.TextSettings.Font.Size := 5;
  LStatus.TextSettings.HorzAlign := TTextAlign.Center;
  LStatus.WordWrap := True;
  LStatus.Text := StatusText;

  BtnDelete := TButton.Create(Row);
  BtnDelete.Parent := Row;
  BtnDelete.Position.X := 266;
  BtnDelete.Position.Y := 14;
  BtnDelete.Width := 26;
  BtnDelete.Height := 24;
  BtnDelete.Text := 'X';
  BtnDelete.Tag := AProgramId;
  BtnDelete.OnClick := DeleteProgramClick;

  BtnEdit := TButton.Create(Row);
  BtnEdit.Parent := Row;
  BtnEdit.Position.X := 296;
  BtnEdit.Position.Y := 14;
  BtnEdit.Width := 26;
  BtnEdit.Height := 24;
  BtnEdit.Text := 'O';
  BtnEdit.Tag := AProgramId;
  BtnEdit.OnClick := EditProgramClick;
end;

procedure TFrmAdminHome.btnAddClick(Sender: TObject);
begin
  TFrmAdminProgramDetail.CreateForProgram(Application, 0, Self).Show;
  Hide;
end;

procedure TFrmAdminHome.btnBackClick(Sender: TObject);
begin
  if Assigned(Application.MainForm) then
    Application.MainForm.Show;
  Close;
end;

function TFrmAdminHome.BuildPath(const APath, AFileName: string): string;
begin
  Result := IncludeTrailingPathDelimiter(APath) + AFileName;
end;

procedure TFrmAdminHome.DeleteProgram(AProgramId: Integer);
begin
  DB.FDConnection1.StartTransaction;
  try
    DB.FDQuery1.Close;
    DB.FDQuery1.SQL.Text :=
      'UPDATE plan_training SET program_id = NULL WHERE program_id = :program_id';
    DB.FDQuery1.ParamByName('program_id').AsInteger := AProgramId;
    DB.FDQuery1.ExecSQL;

    DB.FDQuery1.Close;
    DB.FDQuery1.SQL.Text :=
      'DELETE FROM program_training WHERE program_id = :program_id';
    DB.FDQuery1.ParamByName('program_id').AsInteger := AProgramId;
    DB.FDQuery1.ExecSQL;

    DB.FDConnection1.Commit;
    lblMessage.Text := 'Program je obrisan.';
    RefreshPrograms;
  except
    on E: Exception do
    begin
      DB.FDConnection1.Rollback;
      lblMessage.Text := 'Program nije obrisan: ' + E.Message;
    end;
  end;
end;

procedure TFrmAdminHome.DeleteProgramClick(Sender: TObject);
begin
  if Sender is TButton then
    DeleteProgram(TButton(Sender).Tag);
end;

procedure TFrmAdminHome.EditProgramClick(Sender: TObject);
begin
  if Sender is TButton then
  begin
    TFrmAdminProgramDetail.CreateForProgram(Application, TButton(Sender).Tag, Self).Show;
    Hide;
  end;
end;

procedure TFrmAdminHome.FormActivate(Sender: TObject);
begin
  if Assigned(DB) and DB.FDConnection1.Connected then
    RefreshPrograms;
end;

function TFrmAdminHome.FindAssetFile(const AFileName: string): string;
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

procedure TFrmAdminHome.LoadTemplateBackground;
var
  FileName: string;
begin
  FileName := FindAssetFile('Template3.png');
  if FileName <> '' then
    imgBackground.Bitmap.LoadFromFile(FileName);
end;

procedure TFrmAdminHome.LogoutClick(Sender: TObject);
begin
  DB.ResetCurrentUser;
  if Assigned(Application.MainForm) then
    Application.MainForm.Show;
  Close;
end;

procedure TFrmAdminHome.RefreshPrograms;
const
  CHeaderHeight = 28;
  CRowHeight = 54;
var
  Index: Integer;
begin
  while lyProgramsContent.ChildrenCount > 0 do
    lyProgramsContent.Children[0].Free;

  AddHeaderRow;

  DB.FDQuery1.Close;
  DB.FDQuery1.SQL.Text :=
    'SELECT program_id, title, status ' +
    'FROM program_training WHERE status <> :deleted_status ORDER BY program_id';
  DB.FDQuery1.ParamByName('deleted_status').AsString := 'Obrisan';
  DB.FDQuery1.Open;

  Index := 0;
  while not DB.FDQuery1.Eof do
  begin
    AddProgramRow(CHeaderHeight + (Index * CRowHeight),
      DB.FDQuery1.FieldByName('program_id').AsInteger,
      DB.FDQuery1.FieldByName('title').AsString,
      DB.FDQuery1.FieldByName('status').AsString);
    Inc(Index);
    DB.FDQuery1.Next;
  end;

  lyProgramsContent.Height := CHeaderHeight + (Index * CRowHeight);
  DB.FDQuery1.Close;
end;

procedure TFrmAdminHome.ToggleMenuClick(Sender: TObject);
begin
  FMenuPanel.Visible := not FMenuPanel.Visible;
  FMenuPanel.BringToFront;
  FMenuButton.BringToFront;
end;

end.
