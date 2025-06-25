unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Menus, TASources, TAGraph, ECProgressBar, NumberEdit, math, TASeries,
  TAChartUtils, windows, LazUTF8, unit2;

function DwmGetWindowAttribute(hwnd: HWND; dwAttribute: DWORD; pvAttribute: PVOID; cbAttribute: DWORD): HRESULT; stdcall; external 'dwmapi.dll';

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    ChartForceManual: TChart;
    ChartForceManualLineSeries5: TLineSeries;
    ChartMenu: TPopupMenu;
    ChartRefreshMenu: TMenuItem;
    ChartZoomOutMenu: TMenuItem;
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
    Label16: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    ListChartSource5: TListChartSource;
    Memo1: TMemo;
    OpenSaveFolder: TMenuItem;
    SavePara: TMenuItem;
    Splitter1: TSplitter;
    SSC: TMenuItem;
    Timer1: TTimer;
    Timer2: TTimer;
    Timer3: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ChartForceManualClick(Sender: TObject);
    procedure ChartForceManualDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure ChartForceManualMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ChartForceManualMouseEnter(Sender: TObject);
    procedure ChartForceManualMouseLeave(Sender: TObject);
    procedure ChartRefreshMenuClick(Sender: TObject);
    procedure ChartZoomOutMenuClick(Sender: TObject);
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
    procedure OpenSaveFolderClick(Sender: TObject);
    procedure SaveParaClick(Sender: TObject);
    procedure SSCClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure Timer3Timer(Sender: TObject);
  private

  public
    function get_ss_of(window: hwnd; var bmp: graphics.TBitmap): integer;
    Function CheckDirectory(C_DNAME: string;Debug_:TMemo):boolean;
  end;
//https://www.robotsforroboticists.com/pid-control/
var
  Form1: TForm1;
  EditOutput:boolean;
  StopCal:boolean;
  ChartSimulate:boolean;
  Directory_:string;
  FileName_:string;

  Chart_Enter:boolean;
  Chatr_Zoom:integer;

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
Function TForm1.CheckDirectory(C_DNAME: string;Debug_:TMemo):boolean; //True=Error
var
  tfOut: TextFile;
begin
  result:= false;

  if(C_DNAME<>'')then
  if Not DirectoryExists(C_DNAME) Then
  begin
    {$I-}
    //{$I-} or {$IOCHECKS OFF}
    //{$I-} rewrite (f); {$I+}
    //if IOResult<>0 then begin Writeln ('Error opening file: "file.txt"'); exit; end;
    mkdir(C_DNAME);
    {$I+}
    if IOResult<>0 then
    begin
      Debug_.Append('Directory '+C_DNAME+' error occurred. Details: '+ EInOutError.ClassName);
      ShowMessage('Cannot create '+C_DNAME+' directory. Details: '+ EInOutError.ClassName);
      result:= true;
    end;
  end;

end;

function TForm1.get_ss_of(window: hwnd; var bmp: graphics.TBitmap): integer;
var
  outer: TRect;
  dc: HDC;
begin
  result := 0; // 0 = success
  if not IsWindow(window) then exit(1);
  if not (DwmGetWindowAttribute(window, 9{DWMWA_EXTENDED_FRAME_BOUNDS}, @outer, sizeof(outer)) = S_OK) then exit(2);
  bmp.Width := outer.Width;
  bmp.Height := outer.Height;
  bmp.PixelFormat := pf24bit;
  dc := GetDC(GetDesktopWindow);
  bmp.BeginUpdate(true);
  if not BitBlt(bmp.Canvas.Handle, 0, 0, outer.Width, outer.Height, dc, outer.Left, outer.Top, SRCCOPY) then result := 3;
  bmp.EndUpdate(true);
  bmp.Canvas.Changed;
  ReleaseDC(GetDesktopWindow, dc);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin

  Chart_Enter:=false;
  ChartForceManual.Tag :=0;
  Chatr_Zoom:=0;

  EditOutput:=false;
  StopCal:=false;
  ChartSimulate:=false;

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

