unit mneCSVForms;
{**
 *  This file is part of the "Mini Library"
 *
 * @license   modifiedLGPL (modified of http://www.gnu.org/licenses/lgpl.html)
 *            See the file COPYING.MLGPL, included in this distribution,
 * @author    Zaher Dirkey <zaher at parmaja dot com>
 *}

{*TODO
  * No header grid
  * Sort column
  * Options on Tendency
  * View as text
  * Find and Replace
}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Grids, ExtCtrls, StdCtrls,
  FileUtil, LCLType, Graphics, Menus, Buttons, EditorEngine, IniFiles,
  MsgBox, mnStreams, mncConnections, mncCSV;

type

  { TCSVForm }

  TCSVForm = class(TFrame, IEditorControl)
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    IsRtlMnu: TMenuItem;
    SaveConfigFileBtn: TButton;
    DataGrid: TStringGrid;
    FetchCountLbl: TLabel;
    FetchedLbl: TLabel;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    Panel2: TPanel;
    GridPopupMenu: TPopupMenu;
    StopBtn: TButton;
    StopBtn2: TButton;
    OptionsBtn: TButton;
    DelConfigFileBtn: TButton;

    procedure ConfigFileBtnClick(Sender: TObject);

    procedure DataGridColRowMoved(Sender: TObject; IsColumn: Boolean; sIndex, tIndex: Integer);
    procedure DataGridDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
    procedure DataGridGetEditText(Sender: TObject; ACol, ARow: Integer; var Value: string);

    procedure DataGridHeaderClick(Sender: TObject; IsColumn: Boolean; Index: Integer);
    procedure DataGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    procedure DataGridSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);

      procedure DataGridSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
    procedure DelConfigFileBtnClick(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure MenuItem6Click(Sender: TObject);
    procedure MenuItem8Click(Sender: TObject);
    procedure IsRtlMnuClick(Sender: TObject);
    procedure StopBtn2Click(Sender: TObject);
    procedure OptionsBtnClick(Sender: TObject);
    procedure StopBtnClick(Sender: TObject);
  private
    FOnChanged: TNotifyEvent;
    FOldValue: String;
  protected
    FCancel: Boolean;
    IsNumbers: array of boolean;
    FFileName: string;
    procedure Changed;
  public
    IsRTL: Boolean;
    CSVOptions: TmncCSVOptions;
    FInteractive: Boolean;
    FLoading: Boolean;
    procedure RenameHeader(Index: Integer);
    procedure RefreshControls;
    function IsConfigFileExists: Boolean;
    procedure SaveConfigFile;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
    procedure ClearGrid;
    procedure FillGrid(SQLCMD: TmncCommand; Title: String);
    procedure Load(FileName: string);
    procedure Save(FileName: string);
    constructor Create(TheOwner: TComponent); override;
    function GetMainControl: TWinControl;
  end;

implementation

uses
  mnUtils, CSVOptionsForms, EditorClasses;

{$R *.lfm}

procedure RemoveRows(Grid: TStringGrid; RowIndex, vCount: Integer);
var
  i: Integer;
begin
  with Grid do
  begin
    BeginUpdate;
    try
      for i := RowIndex to RowCount - vCount - 1 do
        Rows[i] := Rows[i + vCount];
      RowCount := RowCount - vCount;
    finally
      EndUpdate;
    end;
  end;
end;

procedure RemoveCols(Grid: TStringGrid; ColIndex, vCount: Integer);
var
  i: Integer;
begin
  with Grid do
  begin
    BeginUpdate;
    try
      for i := ColIndex to ColCount - vCount - 1 do
        Cols[i] := Cols[i + vCount];
      ColCount := ColCount - vCount;
    finally
      EndUpdate;
    end;
  end;
end;

{ TCSVForm }

procedure TCSVForm.ConfigFileBtnClick(Sender: TObject);
begin
  SaveConfigFile;
  RefreshControls;
  Engine.UpdateState([ecsFolder]);
end;

procedure TCSVForm.DataGridColRowMoved(Sender: TObject; IsColumn: Boolean; sIndex, tIndex: Integer);
begin
  Changed;
end;

procedure TCSVForm.DataGridGetEditText(Sender: TObject; ACol, ARow: Integer; var Value: string);
begin
  FOldValue := Value;
end;

procedure TCSVForm.DataGridHeaderClick(Sender: TObject; IsColumn: Boolean; Index: Integer);
begin
  if IsColumn then
    RenameHeader(Index);
end;

procedure TCSVForm.DataGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_C) and (Shift = [ssCtrl]) then
    DataGrid.CopyToClipboard(True)
  else if (Key = VK_ESCAPE) and (Shift = []) then
  begin
    DataGrid.EditorMode := False;
    DataGrid.Cells[DataGrid.Col, DataGrid.Row] := FOldValue;
  end;
