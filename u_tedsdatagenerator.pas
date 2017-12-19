{
   Teds Tremendous Data Generator is a cross platform data generating tool for
   Linux, Windows and Apple Mac. It was created to assist with the development of
   QuickHash-GUI (www.quickhash-gui.org). But it seems too useful not to make
   available to others.

   Contributions from members at the Lazarus forums, Stackoverflow and other
   StackExchnage groups are welcomed and acknowledged.

   Copyright (C) 2017-2018  Ted Smith www.quickhash-gui.org

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   any later version. You are not granted permission to create
   another data generating tool of the same name.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   }
unit u_tedsdatagenerator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, ExtCtrls, Buttons, Menus, sha1;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnGenerateStringData: TButton;
    btnOutputFolder: TButton;
    btnGenerateFiles: TButton;
    btnFilesStop: TButton;
    btnSaveTextToFile: TButton;
    btnClear: TButton;
    cbStringType: TComboBox;
    cbFileSize: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    lblStartTime: TLabel;
    lblEndTime: TLabel;
    lblTimeTaken: TLabel;
    lblFilesCreated: TLabel;
    lbledtNoOfFiles: TLabeledEdit;
    lbledtFileSize: TLabeledEdit;
    lbledtOutputPath: TLabeledEdit;
    lblStatus: TLabel;
    lbledtHowManyLines: TLabeledEdit;
    ledtOwnString: TLabeledEdit;
    memTextOutput: TMemo;
    PageControl1: TPageControl;
    Panel1: TPanel;
    pbFiles: TProgressBar;
    sdSaveText: TSaveDialog;
    RadioGroup1: TRadioGroup;
    SelectOutputFolder: TSelectDirectoryDialog;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    StopCheckTimer: TTimer;
    procedure btnClearClick(Sender: TObject);
    procedure btnFilesStopClick(Sender: TObject);
    procedure btnGenerateStringDataClick(Sender: TObject);
    procedure btnOutputFolderClick(Sender: TObject);
    procedure btnGenerateFilesClick(Sender: TObject);
    procedure btnSaveTextToFileClick(Sender: TObject);
    procedure cbStringTypeChange(Sender: TObject);
    procedure cbFileSizeChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    function FormatByteSize(const bytes: QWord): string;
    procedure menSaveTextToFileClick(Sender: TObject);
    procedure StopCheckTimerTimer(Sender: TObject);
    function CreateBytesNonRandomFile(const aName: string; aSize: Int64; Buffer : array of byte): Boolean;
    function CreateBytesRandomFile (const aName: string; aSize: Int64): Boolean;
    function CreateKbNonRandomFile(const aName: string; aSize: Int64; Buffer : array of byte): Boolean;
    function CreateKBRandomFile (const aName: string; aSize: Int64): Boolean;
    function CreateBigNonRandomFile(const aName: string; aSize: Int64; Buffer : array of byte): Boolean;
    function CreateBigRandomFile(const aName: string; aSize: Int64): Boolean;
  private
    { private declarations }
  public
    FileSizeNeeded : QWord;
    usersselection_files : string;
    StopGenerating : boolean; // Goes to true if user clicks button
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  // Set "random string" as the default text option
  cbStringType.ItemIndex := 1;
  // Set Kb as the default file size option
  cbFileSize.ItemIndex := 1;
  FileSizeNeeded := strtoint(lbledtFileSize.Text);
  // Refresh the label for the default selection of the file tab
  cbFileSizeChange(nil);
  // Set StopGenerating to false;
  StopGenerating := false;
  // Start the application refresh timer
  StopCheckTimer.Enabled:= true;
  // Set default radio button
  RadioGroup1.ItemIndex := 0; // Non-random
  // Set default file size type (Kb, Mb, Gb etc)
  cbFileSize.ItemIndex := 1; //Kb
  // Set default output path
  lbledtOutputPath.Text := GetCurrentDir;
  // Disable text Save As button
  btnSaveTextToFile.Enabled := false;
end;


procedure TForm1.btnGenerateStringDataClick(Sender: TObject);
var
  sl : TStringList;
  NoOfLines, ProgressCounter : integer;
  i : DWord;
  ownstring, RandomStringA, RandomStringB, StringToWrite, usersselection : string;
  fs : TFileStream;