procedure TForm1.OpenSaveFolderClick(Sender: TObject);
begin
  //Directory_
  //FileName_
  //SysUtils.ExecuteProcess(UTF8ToSys('explorer.exe'), '/select,C:\Windows\explorer.exe', []);
  SysUtils.ExecuteProcess(UTF8ToSys('explorer.exe'), '/select,'+FormatDateTime('MM YYYY',Now), []);
end;

procedure TForm1.SaveParaClick(Sender: TObject);
var
  i:integer;
  //MaxRecordTime:integer;
  //Txt:String;
  fileout : TextFile;
  S_Name:string;
  File_OK:Boolean;

begin

  if (FormatDateTime('MM YYYY',Now)<>Directory_) then
  begin
    Directory_:=FormatDateTime('MM YYYY',Now); FileName_:= Directory_+'\'+FormatDateTime('DD MM YYYY hh nn ss',Now)+'.CSV';
  end;
  if CheckDirectory(Directory_,Memo1) then begin showmessage('Unable to save file'); Exit; end;

  S_Name:=Directory_+'\'+FormatDateTime('DD MM YYYY hh nn ss',Now)+'.CSV';
  i:=0;
  File_OK:=True;

  try
    AssignFile(fileout, S_Name);
  except
    on E: EInOutError do
    begin
      //showmessage('AssignFile: '+E.ClassName+'/'+ E.Message+'/'+IntToStr(E.ErrorCode));
      File_OK:=False;
    end;
  end;

  //if File_OK then showmessage('File_OK=OK');
  //if not File_OK then showmessage('File_OK=not OK');
  //Timer3.Enabled:=False;

  while((File_OK = False) and (i<100)) do
  begin
    i:=i+1;
    S_Name:=Directory_+'\'+FormatDateTime('DD MM YYYY hh nn ss',Now)+'_'+IntToStr(i)+'.CSV';
    File_OK:=True;
    try
      AssignFile(fileout, S_Name);
    except
      on E: EInOutError do
      begin
        //showmessage('AssignFile: '+E.ClassName+'/'+ E.Message+'/'+IntToStr(E.ErrorCode));
        File_OK:=False;
      end;
    end;
  end;

   try
     Append(fileout);
   except
     //on E: EInOutError do
     //showmessage('Append: '+E.ClassName+'/'+ E.Message+'/'+IntToStr(E.ErrorCode));
     on E: EInOutError do
     try
       rewrite (fileout);
       writeln(fileout, 'TimeStamp='+FormatDateTime('DD MM YYYY hh nn ss',Now)+',-,-,-,-');
       writeln(fileout, 'kp='+FormatFloat('0.000',kp)+',-,-,-,-');
       writeln(fileout, 'ki='+FormatFloat('0.000',ki)+',-,-,-,-');
       writeln(fileout, 'kd='+FormatFloat('0.000',kd)+',-,-,-,-');
       writeln(fileout, 'setpoint='+FormatFloat('0.0',setpoint)+',-,-,-,-');
       writeln(fileout, 'output='+FormatFloat('0.00000',output)+',-,-,-,-');
     except
       //on E: EInOutError do
       //showmessage('Append: '+E.ClassName+'/'+ E.Message+'/'+IntToStr(E.ErrorCode));
     end;
   end;

   CloseFile(fileout);
end;

procedure TForm1.SSCClick(Sender: TObject);
var
  bmp: graphics.TBitmap;
  i:integer;