end;

procedure TCSVForm.DataGridSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
begin
  Changed;
end;

procedure TCSVForm.DelConfigFileBtnClick(Sender: TObject);
begin
  DeleteFile(FFileName + '.conf');
  RefreshControls;
  Engine.UpdateState([ecsFolder]);
end;

procedure TCSVForm.MenuItem1Click(Sender: TObject);
var
  r, c: Integer;
begin
  if not Msg.No('Are you sure you want to clear cells') then
  begin
    with DataGrid do
    begin
      BeginUpdate;
      try
        for r := Selection.Top to Selection.Bottom do
          for c := Selection.Left to Selection.Right do
          begin
            Cells[c, r] := '';
          end;
      finally
        EndUpdate;
      end;
    end;
    Changed;
  end;
end;

procedure TCSVForm.MenuItem2Click(Sender: TObject);
var
  s: string;
begin
  s := '1';
  if Msg.Input(s, 'Enter columns count to add') then
  begin
    DataGrid.ColCount := DataGrid.ColCount + StrToIntDef(s, 0);
    Changed;
  end;
end;

procedure TCSVForm.MenuItem3Click(Sender: TObject);
begin
  //DataGrid.DeleteCol(DataGrid.Col);
  RemoveCols(DataGrid, DataGrid.Selection.Left,DataGrid.Selection.Right - DataGrid.Selection.Left + 1);
  Changed;
end;

procedure TCSVForm.MenuItem4Click(Sender: TObject);
var
  s: string;
begin
  s := '1';
  if Msg.Input(s, 'Enter rows count to add') then
  begin
    DataGrid.RowCount := DataGrid.RowCount + StrToIntDef(s, 0);
    Changed;
  end;
end;

procedure TCSVForm.MenuItem5Click(Sender: TObject);
begin
  //DataGrid.DeleteRow(DataGrid.Row);
  RemoveRows(DataGrid, DataGrid.Selection.Top,DataGrid.Selection.Bottom - DataGrid.Selection.Top + 1);
  Changed;
end;

procedure TCSVForm.MenuItem6Click(Sender: TObject);
begin
  DataGrid.CopyToClipboard(True);
end;

procedure TCSVForm.MenuItem8Click(Sender: TObject);
begin
  RenameHeader(DataGrid.Col);
end;

procedure TCSVForm.IsRtlMnuClick(Sender: TObject);
begin
  IsRTL := IsRtlMnu.Checked;
  RefreshControls;
  Changed;
end;

procedure TCSVForm.StopBtn2Click(Sender: TObject);
begin
  if not Msg.No('Are you sure you want to clear it') then
  begin
    ClearGrid;
    Changed;
  end;
end;

procedure TCSVForm.OptionsBtnClick(Sender: TObject);
var
  aCSVOptions: TmncCSVOptions;
begin
  aCSVOptions := CSVOptions;
  if ShowCSVOptions('Export CSV', aCSVOptions) then
  begin
    CSVOptions := aCSVOptions;
    Changed;
  end
end;

procedure TCSVForm.StopBtnClick(Sender: TObject);
begin
  FCancel := True;
end;

procedure TCSVForm.Changed;
begin
  if not FLoading and Assigned(FOnChanged) then
    FOnChanged(Self);
end;

procedure TCSVForm.RenameHeader(Index: Integer);
var
  s: string;
begin
  s := DataGrid.Cells[Index, 0];
  if s = '' then
    s := 'Header' + IntToStr(Index);
  if MsgBox.Msg.Input(s, 'Rename column header') then
  begin
    DataGrid.Cells[Index, 0] := s;
    Changed;
  end;
end;