begin
  memTextOutput.Clear;
  i := 0;
  ProgressCounter := 0;
  btnSaveTextToFile.Enabled := false;
  NoOfLines := StrToInt(lbledtHowManyLines.Text);

  Randomize; // <-- Very important to ensure Random() gets a jolly good seeding

  case cbStringType.ItemIndex of
  0: usersselection := 'ownstring';
  1: usersselection := 'randomstrings';
  2: usersselection := 'linenumbers';
  end;

  if usersselection = 'ownstring' then
  begin
    if NoOfLines <= 1000000 then
    try
      ownstring := ledtOwnString.Text;
      sl := TStringList.Create;
      sl.Sorted := false;
      for i := 1 to NoOfLines do
      begin
        sl.Add(ownstring);
      end;
      memTextOutput.lines.Assign(sl) ;
      memTextOutput.Lines.Add(IntToStr(i) + ' lines added.');
    finally
      sl.free;
    end;

    if NoOfLines > 1000000 then
    try
      fs := TFileStream.Create('datadump_ownstring.txt', fmCreate);
      ownstring := ledtOwnString.Text;
      memTextOutput.Lines.Add('Attempting to write ' + IntToStr(NoOfLines) + ' of your string to ' + fs.FileName);
      memTextOutput.Lines.Add('Please wait...');

      for i := 1 to NoOfLines do
      begin
        StringToWrite := ownstring + #13#10;
        fs.Write(StringToWrite[1], Length(StringToWrite));
        // Refresh interface every 3K writes
        inc(ProgressCounter, 1);
        if ProgressCounter = 10000 then
        begin
          ProgressCounter := 0;
          lblStatus.Caption := 'Output file = ' + IntToStr(i) + ' lines so far...';
          Application.ProcessMessages;
        end;
      end;
    finally
      lblStatus.Caption := (IntToStr(NoOfLines) + ' lines of random data written to ' + fs.FileName);
      fs.free;
      memTextOutput.Clear;
      memTextOutput.Lines.Add('Finished.');
    end;
  end;

  if usersselection = 'randomstrings' then
  begin
    if NoOfLines <= 1000000 then
    try
      sl := TStringList.Create;
      sl.Sorted := false;
      for i := 1 to NoOfLines do
      begin
        randomstringA := IntToStr(Random(100000000));
        randomStringB := sha1Print(sha1string(RandomStringA));
        sl.Add(randomstringA+RandomStringB);
      end;
      memTextOutput.lines.Assign(sl);
      memTextOutput.Lines.Add(IntToStr(i) + ' lines added.');
    finally
      sl.free;
    end;

    if NoOfLines > 1000000 then
    try
      fs := TFileStream.Create('datadump.txt', fmCreate);
      memTextOutput.Lines.Add('Attempting to write ' + IntToStr(NoOfLines) + ' lines of random data to ' + fs.FileName);
      memTextOutput.Lines.Add('Please wait...');

      for i := 1 to NoOfLines do
      begin
        randomStringA := '';
        randomStringB := '';
        StringToWrite := '';
        randomstringA := IntToStr(Random(100000000));
        randomStringB := sha1Print(sha1string(RandomStringA));
        StringToWrite := RandomStringA + RandomStringB + #13#10;
        fs.Write(StringToWrite[1], Length(StringToWrite));
        // Refresh interface every 10K writes
        inc(ProgressCounter, 1);
        if ProgressCounter = 10000 then
        begin
          ProgressCounter := 0;
          lblStatus.Caption := 'Output file = ' + IntToStr(i) + ' lines so far...';
          Application.ProcessMessages;
        end;
      end;
    finally
      lblStatus.Caption := (IntToStr(NoOfLines) + ' lines of random data written to ' + fs.FileName);
      memTextOutput.Clear;
      memTextOutput.Lines.Add('Finished.');
      fs.free;
    end;
  end;

  if usersselection = 'linenumbers' then
  begin
    if NoOfLines <= 1000000 then
    try
      sl := TStringList.Create;
      sl.Sorted := false;
      for i := 1 to NoOfLines do
      begin
        sl.Add(IntToStr(i));
      end;
      memTextOutput.lines.Assign(sl) ;
      memTextOutput.Lines.Add(IntToStr(i) + ' lines added.');
    finally
      sl.free;
    end;

    if NoOfLines > 1000000 then
    try
      fs := TFileStream.Create('datadump_linenumbers.txt', fmCreate);
      memTextOutput.Lines.Add('Attempting to write ' + IntToStr(NoOfLines) + ' line numbers to ' + fs.FileName);
      memTextOutput.Lines.Add('Please wait...');
      for i := 1 to NoOfLines do
      begin
        StringToWrite := IntToStr(i) + #13#10;
        fs.Write(StringToWrite[1], Length(StringToWrite));
        // Refresh interface every 10K writes
        inc(ProgressCounter, 1);
        if ProgressCounter = 10000 then
        begin
          ProgressCounter := 0;
          lblStatus.Caption := ('Output file = ' + IntToStr(i) + ' lines so far...');
          Application.ProcessMessages;
        end;
      end;
    finally
      lblStatus.Caption := (IntToStr(NoOfLines) + ' lines written to ' + fs.FileName);
      memTextOutput.Clear;
      memTextOutput.Lines.Add('Finished.');
      fs.free;
    end;
  end;
  btnSaveTextToFile.Enabled := true;
