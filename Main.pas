// ****************************************************************************
//
// Software to make a connection between the Prism astronomical software
// www.hyperion-astronomy.com and the Good Night System (GNS)
// from lunatico.es.
//
// Niklas Storck
// Hallongränd 23, 182 45 Enebyberg, Sweden
// niklas@family-storck.se
//
// 2018-02-02
//
// ****************************************************************************

unit Main;

interface

uses
  ShellApi,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, FolderDialog, Vcl.StdCtrls, Vcl.ExtCtrls,
  W7Classes, W7NaviButtons;

type
  TForm1 = class(TForm)
    OpenDialog1: TOpenDialog;
    EditFolder: TLabeledEdit;
    W7NavigationButton1: TW7NavigationButton;
    Memo1: TMemo;
    Button1: TButton;
    TimerSlow: TTimer;
    LabelInfo: TLabel;
    TimerFast: TTimer;
    procedure W7NavigationButton1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure TimerSlowTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TimerFastTimer(Sender: TObject);
  private
    SLast: String;
    procedure CallGNS(var Return: integer; SNew: string);
    function ObsEnd(SNew: String):Boolean;
    function StripTimeFromString(var STemp: string):String;
    procedure Welcome;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  TimerSlow.Interval:=10000;
  TimerSlow.Enabled:= False;
  Button1.Caption:= 'Run';
  TimerFast.Enabled:=False;
  LabelInfo.caption:='Idle';
  Form1.Caption:='GNS for Prism';
  Form1.Color:=RGB(100,100,100);
  SLast:='';
  LabelInfo.Font.Color:=RGB(255,25,25);
  Welcome;
end;

function TForm1.ObsEnd(SNew:String): Boolean;
// Check if observation has ended by comparing tha string
// with a standarstring.
// Probably I should cahnge this to someting more dynamic
// that the user can change if Prism changes the message.
// It works today.
begin
  ObsEnd:=False;
  if SNew = 'Auto Observations process has been released' then
    ObsEnd:=True
end;

function TForm1.StripTimeFromString(var STemp: string):String;
// Deletes the timestamp from the line.
// This is because it was to much information for GNS to show in
// its main window.
var
  Position: Integer;
begin
  // Extract string after ':' in line
  Position := Pos(':', STemp) + 1; // +1 is to delete the space after ":".
  Delete(STemp, 1, Position);
  Result:=STemp;
end;

procedure TForm1.Welcome;
// Welcome message
begin
  Memo1.Lines.Clear;
  Memo1.Lines.Add('Welcome!');
  Memo1.Lines.Add('');
  Memo1.Lines.Add('1. Start an automatic session with Prism.');
  Memo1.Lines.Add('2. select the new observation logg file. It usually have a name similar to "Obsauto__UTC_2018-02-04__13h31m04s".');
  Memo1.Lines.Add('3. Press <Run>');
  Memo1.Lines.Add('');
  Memo1.Lines.Add('At the moment it is nececcary that GNS is in it''s default directory C:\Program Files (x86)\GNS');
  Memo1.Lines.Add('');
  Memo1.Lines.Add('The software is a tool made for my own use. Its free for anyone to use in their observatory');
  Memo1.Lines.Add('but I can not take any responsibility for any damage to equipment that might happen due');
  Memo1.Lines.Add('to any malfunction of the software.');
  Memo1.Lines.Add('With that said I beleive it to work well.');
  Memo1.Lines.Add('');
  Memo1.Lines.Add('Please drop me a mail if there is some problems: niklas@family-storck.se');
  Memo1.Lines.Add('');
  Memo1.Lines.Add('Clear skies!');
  Memo1.Lines.Add('');
  Memo1.Lines.Add('Niklas Storck');
end;

procedure TForm1.Button1Click(Sender: TObject);
// Switch to handle turn on/off sampling of logfile.
begin
  if TimerSlow.enabled then
  // Turn of
    begin
      TimerSlow.Enabled:= False;
      Button1.Caption:= 'Run';
      TimerFast.Enabled:=False;
      LabelInfo.caption:='Idle';
      LabelInfo.Font.Color:=RGB(255,25,25)

    end
    else
    // Turn on
    begin
      Memo1.Lines.Clear;
      LabelInfo.Font.Color:=RGB(25,255,25);
      Memo1.Lines.Add('Start of sampling at: '+ DateTimeToStr(Now));
      TimerSlow.Enabled:= True;
      Button1.Caption:='Stop';
      TimerFast.Enabled:=True
    end;
end;



procedure TForm1.CallGNS(var Return: integer; SNew: string);
// Calls GNS
// SNew is the Message that is sent
// Return is returncode from ShellExecute. Should be > 32 if ewerything is ok.

var parameters, filename: String;

begin
  Memo1.Lines.Add(SNew);
  filename:='C:\Program Files (x86)\GNS\update.vbs';
  parameters:=' "'+StripTimeFromString(SNew)+'"'+' 120';
  return:=ShellExecute(handle,'open',Pchar(filename),PChar(parameters),'',SW_MINIMIZE);

  if ObsEnd(SNew) then
  // Observation ended ok. Send stop instruction to GNS
  begin
    filename:='C:\Program Files (x86)\GNS\switchoff.vbs';
    return:=ShellExecute(handle,'open',Pchar(filename),'','',SW_MINIMIZE);
    Memo1.Lines.Add('The session has ended. Shutdown is sent to GNS.');
    Button1Click(self);
    LabelInfo.caption:='Ready';
    LabelInfo.Font.Color:=RGB(25,25,255)
  end;
end;

procedure TForm1.TimerFastTimer(Sender: TObject);
// Ticks the clock
begin
  LabelInfo.caption:='Running :'+DateTimeToStr(now)
end;


procedure TForm1.TimerSlowTimer(Sender: TObject);
// Reads the last line of the selected logfile
var F: TextFile;
    SNew, STemp: String;
    return: Integer;
begin
   STemp:='';
   if fileexists(EditFolder.Text) then
     begin

       AssignFile(F,EditFolder.Text);
       Reset(F);
       repeat
         Readln(F,SNew);
       until EOF(F);
       STemp:=Snew;
       if SNew <> SLast then
         begin
          CallGNS(return, SNew);
          if return < 32 then
            Memo1.Lines.Add('Problem with talking to gns. Error: '+ intToStr(Return))
         end;
       SLast:=STemp;
       CloseFile(F)
     end
   else
     begin
       Memo1.Lines.Add('File '+EditFolder.Text+' not found!');
       Memo1.Lines.Add('Session ended!');
       Button1Click(self);
     end;
end;

procedure TForm1.W7NavigationButton1Click(Sender: TObject);
// Select file to read
begin
  if OpenDialog1.execute then
    EditFolder.Text:= OpenDialog1.FileName;
end;

end.
