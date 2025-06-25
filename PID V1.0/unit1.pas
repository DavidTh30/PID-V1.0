unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ECProgressBar, NumberEdit, math;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    ECProgressBar1: TECProgressBar;
    ECProgressBar2: TECProgressBar;
    ECProgressBar3: TECProgressBar;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Timer1: TTimer;
    Timer2: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Edit1EditingDone(Sender: TObject);
    procedure Edit2EditingDone(Sender: TObject);
    procedure Edit3EditingDone(Sender: TObject);
    procedure Edit4EditingDone(Sender: TObject);
    procedure Edit5EditingDone(Sender: TObject);
    procedure Edit5Enter(Sender: TObject);
    procedure Edit5KeyPress(Sender: TObject; var Key: char);
    procedure Edit5MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Edit5MouseEnter(Sender: TObject);
    procedure Edit5MouseLeave(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;
  EditOutput:boolean;

  dt: double;
  dt_old: LongWord;

  kp:double;
  ki:double;
  kd:double;

  setpoint:double;

  input:double;
  output:double;

  error_:double;
  previous_error:double;

  proportional:double;
  integral:double;
  derivative:double;

  RandomHardware:double;
  RandomStableLost:double;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  EditOutput:=false;

  kp:=0.7;
  Edit1.Text:=FormatFloat('0.000',kp);
  ki:=0.2;
  Edit2.Text:=FormatFloat('0.000',ki);
  kd:=0.001;
  Edit3.Text:=FormatFloat('0.000',kd);
  dt:=0.0;
  dt_old:=GetTickCount;

  setpoint:=75.0;
  Edit4.Text:=FormatFloat('0.0',setpoint);
  input:=0.0;
  output:=0.0;
  previous_error:=0;
  integral:=0;

  Randomize;
  RandomHardware:=4.0+(Random(35)/10);
  RandomStableLost:=2.0+Random(30);
end;

procedure TForm1.Edit1EditingDone(Sender: TObject);
var
  wideChars_   : array[0..11] of WideChar;
  Tempo:double;
begin
  //StringToWideChar(Edit1.Text, wideChars_, 12);

  if TryStrToFloat(Edit1.Text,Tempo) then
    begin
      kp:=StrToFloat(Edit1.Text);
      Edit1.Text:=FormatFloat('0.000',kp);
      kp:=StrToFloat(Edit1.Text);
    end
  else
    Edit1.Text:=FormatFloat('0.000',kp);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  timer1.Enabled:=not timer1.Enabled;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin

  Timer1.Enabled:=false;
  Timer2.Enabled:=false;

  Application.ProcessMessages;

  dt:=0.0;
  dt_old:=GetTickCount;

  input:=0.0;
  output:=0.0;
  previous_error:=0;

  proportional:=0.0;
  integral:= 0.0;
  derivative:= 0.0;
  previous_error:=0.0;

  Timer1.Enabled:=true;
  Timer2.Enabled:=true;
end;

procedure TForm1.Edit2EditingDone(Sender: TObject);
var
  Tempo:double;
begin
  if TryStrToFloat(Edit2.Text,Tempo) then
    begin
      ki:=StrToFloat(Edit2.Text);
      Edit2.Text:=FormatFloat('0.000',ki);
      ki:=StrToFloat(Edit2.Text);
    end
  else
    Edit2.Text:=FormatFloat('0.000',ki);
end;

procedure TForm1.Edit3EditingDone(Sender: TObject);
var
  Tempo:double;
begin
  if TryStrToFloat(Edit3.Text,Tempo) then
    begin
      kd:=StrToFloat(Edit3.Text);
      Edit3.Text:=FormatFloat('0.000',kd);
      kd:=StrToFloat(Edit3.Text);
    end
  else
    Edit3.Text:=FormatFloat('0.000',kd);
end;

procedure TForm1.Edit4EditingDone(Sender: TObject);
var
  Tempo:double;
begin
  if TryStrToFloat(Edit4.Text,Tempo) then
    begin
      setpoint:=StrToFloat(Edit4.Text);
      if setpoint > 100.0 then setpoint:=100.0;
      if setpoint < 0.0 then setpoint:=0.0;
      Edit4.Text:=FormatFloat('0.0',setpoint);
      setpoint:=StrToFloat(Edit4.Text);
    end
  else
    Edit4.Text:=FormatFloat('0.0',setpoint);
end;

procedure TForm1.Edit5EditingDone(Sender: TObject);
var
  Tempo:double;
begin
  if TryStrToFloat(Edit5.Text,Tempo) then
    begin
      output:=StrToFloat(Edit5.Text);
      if output > 100.0 then output:=100.0;
      if output < -100.0 then output:= -100.0;
      Edit5.Text:=FormatFloat('0.00000',output);
      output:=StrToFloat(Edit5.Text);
    end
  else
    Edit5.Text:=FormatFloat('0.00000',output);

  EditOutput:=false;
end;

procedure TForm1.Edit5Enter(Sender: TObject);
begin
  EditOutput:=true;
end;

procedure TForm1.Edit5KeyPress(Sender: TObject; var Key: char);
begin
  if (Key = #27) then    //VK_Escape
  begin
    EditOutput := false;
    Edit5.ClearSelection;
    //Edit5.SetFocus:=false;
  end
  else
    EditOutput := true;
end;

procedure TForm1.Edit5MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  EditOutput := true;
end;

procedure TForm1.Edit5MouseEnter(Sender: TObject);
begin

end;

procedure TForm1.Edit5MouseLeave(Sender: TObject);
begin

end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  dt:=(GetTickCount()-dt_old)/1000.00;
  dt_old:=GetTickCount();

  Label2.Caption:='setpoint='+ FormatFloat('0.0',setpoint); //FloatToStr(setpoint);
  Label9.Caption:='kp='; //+FormatFloat('0.000',kp); //FloatToStr(kp);
  Label10.Caption:='ki='; //+FormatFloat('0.000',ki); //FloatToStr(ki);
  Label11.Caption:='kd='; //+FormatFloat('0.000',kd); //FloatToStr(kd);
  Label4.Caption:='output='+FormatFloat('0.00000',output); //FloatToStr(output);
  if not EditOutput then Edit5.Caption:=FormatFloat('0.00000',output);

  Label1.Caption:='dt='+FormatFloat('0.000s.',dt); //FloatToStr(dt);

  Label3.Caption:='input='+FormatFloat('0.0',input); //FloatToStr(input);
  Label5.Caption:='error_='+FormatFloat('0.000',error_); //FloatToStr(error_);

  Label6.Caption:='proportional='+FormatFloat('0.000',proportional); //FloatToStr(proportional);
  Label7.Caption:='integral='+FormatFloat('0.000',integral); //FloatToStr(integral);
  Label8.Caption:='derivative='+FormatFloat('0.000',derivative); //FloatToStr(derivative);

  Label12.Caption:='RandomHardware='+FormatFloat('0.0',RandomHardware);
  Label13.Caption:='RandomStableLost='+FormatFloat('0.000',RandomStableLost*dt);

  //Label12.Caption:='kd='+FormatFloat('0.000',RandomHardware); //FloatToStr(RandomHardware);

  error_:= setpoint-input;

  proportional:=error_;
  integral:= integral+(error_*dt);
  derivative:= (error_-previous_error)/dt;
  previous_error:=error_;

  output:=(kp*proportional)+(ki*integral)+(kd*derivative);

  if output > 100.0 then output:=100.0;
  if output < -100.0 then output:=-100.0;

end;

procedure TForm1.Timer2Timer(Sender: TObject);
begin

  input:=input+(output/RandomHardware);
  input:=input-(RandomStableLost*dt);

  if input > 100.0 then input:=100.0;
  if input < 0.0 then input:=0.0;

  ECProgressBar1.Position:=setpoint;
  ECProgressBar2.Position:=input;
  ECProgressBar3.Position:=output;

  if not timer1.Enabled then
  begin
    Label2.Caption:='setpoint='+ FormatFloat('0.0',setpoint); //FloatToStr(setpoint);
    Label4.Caption:='output='+FormatFloat('0.00000',output);
    if not EditOutput then Edit5.Caption:=FormatFloat('0.00000',output);
  end;
end;

end.