end;

procedure TForm1.btnFilesStopClick(Sender: TObject);
begin
  StopGenerating := true;
  Application.ProcessMessages;
end;

// Empty the text window
procedure TForm1.btnClearClick(Sender: TObject);
begin
  memTextOutput.Clear;
end;

procedure TForm1.btnOutputFolderClick(Sender: TObject);
begin
  if SelectOutputFolder.Execute then lbledtOutputPath.Text:= SelectOutputFolder.filename;
end;


procedure TForm1.menSaveTextToFileClick(Sender: TObject);
begin

end;

procedure TForm1.StopCheckTimerTimer(Sender: TObject);
begin
  // Every second or so, refresh the interface to keep it responsive
  Application.ProcessMessages;
end;

procedure TForm1.btnGenerateFilesClick(Sender: TObject);
var
  FileCountNeeded, i : integer;
  OutputFolder, DateAndTimeNow,   Filename : string;
  ByteBuffer : Byte ;                       // Byte Buffer - the smallest tiny buf;
  KbBuffer   : array [0..1023] of byte;     // Kb Buffer   - the perfect Goldilox buf
  MbBuffer   : array [0..1048575] of byte;  // Mb Buffer   - the biggest bravest buff
  StartTime, EndTime : TDateTime;
begin
  cbFileSizeChange(nil);
  FileCountNeeded :=  strtoint(lbledtNoOfFiles.Text);

  OutputFolder    := IncludeTrailingBackslash(lbledtOutputPath.Text);
  // Just in case the user manually types the path to a folder instead of using
  // the button to change from the default location. It seems despite adding a button
  // to make this easy, folk still enjoy typing or pasting.
  if not DirectoryExists(OutputFolder) then
  begin
    if not ForceDirectories(OutputFolder) then ShowMessage(OutputFolder + ' could not be created.');
  end;

  // Generate a randomised seed for Random to use
  Randomize;    // <-- Very important to ensure Random() gets a jolly good seeding

  // Reset variables
  i := 0;
  pbFiles.Position:= 0;
  lblFilesCreated.Caption:= 'Generating data...please wait';
  lblStartTime.Caption := '...';
  lblEndTime.Caption   := '...';
  lblTimeTaken.Caption := '...';

  // Record start time
  StartTime := Now;
  lblStartTime.Caption:= FormatDateTime('YYYY-MM-DD HH:MM:SS', StartTime);
  Application.ProcessMessages;

  // Create multiple Byte sized files
  if usersselection_files = 'b' then
  begin
    if RadioGroup1.ItemIndex = 0 then    // Non random selected
    begin
      ByteBuffer := $FF;                 // Fill memory buffer with 1 byte of 0xFF
      for i := 1 to FileCountNeeded do
      begin
        if StopGenerating = false then
        begin
          lblFilesCreated.Caption:= IntToStr(i) + ' files created...';
          lblFilesCreated.Refresh;
          DateAndTimeNow := FormatDateTime('YYYY-MM-DD-HH-MM-SS', Now);
          Filename := OutputFolder+DateAndTimeNow+'-'+IntToStr(i)+'.raw';
          CreateBytesNonRandomFile(Filename, FileSizeNeeded, ByteBuffer);
          pbFiles.Position:= ((i * 100) DIV FileCountNeeded);
          Application.ProcessMessages;
        end;
      end;
    end // End of radio group
      else                             // Random selected
      for i := 1 to FileCountNeeded do
      begin
        if StopGenerating = false then
        begin
          lblFilesCreated.Caption:= IntToStr(i) + ' files created...';
          lblFilesCreated.Refresh;
          DateAndTimeNow := FormatDateTime('YYYY-MM-DD-HH-MM-SS', Now);
          Filename := OutputFolder+DateAndTimeNow+'-'+IntToStr(i)+'.raw';
          CreateBytesRandomFile(Filename, FileSizeNeeded);
          pbFiles.Position:= ((i * 100) DIV FileCountNeeded);
          Application.ProcessMessages;
        end;
      end;
  end;

  // Create multiple Kb sized files
  if usersselection_files = 'Kb' then
  begin
    if RadioGroup1.ItemIndex = 0 then   // Non random selected
    begin
      FillChar(KbBuffer, SizeOf(KbBuffer), $FF);  // Fill memory buffer with 1Kb of 0xFF
      for i := 1 to FileCountNeeded do
      begin
        if StopGenerating = false then
        begin
          lblFilesCreated.Caption:= IntToStr(i) + ' files created...';
          lblFilesCreated.Refresh;
          DateAndTimeNow := FormatDateTime('YYYY-MM-DD-HH-MM-SS', Now);
          Filename := OutputFolder+DateAndTimeNow+'-'+IntToStr(i)+'.raw';
          CreateKbNonRandomFile(Filename, FileSizeNeeded, KbBuffer);
          pbFiles.Position:= ((i * 100) DIV FileCountNeeded);
          Application.ProcessMessages;
        end;
      end;
    end // End of radio group
      else                              // Random selected
      for i := 1 to FileCountNeeded do
      begin
        if StopGenerating = false then
        begin
          lblFilesCreated.Caption:= IntToStr(i) + ' files created...';
          lblFilesCreated.Refresh;
          DateAndTimeNow := FormatDateTime('YYYY-MM-DD-HH-MM-SS', Now);
          Filename := OutputFolder+DateAndTimeNow+'-'+IntToStr(i)+'.raw';
          CreateKbRandomFile(Filename, FileSizeNeeded);
          pbFiles.Position:= ((i * 100) DIV FileCountNeeded);
          Application.ProcessMessages;
        end;
      end;
  end;

  // Create multiple Mb, Gb, or even Tb files. Upwards of Mb, not practical to create
  // memory buffers of hundfreds of Mb or even Gb, so buffer size becomes multiple
  // of 1Mb until required filesize is reached.

    if (usersselection_files = 'Mb') or (usersselection_files = 'Gb') or (usersselection_files = 'Tb') then
    begin
      if RadioGroup1.ItemIndex = 0 then    // Non random selected
      begin
        FillChar(MbBuffer, SizeOf(MbBuffer), $FF); // Fill 1Mb memory buffer with 1Mb of 0xFF
        for i := 1 to FileCountNeeded do
        begin
          if StopGenerating = false then
          begin
            lblFilesCreated.Caption:= IntToStr(i) + ' files created...';
            lblFilesCreated.Refresh;
            DateAndTimeNow := FormatDateTime('YYYY-MM-DD-HH-MM-SS', Now);
            Filename := OutputFolder+DateAndTimeNow+'-'+IntToStr(i)+'.raw';
            CreateBigNonRandomFile(Filename, FileSizeNeeded, MbBuffer);
            pbFiles.Position:= ((i * 100) DIV FileCountNeeded);
            Application.ProcessMessages;
          end;
        end;
      end // End of radio group
        else                              // Random selected
        for i := 1 to FileCountNeeded do
        begin
          if StopGenerating = false then
          begin
            lblFilesCreated.Caption:= IntToStr(i) + ' files created...';
            lblFilesCreated.Refresh;
            DateAndTimeNow := FormatDateTime('YYYY-MM-DD-HH-MM-SS', Now);
            Filename := OutputFolder+DateAndTimeNow+'-'+IntToStr(i)+'.raw';
            CreateBigRandomFile(Filename, FileSizeNeeded);
            pbFiles.Position:= ((i * 100) DIV FileCountNeeded);
            Application.ProcessMessages;
          end;
        end;
    end;

    // If the user has not aborted the data generation, report the end result
    // Otherwise, state the date and time the process was aborted.
    if StopGenerating = false then
    begin
      EndTime := Now;
      lblFilesCreated.Caption := IntToStr(i) + ' files created. Finished';
    end
    else
    begin
      EndTime := Now;
      lblFilesCreated.Caption := 'Process aborted by user at ' + FormatDateTime('YYYY-MM-DD HH:MM:SS', EndTime);
    end;

    // Format the time taken as days, hours, minutes, seconds and milliseconds
    lblTimeTaken.caption := (Format('%d days %s', [trunc(EndTime-StartTime), FormatDateTime('h" hrs, "n" min, "s" sec (and "ms" ms)"', EndTime-StartTime)]));
    lblEndTime.Caption:= FormatDateTime('YYYY-MM-DD HH:MM:SS', EndTime);
  end;