procedure TCSVForm.RefreshControls;
begin
  DelConfigFileBtn.Visible := IsConfigFileExists;
  SaveConfigFileBtn.Visible := not DelConfigFileBtn.Visible;
  IsRTLMnu.Checked := IsRTL;
  if IsRTL then
    DataGrid.BiDiMode := bdRightToLeft
  else
    DataGrid.BiDiMode := bdLeftToRight;
end;

function TCSVForm.IsConfigFileExists: Boolean;
begin
  Result := FileExists(FFileName + '.conf');
end;

procedure TCSVForm.SaveConfigFile;
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(FFileName + '.conf');
  try
    CSVOptions.SaveToIni('options', ini);
    ini.WriteBool('ui', 'rtl', IsRTL);
  finally
    ini.Free;
  end;
end;

procedure TCSVForm.ClearGrid;
begin
  IsNumbers := nil;
  DataGrid.ColWidths[0] := 20;
  DataGrid.Row := 1;
  DataGrid.Col := 1;
  DataGrid.FixedCols := 1;
  DataGrid.FixedRows := 1;
  DataGrid.ColCount := 1;
  DataGrid.RowCount := 1;
  DataGrid.Cells[0, 0] := '';
end;

procedure TCSVForm.Save(FileName: string);
var
  aFile: TFileStream;
  csvCnn: TmncCSVConnection;
  csvSes: TmncCSVSession;
  csvCMD: TmncCSVCommand;
  c, r: Integer;
begin
  FFileName := FileName;
  csvCnn := TmncCSVConnection.Create;
  csvSes := TmncCSVSession.Create(csvCnn);
  try
    csvSes.CSVOptions := CSVOptions;
    csvCnn.Connect;
    csvSes.Start;
    aFile := TFileStream.Create(FileName, fmCreate or fmOpenWrite);
    csvCMD := TmncCSVCommand.Create(csvSes, aFile, csvmWrite);
    try
      //adding header, even if we will not save it
      for c := 1 to DataGrid.ColCount - 1 do
      begin
        csvCMD.Columns.Add(DataGrid.Cells[c, 0], dtString);
      end;
      csvCMD.Prepare; //generate Params and save header
      r := 1; //first row of data
      while r < DataGrid.RowCount do
      begin
        for c := 1 to DataGrid.ColCount - 1 do
        begin
          csvCMD.Params.Items[c - 1].Value := DataGrid.Cells[c, r];
        end;
        csvCMD.Execute;
        r := r+ 1;
      end;

    finally
      aFile.Free;
    end
  finally
    csvSes.Free;
    csvCnn.Free;
  end;
  if IsConfigFileExists then
    SaveConfigFile;
end;

procedure TCSVForm.Load(FileName: string);
var
  aFile: TFileStream;
  b: Boolean;
  csvCnn: TmncCSVConnection;
  csvSes: TmncCSVSession;
  csvCMD: TmncCSVCommand;
  Ini: TIniFile;
begin
  FFileName := FileName;

  FLoading := True;
  try
    ClearGrid;
    csvCnn := TmncCSVConnection.Create;
    csvSes := TmncCSVSession.Create(csvCnn);
    try
      b := IsConfigFileExists;
      if b then
        Ini := TIniFile.Create(FFileName + '.conf')
      else
        Ini := TIniFile.Create(Engine.WorkSpace + 'mne-csv-options.ini');
      try
        CSVOptions.LoadFromIni('options', Ini);
        IsRTL := Ini.ReadBool('ui', 'rtl', false);
      finally
        Ini.Free;
      end;

      RefreshControls;

      if b or ShowCSVOptions('Export CSV', CSVOptions) then
      begin
        csvSes.CSVOptions := CSVOptions;
        csvCnn.Connect;
        csvSes.Start;
        aFile := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
        csvCMD := TmncCSVCommand.Create(csvSes, aFile, csvmRead);
        csvCMD.EmptyLine := elSkip;
        try
          if csvCMD.Execute then //not empty, or eof
            FillGrid(csvCMD, 'File: ' + FileName);
        finally
          aFile.Free;
          csvCMD.Free;
        end;

        Ini := TIniFile.Create(Engine.WorkSpace + 'mne-csv-options.ini');
        try
          CSVOptions.SaveToIni('options', Ini);
        finally
          Ini.Free;
        end;
      end;
    finally
      csvSes.Free;
      csvCnn.Free;
    end;
  finally
    FLoading := False;
  end;
  {if DataGrid.Columns.Count >0 then
    DataGrid.Columns[1].Alignment := taRightJustify;}
