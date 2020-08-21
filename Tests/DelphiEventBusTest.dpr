program DelphiEventBusTest;

{$IFNDEF TESTINSIGHT}
  {$IFNDEF GUI_TESTRUNNER}
    {$APPTYPE CONSOLE}
    {$DEFINE CONSOLE_TESTRUNNER}
  {$ENDIF}
{$ENDIF}

{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  {$IFDEF GUI_TESTRUNNER}
  Vcl.Forms,
  {$ENDIF }
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF }
  {$IFDEF CONSOLE_TESTRUNNER}
  DUnitX.Loggers.Console,
  {$ENDIF }
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  EventBusTest in 'EventBusTest.pas',
  BaseTest in 'BaseTest.pas',
  BasicObjects in 'BasicObjects.pas';

{$IFDEF CONSOLE_TESTRUNNER}
procedure MainConsole;
begin
  try
    // Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    // Create the test runner
    var runner := TDUnitX.CreateRunner;
    // Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    // tell the runner how we will log things
    // Log to the console window
    var logger := TDUnitXConsoleLogger.Create(True);
    runner.AddLogger(logger);
    // Generate an NUnit compatible XML File
    var nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);
    // When true, Assertions must be made during tests;
    runner.FailsOnNoAsserts := False;
    // Run tests
    var results := runner.Execute;
    if not results.AllPassed then System.ExitCode := EXIT_ERRORS;
    {$IFNDEF CI}
    // We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
   {$ENDIF}
  except
    on E: Exception do begin
      System.Writeln(E.ClassName, ': ', E.Message);
    end;
  end;
end;
{$ENDIF}

{$IFDEF GUI_TESTRUNNER}
procedure MainGUI;
begin
  Application.Initialize;
  Application.CreateForm(TGUIVCLTestRunner, GUIVCLTestRunner);
  Application.Run;
end;
{$ENDIF}

begin
  ReportMemoryLeaksOnShutdown := True;
{$IFDEF CONSOLE_TESTRUNNER}
  MainConsole;
{$ENDIF}

{$IFDEF GUI_TESTRUNNER}
  MainGUI;
{$ENDIF}

{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
{$ENDIF}
end.