// Save text output to a file.
procedure TForm1.btnSaveTextToFileClick(Sender: TObject);
var
  fs : TFileStream;
  i : integer;
  TextToWrite : string;
begin
  sdSaveText.Title := 'Save text box as...';
  sdSaveText.InitialDir := GetCurrentDir;
  sdSaveText.Filter := 'Text|*.txt';
  sdSaveText.DefaultExt := 'txt';

  if sdSaveText.Execute then
  try
    fs := TFileStream.Create(sdSaveText.FileName, fmCreate);
    for i := 0 to memTextOutput.Lines.Count -1 do
    begin
      TextToWrite := memTextOutput.Lines.Strings[i] + #13#10;
      fs.Write(TextToWrite[1], Length(TextToWrite));
    end;
    fs.free;
  finally
    ShowMessage(sdSaveText.FileName + ' saved OK');
  end;
end;

// Create a non-random file that is bytes in size. Buffer passed should be 1 byte
function TForm1.CreateBytesNonRandomFile(const aName: string; aSize: Int64; Buffer : array of byte): Boolean;
var
  fs : TFileStream;
  BytesWritten : integer;
begin
  result := false;
  BytesWritten := -1;
  try
  fs := TFileStream.Create(aName, fmCreate);
  repeat
    BytesWritten := fs.Write(Buffer, SizeOf(Buffer));
      if BytesWritten = -1 then
        begin
          RaiseLastOSError;
          exit;
        end;
  until (fs.Size >= aSize) or (StopGenerating = true);
  fs.Free;
  finally
    result := true;
  end;