end;

procedure TCSVForm.FillGrid(SQLCMD: TmncCommand; Title: String);

  function GetTextWidth(Text: String): Integer;
  begin
    Result := DataGrid.Canvas.TextWidth(Text);
  end;

  function GetCharWidth: Integer;
  begin
    Result := (GetTextWidth('Wi') div 2);
  end;

var
  i, c, w: Integer;
  s: String;
  b: Boolean;
  str: string;
  startCol: integer;
  cols: Integer;
  max: array of integer;
  procedure CalcWidths;
  var
    i: Integer;
  begin
    max[0] := length(IntToStr(c));
    for i := 0 to cols do
    begin
      w := GetTextWidth(StringOfChar('W', max[i])) + 10;
      if w < 10 then
        w := 10;
      DataGrid.ColWidths[startCol + i] := w;
    end;
  end;
var
  Steps: Integer;
  HaveHeader: Boolean;
begin
  StopBtn.Enabled := True;
  Steps := 100;
  if not FInteractive then
    DataGrid.BeginUpdate;
  try
    IsNumbers := nil;
    if Title = '' then
      Caption := 'Data'
    else
      Caption := 'Data: ' + Title;

    FetchedLbl.Caption := 'Fetched: ';
    max := nil;
    FCancel := False;

    cols := SQLCMD.Columns.Count;
    HaveHeader := cols > 0;
    if not HaveHeader then
    begin
      cols := SQLCMD.Fields.Count;
    end;
    setLength(max, cols + 1);
    setLength(IsNumbers, cols + 1);

    startCol := DataGrid.ColCount - 1;
    DataGrid.ColCount := startCol + cols + 1; //1 for fixed col
    DataGrid.Col := startCol;

    if HaveHeader then
    begin
      for i := 0 to cols - 1 do
      begin
        s := SQLCMD.Columns[i].Name;
        max[i + 1] := length(s);
        DataGrid.Cells[startCol + i + 1, 0] := s;
        b := SQLCMD.Columns[i].IsNumber;
        IsNumbers[i] := b;
      end;
    end;
    c := 1;
    CalcWidths;

    if FInteractive then
      Application.ProcessMessages;

    while not SQLCMD.Done do
    begin
      if DataGrid.RowCount <= (c + 1) then
      begin
        if not FInteractive or (c >= Steps) then
          DataGrid.RowCount := c + Steps
        else
          DataGrid.RowCount := c + 1;
      end;
      DataGrid.Cells[0, c] := IntToStr(c);
      for i := 0 to cols - 1 do
      begin
        if i < SQLCMD.Fields.Count then
        begin
          str := SQLCMD.Fields.Items[i].AsString;
          if length(str) > max[i + 1] then
            max[i + 1] := length(str);
          DataGrid.Cells[startCol + i + 1, c] := str;
        end;
      end;
      Inc(c);
      //before 100 rows will see the grid row by row filled, cheeting the eyes of user
      if (c < Steps) or (Frac(c / Steps) = 0) then
      begin
        if FInteractive then
        begin
          FetchCountLbl.Caption := IntToStr(c - 1);
          CalcWidths;
        end;
        Application.ProcessMessages;
        {if c > 100000 then
          steps := 100000
        else
        if c > 10000 then
          steps := 10000
        else
        if c > 2500 then
          steps := 1000
        else }if c > 500 then
          steps := 500;
      end;
      if FCancel then
        break;
      SQLCMD.Next;
    end;
    CalcWidths;
    DataGrid.RowCount := c;
    FetchCountLbl.Caption := IntToStr(c - 1);
  finally
    if not FInteractive then
      DataGrid.EndUpdate(True);
    StopBtn.Enabled := False;
  end;
end;

constructor TCSVForm.Create(TheOwner: TComponent);
  function GetDefaultRowHeight: integer;//TODO use grid function(protected now)
  var
    TmpCanvas: TCanvas;
  begin
    with DataGrid do
    begin
      tmpCanvas := GetWorkingCanvas(Canvas);
      tmpCanvas.Font := Font;
      result := tmpCanvas.TextHeight('Fj')+7;
      if tmpCanvas<>Canvas then
        FreeWorkingCanvas(tmpCanvas);
    end;
  end;

