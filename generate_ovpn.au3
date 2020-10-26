#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
#include <File.au3>

$INI        = "generate_ovpn.ini"
$COMPANY    = IniRead ( $INI, "main", "company", "company" )
$KEYPASS    = IniRead ( $INI, "main", "keypass", "keypass" )
$nameCA     = IniRead ( $INI, "main", "CA", "CA" )
$OPENSSL    = IniRead ( $INI, "main", "openssl", "openssl.exe" )

If Not FileExists($INI) Then
    MsgBox(0,"Error", $INI & " neexistuje")
    Exit
EndIf

If Not FileExists($OPENSSL) Then
    MsgBox(0,"Error", $OPENSSL & " neexistuje")
    Exit
EndIf

$FileList = _FileListToArray(".","cert_export_*.key")
If @error = 1 Then
    MsgBox(0, "", "No Files\Folders Found.")
    Exit
EndIf

;konverze klíče do verze bez hesla
Local $user[$FileList[0]+1]
$splash = SplashTextOn("","",200,100)
For $i = 1 To $FileList[0]
    $u=StringRegExp($FileList[$i], _
        'cert_export_(.+)\.key', $STR_REGEXPARRAYMATCH)
    $user[$i]=$u[0]
    ControlSetText("","",$splash,"Konvertuji klíč " & $user[$i])
    $fileKey =  $FileList[$i] & "-nopass"
    RunWait($OPENSSL & " rsa -passin pass:" & $KEYPASS & " -in " & $FileList[$i] & " -out " & $fileKey,"",@SW_HIDE)
    If not FileExists($fileKey) Then
        SplashOff()
        MsgBox(0,"Error", "Soubor s klíčem " & $fileKey & " nebyl vytvořen")
        Exit
    EndIf
Next

For $i = 1 To $FileList[0]
    ControlSetText("","",$splash,"Vytvářím OVPN pro  " & $user[$i])
    $fileOvpn   = $COMPANY & "-" & $user[$i] & ".ovpn"
    $fileCrt    = "cert_export_" & $user[$i] & ".crt"
    $fileKey    = "cert_export_" & $user[$i] & ".key-nopass"
    $fileCA     = "cert_export_" & $nameCA & ".crt"
    
    $sizeCrt    = FileGetSize($fileCrt)
    $sizeKey    = FileGetSize($fileKey)
    $sizeCA     = FileGetSize($fileCA)
    $sizeTempl  = FileGetSize("template.ovpn")

    $template   = FileRead("template.ovpn",$sizeTempl)
    $txtCA      = FileRead($fileCA,$sizeCA)
    $txtCrt     = FileRead($fileCrt,$sizeCrt)
    $txtKey     = FileRead($fileKey,$sizeKey)
    
    $file      = FileOpen($fileOvpn,$FO_OVERWRITE)
    FileWrite($file,$template)
    FileWrite($file, @CRLF & "<cert>" & @CRLF & $txtCrt & "</cert>")
    FileWrite($file, @CRLF & "<key>" & @CRLF & $txtKey & "</key>")
    FileWrite($file, @CRLF & "<ca>" & @CRLF & $txtCA & "</ca>")
    FileClose($file)

    ; výsledný OVPN musí být vždy větší
    $sizeOvpn       = FileGetSize($fileOvpn)
    $copmaresize    = ($sizeCrt + $sizeKey + $sizeTempl + $sizeCA - $sizeOvpn)
    If  $copmaresize > 0 Then
        SplashOff()
        MsgBox(0,"Error " & $user[$i],"Soucet zdrojovych souboru: " & ($sizeCrt + $sizeKey + $sizeTempl) & " oproti OVPN: " & $sizeOvpn & " je vetší než OVPN, zřejme se nenaimporovalo vše.")
        Exit
    Endif
Next

SplashOff()
MsgBox(0, "Key", "Vytvořeno " & $i-1 & " OVPN souborů.")