end;

// Create a random file that is bytes in size. No Buffer
function TForm1.CreateBytesRandomFile (const aName: string; aSize: Int64): Boolean;
const
  smalldata = High(Byte);
var
  fs : TFileStream;
begin
  result := false;
  try
    fs := TFileStream.Create(aName, fmCreate);
    repeat
      fs.WriteByte(Random(smalldata));
    until (fs.Size >= aSize) or (StopGenerating = true);
    fs.Free;
  finally
    result := true;
  end;
end;
// Create a non-random file that is Kbytes in size. Buffer passed should be 1Kb
function TForm1.CreateKbNonRandomFile(const aName: string; aSize: Int64; Buffer : array of byte): Boolean;
var
  fs : TFileStream;
  BytesWritten : integer;
begin
  BytesWritten := -1;
  result := false;
  try
  fs := TFileStream.Create(aName, fmCreate);
  repeat
    BytesWritten := fs.Write(Buffer, SizeOf(Buffer));
      if BytesWritten = -1 then
        begin
          RaiseLastOSError;
          exit;
        end;
  until (fs.Size >= aSize) or (StopGenerating = true);
  fs.Free;
  finally
    result := true;
  end;
end;

// Create a random file that is Kbytes in size. No Buffer
function TForm1.CreateKBRandomFile (const aName: string; aSize: Int64): Boolean;
var
  KbBuffer   : array [0..1023] of byte;
  i : integer;
  fs : TFileStream;
begin
  result := false;
  // Fill the 1Kb buffer with a thousand random bytes
  // Randomize is called once, above, and creates the seeding needed for better randomness
  For i := 0 to 1023 do
  begin
    KBBuffer[i] := Random(255);
  end;

  try
    fs := TFileStream.Create(aName, fmCreate);
    repeat
      fs.Write(KBBuffer, SizeOf(KbBuffer));
    until (fs.Size >= aSize) or (StopGenerating = true);
    fs.Free;
  finally
    result := true;
  end;
 end;

// Create a non-random file that is Mbytes in size. Buffer passed should be 1Mb
function TForm1.CreateBigNonRandomFile(const aName: string; aSize: Int64; Buffer : array of byte): Boolean;
var
  fs : TFileStream;
  BytesWritten : integer;
begin
  BytesWritten := -1;
  result := false;
  try
    fs := TFileStream.Create(aName, fmCreate);
    repeat
      BytesWritten := fs.Write(Buffer, SizeOf(Buffer)); // Should be a 1Mb Buffer
        if BytesWritten = -1 then
          begin
            RaiseLastOSError;
            exit;
          end
      until (fs.Size >= aSize) or (StopGenerating = true);
      fs.Free;
  finally
    result := true;
  end;
end;

