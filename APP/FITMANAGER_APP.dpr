program FITMANAGER_APP;

uses
  System.StartUpCopy,
  FMX.Forms,
  dmDatabase in 'dmDatabase.pas' {DB: TDataModule},
  FITMANAGER_login in 'FITMANAGER_login.pas' {FrmLogin},
  FITMANAGER_register in 'FITMANAGER_register.pas' {FrmRegister},
  FITMANAGER_roleSelect in 'FITMANAGER_roleSelect.pas' {FrmRoleSelect},
  FITMANAGER_memberHome in 'FITMANAGER_memberHome.pas',
  FITMANAGER_trainerHome in 'FITMANAGER_trainerHome.pas',
  FITMANAGER_memberPlanDetail in 'FITMANAGER_memberPlanDetail.pas' {FrmMemberPlanDetail},
  FITMANAGER_progressUpdate in 'FITMANAGER_progressUpdate.pas',
  FITMANAGER_trainingOperations in 'FITMANAGER_trainingOperations.pas' {FrmTrainingOperations},
  FITMANAGER_adminHome in 'FITMANAGER_adminHome.pas' {FrmAdminHome},
  FITMANAGER_adminProgramDetail in 'FITMANAGER_adminProgramDetail.pas' {FrmAdminProgramDetail};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDB, DB);
  Application.CreateForm(TFrmLogin, FrmLogin);
  Application.Run;
end.
