unit FITMANAGER_login;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Edit,
  FMX.Objects, FMX.Controls.Presentation;

type
  TFrmLogin = class(TForm)
    imgBackground: TImage;
    lblTitle: TLabel;
    lblInfo: TLabel;
    edtLogin: TEdit;
    edtPassword: TEdit;
    lblMessage: TLabel;
    btnLogin: TButton;
    btnRegister: TButton;
    procedure btnLoginClick(Sender: TObject);
    procedure btnRegisterClick(Sender: TObject);
  private
    function BuildPath(const APath, AFileName: string): string;
    function FindAssetFile(const AFileName: string): string;
    procedure LoadTemplateBackground;
    procedure OpenUserHome;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  FrmLogin: TFrmLogin;

implementation

uses
  dmDatabase, FITMANAGER_adminHome, FITMANAGER_memberHome,
  FITMANAGER_register, FITMANAGER_trainerHome;

{$R *.fmx}

constructor TFrmLogin.Create(AOwner: TComponent);
begin
  inherited;
  LoadTemplateBackground;
  lblTitle.Visible := False;
  lblInfo.Visible := False;
  imgBackground.SendToBack;
end;

function TFrmLogin.BuildPath(const APath, AFileName: string): string;
begin
  Result := IncludeTrailingPathDelimiter(APath) + AFileName;
end;

function TFrmLogin.FindAssetFile(const AFileName: string): string;
var
  Candidate: string;
begin
  Candidate := BuildPath(BuildPath(ExtractFilePath(ParamStr(0)), 'assets'), AFileName);
  if TFile.Exists(Candidate) then
    Exit(Candidate);

  Candidate := BuildPath(ExtractFilePath(ParamStr(0)), AFileName);
  if TFile.Exists(Candidate) then
    Exit(Candidate);

  {$IFDEF MSWINDOWS}
  Candidate := ExpandFileName(BuildPath(
    BuildPath(ExtractFilePath(ParamStr(0)), '..\..\assets'), AFileName));
  if TFile.Exists(Candidate) then
    Exit(Candidate);

  Candidate := ExpandFileName(BuildPath(
    BuildPath(GetCurrentDir, 'assets'), AFileName));
  if TFile.Exists(Candidate) then
    Exit(Candidate);
  {$ENDIF}

  Candidate := BuildPath(System.IOUtils.TPath.GetDocumentsPath, AFileName);
  if TFile.Exists(Candidate) then
    Exit(Candidate);

  Result := '';
end;

procedure TFrmLogin.LoadTemplateBackground;
var
  FileName: string;
begin
  FileName := FindAssetFile('login_template_clean.png');
  if FileName = '' then
    FileName := FindAssetFile('login_template.png');
  if FileName <> '' then
    imgBackground.Bitmap.LoadFromFile(FileName);
end;

procedure TFrmLogin.btnLoginClick(Sender: TObject);
begin
  if (Trim(edtLogin.Text) = '') or (edtPassword.Text = '') then
  begin
    lblMessage.Text := 'Unesi email i lozinku.';
    Exit;
  end;

  try
    if DB.AuthenticateUser(edtLogin.Text, edtPassword.Text) then
      OpenUserHome
    else
      lblMessage.Text := 'Pogresan login ili lozinka.';
  except
    on E: Exception do
      lblMessage.Text := 'Greska pri prijavi: ' + E.Message;
  end;
end;

procedure TFrmLogin.btnRegisterClick(Sender: TObject);
begin
  TFrmRegister.Create(Application).Show;
  Hide;
end;

procedure TFrmLogin.OpenUserHome;
begin
  case DB.CurrentRole of
    urAdmin:
      TFrmAdminHome.Create(Application).Show;
    urTrainer:
      TFrmTrainerHome.Create(Application).Show;
    urMember:
      TFrmMemberHome.Create(Application).Show;
  else
    lblMessage.Text := 'Korisnik nema dodeljenu ulogu.';
    Exit;
  end;

  Hide;
end;

end.