begin
  if (FormatDateTime('MM YYYY',Now)<>Directory_) then
  begin
    Directory_:=FormatDateTime('MM YYYY',Now); FileName_:= Directory_+'\'+FormatDateTime('DD MM YYYY hh nn ss',Now)+'.bmp';
  end;
  if CheckDirectory(Directory_,Memo1) then begin showmessage('Unable to save file'); Exit; end;

  try
    bmp := graphics.TBitmap.Create;
    for i:=1 to 1000 do
    begin
      Application.ProcessMessages
    end;
    if get_ss_of(Form1.Handle, bmp) = 0 then
    begin
      // display on TImage
      //image1.Picture.Assign(bmp);
      // or save to file
      FileName_:= Directory_+'\'+FormatDateTime('DD MM YYYY hh nn ss',Now)+'.bmp';
      bmp.SaveToFile(FileName_);
    end;
  finally
    bmp.Free;
  end;
  //ScreenshotToFile('123.bmp',0);
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
  StopCal:=not StopCal;
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

procedure TForm1.Button3Click(Sender: TObject);
begin
  Form2.Show;
end;

procedure TForm1.ChartForceManualClick(Sender: TObject);
begin
  ChartForceManual.Tag :=1;
end;

procedure TForm1.ChartForceManualDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
  ChartForceManual.Tag :=1;
end;

procedure TForm1.ChartForceManualMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  ChartForceManual.Tag :=1;
end;

procedure TForm1.ChartForceManualMouseEnter(Sender: TObject);
begin
  Chart_Enter:=true;
end;

procedure TForm1.ChartForceManualMouseLeave(Sender: TObject);
begin
  Chart_Enter:=true;
end;

procedure TForm1.ChartRefreshMenuClick(Sender: TObject);
begin
  ChartForceManual.Tag:=0;
  Chatr_Zoom:=0;
end;

procedure TForm1.ChartZoomOutMenuClick(Sender: TObject);
var
  AC: TDoublePoint;
  AZ: TDoubleRect;
begin
  ChartForceManual.Tag:=1;
  AC:=ChartForceManual.LogicalExtent.a;
  AC.X:=AC.X-2;
  AC.Y:=AC.Y-2;
  AZ.a:=AC;
  AC:=ChartForceManual.LogicalExtent.b;
  AC.X:=AC.X+2;
  AC.Y:=AC.Y+2;
  AZ.b:=AC;
  ChartForceManual.LogicalExtent:=AZ;
  Chatr_Zoom:=Chatr_Zoom-5;
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
      Label2.Caption:='setpoint='+ FormatFloat('0.0',setpoint);
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
      Label4.Caption:='output='+FormatFloat('0.00000',output);
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
  dt:=(GetTickCount-dt_old)/1000.00;
  dt:=0.109;  //Fix bug  GetTickCount
  dt_old:=GetTickCount;
  if StopCal then exit;
  Label2.Caption:='setpoint='+ FormatFloat('0.0',setpoint); //FloatToStr(setpoint);
  Label9.Caption:='kp='; //+FormatFloat('0.000',kp); //FloatToStr(kp);
  Label10.Caption:='ki='; //+FormatFloat('0.000',ki); //FloatToStr(ki);
  Label11.Caption:='kd='; //+FormatFloat('0.000',kd); //FloatToStr(kd);
  Label4.Caption:='output='+FormatFloat('0.00000',output); //FloatToStr(output);
  if not EditOutput then Edit5.Caption:=FormatFloat('0.00000',output);

  Label1.Caption:='dt='+FormatFloat('0.000s.',dt); //FloatToStr(dt);

  Label3.Caption:='input(Actual)='+FormatFloat('0.0',input); //FloatToStr(input);
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

  if Form2.Active then
  begin
    Form2.Label20.Caption:=FormatFloat('0.000',error_)+'='+FormatFloat('0.0',setpoint)+'-'+FormatFloat('0.0',input);
    Form2.Label21.Caption:=FormatFloat('0.000',integral)+'='+FormatFloat('0.000',integral)+'+'+FormatFloat('0.000',error_)+'*'+FormatFloat('0.000s.',dt);
    Form2.Label22.Caption:=FormatFloat('0.000s.',dt)+'=('+IntToStr(GetTickCount)+'-'+IntToStr(dt_old)+')/'+FormatFloat('0.000ms.',1000.00);
    Form2.Label23.Caption:=FormatFloat('0.00000',output)+'=('+FormatFloat('0.000',kp)+'*'+FormatFloat('0.000',error_)+')+('+FormatFloat('0.000',ki)+'*'+FormatFloat('0.000',integral)+')+('+FormatFloat('0.000',kd)+'*'+FormatFloat('0.000s.',dt)+')+0';
  end;
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