// Create a big random file that is Mb, Gb or Tb in size. Slow
function TForm1.CreateBigRandomFile(const aName: string; aSize: Int64): Boolean;
var
  MbBuffer   : array [0..1048575] of byte;
  i : integer;
  fs : TFileStream;
begin
  result := false;
  // Fill the 1Mb buffer with a million random bytes
  // Randomize is called once, above, and creates the seeding needed for better randomness
  For i := 0 to 1048576 do
  begin
    MBBuffer[i] := Random(255);
  end;

  try
    fs := TFileStream.Create(aName, fmCreate);
    repeat
      fs.Write(MBBuffer, SizeOf(MbBuffer));
    until (fs.Size >= aSize) or (StopGenerating = true);
    fs.Free;
  finally
    result := true;
  end;
 end;

procedure TForm1.cbStringTypeChange(Sender: TObject);
var
  usersselection_text : string;
begin
  {
    options are :
    0 : My own string
    1 : Random strings
    2 : Just line numbers
  }
  case cbStringType.ItemIndex of
  0: usersselection_text := 'ownstring';
  1: usersselection_text := 'randomstrings';
  2: usersselection_text := 'linenumbers';
  end;

  if usersselection_text = 'ownstring' then
  begin
    ledtOwnString.Visible:=true;
  end;

  if usersselection_text = 'randomstrings' then
  begin
    ledtOwnString.Visible:=false;
  end;

  if usersselection_text = 'linenumbers' then
  begin
    ledtOwnString.Visible:=false;
  end;

end;

// Determine how big the files are to be
procedure TForm1.cbFileSizeChange(Sender: TObject);
var
  B: byte;
  KB: word;
  MB: QWord;
  GB: QWord;
  TB: QWord;
begin
  usersselection_files := '';
    {
    Bytes (B)
    Kilobytes (Kb)
    Megabytes (Mb)
    Gigabytes (Gb)
    }
  case cbFileSize.ItemIndex of
    0: usersselection_files := 'b';
    1: usersselection_files := 'Kb';
    2: usersselection_files := 'Mb';
    3: usersselection_files := 'Gb';
    4: usersselection_files := 'Tb';
  end;

  B  := 1;         //byte
  KB := 1024 * B;  //kilobyte
  MB := 1024 * KB; //megabyte
  GB := 1024 * MB; //gigabyte
  TB := 1024 * GB; //terabyte

 if lbledtFileSize.Text <> '' then
 begin
   if usersselection_files = 'b' then
   begin
     FileSizeNeeded := strtoint(lbledtFileSize.Text) * B;
     Label1.Caption := 'File size: ' + FormatByteSize(FileSizeNeeded);
   end
     else
       if usersselection_files = 'Kb' then
       begin
         FileSizeNeeded := strtoint(lbledtFileSize.Text) * Kb;
         Label1.Caption := 'File size: ' + FormatByteSize(FileSizeNeeded);
       end
         else
           if usersselection_files = 'Mb' then
           begin
             FileSizeNeeded := strtoint(lbledtFileSize.Text) * Mb;
             Label1.Caption := 'File size: ' + FormatByteSize(FileSizeNeeded);
           end
             else
               if usersselection_files = 'Gb' then
               begin
                 FileSizeNeeded := strtoint(lbledtFileSize.Text) * Gb;
                 Label1.Caption := 'File size: ' + FormatByteSize(FileSizeNeeded);
               end
                 else
                   if usersselection_files = 'Tb' then
                    begin
                      FileSizeNeeded := strtoint(lbledtFileSize.Text) * Tb;
                      Label1.Caption := 'File size: ' + FormatByteSize(FileSizeNeeded);
                    end;
  end;
end;


// Format the file size to the proper human readable convention for display purposes
function TForm1.FormatByteSize(const bytes: QWord): string;
var
  B : byte;
  KB: word;
  MB: QWord;
  GB: QWord;
  TB: QWord;
begin

  B  := 1;           //byte
  KB := 1024 * B;   //kilobyte
  MB := 1024 * KB;  //megabyte
  GB := 1024 * MB;  //gigabyte
  TB := 1024 * GB;  //terabyte

  if bytes > TB then
    result := FormatFloat('#.## TiB', bytes / TB)
  else
    if bytes > GB then
      result := FormatFloat('#.## GiB', bytes / GB)
    else
      if bytes > MB then
        result := FormatFloat('#.## MiB', bytes / MB)
      else
        if bytes > KB then
          result := FormatFloat('#.## KiB', bytes / KB)
        else
          result := FormatFloat('#.## bytes', bytes) ;
end;

end.

