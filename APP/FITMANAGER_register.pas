unit FITMANAGER_register;

interface

uses
  System.SysUtils, System.Classes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Edit,
  FMX.Controls.Presentation;

type
  TFrmRegister = class(TForm)
    lblTitle: TLabel;
    edtFirstName: TEdit;
    edtLastName: TEdit;
    edtUsername: TEdit;
    edtEmail: TEdit;
    edtPhone: TEdit;
    edtPassword: TEdit;
    edtRepeatPassword: TEdit;
    lblMessage: TLabel;
    btnCreate: TButton;
    btnBack: TButton;
    procedure btnBackClick(Sender: TObject);
    procedure btnCreateClick(Sender: TObject);
  private
    procedure BackToLogin;
  public
  end;

var
  FrmRegister: TFrmRegister;

implementation

uses
  dmDatabase;

{$R *.fmx}

procedure TFrmRegister.BackToLogin;
begin
  if Assigned(Application.MainForm) then
    Application.MainForm.Show;
  Close;
end;

procedure TFrmRegister.btnBackClick(Sender: TObject);
begin
  BackToLogin;
end;

procedure TFrmRegister.btnCreateClick(Sender: TObject);
begin
  if (Trim(edtFirstName.Text) = '') or (Trim(edtLastName.Text) = '') or
     (Trim(edtUsername.Text) = '') or (Trim(edtEmail.Text) = '') or
     (Trim(edtPhone.Text) = '') or (edtPassword.Text = '') or
     (edtRepeatPassword.Text = '') then
  begin
    lblMessage.Text := 'Popuni sva polja.';
    Exit;
  end;

  if edtPassword.Text <> edtRepeatPassword.Text then
  begin
    lblMessage.Text := 'Lozinke se ne poklapaju.';
    Exit;
  end;

  try
    if DB.RegisterMemberUser(edtFirstName.Text, edtLastName.Text, edtUsername.Text,
      edtPassword.Text, edtEmail.Text, edtPhone.Text) then
    begin
      lblMessage.Text := 'Registracija uspesna.';
      BackToLogin;
    end
    else
      lblMessage.Text := 'Username ili email vec postoji u sistemu.';
  except
    on E: Exception do
      lblMessage.Text := 'Registracija nije uspela: ' + E.Message;
  end;
end;

end.