procedure TForm1.Timer3Timer(Sender: TObject);
var
  i:integer;
  MaxRecordTime:integer;
  Txt:String;
  Ra:Double;

begin
   Randomize();

  MaxRecordTime:=60*60*12;
  if ListChartSource5.Count >= MaxRecordTime then
  begin
    for i:=0 to MaxRecordTime-2 do
    begin
      //ListChartSource1.Item[i]^.Y:=ListChartSource1.Item[i+1]^.Y;
      //ListChartSource1.Item[i]^.Text:=ListChartSource1.Item[i+1]^.Text;

      //ListChartSource4.Item[i]^.Y:=ListChartSource4.Item[i+1]^.Y;
      //ListChartSource4.Item[i]^.Text:=ListChartSource4.Item[i+1]^.Text;

      ListChartSource5.Item[i]^.Y:=ListChartSource5.Item[i+1]^.Y;
      ListChartSource5.Item[i]^.Text:=ListChartSource5.Item[i+1]^.Text;

    end;
    //ListChartSource1.Delete(MaxRecordTime-1);
    //ListChartSource4.Delete(MaxRecordTime-1);
    ListChartSource5.Delete(MaxRecordTime-1);
  end;


  Txt:=FormatDateTime('hh',  Now)+':'+FormatDateTime('nn',  Now)+':'+FormatDateTime('ss',  Now);


  Ra:= input;
  if ChartSimulate then Ra:= Int(Random(1*1000));
  //if ChartForceManual.Extent.YMax<Ra then ChartForceManual.Extent.YMax:=Ra+1;
  //if ChartForceManual.Extent.YMin>Ra then ChartForceManual.Extent.YMin:=Ra-1;
  if ChartForceManual.Extent.YMax < Ra+2 then
    begin
      ChartForceManual.Extent.YMax := Ra+2;
      ChartForceManual.ExtentSizeLimit.YMax:= Ra+2; ;
    end;
    if ChartForceManual.Extent.YMin > Ra-1 then
    begin
      ChartForceManual.Extent.YMin := Ra-1;
      ChartForceManual.ExtentSizeLimit.YMin:= Ra-1; ;
    end;
  if ListChartSource5.Count < MaxRecordTime then ListChartSource5.Add(ListChartSource5.Count,Ra,Txt,clRed);

If (ListChartSource5.Count>240) and (ChartForceManual.Tag = 0) then
  begin
    ChartForceManual.BottomAxis.Range.Max:=ListChartSource5.Count;
    //ChartForceManual.BottomAxis.Range.UseMax:=True;
    ChartForceManual.BottomAxis.Range.Min:=ListChartSource5.Count-240;
    //ChartForceManual.BottomAxis.Range.UseMin:=True;
    ChartForceManual.Extent.XMin:=ListChartSource5.Count-240;  ChartForceManual.Extent.XMax:=ListChartSource5.Count;
  end;
  If (ListChartSource5.Count<=240) and (ChartForceManual.Tag = 0) then
  begin
    if(ListChartSource5.Count<=60)then
    ChartForceManual.BottomAxis.Range.Max:=60;
    if(ListChartSource5.Count>60)then
    ChartForceManual.BottomAxis.Range.Max:=ListChartSource5.Count;
    ChartForceManual.BottomAxis.Range.Min:=0;
    ChartForceManual.Extent.XMin:=0;
    if(ListChartSource5.Count<=60)then
    ChartForceManual.Extent.XMax:=60;
    if(ListChartSource5.Count>60)then
    ChartForceManual.Extent.XMax:=ListChartSource5.Count;
  end;

end;

end.