begin
  inherited Create(TheOwner);
  FillByte(CSVOptions, Sizeof(CSVOptions), 0);
  with DataGrid do
  begin
    {Font.Name := 'Tahoma';
    Font.Size := 10;
    Font.Name := Engine.Options.Profile.Attributes.FontName;
    Font.Size := Engine.Options.Profile.Attributes.FontSize;
    if Engine.Options.Profile.Attributes.FontNoAntialiasing then
      Font.Quality := fqNonAntialiased
    else
      Font.Quality := fqDefault;}
    DefaultRowHeight := GetDefaultRowHeight;
  end;
  CSVOptions.HeaderLine := hdrNormal;
  CSVOptions.DelimiterChar := ',';
  CSVOptions.EndOfLine := sUnixEndOfLine;
  Color := Engine.Options.Profile.Attributes.Default.Background;
  Font.Color := Engine.Options.Profile.Attributes.Default.Foreground;
  DataGrid.Color := Engine.Options.Profile.Attributes.Default.Background;
  DataGrid.Font.Color := Engine.Options.Profile.Attributes.Default.Foreground;
  DataGrid.FixedColor := Engine.Options.Profile.Attributes.Panel.Background;
  DataGrid.TitleFont.Color := Engine.Options.Profile.Attributes.Panel.Foreground;
  DataGrid.GridLineColor := Engine.Options.Profile.Attributes.Separator.Foreground;

  DataGrid.FocusColor := Engine.Options.Profile.Attributes.Selected.Background;
  DataGrid.AlternateColor := Engine.Options.Profile.Attributes.Comment.Background
  //Color := Engine.Options.Profile.Attributes.Default.Background;
  //Font.Color := Engine.Options.Profile.Attributes.Default.Foreground;
end;

function TCSVForm.GetMainControl: TWinControl;
begin
  Result := DataGrid;
end;

procedure TCSVForm.DataGridDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
begin
  DataGrid.Canvas.Font.Assign(DataGrid.Font);
  DataGrid.Canvas.Font.Color := Engine.Options.Profile.Attributes.Default.Foreground;
  if (aRow < DataGrid.FixedRows) or (aCol < DataGrid.FixedCols) then
  begin
    DataGrid.Canvas.Brush.Color := Engine.Options.Profile.Attributes.Panel.Background;
    DataGrid.Canvas.Font.Color := Engine.Options.Profile.Attributes.Panel.Foreground;
  end
  else if ((aRow = DataGrid.Row) and (aCol = DataGrid.Col)) or
          ((aRow >= DataGrid.Selection.Top) and (aRow <= DataGrid.Selection.Bottom) and (aCol >= DataGrid.Selection.Left) and (aCol <= DataGrid.Selection.Right))
    then
  begin
    if DataGrid.Focused then
    begin
      DataGrid.Canvas.Brush.Color := Engine.Options.Profile.Attributes.Selected.Background;
      DataGrid.Canvas.Font.Color := Engine.Options.Profile.Attributes.Selected.Foreground;
    end
    else
    begin
      DataGrid.Canvas.Brush.Color := Engine.Options.Profile.Attributes.Text.Background;
      DataGrid.Canvas.Font.Color := Engine.Options.Profile.Attributes.Text.Foreground;
    end;
  end
  else if (aRow = DataGrid.Row) then
  begin
    DataGrid.Canvas.Brush.Color := Engine.Options.Profile.Attributes.Active.Background;
    DataGrid.Canvas.Font.Color := Engine.Options.Profile.Attributes.Active.Foreground;
  end
  else
  begin
    DataGrid.Canvas.Brush.Color := Engine.Options.Profile.Attributes.Default.Background;
  end;
  DataGrid.Canvas.FillRect(aRect);
  DataGrid.DefaultDrawCell(aCol, aRow, aRect, aState);
end;

procedure TCSVForm.DataGridSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
begin
  Editor.Font.Assign(DataGrid.Font);
  Editor.Color := Engine.Options.Profile.Attributes.Selected.Background;
  Editor.Font.Color := Engine.Options.Profile.Attributes.Selected.Foreground;
end;

end.

